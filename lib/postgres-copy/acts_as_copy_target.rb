require 'csv'

def get_file_mode mode, encoding = nil
  if encoding
    "#{mode}:#{encoding}"
  else
    mode
  end
end

module PostgresCopy
  module ActsAsCopyTarget
    extend ActiveSupport::Concern

    included do
    end

    module CopyMethods
      # Copy data to a file passed as a string (the file path) or to lines that are passed to a block
      def copy_to path = nil, options = {}
        options = { delimiter: ",", format: :csv, header: true }.merge(options)
        options_string = if options[:format] == :binary
                           "BINARY"
                         else
                           "DELIMITER '#{options[:delimiter]}' CSV #{options[:header] ? 'HEADER' : ''}"
                         end
        options_query = options.delete(:query) || self.all.to_sql

        if path
          raise "You have to choose between exporting to a file or receiving the lines inside a block" if block_given?
          connection.execute "COPY (#{options_query}) TO '#{sanitize_sql(path)}' WITH #{options_string}"
        else
          connection.raw_connection.copy_data "COPY (#{options_query}) TO STDOUT WITH #{options_string}" do
            while line = connection.raw_connection.get_copy_data do
              yield(line) if block_given?
            end
          end
        end
        return self
      end

      # Create an enumerator with each line from the CSV.
      # Note that using this directly in a controller response
      # will perform very poorly as each line will get put
      # into its own chunk. Joining every (eg) 100 rows together
      # is much, much faster.
      def copy_to_enumerator(options={})
        buffer_lines = options.delete(:buffer_lines)
        # Somehow, self loses its scope once inside the Enumerator
        scope = self.current_scope || self
        result = Enumerator.new do |y|
          scope.copy_to(nil, options) do |line|
            y << line
          end
        end

        if buffer_lines.to_i > 0
          Enumerator.new do |y|
            result.each_slice(buffer_lines.to_i) do |slice|
              y << slice.join
            end
          end
        else
          result
        end
      end

      # Copy all data to a single string
      def copy_to_string options = {}
        data = ''
        self.copy_to(nil, options){|l| data << l }
        if options[:format] == :binary
          data.force_encoding("ASCII-8BIT")
        end
        data
      end

      # Copy data from a CSV that can be passed as a string (the file path) or as an IO object.
      # * You can change the default delimiter passing delimiter: '' in the options hash
      # * You can map fields from the file to different fields in the table using a map in the options hash
      # * For further details on usage take a look at the README.md
      def copy_from path_or_io, options = {}
        options = { delimiter: ",", format: :csv, header: true, quote: '"' }.merge(options)
        options[:delimiter] = "\t" if options[:format] == :tsv
        options_string = if options[:format] == :binary
                           "BINARY"
                         else
                           quote = options[:quote] == "'" ? "''" : options[:quote]
                           null = options.key?(:null) ? "NULL '#{options[:null]}'" : nil
                           force_null = options.key?(:force_null) ? "FORCE_NULL(#{options[:force_null].join(',')})" : nil
                           delimiter = options[:format] == :tsv ? "E'\t'" : "'#{options[:delimiter]}'"
                           "WITH (" + ["DELIMITER #{delimiter}", "QUOTE '#{quote}'", null, force_null, "FORMAT CSV"].compact.join(', ') + ")"
                         end
        io = path_or_io.instance_of?(String) ? File.open(path_or_io, get_file_mode('r', options[:encoding])) : path_or_io

        if options[:format] == :binary
          columns_list = options[:columns] || []
        elsif options[:header]
          line = io.gets
          columns_list = options[:columns] || line.strip.split(options[:delimiter])
        else
          columns_list = options[:columns]
        end

        table = if options[:table]
                  connection.quote_table_name(options[:table])
                else
                  quoted_table_name
                end

        columns_list = columns_list.map{|c| options[:map][c.to_s] || c.to_s } if options[:map]
        columns_string = columns_list.size > 0 ? "(\"#{columns_list.join('","')}\")" : ""
        connection.raw_connection.copy_data %{COPY #{table} #{columns_string} FROM STDIN #{options_string}} do
          if options[:format] == :binary
            bytes = 0
            begin
              while line = io.readpartial(10240)
                connection.raw_connection.put_copy_data line
                bytes += line.bytesize
              end
            rescue EOFError
            end
          else
            line_buffer = ''

            while line = io.gets do
              next if line.strip.size == 0

              line_buffer += line

              # If line is incomplete, get the next line until it terminates
              if line_buffer =~ /\n$/ || line_buffer =~ /\Z/
                if block_given?
                  begin
                    row = CSV.parse_line(line_buffer.strip, col_sep: options[:delimiter])
                    yield(row)
                    next if row.all?(&:nil?)
                    line_buffer = CSV.generate_line(row, col_sep: options[:delimiter])
                  rescue CSV::MalformedCSVError
                    next
                  end
                end

                connection.raw_connection.put_copy_data(line_buffer)

                # Clear the buffer
                line_buffer = ''
              end
            end
          end
        end
      end
    end

    module ClassMethods
      def acts_as_copy_target
        extend PostgresCopy::ActsAsCopyTarget::CopyMethods
      end
    end
  end
end

ActiveRecord::Base.send :include, PostgresCopy::ActsAsCopyTarget

require 'csv'

module PostgresCopy
  module ActsAsCopyTarget
    extend ActiveSupport::Concern

    included do
    end

    module CopyMethods
      # Copy data to a file passed as a string (the file path) or to lines that are passed to a block
      def copy_to path = nil, options = {}
        options = {:delimiter => ",", :format => :csv, :header => true}.merge(options)
        options_string = if options[:format] == :binary
                           "BINARY"
                         else
                           "DELIMITER '#{options[:delimiter]}' CSV #{options[:header] ? 'HEADER' : ''}"
                         end

        if path
          raise "You have to choose between exporting to a file or receiving the lines inside a block" if block_given?
          connection.execute "COPY (#{self.all.to_sql}) TO #{sanitize(path)} WITH #{options_string}"
        else
          connection.raw_connection.copy_data "COPY (#{self.all.to_sql}) TO STDOUT WITH #{options_string}" do
            while line = connection.raw_connection.get_copy_data do
              yield(line) if block_given?
            end
          end
        end
        return self
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
        options = {:delimiter => ",", :format => :csv, :header => true, :quote => '"'}.merge(options)
        options_string = if options[:format] == :binary
                           "BINARY"
                         else
                           quote = options[:quote] == "'" ? "''" : options[:quote]
                           null = options.key?(:null) ? "NULL '#{options[:null]}'" : ''
                           "DELIMITER '#{options[:delimiter]}' QUOTE '#{quote}' #{null} CSV"
                         end
        io = path_or_io.instance_of?(String) ? File.open(path_or_io, 'r') : path_or_io

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

        columns_list = columns_list.map{|c| options[:map][c.to_s] } if options[:map]
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
            while line = io.gets do
              next if line.strip.size == 0
              if block_given?
                row = CSV.parse_line(line.strip, {:col_sep => options[:delimiter]})
                yield(row)
                next if row.all?{|f| f.nil? }
                line = CSV.generate_line(row, {:col_sep => options[:delimiter]})
              end
              connection.raw_connection.put_copy_data line
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

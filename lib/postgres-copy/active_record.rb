module ActiveRecord
  class Base
    # Copy data to a file passed as a string (the file path) or to lines that are passed to a block
    def self.pg_copy_to path = nil, options = {}
      options = {:delimiter => ",", :format => :csv, :header => true}.merge(options)
      options_string = if options[:format] == :binary
                        "BINARY"
                       else
                        "DELIMITER '#{options[:delimiter]}' CSV #{options[:header] ? 'HEADER' : ''}"
                       end

      if path
        raise "You have to choose between exporting to a file or receiving the lines inside a block" if block_given?
        connection.execute "COPY (#{self.scoped.to_sql}) TO #{sanitize(path)} WITH #{options_string}"
      else
        connection.execute "COPY (#{self.scoped.to_sql}) TO STDOUT WITH #{options_string}"
        while line = connection.raw_connection.get_copy_data do
          yield(line) if block_given?
        end
      end
      return self
    end

    # Copy all data to a single string
    def self.pg_copy_to_string options = {}
      data = ''
      self.pg_copy_to(nil, options){|l| data << l }
      if options[:format] == :binary
        data.force_encoding("ASCII-8BIT")
      end
      data
    end

    # Copy data from a CSV that can be passed as a string (the file path) or as an IO object.
    # * You can change the default delimiter passing delimiter: '' in the options hash
    # * You can map fields from the file to different fields in the table using a map in the options hash
    # * For further details on usage take a look at the README.md
    def self.pg_copy_from path_or_io, options = {}
      options.reverse_merge!({:delimiter => ",", :format => :csv, :header => true})
      options_string = options[:format] == :binary ? "BINARY" : "DELIMITER '#{options[:delimiter]}' CSV"

      io = path_or_io.instance_of?(String) ? File.open(path_or_io, 'r') : path_or_io
      columns_list = get_columns_list(io, options)
      table = get_table_name(options)

      columns_list = columns_list.map{|c| options[:map][c.to_s] } if options[:map]
      columns_string = columns_list.size > 0 ? "(\"#{columns_list.join('","')}\")" : ""
      connection.raw_connection.copy_data %{COPY #{table} #{columns_string} FROM STDIN #{options_string}} do

        if block_given?
          block = Proc.new
        end
        while line = read_input_line(io, options, &block) do
          next if line.strip.size == 0
          connection.raw_connection.put_copy_data line
        end
      end
    end

    private 

    def self.get_columns_list(io, options)
      columns_list = options[:columns] || []

      if options[:format] != :binary && options[:header]
        #if header is present, we need to strip it from io, whether we use it for the columns list or not.
        line = io.gets
          if columns_list.empty?
            columns_list = line.strip.split(options[:delimiter])
          end
      end
      return columns_list
    end

    def self.get_table_name(options)
      if options[:table]
        connection.quote_table_name(options[:table])
      else
        quoted_table_name
      end
    end

    def self.read_input_line(io, options)
      if options[:format] == :binary
        begin
          return io.readpartial(10240)
        rescue EOFError
        end
      else
        line = io.gets
        if block_given? && line
          row = line.strip.split(options[:delimiter])
          yield(row)
          line = row.join(options[:delimiter]) + "\n"
        end
        return line
      end
    end

  end
end

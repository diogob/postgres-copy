module ActiveRecord
  class Base
    def self.pg_copy_to path = nil, options = {}
      options = {:delimiter => ","}.merge(options)
      if path
        raise "You have to choose between exporting to a file or receiving the lines inside a block" if block_given?
        connection.execute "COPY (#{self.scoped.to_sql}) TO #{sanitize(path)} WITH DELIMITER '#{options[:delimiter]}' CSV HEADER"
      else
        connection.execute "COPY (#{self.scoped.to_sql}) TO STDOUT WITH DELIMITER '#{options[:delimiter]}' CSV HEADER"
        while line = connection.raw_connection.get_copy_data do
          yield(line) if block_given?
        end
      end
      return self
    end
    
    def self.pg_copy_to_string options = {}
      # It would be cool to work like an Enumerable
      data = ''
      self.pg_copy_to(nil, options){|l| data += l }
      data
    end

    def self.pg_copy_from path_or_io, options = {}
      options = {:delimiter => ","}.merge(options)
      io = path_or_io.instance_of?(String) ? File.open(path_or_io, 'r') : path_or_io
      # The first line should be always the HEADER.
      line = io.gets
      columns_list = options[:columns] || line.strip.split(options[:delimiter])
      columns_list = columns_list.map{|c| options[:map][c.to_s] } if options[:map]
      connection.execute %{COPY #{quoted_table_name} ("#{columns_list.join('","')}") FROM STDIN WITH DELIMITER '#{options[:delimiter]}' CSV}
      while line = io.gets do
        next if line.strip.size == 0
        if block_given?
          row = line.strip.split(options[:delimiter])
          yield(row)
          line = row.join(options[:delimiter]) + "\n"
        end
        connection.raw_connection.put_copy_data line
      end
      connection.raw_connection.put_copy_end
    end
  end
end

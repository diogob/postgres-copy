module ActiveRecord
  class Base
    def self.pg_copy_to path = nil
      if path
        raise "You have to choose between exporting to a file or receiving the lines inside a block" if block_given?
        connection.execute "COPY (#{self.scoped.to_sql}) TO #{sanitize(path)} WITH DELIMITER '\t' CSV HEADER"
      else
        connection.execute "COPY (#{self.scoped.to_sql}) TO STDOUT WITH DELIMITER '\t' CSV HEADER"
        while line = connection.raw_connection.get_copy_data do
          yield(line) if block_given?
        end
      end
      return self
    end

    def self.pg_copy_from path_or_io, options = {:delimiter => "\t"}
      if path_or_io.instance_of? String
        connection.execute "COPY #{quoted_table_name} FROM #{sanitize(path_or_io)} WITH DELIMITER '#{options[:delimiter]}' CSV HEADER"
      else
        connection.execute "COPY #{quoted_table_name} FROM STDIN WITH DELIMITER '#{options[:delimiter]}' CSV"
        line = path_or_io.gets
        header = line.strip.split(options[:delimiter])
        while line = path_or_io.gets do
          if block_given?
            row = line.strip.split(options[:delimiter])
            yield(row)
            line = row.join(options[:delimiter])
          end
          connection.raw_connection.put_copy_data line
        end
        connection.raw_connection.put_copy_end
      end
    end
  end
end

module ActiveRecord
  class Base
    def self.pg_copy_to path = nil
      if path
        raise "You have to choose between exporting to a file or receiving the lines inside a block" if block_given?
        connection.execute "COPY (#{self.scoped.to_sql}) TO '#{path}' WITH DELIMITER '\t' CSV HEADER"
      else
        connection.execute "COPY (#{self.scoped.to_sql}) TO STDOUT WITH DELIMITER '\t' CSV HEADER"
        while line = connection.raw_connection.get_copy_data do
          yield(line) if block_given?
        end
      end
      return self
    end
    def self.pg_copy_from path_or_io, field_map = nil
      if path_or_io.instance_of? String
        connection.execute "COPY #{quoted_table_name} FROM '#{path_or_io}' WITH DELIMITER '\t' CSV HEADER"
      end
    end
  end
end

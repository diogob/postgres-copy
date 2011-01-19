module ActiveRecord
  class Base
    def self.pg_copy_to path = nil
      raise "You have to choose between exporting to a file or receiving the lines inside a block" if path and block_given?
      if path
        connection.execute "COPY (#{self.scoped.to_sql}) TO '#{path}' WITH DELIMITER '\t' CSV HEADER"
        return
      end
      connection.execute "COPY (#{self.scoped.to_sql}) TO STDOUT WITH DELIMITER '\t' CSV HEADER"
      while line = connection.raw_connection.get_copy_data do
        yield(line) if block_given?
      end
    end
  end
end

module PostgresCopy
  module WithTempTable
    def self.generate(connection = ActiveRecord::Base.connection, base_klass:
      ActiveRecord::Base, temp_table_name: nil, create_table_opts: {id: :bigint})
      raise "You have to pass a table schema definition block!" unless block_given?
      table_name = temp_table_name || "temp_table_#{SecureRandom.hex}"

      connection.create_table table_name, temporary: true, **create_table_opts do |t|
        yield t
      end

      klass = Class.new(base_klass) do
        acts_as_copy_target
        self.table_name = table_name
      end
    end
  end
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fixtures/test_model'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  config.before(:suite) do
    # we create a test database if it does not exist
    # I do not use database users or password for the tests, using ident authentication instead
    begin
      ActiveRecord::Base.establish_connection(
        :adapter  => "postgresql",
        :host     => "localhost",
        :database => "ar_pg_copy_test"
      )
      ActiveRecord::Base.connection.execute %{
        SET client_min_messages TO warning;
        DROP TABLE IF EXISTS test_models; 
        CREATE TABLE test_models (id serial PRIMARY KEY, data text);
}
    rescue Exception => e
      puts "RESCUE"
      ActiveRecord::Base.establish_connection(
        :adapter  => "postgresql",
        :host     => "localhost",
        :database => "postgres"
      )
      ActiveRecord::Base.connection.execute "CREATE DATABASE ar_pg_copy_test"
      retry
    end
  end

  config.before(:each) do
    ActiveRecord::Base.connection.execute %{
      TRUNCATE TABLE test_models;
      SELECT setval('test_models_id_seq', 1, false);
}
    TestModel.create :data => 'test data 1'
  end

end

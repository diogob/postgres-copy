$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fixtures/test_model'
require 'fixtures/extra_field'
require 'rspec'
require 'rspec/autorun'

RSpec.configure do |config|
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
        DROP TABLE IF EXISTS extra_fields; 
        CREATE TABLE test_models (id serial PRIMARY KEY, data text);
        CREATE TABLE extra_fields (id serial PRIMARY KEY, data text, created_at timestamp, updated_at timestamp);
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

end

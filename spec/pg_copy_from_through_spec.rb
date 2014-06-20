require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "COPY FROM with :through_table option" do
  before(:each) do
    ActiveRecord::Base.connection.execute %{
      TRUNCATE TABLE test_models;
      SELECT setval('test_models_id_seq', 1, false);
    }
    TestModel.create(id: 1, data: "From the before time, in the long long ago")
  end

  it "should not violate primary key constraint" do
    expect{
      TestModel.pg_copy_from File.expand_path('spec/fixtures/comma_with_header.csv'), :through_table => "test_models_temp"
    }.to_not raise_error
  end

  it "should upsert (update existing records and insert new records)" do
    TestModel.pg_copy_from File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t", :through_table => "test_models_temp"
    TestModel.order(:id).all.map{|r| r.attributes}.
      should == [{"id"=>1, "data"=>"test data 1"}, {"id"=>2, "data"=>"test data 2"}]
  end

  it "should require columns option if no header" do
    expect{
      TestModel.pg_copy_from File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary, :through_table => "test_models_temp"
      }.to raise_error("The :through_table option requires either the :columns option or :header => true")
  end

  it "should clean up the temp table after completion" do
    TestModel.pg_copy_from File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t", :through_table => "test_models_temp"
    ActiveRecord::Base.connection.tables.should_not include("test_models_temp")
  end

  it "should gracefully drop the temp table if it already exists" do
    ActiveRecord::Base.connection.execute "CREATE TEMP TABLE test_models_temp (LIKE test_models);"

    TestModel.pg_copy_from File.expand_path('spec/fixtures/tab_with_two_lines.csv'), :delimiter => "\t", :through_table => "test_models_temp"
    TestModel.order(:id).all.map{|r| r.attributes}.
      should == [{"id"=>1, "data"=>"test data 1"}, {"id"=>2, "data"=>"test data 2"}]
  end

end

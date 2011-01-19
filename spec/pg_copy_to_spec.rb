require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "COPY TO" do
  before(:all) do
    ActiveRecord::Base.connection.execute %{
      TRUNCATE TABLE test_models;
      SELECT setval('test_models_id_seq', 1, false);
}
    TestModel.create :data => 'test data 1'
  end

  it "should copy and pass data to block if block is given and no path is passed" do
    File.open('spec/fixtures/semicolon_with_header.csv', 'r') do |f|
      TestModel.pg_copy_to do |row|
        row.should == f.readline
      end
    end
  end

  it "should copy to disk if block is not given and a path is passed" do
    TestModel.pg_copy_to '/tmp/export.csv'
    File.open('spec/fixtures/semicolon_with_header.csv', 'r') do |fixture|
      File.open('/tmp/export.csv', 'r') do |result|
        result.read.should == fixture.read
      end
    end
  end

  it "should raise exception if I pass a path and a block simultaneously" do
    lambda do
      TestModel.pg_copy_to('/tmp/bogus_path') do |row|
      end
    end.should raise_error
  end
end

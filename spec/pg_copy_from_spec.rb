require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "COPY FROM" do
  before(:each) do
    ActiveRecord::Base.connection.execute %{
      TRUNCATE TABLE test_models;
      SELECT setval('test_models_id_seq', 1, false);
}
  end

  it "should import from file if path is passed without field_map" do
    TestModel.pg_copy_from File.expand_path('spec/fixtures/tab_with_header.csv')
    TestModel.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should import from IO without field_map" do
    TestModel.pg_copy_from File.open(File.expand_path('spec/fixtures/tab_with_header.csv'), 'r')
    TestModel.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should import with custom delimiter from path" do
    TestModel.pg_copy_from File.expand_path('spec/fixtures/semicolon_with_header.csv'), :delimiter => ';'
    TestModel.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should import with custom delimiter from IO" do
    TestModel.pg_copy_from File.open(File.expand_path('spec/fixtures/semicolon_with_header.csv'), 'r'), :delimiter => ';'
    TestModel.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should import and allow changes in block" do
    TestModel.pg_copy_from(File.open(File.expand_path('spec/fixtures/tab_with_header.csv'), 'r')) do |row|
      row[1] = 'changed this data'
    end
    TestModel.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'changed this data'}]
  end

  it "should import 2 lines and allow changes in block" do
    TestModel.pg_copy_from(File.open(File.expand_path('spec/fixtures/tab_with_two_lines.csv'), 'r')) do |row|
      row[1] = 'changed this data'
    end
    TestModel.order(:id).first.attributes.should == {'id' => 1, 'data' => 'changed this data'}
    TestModel.count.should == 2
  end

  it "should be able to copy from using custom set of columns" do
    TestModel.pg_copy_from(File.open(File.expand_path('spec/fixtures/tab_only_data.csv'), 'r'), :columns => ["data"])
    TestModel.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "default set of columns should be all table columns minus [id, created_at, updated_at]" do
    ExtraField.pg_copy_from(File.open(File.expand_path('spec/fixtures/tab_with_header.csv'), 'r'))
    ExtraField.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1', 'created_at' => nil, 'updated_at' => nil}]
  end

  it "should be able to map the header in the file to diferent column names" do
    TestModel.pg_copy_from(File.open(File.expand_path('spec/fixtures/tab_with_different_header.csv'), 'r'), :map => {'cod' => 'id', 'info' => 'data'})
    TestModel.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should be able to map the header in the file to diferent column names with custom delimiter" do
    TestModel.pg_copy_from(File.open(File.expand_path('spec/fixtures/semicolon_with_different_header.csv'), 'r'), :delimiter => ';', :map => {'cod' => 'id', 'info' => 'data'})
    TestModel.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should ignore empty lines" do
    TestModel.pg_copy_from(File.open(File.expand_path('spec/fixtures/tab_with_extra_line.csv'), 'r'))
    TestModel.order(:id).all.map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should raise error in malformed files" do
    lambda do
      TestModel.pg_copy_from(File.open(File.expand_path('spec/fixtures/tab_with_error.csv'), 'r'))
    end.should raise_error
    TestModel.order(:id).all.map{|r| r.attributes}.should == []
  end

  it "should copy from even when table fields need identifier quoting" do
    ReservedWordModel.pg_copy_from File.expand_path('spec/fixtures/reserved_words.csv')
    ReservedWordModel.order(:id).all.map{|r| r.attributes}.should == [{"group"=>"group name", "id"=>1, "select"=>"test select"}]
  end
end


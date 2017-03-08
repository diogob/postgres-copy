require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "COPY FROM" do
  before(:each) do
    ActiveRecord::Base.connection.execute %{
      TRUNCATE TABLE test_models;
      TRUNCATE TABLE test_extended_models;
      SELECT setval('test_models_id_seq', 1, false);
    }
  end

  it "should import from file if path is passed without field_map" do
    TestModel.copy_from File.expand_path('spec/fixtures/comma_with_header.csv')
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should import from IO without field_map" do
    TestModel.copy_from File.open(File.expand_path('spec/fixtures/comma_with_header.csv'), 'r')
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should import with custom delimiter from path" do
    TestModel.copy_from File.expand_path('spec/fixtures/semicolon_with_header.csv'), :delimiter => ';'
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should import with custom delimiter from IO" do
    TestModel.copy_from File.open(File.expand_path('spec/fixtures/semicolon_with_header.csv'), 'r'), :delimiter => ';'
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should import and allow changes in block" do
    TestModel.copy_from(File.open(File.expand_path('spec/fixtures/comma_with_header.csv'), 'r')) do |row|
      row[1] = 'changed this data'
    end
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'changed this data'}]
  end

  it "should import 2 lines and allow changes in block" do
    TestModel.copy_from(File.open(File.expand_path('spec/fixtures/tab_with_two_lines.csv'), 'r'), :delimiter => "\t") do |row|
      row[1] = 'changed this data'
    end
    TestModel.order(:id).first.attributes.should == {'id' => 1, 'data' => 'changed this data'}
    TestModel.count.should == 2
  end

  it "should be able to copy from using custom set of columns" do
    TestModel.copy_from(File.open(File.expand_path('spec/fixtures/tab_only_data.csv'), 'r'), :delimiter => "\t", :columns => ["data"])
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "default set of columns should be all table columns minus [id, created_at, updated_at]" do
    ExtraField.copy_from(File.open(File.expand_path('spec/fixtures/comma_with_header.csv'), 'r'))
    ExtraField.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1', 'created_at' => nil, 'updated_at' => nil}]
  end

  it "should not expect a header when :header is false" do
    TestModel.copy_from(File.open(File.expand_path('spec/fixtures/comma_without_header.csv'), 'r'), :header => false, :columns => [:id,:data])
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should use the table name given by :table" do
    ExtraField.copy_from(File.open(File.expand_path('spec/fixtures/comma_without_header.csv'), 'r'), :header => false, :columns => [:id,:data], :table => "test_models")
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should be able to map the header in the file to diferent column names" do
    TestModel.copy_from(File.open(File.expand_path('spec/fixtures/tab_with_different_header.csv'), 'r'), :delimiter => "\t", :map => {'cod' => 'id', 'info' => 'data'})
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should be able to map the header in the file to diferent column names with custom delimiter" do
    TestModel.copy_from(File.open(File.expand_path('spec/fixtures/semicolon_with_different_header.csv'), 'r'), :delimiter => ';', :map => {'cod' => 'id', 'info' => 'data'})
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should ignore empty lines" do
    TestModel.copy_from(File.open(File.expand_path('spec/fixtures/tab_with_extra_line.csv'), 'r'), :delimiter => "\t")
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test data 1'}]
  end

  it "should ignore all-nil rows" do
    lambda do
      TestModel.copy_from(File.open(File.expand_path('spec/fixtures/tab_with_error.csv'), 'r'), :delimiter => "\t") do |row|
        0.upto(row.length) {|idx| row[idx] = nil}
      end
    end.should_not raise_error
    TestModel.order(:id).map{|r| r.attributes}.should == []
  end

  #we should implement this later
  #it "should raise error in malformed files" do
    #lambda do
      #TestModel.copy_from(File.open(File.expand_path('spec/fixtures/tab_with_error.csv'), 'r'))
    #end.should raise_error
    #TestModel.order(:id).map{|r| r.attributes}.should == []
  #end

  it "should copy from even when table fields need identifier quoting" do
    ReservedWordModel.copy_from File.expand_path('spec/fixtures/reserved_words.csv'), :delimiter => "\t"
    ReservedWordModel.order(:id).map{|r| r.attributes}.should == [{"group"=>"group name", "id"=>1, "select"=>"test select"}]
  end
  
  it "should import even last columns have empty values" do
    TestExtendedModel.copy_from File.expand_path('spec/fixtures/comma_with_header_empty_values_at_the_end.csv')
    TestExtendedModel.order(:id).map{|r| r.attributes}.should == 
      [{"id"=>1, "data"=>"test data 1", "more_data"=>nil, "other_data"=>nil, "final_data"=>nil},
       {"id"=>2, "data"=>"test data 2", "more_data"=>"9", "other_data"=>nil, "final_data"=>nil},
       {"id"=>3, "data"=>"test data 2", "more_data"=>"9", "other_data"=>nil, "final_data"=>"0"}]
  end
  
  it "should import even last columns have empty values with block" do
    TestExtendedModel.copy_from File.expand_path('spec/fixtures/comma_with_header_empty_values_at_the_end.csv') do |row|
      row[4]="666"
    end
    TestExtendedModel.order(:id).map{|r| r.attributes}.should == 
      [{"id"=>1, "data"=>"test data 1", "more_data"=>nil, "other_data"=>nil, "final_data"=>"666"},
       {"id"=>2, "data"=>"test data 2", "more_data"=>"9", "other_data"=>nil, "final_data"=>"666"},
       {"id"=>3, "data"=>"test data 2", "more_data"=>"9", "other_data"=>nil, "final_data"=>"666"}]
  end

  it "should import lines with single quotes" do
    TestModel.copy_from(File.open(File.expand_path('spec/fixtures/semicolon_with_quote.csv'), 'r'), :delimiter => ";", :quote => "'")
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test "data" 1'}]
  end

  it "should import lines with commas inside fields with default options" do
    TestModel.copy_from(File.open(File.expand_path('spec/fixtures/comma_inside_field.csv'), 'r'))
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test, again'}]
  end

  it "should import lines with commas inside fields with block given" do
    File.open(File.expand_path('spec/fixtures/comma_inside_field.csv'), 'r') do |file|
      TestModel.copy_from(file) do |row|
        # since our CSV line look like this: {1,"test, again"} we expect only two elements withing row
        row.size.should == 2
        row[0].should == '1'
        row[1].should == 'test, again'
      end
    end
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'test, again'}]
  end

  it "should import with custom null expression from path" do
    TestModel.copy_from File.expand_path('spec/fixtures/special_null_with_header.csv'), :null => 'NULL'
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => nil}]
  end

  it "should import with custom null expression from IO" do
    TestModel.copy_from File.open(File.expand_path('spec/fixtures/special_null_with_header.csv'), 'r'), :null => 'NULL'
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => nil}]
  end
end

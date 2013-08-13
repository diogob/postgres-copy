require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "COPY FROM BINARY" do
  before(:each) do
    ActiveRecord::Base.connection.execute %{
      TRUNCATE TABLE test_models;
      SELECT setval('test_models_id_seq', 1, false);
}
  end

  it "should import from file if path is passed without field_map" do
    TestModel.pg_copy_from File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary, columns: [:id, :data]
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'text'}]
  end

  it "should import from file if columns are not specified" do
    TestModel.pg_copy_from File.expand_path('spec/fixtures/2_col_binary_data.dat'), :format => :binary
    TestModel.order(:id).map{|r| r.attributes}.should == [{'id' => 1, 'data' => 'text'}]
  end

end


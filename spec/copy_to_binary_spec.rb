require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "COPY TO BINARY" do
  before(:all) do
    ActiveRecord::Base.connection.execute %{
      TRUNCATE TABLE test_models;
      SELECT setval('test_models_id_seq', 1, false);
}
    TestModel.create :data => 'text'
  end

  describe "should allow binary output to string" do
    context "with only binary option" do
      subject{ TestModel.copy_to_string(:format => :binary) }
      it{ should == File.open('spec/fixtures/2_col_binary_data.dat', 'r:ASCII-8BIT').read }
    end
    context "with custom select" do
      subject{ TestModel.select("id, data").copy_to_string(:format => :binary) }
      it{ should == File.open('spec/fixtures/2_col_binary_data.dat', 'r:ASCII-8BIT').read }
    end
  end
end

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'postgres-copy/with_temp_table'

describe '.generate' do
  subject(:generate) {
    PostgresCopy::WithTempTable.generate do |t|
      t.string :data
    end
  }

  it {
    generate.copy_from 'spec/fixtures/comma_with_header.csv'
    data = generate.all.first
    expect(data.id).to eq(1)
    expect(data.data).to eq('test data 1')
  }
end

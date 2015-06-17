require 'spec_helper'
require 'fileutils'

describe Mongokit::CsvTransformer do

  module MongokitTest
    class Address
      include Mongoid::Document

      mongokit :model_helpers, :csv_transformer

      multi_fields :name, :region, :district, :state

      field :zip_code, type: Integer
    end
  end

  let(:model) { MongokitTest::Address }

  describe '#import' do
    it 'array header mapping' do
      model.csv_import_mapping :address, [:name, :zip_code], headers: true do |row, attrs|
        attrs[:zip_code] = attrs[:zip_code].to_i
      end

      model.from_address_csv(fixture_file('address.csv'))

      expect(model.count).to eq 5

      record = model.first
      expect(record.name).to be_present
      expect(record.zip_code).to be_present
    end

    it 'using hash header mapping' do
      model.csv_import_mapping :full_address, {name: 0, zip_code: 1, region: 5, district: 8, state: 9}, headers: true do |row, attrs|
        attrs[:zip_code] = attrs[:zip_code].to_i
        attrs[:state].downcase!
      end

      model.from_full_address_csv(fixture_file('address.csv'))

      expect(model.count).to eq 5

      records = model.all.to_a

      [:name, :zip_code, :region, :district, :state].each do |f|
        records.each{|record|  expect(record[f]).to be_present}
      end
    end
  end

  describe "#export" do
    it 'by given fields' do

      YAML.load_file(fixture_file('address.yml')).each do |attrs|
        model.create(attrs)
      end

      model.csv_export_mapping :zipcode, [:zip_code, :name, :region] do |row, record|
        row[:zip_code] = "IN-#{row[:zip_code]}"
      end

      FileUtils.mkdir_p "#{SPEC_DIR}/tmp"
      out_file = "#{SPEC_DIR}/tmp/zipcode.csv"

      model.to_zipcode_csv(out_file)

      lines = CSV.open(out_file).readlines
      expect(lines.length).to eq model.count
      FileUtils.rm(out_file)
    end
  end
end

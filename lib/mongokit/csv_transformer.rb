require 'mongokit/csv_transformer/csv_io'

module Mongokit
  module CsvTransformer
    extend ActiveSupport::Concern

    #
    # == Example
    #   class Address
    #     include Mongoid::Document
    #
    #     mongokit :csv_transformer
    #
    #     field :name
    #     field :region
    #     field :district
    #     field :state
    #     field :zip_code, type: Integer
    #
    #     csv_import_mapping :address, [:name, :zip_code], headers: true do |row, attrs|
    #       attrs[:zip_code] = attrs[:zip_code].to_i
    #     end
    #
    #     csv_export_mapping :address, [:zip_code, :name, :region] do |row, record|
    #       row[:zip_code] = "IN-#{row[:zip_code]}"
    #     end
    #   end
    #
    #   Address.from_address_csv('address.csv') # Import
    #   Address.to_address_csv('address.csv')   # Export
    #
    module ClassMethods
      CsvTransformerError = Class.new(StandardError)

      def csv_import_mapping(name, fields, options = {},  &block)
        if respond_to?("from_#{name}_csv")
          raise CsvTransformerError, "#{name} import mapper is already defined."
        end

        self.class.instance_eval do
          define_method "from_#{name}_csv" do |file|
            options[:columns] = fields
            csv_import(file, options, &block)
          end
        end
      end

      def csv_export_mapping(name, fields, options = {},  &block)
        if respond_to?("to_#{name}_csv")
          raise CsvTransformerError, "#{name} export mapper is already defined."
        end

        self.class.instance_eval do
          define_method "to_#{name}_csv" do |file, criteria = nil|
            options[:columns] = fields
            criteria = self.all if criteria.nil?
            csv_export(file, criteria, options, &block)
          end
        end
      end

      def _csv_columns_(options = nil)
        columns = fields.collect do |f, o|
          if o.class == Mongoid::Fields::Standard && o.type != BSON::ObjectId
            o.name
          end
        end

        columns.compact!
        options ? Options.process(options[:columns] || columns, options) : columns
      end

      def csv_export(file, criteria, options = {}, &block)
        columns = _csv_columns_(options)
        io = CsvIO.new(:write, file, columns, options)

        criteria.in_batches do |records|
          records.each do |record|
            row = io.to_row(record, block)
            io << row if row
          end
        end

        io.close
      end

      def csv_import(file, options = {}, &block)
        io = CsvIO.new(:read, file, options[:columns] || _csv_columns_, options)

        io.each do |row|
          attrs = io.to_attrs(row, block)
          create(attrs) if attrs
        end
      end
    end
  end
end

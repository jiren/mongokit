require 'spec_helper'

describe Mongokit::AutoIncrement do

  module MongokitTest
    class Order
      include Mongoid::Document

      field :condition, type: Boolean, default: false

      mongokit :auto_increment

      auto_increment :order_no, pattern: "%Y%m#####", if: Proc.new{|order| order.condition }
      auto_increment :order_count, if: :some_private_method

      private

      def some_private_method
        true
      end
    end
  end

  let(:pattern_options) do
    {
      number_symbol: '#', start: 0, step: 1, pattern: '%Y%m#####', attribute: :order_no, 
      model: MongokitTest::Order, type: String, time_format: '%Y%m'
    }
  end

  let(:default_options) do
    {
      number_symbol: "#", start: 0, step: 1, attribute: :order_count,
      model: MongokitTest::Order, type: Integer
    }
  end

  let(:model) { MongokitTest::Order }

  before(:each) do
    Mongokit::Models::AutoIncrementCounter.find_or_create_with_seed(pattern_options)
    Mongokit::Models::AutoIncrementCounter.find_or_create_with_seed(default_options)
  end

  it 'increment default counter and pattern counter' do
    5.times do |i|
      c = i + 1
      order = model.create(condition: true)
      expect(model.count).to eq(c)
      expect(order.order_count).to eq(c)

      order_no = Time.now.strftime('%Y%m#####')
      order_no.gsub!('#####', "%05d" % c.to_s)
      expect(order.order_no).to eq(order_no)
    end
  end

  it "increments counter only when condition is satisfied and condition type is Proc" do
    order = model.create(condition: true)
    expect(model.count).to eq(1)
    order_no = Time.now.strftime('%Y%m#####')
    order_no.gsub!('#####', "%05d" % 1.to_s)
    expect(order.order_no).to eq(order_no)

    order1 = model.create(condition: false)
    expect(model.count).to eq(2)
    expect(order1.order_no).to eq(nil)

    order2 = model.create(condition: true)
    expect(model.count).to eq(3)
    order_no = Time.now.strftime('%Y%m#####')
    order_no.gsub!('#####', "%05d" % 2.to_s)
    expect(order2.order_no).to eq(order_no)
  end

  it "increments the counter only when condition is satified and condition type is a private method" do
    order = model.create
    expect(model.count).to eq(1)
    expect(order.order_count).to eq(1)

    order1 = model.new
    allow(order1).to receive(:some_private_method).and_return(false)
    order1.save
    expect(model.count).to eq(2)
    expect(order1.order_count).to eq(nil)

    order2 = model.create
    expect(model.count).to eq(3)
    expect(order2.order_count).to eq(2)
  end

  it 'reset counter for next month' do
    order = model.create(condition: true)
    expect(order.order_no).to include(Time.now.strftime('%Y%m'))

    time = Time.now.next_month
    allow(Time).to receive(:now).and_return(time)

    order = model.create(condition: true)
    expect(order.order_no).to include(Time.now.strftime('%Y%m00001'))
  end

  it 'set default start number' do
    model = new_model(:auto_increment)
    model.auto_increment :order_count, start: 100

    record = model.create

    expect(record.order_count).to eq 100
  end

  it 'increment by step option value' do
    model = new_model(:auto_increment)
    model.auto_increment :order_count, step: 10

    record = model.create

    expect(record.order_count).to eq 10
  end
end

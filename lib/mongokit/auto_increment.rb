require 'mongokit/auto_increment/counter'
require 'mongokit/auto_increment/formater'
require 'mongokit/models/auto_increment_counter'

module Mongokit
  module AutoIncrement
    extend ActiveSupport::Concern

    included do
      unless included_modules.include?(Mongoid::Timestamps)
        include Mongoid::Timestamps
      end
    end

    module ClassMethods
      #
      # == Example
      #   class Order
      #     include Mongoid::Document
      #     mongokit :auto_increment
      #
      #     auto_increment :order_count,
      #     auto_increment :order_no, pattern: "%Y%m#####"  # Default number symbol is #
      #   end
      #
      #   order = Order.create
      #   order.order_count  # 1
      #   order.order_no     # 20150500001
      #
      def auto_increment(attribute, _options = {})
        options = {
          number_symbol: '#',
          start:  0,
          step: 1
        }

        options.merge!(_options)
        options[:attribute] = attribute
        options[:model] = self
        options[:type] ||= Integer
        condition = options[:if] || true

        if options[:pattern]
          options[:time_format] = Mongokit::Counter.to_time_format(options[:pattern])
          options[:type] = String
        end

        field(attribute, type: options[:type])

        # create new record in counter collection
        Models::AutoIncrementCounter.find_or_create_with_seed(options)

        after_create do |doc|
          satisfied = if condition.class == TrueClass
                        true
                      elsif condition.class == Proc
                        condition.call(doc)
                      else
                        doc.instance_eval { eval(condition.to_s) }
                      end

          doc.set(attribute => Mongokit::Counter.next(options)) if satisfied 
        end

        define_method("reserve_#{attribute}!") do
          set(attribute => Mongokit::Counter.next(options))
        end

        define_method("current_#{attribute}_counter") do
          Models::AutoIncrementCounter.current_counter(options)
        end
      end
    end
  end
end

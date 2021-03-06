module Mongokit
  module MongoidDocument
    def mongokit(*modules)
      modules = modules.map(&:to_sym).uniq

      modules.each do |module_name|
        const_name = Mongokit::MODULE_NAMES[module_name]

        if const_name
          self.send :include, Mongokit.const_get(const_name)
        else
          raise MongokitError, "#{module_name} not existing in mongokit"
        end
      end
    end
  end
end

Mongoid::Document::ClassMethods.send :include, Mongokit::MongoidDocument

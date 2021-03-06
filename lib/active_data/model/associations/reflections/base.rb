module ActiveData
  module Model
    module Associations
      module Reflections
        class Base
          READ = ->(reflection, object) { object.read_attribute reflection.name }
          WRITE = ->(reflection, object, value) { object.write_attribute reflection.name, value }

          attr_reader :name, :options
          attr_accessor :parent_reflection
          delegate :association_class, to: 'self.class'

          def self.build target, generated_methods, name, options = {}, &block
            if block
              options[:class] = proc do |reflection|
                superclass = reflection.options[:class_name].to_s.presence.try(:constantize)
                klass = Class.new(superclass || Object) do
                  include ActiveData::Model
                  include ActiveData::Model::Associations
                  include ActiveData::Model::Lifecycle
                  include ActiveData::Model::Primary
                end
                target.const_set(name.to_s.classify, klass)
                klass.class_eval(&block)
                klass
              end
            end
            new(name, options)
          end

          def self.generate_methods name, target
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name} force_reload = false
                association(:#{name}).reader(force_reload)
              end

              def #{name}= value
                association(:#{name}).writer(value)
              end
            RUBY
          end

          def self.association_class
            @association_class ||= "ActiveData::Model::Associations::#{name.demodulize}".constantize
          end

          def initialize name, options = {}
            @name, @options = name.to_sym, options
          end

          def macro
            self.class.name.demodulize.underscore.to_sym
          end

          def klass
            @klass ||= options[:class] ?
              options[:class].call(self) :
              (options[:class_name].presence || name.to_s.classify).to_s.constantize
          end

          def validate?
            false
          end

          def belongs_to?
            false
          end

          def build_association object
            self.class.association_class.new object, self
          end

          def read_source object
            (options[:read] || READ).call(self, object)
          end

          def write_source object, value
            (options[:write] || WRITE).call(self, object, value)
          end

          def default object
            defaultizer = options[:default]
            if defaultizer.is_a?(Proc)
              if defaultizer.arity != 0
                defaultizer.call(object)
              else
                object.instance_exec(&defaultizer)
              end
            else
              defaultizer
            end
          end

          def inspect
            "#{self.class.name.demodulize}(#{klass})"
          end
        end
      end
    end
  end
end

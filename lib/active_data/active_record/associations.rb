module ActiveData
  module ActiveRecord
    module Associations
      module Reflections
        class EmbedsOne < ActiveData::Model::Associations::Reflections::EmbedsOne
          def is_a? klass
            super || klass == ::ActiveRecord::Reflection::AssociationReflection
          end
        end

        class EmbedsMany < ActiveData::Model::Associations::Reflections::EmbedsMany
          def is_a? klass
            super || klass == ::ActiveRecord::Reflection::AssociationReflection
          end
        end
      end

      extend ActiveSupport::Concern

      included do
        { embeds_many: Reflections::EmbedsMany, embeds_one: Reflections::EmbedsOne }.each do |(name, reflection_class)|
          define_singleton_method name do |name, options = {}, &block|
            reflection = reflection_class.build(self, self, name, options.reverse_merge(
              read: ->(reflection, object) {
                value = object.read_attribute(reflection.name)
                JSON.parse(value) if value.present?
              },
              write: ->(reflection, object, value) {
                object.send(:write_attribute, reflection.name, value ? value.to_json : nil)
              }
            ), &block)
            if ::ActiveRecord::Reflection.respond_to? :add_reflection
              ::ActiveRecord::Reflection.add_reflection self, reflection.name, reflection
            else
              self.reflections = reflections.merge(reflection.name => reflection)
            end

            callback_name = "update_#{reflection.name}_association"
            before_save callback_name
            class_eval <<-METHOD, __FILE__, __LINE__ + 1
              def #{callback_name}
                association = association(:#{reflection.name})
                result = association.save!
                association.reload
                result
              end
            METHOD
          end
        end
      end
    end
  end
end

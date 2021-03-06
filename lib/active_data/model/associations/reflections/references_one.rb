module ActiveData
  module Model
    module Associations
      module Reflections
        class ReferencesOne < ReferenceReflection
          def self.build target, generated_methods, name, *args, &block
            reflection = super
            if target < ActiveData::Model::Attributes && !target.has_attribute?(reflection.reference_key)
              target.attribute(reflection.reference_key, Integer)
            end
            reflection
          end

          def collection?
            false
          end

          def reference_key
            @reference_key ||= options[:reference_key].presence.try(:to_sym) ||
              :"#{name}_#{primary_key}"
          end
        end
      end
    end
  end
end

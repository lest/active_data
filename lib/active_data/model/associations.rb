require 'active_data/model/associations/collection/proxy'
require 'active_data/model/associations/collection/embedded'
require 'active_data/model/associations/collection/referenced'

require 'active_data/model/associations/reflections/base'
require 'active_data/model/associations/reflections/embeds_one'
require 'active_data/model/associations/reflections/embeds_many'
require 'active_data/model/associations/reflections/reference_reflection'
require 'active_data/model/associations/reflections/references_one'
require 'active_data/model/associations/reflections/references_many'

require 'active_data/model/associations/base'
require 'active_data/model/associations/embeds_one'
require 'active_data/model/associations/embeds_many'
require 'active_data/model/associations/references_one'
require 'active_data/model/associations/references_many'
require 'active_data/model/associations/nested_attributes'

module ActiveData
  module Model
    module Associations
      extend ActiveSupport::Concern

      included do
        include NestedAttributes

        class_attribute :_associations, :_association_aliases, instance_reader: false, instance_writer: false
        self._associations = {}
        self._association_aliases = {}

        delegate :association_names, to: 'self.class'

        {
          embeds_many: Reflections::EmbedsMany,
          embeds_one: Reflections::EmbedsOne,
          references_one: Reflections::ReferencesOne,
          references_many: Reflections::ReferencesMany
        }.each do |(name, reflection_class)|
          define_singleton_method name do |*args, &block|
            reflection = reflection_class.build self, generated_associations_methods, *args, &block
            self._associations = _associations.merge(reflection.name => reflection)
            reflection
          end
        end
      end

      module ClassMethods
        def reflections
          _associations
        end

        def alias_association(alias_name, association_name)
          reflection = reflect_on_association(association_name)
          raise ArgumentError.new("Can't alias undefined association `#{attribute_name}` on #{self}") unless reflection
          reflection.class.generate_methods alias_name, generated_associations_methods
          self._association_aliases = _association_aliases.merge(alias_name.to_sym => reflection.name)
          reflection
        end

        def reflect_on_association name
          name = name.to_sym
          _associations[_association_aliases[name] || name]
        end

        def association_names
          _associations.keys
        end

      private

        def attributes_for_inspect
          (_associations.map do |name, reflection|
            "#{name}: #{reflection.inspect}"
          end + [super]).join(', ')
        end

        def generated_associations_methods
          @generated_associations_methods ||= const_set(:GeneratedAssociationsMethods, Module.new)
            .tap { |proxy| include proxy }
        end
      end

      def == other
        super && association_names.all? do |association|
          public_send(association) == other.public_send(association)
        end
      end
      alias_method :eql?, :==

      def association name
        if reflection = self.class.reflect_on_association(name)
          (@_associations ||= {})[reflection.name] ||= reflection.build_association(self)
        end
      end

      def save_associations!
        association_names.all? do |name|
          association = association(name)
          result = association.save!
          association.reload
          result
        end
      end

      def valid_ancestry?
        errors.clear
        association_names.each do |name|
          association = association(name)
          if association.collection?
            association.target.each.with_index do |object, i|
              object.respond_to?(:valid_ancestry?) ?
                object.valid_ancestry? :
                object.valid?

              if object.errors.present?
                (errors.messages[name] ||= [])[i] = object.errors.messages
              end
            end
          else
            if association.target
              association.target.respond_to?(:valid_ancestry?) ?
                association.target.valid_ancestry? :
                association.target.valid?

              if association.target.errors.present?
                errors.messages[name] = association.target.errors.messages
              end
            end
          end
        end
        run_validations!
      end
      alias_method :validate_ancestry, :valid_ancestry?

      def invalid_ancestry?
        !valid_ancestry?
      end

      def validate_ancestry!
        valid_ancestry? || raise_validation_error
      end

    private

      def attributes_for_inspect
        (association_names.map do |name|
          association = association(name)
          "#{name}: #{association.inspect}"
        end + [super]).join(', ')
      end
    end
  end
end

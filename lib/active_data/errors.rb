module ActiveData
  class ActiveDataError < StandardError
  end

  class NotFound < ActiveDataError
  end

  # Backported from active_model 5
  class ValidationError < ActiveDataError
    attr_reader :model

    def initialize(model)
      @model = model
      errors = @model.errors.full_messages.join(", ")
      super(I18n.t(:"#{@model.class.i18n_scope}.errors.messages.model_invalid", errors: errors, default: :'errors.messages.model_invalid'))
    end
  end

  class UnsavableObject < ActiveDataError
  end

  class UndestroyableObject < ActiveDataError
  end

  class ObjectNotSaved < ActiveDataError
  end

  class ObjectNotDestroyed < ActiveDataError
  end

  class AssociationNotSaved < ActiveDataError
  end

  class AssociationObjectNotPersisted < ActiveDataError
  end

  class AssociationTypeMismatch < ActiveDataError
    def initialize expected, got
      super "Expected `#{expected}` (##{expected.object_id}), but got `#{got}` (##{got.object_id})"
    end
  end

  class ObjectNotFound < ActiveDataError
    def initialize object, association_name, record_id
      message = "Couldn't find #{object.class.reflect_on_association(association_name).klass.name}" \
        "with #{object.respond_to?(:_primary_name) ? object._primary_name : 'id'} = #{record_id} for #{object.inspect}"
      super message
    end
  end

  class TooManyObjects < ActiveDataError
    def initialize limit, actual_size
      super "Maximum #{limit} objects are allowed. Got #{actual_size} objects instead."
    end
  end

  class NormalizerMissing < NoMethodError
    def initialize name
      super <<-EOS
Could not find normalizer `:#{name}`
You can define it with:

  ActiveData.normalizer(:#{name}) do |value, options|
    # do some staff with value and options
  end
      EOS
    end
  end

  class TypecasterMissing < NoMethodError
    def initialize *classes
      super <<-EOS
Could not find typecaster for #{classes}
You can define it with:

  ActiveData.typecaster('#{classes.first}') do |value|
    # do some staff with value and options
  end
      EOS
    end
  end
end

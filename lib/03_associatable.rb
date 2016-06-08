require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default = {
      :primary_key => :id,
      :foreign_key => "#{name.downcase}_id".to_sym,
      :class_name => name.to_s.camelcase
    }
    attributes_hash = default.merge(options)
    @foreign_key = attributes_hash[:foreign_key]
    @primary_key = attributes_hash[:primary_key]
    @class_name = attributes_hash[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default = {
      :primary_key => :id,
      :foreign_key => "#{self_class_name.downcase}_id".to_sym,
      :class_name => name.to_s.singularize.camelcase
    }
    attributes_hash = default.merge(options)
    @foreign_key = attributes_hash[:foreign_key]
    @primary_key = attributes_hash[:primary_key]
    @class_name = attributes_hash[:class_name]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    assoc_options[name] = BelongsToOptions.new(name, options)
    assoc = assoc_options[name]

    define_method(name) do
      f_key = self.send(assoc.foreign_key)
      assoc.model_class.where(assoc.primary_key => f_key).first
    end

  end

  def has_many(name, options = {})
    assoc_options[name] = HasManyOptions.new(name, self.to_s, options)
    assoc = assoc_options[name]

    define_method(name) do
      p_key = self.send(assoc.primary_key)
      assoc.model_class.where(assoc.foreign_key => p_key)
    end

  end

  def assoc_options
    @assoc_options ||= {}
  end

end

class SQLObject
  extend Associatable
  # Mixin Associatable here...
end

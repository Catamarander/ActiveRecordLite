require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

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
    @class_name.underscore + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = "#{name}_id".to_sym
    @class_name = name.to_s.camelcase
    @primary_key = :id

    options.each do |key, value|
      instance_variable_set "@#{key}", value
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    # byebug if self_class_name.nil?
    @foreign_key = "#{self_class_name.downcase}_id".to_sym
    @class_name = name.to_s.singularize.capitalize
    @primary_key = :id

    options.each do |key, value|
      instance_variable_set "@#{key}", value
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    # byebug if name == :human
    @assoc_options = {"#{name}".to_sym => options}

    define_method name do
      options.model_class.where(
        "#{options.primary_key }".to_sym => self.id
      )[0]
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method name do
      options.model_class.where(
      "#{options.foreign_key }".to_sym => self.id
      )
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end

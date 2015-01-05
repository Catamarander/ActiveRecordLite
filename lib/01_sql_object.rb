require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    table_information = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    table_information[0].map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column_name|
      define_method "#{column_name}=" do |attribute|
        attributes[column_name] = attribute
      end
    end

    columns.each do |column_name|
      define_method "#{column_name}" do
        attributes[column_name]
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.tableize
    # ...
  end

  def self.all
    table_information = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(table_information)
  end

  def self.parse_all(results)
    results.map do |instance_object|
      self.new(instance_object)
    end
  end

  def self.find(id)
    found_entry = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
      LIMIT
        1
    SQL

    if found_entry.empty?
      return nil
    end

    self.new(found_entry[0])
  end

  def initialize(params = {})
    params.each_key do |key|
      unless self.class.columns.include? key.to_sym
        raise "unknown attribute '#{key}'"
      end
    end

    params.each do |key, value|
      attributes[key.to_sym] = value
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # not just attributes.value so that we can maintain the col order
    values = []
    self.class.columns.each do |value|
      values << attributes[value]
    end

    values
  end

  def insert
    col_length = self.class.columns.length
    col_names = self.class.columns * ", "
    question_marks = (["?"] * col_length) * ", "

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_length = self.class.columns.length
    col_names = self.class.columns.map do |attr_name|
      "#{attr_name} = ?"
    end * ", "

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    if id.nil?
      self.insert
    else
      self.update
    end
  end
end

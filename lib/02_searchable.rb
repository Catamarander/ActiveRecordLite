require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = []
    values = []
    params.each_key do |key|
      where_line << key.to_s
      values << params[key]
    end

    where_line = (where_line * " = ? AND ") + " = ?"

    table_information = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    output = []

    table_information.each do |table_hash|
      output << self.new(table_hash)
    end

    output
  end
end

class SQLObject
  extend Searchable
end

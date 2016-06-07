require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map{|k,_| "#{k} = ?"}.join(" AND ")
    values = params.values
    cats = DBConnection.execute(<<-SQL, *values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{where_line}
    SQL
    cats.map{ |cat| self.new(cat) }
  end
end

class SQLObject
  extend Searchable

end

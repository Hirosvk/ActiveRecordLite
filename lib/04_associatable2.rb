require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through = assoc_options[through_name]
    source = through.model_class.assoc_options[source_name]
    # require 'byebug'; debugger
    define_method(name) do
      source_table = source.model_class.table_name
      source_pk = source.primary_key
      source_fk = source.foreign_key

      through_table = through.model_class.table_name
      through_pk = through.primary_key
      through_fk = through.foreign_key

      fk = self.send(through_fk)

      result = DBConnection.execute(<<-SQL, fk)
        SELECT
          #{source_table}.*
        FROM
          #{through_table} JOIN #{source_table}
          ON #{through_table}.#{source_fk} = #{source_table}.#{source_pk}
        WHERE
          #{through_table}.#{through_pk} = ?
      SQL
      source.model_class.parse_all(result).first
      # self.send(through_name).send(source_name)
    end

  end
end

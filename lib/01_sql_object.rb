require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  # DBConnection.open('cats.db')
  def self.columns
    @columns ||= DBConnection.execute2("SELECT * FROM #{table_name}").first.map(&:to_sym)
    @columns
  end


  def self.finalize!
    columns.each do |column|

      define_method("#{column}") do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end

    end
  end


  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    all_cats = DBConnection.execute("SELECT * FROM #{table_name}")
    parse_all(all_cats)
  end

  def self.parse_all(results)
    results.map{ |att_hash| self.new(att_hash) }
  end

  def self.find(id)
    thecat = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
    thecat = thecat.first
    return nil if thecat.nil?
    self.new(thecat)
  end


  def initialize(params = {})
    differences = (params.keys.map(&:to_sym) - self.class.columns) #attributes names are symbols.
    raise "unknown attribute '#{differences.first}'" unless differences.empty?

    params.each do |key, val|
      self.send("#{key}=", val)
    end
  end

  def attributes
    @attributes ||= {}
    # ...
  end

  def attribute_values
    self.class.columns.map do |col|
      self.send(col)
    end
    # The below code will fetch attributes that are not included in the columns
    # attributes.values
  end

  def insert
    col_names = self.class.columns.drop(1).map(&:to_s).join(', ') # drop ':id' columns
    question_marks = (["?"] * (self.class.columns.drop(1).length - 1)).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

# The following code did not work, receiving non-descriptive errors for unknown reasons
  # DBConnection.execute(<<-SQL)
  #   INSERT INTO
  #     #{self.class.table_name} (#{col_name})
  #   VALUES
  #     (#{attribute_values.drop(1).join(',')})
  # SQL
  # self.id = DBConnection.last_insert_row_id

#### Always use '?' in SQL, otherwise there will be wierd errors.

  def update
    the_id = attributes[:id]
    col_names = attributes.keys.reject{|key| key == :id}
    col_values = attributes.map{|k,v| v unless k == :id}.reject(&:nil?)

    set_stmts = col_names.map do |col_name|
      "#{col_name} = ?"
    end.join(", ")

    DBConnection.execute(<<-SQL, *col_values, the_id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_stmts}
      WHERE
        id = ?
    SQL
  end

  def save
    exist = DBConnection.execute(<<-SQL, self.id)
      SELECT *
      FROM #{self.class.table_name}
      WHERE id = ?
    SQL

    if exist.empty?
      insert
    else
      update
    end
  end


end

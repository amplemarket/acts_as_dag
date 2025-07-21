$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'rspec'
require 'pry'
require 'active_record'
require 'logger'
require 'acts_as_dag'

puts ActiveRecord.version

ENV['RAILS_ENV'] ||= 'test'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::WARN

# ActiveRecord 6.0 and above supports multiple database connections
if ActiveRecord::VERSION::MAJOR >= 6
  ActiveRecord::Base.configurations = {
    "test" => {
      "primary" => {
        "adapter" => "sqlite3",
        "database" => "file:primary?mode=memory"
      },
      "other_database" => {
        "adapter" => "sqlite3",
        "database" => "file:other_db_memory?mode=memory"
      }
    }
  }
else
  ActiveRecord::Base.configurations = {
    "test" => {
      "adapter" => "sqlite3",
      "database" => "file:primary?mode=memory"
    }
  }
end

ActiveRecord::Base.establish_connection

ActiveRecord::Schema.define(:version => 0) do

  # MODEL TABLES

  create_table :separate_link_models, :force => true do |t|
    t.string :name
  end


  create_table :unified_link_models, :force => true do |t|
    t.string :name
  end

  # SUPPORTING TABLES

  create_table :separate_link_model_links, :force => true do |t|
    t.integer :parent_id
    t.integer :child_id
  end

  create_table :separate_link_model_descendants, :force => true do |t|
    t.integer :ancestor_id
    t.integer :descendant_id
    t.integer :distance
  end

  create_table :acts_as_dag_links, :force => true do |t|
    t.integer :parent_id
    t.integer :child_id
    t.string :category_type
  end

  create_table :acts_as_dag_descendants, :force => true do |t|
    t.integer :ancestor_id
    t.integer :descendant_id
    t.integer :distance
    t.string :category_type
  end
end

class SeparateLinkModel < ActiveRecord::Base
  acts_as_dag :link_table => 'separate_link_model_links', :descendant_table => 'separate_link_model_descendants', :link_conditions => nil
end

class UnifiedLinkModel < ActiveRecord::Base
  acts_as_dag
end

if ActiveRecord::VERSION::MAJOR >= 6
  class AnotherDBAbstractClass < ActiveRecord::Base
    self.abstract_class = true

    connects_to database: { writing: :other_database }
  end

  schema_class = ActiveRecord::Schema[ActiveRecord::Migration.current_version]
  schema = schema_class.new
  schema.instance_variable_set(:@connection, AnotherDBAbstractClass.connection)
  schema.define(version: 0) do
    create_table :another_db_models, force: true do |t|
      t.string :name
    end

    create_table :acts_as_dag_links, :force => true do |t|
      t.integer :parent_id
      t.integer :child_id
      t.string :category_type
    end

    create_table :acts_as_dag_descendants, :force => true do |t|
      t.integer :ancestor_id
      t.integer :descendant_id
      t.integer :distance
      t.string :category_type
    end
  end

  class AnotherDBModel < AnotherDBAbstractClass
    acts_as_dag
  end
end

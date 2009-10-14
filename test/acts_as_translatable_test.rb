require 'test/unit'

require 'rubygems'
gem 'activerecord', '>= 1.15.4.7794'
require 'active_record'

require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    create_table :translatable_mixin_translations do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :model_id, :integer
      t.column :language, :string
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
end

class TranslatableMixinTranslation < ActiveRecord::Base
end

class TranslatableMixin < Mixin
  acts_as_translatable :attributes => [:description]

  def self.table_name() "mixins" end
end

class ActsAsTranslatableTest < Test::Unit::TestCase

  def setup
    setup_db
    %w(joe joan kurt berta).each do |name|
      TranslatableMixin.create! :name => name,
      :description => "This is #{name.capitalize}."
    end
  end

  def teardown
    teardown_db
  end

  # Replace this with your real tests.
  def test_get_without_translations
    joe=TranslatableMixin.find_by_name("joe")
    assert_equal "joe", joe.name
    assert_equal "This is Joe.", joe.description
  end
end

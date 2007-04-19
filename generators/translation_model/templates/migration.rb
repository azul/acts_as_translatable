class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
      t.column :language_id, :string, :limit => 2, :null => false
      t.column :<%= foreign_key%>, :integer, :null => false
    end
    add_index :<%= table_name %>, [ :<%= foreign_key%>, :language_id ], :unique => true
  end

  def self.down
    remove_index :<%= table_name %>, [ :<%= foreign_key%>, :language_id ]
    drop_table :<%= table_name %>
  end
end

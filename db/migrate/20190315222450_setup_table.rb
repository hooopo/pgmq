class SetupTable < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute "CREATE SCHEMA IF NOT EXISTS pgmq"
    # todo -> create_table

    create_table :jobs do |t|
      t.string :name
    end
  end
end

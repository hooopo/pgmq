class RenameSomeColumn < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    rename_column :jobs, :competed_at, :completed_at
    rename_column :jobs, :id, :jid
  end
end

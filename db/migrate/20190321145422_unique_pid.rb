class UniquePid < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    add_index :workers, :pid, unique: true
  end
end

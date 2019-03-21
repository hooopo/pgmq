class ChangeDefaultArgValue < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute "alter table jobs alter column args set default '[]'::jsonb"
  end
end

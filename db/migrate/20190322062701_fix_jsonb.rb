class FixJsonb < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute "alter table jobs alter column custom set default '{}'::jsonb"
    execute "alter table jobs alter column failure set default '{}'::jsonb"
  end
end

class MvToDeadAndDone < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute "alter table done_jobs add primary key (jid)"
    execute "alter table dead_jobs add primary key (jid)"
    execute <<~SQL
      CREATE FUNCTION archive_done_jobs() RETURNS void AS $$
        WITH deleted AS (
          DELETE FROM ONLY jobs WHERE state = 'done' RETURNING *
        )
        INSERT INTO done_jobs SELECT * FROM deleted;
      $$ LANGUAGE sql;
    SQL

    execute <<~SQL
      CREATE FUNCTION archive_dead_jobs() RETURNS void AS $$
        WITH deleted AS (
          DELETE FROM ONLY jobs WHERE state = 'dead' RETURNING *
        )
        INSERT INTO dead_jobs SELECT * FROM deleted;
      $$ LANGUAGE sql;
    SQL
  end
end

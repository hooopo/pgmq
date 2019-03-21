class FetchJob < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute <<~SQL
      CREATE OR REPLACE FUNCTION fetch_jobs(lmt integer default 1)
        returns setof jobs 
        language sql
      AS $function$
        UPDATE jobs 
           SET state = 'working'
         WHERE jid = (
                      SELECT jid
                        FROM jobs
                       WHERE state = 'scheduled' AND at <= now()
                    ORDER BY priority DESC, at DESC NULLS LAST
                             FOR UPDATE SKIP LOCKED
                       LIMIT 1
          )
        RETURNING *;
      $function$
    SQL
  end
end

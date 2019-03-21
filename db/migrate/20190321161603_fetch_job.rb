class FetchJob < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute <<~SQL
      CREATE OR REPLACE FUNCTION fetch_jobs(lmt integer default 1)
        returns setof jobs 
        language sql
      AS $function$
        UPDATE ONLY jobs 
           SET state = 'working'
         WHERE jid IN (
                      SELECT jid
                        FROM  ONLY jobs
                       WHERE state = 'scheduled' AND at <= now()
                    ORDER BY at DESC NULLS LAST, priority DESC
                             FOR UPDATE SKIP LOCKED
                       LIMIT lmt
          )
        RETURNING *;
      $function$
    SQL
  end
end

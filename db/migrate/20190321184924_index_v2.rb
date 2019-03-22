class IndexV2 < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute "DROP INDEX idx_job_1"
    execute "CREATE INDEX idx_job_2 ON jobs (state, at DESC NULLS LAST, priority DESC, jid) WHERE state = 'scheduled'"
  end
end

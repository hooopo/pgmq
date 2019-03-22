class AddIndex < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute "CREATE INDEX idx_job_1 ON jobs (state, at DESC, priority DESC) WHERE state = 'scheduled'"
  end
end

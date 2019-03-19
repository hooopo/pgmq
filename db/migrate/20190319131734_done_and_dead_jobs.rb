class DoneAndDeadJobs < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute "CREATE TABLE done_jobs () INHERITS (jobs);"
    execute "CREATE TABLE dead_jobs () INHERITS (jobs);"
  end
end

class SetupTable < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute "CREATE SCHEMA IF NOT EXISTS pgmq"
    execute "CREATE TYPE state AS ENUM ('scheduled', 'working', 'dead', 'done')"

    create_table :workers, comment: 'Workers for pgmq' do |t|
      t.string :hostname, null: false, comment: 'Worker hostname'
      t.integer :pid, null: false, comment: 'Worker process id'
      t.string :v, default: '1.0', comment: 'Worker version'
      t.string :labels, array: true, default: '{}'
      t.datetime :started_at, default: 'now()'
      t.datetime :last_active_at, default: 'now()'
    end
    
    # Job Payload via Faktory: https://github.com/contribsys/faktory/wiki/The-Job-Payload
    create_table :jobs, comment: 'Jobs for pgmq' do |t|
      t.string :queue, default: 'default', comment: 'Push this job to a particular queue. The default queue is, unsurprisingly, "default".'
      t.string :jobtype, null: false,  comment: 'The worker uses jobtype to determine how to execute this job'
      t.jsonb :args, default: '[]', comment: 'The args is an array of parameters necessary for the job to execute, it may be empty.'
      t.integer :priority, default: 5, comment: 'Priority within the queue, may be 1-9, default is 5. 9 is high priority, 1 is low priority.'
      t.datetime :created_at, default: 'now()', comment: 'The client may set this or Pgmq will fill it in when it receives a job.'
      t.datetime :enqueued_at, comment: 'Worker will set this when it enqueues a job'
      t.datetime :competed_at, comment: 'Worker will set when this job completed at.'
      t.column :state, :state, default: 'scheduled', comment: 'state for current job', null: false
      t.datetime :at, default: '1111-01-01', comment: <<~COMMENT
        Schedule a job to run at a point in time. 
        The job will be enqueued within a few seconds of that point in time. 
      COMMENT

      t.integer :redo_after, comment: 'Worker will enqueue this job after N second, it can act as crontab'

      t.integer :reserve_for, default: 600, comment: <<~COMMENT
        Set the reservation timeout for a job, in seconds. 
        When a worker fetches a job, it has up to N seconds to ACK or FAIL the job. 
        After N seconds, the job will be requeued for execution by another worker. 
        Default is 1800 seconds or 30 minutes, minimum is 60 seconds.
      COMMENT
      
      t.integer :retry, default: 25, comment: <<~COMMENT
        Set the number of retries to perform if this job fails. 
        Default is 25. 
        A value of 0 means the job will not be retried and will be discarded if it fails. 
        A value of -1 means don't retry but move the job immediately to the Dead set if it fails.
      COMMENT

      t.integer :backtrace, default: 0, comment: <<~COMMENT
        Retain up to N lines of backtrace given to the FAIL command. 
        Default is 0.  
        Best practice is to integrate your workers with an existing error service, 
        but you can enable this to get a better view of why a job is retrying in the Web UI.
      COMMENT

      t.jsonb :custom, default: '{}', comment: <<~COMMENT
        This can be extremely helpful for cross-cutting concerns which should propagate between systems, 
        e.g. locale for user-specific text translations, 
        request_id for tracing execution across a complex distributed system
      COMMENT

      t.jsonb :failure, default: '{}', comment: <<~COMMENT
        A hash with data about this job's most recent failure
      COMMENT

      t.bigint :worker_id, comment: 'Which worker run this job'
    end

    execute "ALTER TABLE jobs ADD CONSTRAINT args CHECK(jsonb_typeof(args) = 'array');"
  end
end

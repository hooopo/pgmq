require 'standalone_migrations'
require 'dotenv/load'
require 'pry'
ActiveRecord::Base.schema_format = :sql
StandaloneMigrations::Tasks.load_tasks
ActiveRecord::Base.connection.execute("CREATE SCHEMA IF NOT EXISTS pgmq;")
ActiveRecord::Base.schema_migrations_table_name = "pgmq.schema_migrations"
ActiveRecord::Base.internal_metadata_table_name = "pgmq.ar_internal_metadata"


class UuidJid < ActiveRecord::Migration[5.2]
  def change
    self.class.schema_search_path = 'pgmq, public'
    execute %Q{create EXTENSION "uuid-ossp"}
    execute "ALTER TABLE jobs ALTER COLUMN jid DROP DEFAULT"
    execute "ALTER TABLE jobs ALTER COLUMN jid SET DATA TYPE UUID USING LPAD(TO_HEX(jid), 32, '0')::UUID;"
    execute "ALTER TABLE jobs ALTER COLUMN jid SET DEFAULT uuid_generate_v4()"
    execute "DROP SEQUENCE jobs_id_seq"
  end
end

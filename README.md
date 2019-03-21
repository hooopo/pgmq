# pgmq


## for dev

* cp .env.example .env
* bundle exec rake db:create
* bundle exec rake db:migrate

## insert seed job

* psql pgmq_dev
* set search_path to pgmq;
* \i seed.sql

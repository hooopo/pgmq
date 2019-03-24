# pgmq


## For dev

* cp .env.example .env
* bundle exec rake db:create
* bundle exec rake db:migrate

## Insert seed job

* psql pgmq_dev
* set search_path to pgmq;
* \i seed.sql

## Workers

* ruby demo worker: https://github.com/hooopo/pgmq_worker_ruby_demo
* ruby worker base on Faktory: https://github.com/hooopo/faktory_worker_ruby/tree/pgmq
* worker demo base on Factory: https://github.com/hooopo/pgmq_faktory_demo

## Features

* [x] multiple named queues
* [x] exactly once
* [x] priorities
* [x] delayed jobs
* [x] persistent jobs
* [x] retries with backoff
* [ ] cron job
* [ ] broadcast msg to multiple queues
* [ ] job dependencies
* [ ] rate limiting
* [ ] unique jobs
* [ ] expire jobs
* [ ] cocurrency & priority by tenant for saas
* [ ] statistics & web ui
* [ ] fast requeue
* [ ] distributed workers
* [ ] batch processing

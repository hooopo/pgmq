insert into jobs (at, enqueued_at, created_at, jobtype) 
select now() - (interval '12 hour') + random() * interval '1 day' as at, 
       now() as enqueued_at, 
       now() as created_at, 
       'HelloJob' 
  from generate_series(1, 1000000);

  vacuum full jobs;
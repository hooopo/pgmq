insert into jobs (created_at, jobtype, args) 
select now() as created_at, 
       'HelloJob' as jobtype,
       '[1, "a"]' as args
  from generate_series(1, 100000);

  vacuum full jobs;
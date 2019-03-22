SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgmq; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgmq;


--
-- Name: state; Type: TYPE; Schema: pgmq; Owner: -
--

CREATE TYPE pgmq.state AS ENUM (
    'scheduled',
    'working',
    'retry',
    'dead',
    'done'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: jobs; Type: TABLE; Schema: pgmq; Owner: -
--

CREATE TABLE pgmq.jobs (
    jid bigint NOT NULL,
    queue character varying DEFAULT 'default'::character varying,
    jobtype character varying NOT NULL,
    args jsonb DEFAULT '[]'::jsonb,
    priority integer DEFAULT 5,
    created_at timestamp without time zone,
    enqueued_at timestamp without time zone,
    completed_at timestamp without time zone,
    state pgmq.state DEFAULT 'scheduled'::pgmq.state NOT NULL,
    at timestamp without time zone DEFAULT '1111-01-01 00:00:00'::timestamp without time zone,
    redo_after integer,
    reserve_for integer DEFAULT 600,
    retry integer DEFAULT 25,
    backtrace integer DEFAULT 0,
    custom jsonb DEFAULT '{}'::jsonb,
    failure jsonb DEFAULT '{}'::jsonb,
    worker_id bigint,
    CONSTRAINT args CHECK ((jsonb_typeof(args) = 'array'::text))
);


--
-- Name: TABLE jobs; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON TABLE pgmq.jobs IS 'Jobs for pgmq';


--
-- Name: COLUMN jobs.queue; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.queue IS 'Push this job to a particular queue. The default queue is, unsurprisingly, "default".';


--
-- Name: COLUMN jobs.jobtype; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.jobtype IS 'The worker uses jobtype to determine how to execute this job';


--
-- Name: COLUMN jobs.args; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.args IS 'The args is an array of parameters necessary for the job to execute, it may be empty.';


--
-- Name: COLUMN jobs.priority; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.priority IS 'Priority within the queue, may be 1-9, default is 5. 9 is high priority, 1 is low priority.';


--
-- Name: COLUMN jobs.created_at; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.created_at IS 'The client may set this or Pgmq will fill it in when it receives a job.';


--
-- Name: COLUMN jobs.enqueued_at; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.enqueued_at IS 'Worker will set this when it enqueues a job';


--
-- Name: COLUMN jobs.completed_at; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.completed_at IS 'Worker will set when this job completed at.';


--
-- Name: COLUMN jobs.state; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.state IS 'state for current job';


--
-- Name: COLUMN jobs.at; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.at IS 'Schedule a job to run at a point in time. 
The job will be enqueued within a few seconds of that point in time. 
';


--
-- Name: COLUMN jobs.redo_after; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.redo_after IS 'Worker will enqueue this job after N second, it can act as crontab';


--
-- Name: COLUMN jobs.reserve_for; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.reserve_for IS 'Set the reservation timeout for a job, in seconds. 
When a worker fetches a job, it has up to N seconds to ACK or FAIL the job. 
After N seconds, the job will be requeued for execution by another worker. 
Default is 1800 seconds or 30 minutes, minimum is 60 seconds.
';


--
-- Name: COLUMN jobs.retry; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.retry IS 'Set the number of retries to perform if this job fails. 
Default is 25. 
A value of 0 means the job will not be retried and will be discarded if it fails. 
A value of -1 means don''t retry but move the job immediately to the Dead set if it fails.
';


--
-- Name: COLUMN jobs.backtrace; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.backtrace IS 'Retain up to N lines of backtrace given to the FAIL command. 
Default is 0.  
Best practice is to integrate your workers with an existing error service, 
but you can enable this to get a better view of why a job is retrying in the Web UI.
';


--
-- Name: COLUMN jobs.custom; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.custom IS 'This can be extremely helpful for cross-cutting concerns which should propagate between systems, 
e.g. locale for user-specific text translations, 
request_id for tracing execution across a complex distributed system
';


--
-- Name: COLUMN jobs.failure; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.failure IS 'A hash with data about this job''s most recent failure
';


--
-- Name: COLUMN jobs.worker_id; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.jobs.worker_id IS 'Which worker run this job';


--
-- Name: fetch_jobs(integer); Type: FUNCTION; Schema: pgmq; Owner: -
--

CREATE FUNCTION pgmq.fetch_jobs(lmt integer DEFAULT 1) RETURNS SETOF pgmq.jobs
    LANGUAGE sql
    AS $$
  UPDATE ONLY jobs 
     SET state = 'working'
   WHERE jid IN (
                SELECT jid
                  FROM  ONLY jobs
                 WHERE state = 'scheduled' AND at <= now()
              ORDER BY at DESC, priority DESC
                       FOR UPDATE SKIP LOCKED
                 LIMIT lmt
    )
  RETURNING *;
$$;


--
-- Name: dead_jobs; Type: TABLE; Schema: pgmq; Owner: -
--

CREATE TABLE pgmq.dead_jobs (
)
INHERITS (pgmq.jobs);


--
-- Name: done_jobs; Type: TABLE; Schema: pgmq; Owner: -
--

CREATE TABLE pgmq.done_jobs (
)
INHERITS (pgmq.jobs);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: pgmq; Owner: -
--

CREATE SEQUENCE pgmq.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: pgmq; Owner: -
--

ALTER SEQUENCE pgmq.jobs_id_seq OWNED BY pgmq.jobs.jid;


--
-- Name: workers; Type: TABLE; Schema: pgmq; Owner: -
--

CREATE TABLE pgmq.workers (
    id bigint NOT NULL,
    hostname character varying NOT NULL,
    pid integer NOT NULL,
    v character varying DEFAULT '1.0'::character varying,
    labels character varying[] DEFAULT '{}'::character varying[],
    started_at timestamp without time zone,
    last_active_at timestamp without time zone
);


--
-- Name: TABLE workers; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON TABLE pgmq.workers IS 'Workers for pgmq';


--
-- Name: COLUMN workers.hostname; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.workers.hostname IS 'Worker hostname';


--
-- Name: COLUMN workers.pid; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.workers.pid IS 'Worker process id';


--
-- Name: COLUMN workers.v; Type: COMMENT; Schema: pgmq; Owner: -
--

COMMENT ON COLUMN pgmq.workers.v IS 'Worker version';


--
-- Name: workers_id_seq; Type: SEQUENCE; Schema: pgmq; Owner: -
--

CREATE SEQUENCE pgmq.workers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workers_id_seq; Type: SEQUENCE OWNED BY; Schema: pgmq; Owner: -
--

ALTER SEQUENCE pgmq.workers_id_seq OWNED BY pgmq.workers.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: dead_jobs jid; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN jid SET DEFAULT nextval('pgmq.jobs_id_seq'::regclass);


--
-- Name: dead_jobs queue; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN queue SET DEFAULT 'default'::character varying;


--
-- Name: dead_jobs args; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN args SET DEFAULT '[]'::jsonb;


--
-- Name: dead_jobs priority; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN priority SET DEFAULT 5;


--
-- Name: dead_jobs state; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN state SET DEFAULT 'scheduled'::pgmq.state;


--
-- Name: dead_jobs at; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN at SET DEFAULT '1111-01-01 00:00:00'::timestamp without time zone;


--
-- Name: dead_jobs reserve_for; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN reserve_for SET DEFAULT 600;


--
-- Name: dead_jobs retry; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN retry SET DEFAULT 25;


--
-- Name: dead_jobs backtrace; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN backtrace SET DEFAULT 0;


--
-- Name: dead_jobs custom; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN custom SET DEFAULT '{}'::jsonb;


--
-- Name: dead_jobs failure; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.dead_jobs ALTER COLUMN failure SET DEFAULT '{}'::jsonb;


--
-- Name: done_jobs jid; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN jid SET DEFAULT nextval('pgmq.jobs_id_seq'::regclass);


--
-- Name: done_jobs queue; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN queue SET DEFAULT 'default'::character varying;


--
-- Name: done_jobs args; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN args SET DEFAULT '[]'::jsonb;


--
-- Name: done_jobs priority; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN priority SET DEFAULT 5;


--
-- Name: done_jobs state; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN state SET DEFAULT 'scheduled'::pgmq.state;


--
-- Name: done_jobs at; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN at SET DEFAULT '1111-01-01 00:00:00'::timestamp without time zone;


--
-- Name: done_jobs reserve_for; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN reserve_for SET DEFAULT 600;


--
-- Name: done_jobs retry; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN retry SET DEFAULT 25;


--
-- Name: done_jobs backtrace; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN backtrace SET DEFAULT 0;


--
-- Name: done_jobs custom; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN custom SET DEFAULT '{}'::jsonb;


--
-- Name: done_jobs failure; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.done_jobs ALTER COLUMN failure SET DEFAULT '{}'::jsonb;


--
-- Name: jobs jid; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.jobs ALTER COLUMN jid SET DEFAULT nextval('pgmq.jobs_id_seq'::regclass);


--
-- Name: workers id; Type: DEFAULT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.workers ALTER COLUMN id SET DEFAULT nextval('pgmq.workers_id_seq'::regclass);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (jid);


--
-- Name: workers workers_pkey; Type: CONSTRAINT; Schema: pgmq; Owner: -
--

ALTER TABLE ONLY pgmq.workers
    ADD CONSTRAINT workers_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: idx_job_2; Type: INDEX; Schema: pgmq; Owner: -
--

CREATE INDEX idx_job_2 ON pgmq.jobs USING btree (state, at DESC, priority DESC, jid) WHERE (state = 'scheduled'::pgmq.state);


--
-- Name: index_workers_on_pid; Type: INDEX; Schema: pgmq; Owner: -
--

CREATE UNIQUE INDEX index_workers_on_pid ON pgmq.workers USING btree (pid);


--
-- PostgreSQL database dump complete
--

SET search_path TO pgmq, public;

INSERT INTO "schema_migrations" (version) VALUES
('20190315222450'),
('20190319131734'),
('20190319133413'),
('20190321145422'),
('20190321161603'),
('20190321175446'),
('20190321181237'),
('20190321184924'),
('20190322062701');



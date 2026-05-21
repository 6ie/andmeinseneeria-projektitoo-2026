CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS intermediate;
CREATE SCHEMA IF NOT EXISTS production;

CREATE TABLE IF NOT EXISTS staging.pipeline_runs (
    run_id uuid PRIMARY KEY,
    fetched_at timestamptz NOT NULL,
    source_name text NOT NULL,
    status text NOT NULL,
    message text
);
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS intermediate;
CREATE SCHEMA IF NOT EXISTS production;

CREATE TABLE IF NOT EXISTS staging.raw_snapshot (
    run_id uuid PRIMARY KEY,
    fetched_at timestamptz NOT NULL,
    source_name text NOT NULL,
    row_count int,
    raw_data jsonb NOT NULL,
    status text NOT NULL,
    message text
);
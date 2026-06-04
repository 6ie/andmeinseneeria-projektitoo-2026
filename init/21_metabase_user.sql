DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'projektDash') THEN
    CREATE USER "projektDash" WITH PASSWORD 'projektDash';
  END IF;
END
$$;
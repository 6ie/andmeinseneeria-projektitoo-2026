#!/bin/bash
set -e


DUMP_FILE="/docker-entrypoint-initdb.d/metabase_appdb.dump"
DB_NAME="metabase_appdb"
echo "Metabase init script starting..."

# Kas dump on olemas?
if [ ! -f "$DUMP_FILE" ]; then
  echo "No Metabase dump found at $DUMP_FILE, skipping restore."
  exit 0
fi

# Kas andmebaas juba olemas?
DB_EXISTS=$(psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")

if [ "$DB_EXISTS" = "1" ]; then
  echo "Database ${DB_NAME} already exists, skipping restore."
  exit 0
fi

METABASE_USER="projektDash"

echo "Creating database ${DB_NAME}..."
createdb -U "$POSTGRES_USER" -O "$METABASE_USER" "$DB_NAME"

echo "Restoring Metabase app DB from dump..."
pg_restore -U "$POSTGRES_USER" --no-owner --no-acl -d "$DB_NAME" "$DUMP_FILE"

echo "Granting privileges to ${METABASE_USER}..."
psql -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO \"${METABASE_USER}\";"
psql -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO \"${METABASE_USER}\";"
psql -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO \"${METABASE_USER}\";"

echo "Metabase restore finished."

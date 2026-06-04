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

echo "Creating database ${DB_NAME}..."
createdb -U "$POSTGRES_USER" "$DB_NAME"

echo "Restoring Metabase app DB from dump..."
pg_restore -U "$POSTGRES_USER" -d "$DB_NAME" "$DUMP_FILE"

echo "Metabase restore finished."

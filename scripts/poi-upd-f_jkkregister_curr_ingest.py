"""
Andmete baasi sisselugemise skript: loeb JSON API-st andmeid ja laeb need PostgreSQL andmebaasi staging schemasse.
"""

import json
import urllib.request
import uuid
import psycopg2
from psycopg2.extras import Json
import time
from datetime import datetime, timezone
import os

DB_CONFIG = {   
    "host": os.getenv("DB_HOST", "analytics-db"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "dbname": os.environ["POSTGRES_DB"],
    "user": os.environ["POSTGRES_USER"],
    "password": os.environ["POSTGRES_PASSWORD"],
}


def extract():
    """Extract: loeme PostgREST API-st jäätmekäitluskohtade registri andmed."""
    url = "https://keskkonnaandmed.envir.ee/f_jkkregister_curr"
    print(f"Extracting data from {url} ...")
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read().decode())
    print(f"  -> Saadud {len(data)} jäätmekäitluskohta")
    return data

def load(data):
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    cur.execute(
        """INSERT INTO staging.raw_snapshot (run_id, fetched_at, source_name, row_count, raw_data, status)
            VALUES (%s, %s, %s, %s, %s, %s)""",
        (str(uuid.uuid4()), datetime.now(timezone.utc), "f_jkkregister_curr", len(data), Json(data), "SUCCESS"),
    )

    conn.commit()
    print(f"  -> Laaditud andmed tabelisse raw_snapshot")

    # Kontrolli tulemust
    cur.execute("""SELECT fetched_at, jsonb_array_length(raw_data) 
                FROM staging.raw_snapshot 
                ORDER BY fetched_at DESC 
                LIMIT 1""")
    row = cur.fetchone()
    if row is None:
        fetched = None
        count = 0
    else:
        fetched, count = row[0], row[1]

    print(f"  -> Viimati laaditud ({fetched}) tabelis f_jkkregister_curr kokku {count} rida")

    cur.close()
    conn.close()


def main():
    print("=== ETL protsess ===")
    print()

    # Extract
    raw = extract()
    print(f"Extracted: {len(raw)} kirjet\n")

    # Load
    load(raw)
    print()
    print("=== ETL lõpetatud ===")


if __name__ == "__main__":
    # Oota kuni andmebaas on valmis
    time.sleep(3)
    main()

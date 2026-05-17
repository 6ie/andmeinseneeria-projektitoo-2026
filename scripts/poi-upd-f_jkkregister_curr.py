"""
Lihtne ETL skript: loeb JSON API-st andmeid ja laeb need PostgreSQL andmebaasi.
"""

import json
import urllib.request
import psycopg2
import time
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
    url = "https://keskkonnaandmed.envir.ee/f_jkkregister_curr?select=objekti_nimetus,jkk_kood"
    print(f"Extracting data from {url} ...")
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read().decode())
    print(f"  -> Saadud {len(data)} jäätmekäitluskohta")
    return data

def transform(raw_data):
    """Transform: puhastame ja normaliseerime andmed."""
    rows = []
    for item in raw_data:
        objekti_nimetus = item.get("objekti_nimetus", ["!Tundmatu"])
        jkk_kood = item.get("jkk_kood", ["!Tundmatu"])
        rows.append((objekti_nimetus, jkk_kood))
    # Sorteerime jkk_koodi järgi kasvavalt
    rows.sort(key=lambda r: r[1], reverse=False)
    print(f"  -> Transformeeritud {len(rows)} rida")
    return rows

def load(rows):
    """Load: kirjutame andmed PostgreSQL tabelisse."""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS f_jkkregister_curr (
            id SERIAL PRIMARY KEY,            
            objekti_nimetus TEXT,
            jkk_kood TEXT,
            loaded_at TIMESTAMP DEFAULT NOW()
        )
    """)

    # Truncate enne uut laadimist (idempotentne laadimine)
    cur.execute("TRUNCATE TABLE f_jkkregister_curr RESTART IDENTITY")

    for row in rows:
        cur.execute(
            """INSERT INTO f_jkkregister_curr (objekti_nimetus, jkk_kood)
               VALUES (%s, %s)""",
            row,
        )

    conn.commit()
    print(f"  -> Laaditud {len(rows)} rida tabelisse f_jkkregister_curr")

    # Kontrolli tulemust
    cur.execute("SELECT COUNT(*) FROM f_jkkregister_curr")
    count = cur.fetchone()[0]
    print(f"  -> Tabelis kokku {count} rida")

    cur.close()
    conn.close()


def main():
    print("=== ETL protsess ===")
    print()

    # Extract
    raw = extract()
    print(f"Extracted: {len(raw)} kirjet\n")


    # Transform
    rows = transform(raw)
    print(f"Transformed: {len(rows)} rida\n")


    # Load
    load(rows)
    print()
    print("=== ETL lõpetatud ===")


if __name__ == "__main__":
    # Oota kuni andmebaas on valmis
    time.sleep(3)
    main()

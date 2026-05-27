"""
Jäätmekäitluskohtade POI uuendus — Airflow DAG

Orkestreerib:
1. Jäätmekäitluskohtade laadimine PostgREST API-st
2. Postgre andmebaasi protseduurid andmete transformeerimiseks (staging -> intermediate -> production)
"""

import pendulum

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag, task

@dag(
    dag_id="jkk-poi-upd-pipeline",
    schedule="@daily",
    start_date=pendulum.datetime(2025, 5, 24, tz="UTC"),
    catchup=False,
    tags=["jkk", "poi"],
)
def jkk_poi_update_pipeline():

    @task
    def extract_jkk_data(ds=None) -> str:
        """
        Pärib JKK andmed API-st ühe JSON-objektina.
        Tagastab XCom-i kaudu ainult failitee (mitte andmed ise).
        Impordid on taski sees — ei käivitu DAG-i parsimise ajal.
        """
        import json
        import requests
        from datetime import date

        url = "https://keskkonnaandmed.envir.ee/f_jkkregister_curr"

        resp = requests.get(url, timeout=30)
        resp.raise_for_status()

        data = resp.json()

        path = f"/tmp/jkk_{ds or date.today().isoformat()}.json"
        with open(path, "w") as f:
            json.dump(data, f)
        print(f"Laeti {len(data)} jäätmekäitluskohta, salvestatud: {path}")
        
        return path


    @task
    def load_jkk_staging(file_path: str) -> int:
        """
        Loeb JKK andmed failist (XCom annab ainult tee) ja laeb staging tabelisse.
        """
        import json
        import uuid
        from datetime import datetime, timezone
        from contextlib import closing

        from airflow.providers.postgres.hooks.postgres import PostgresHook

        with open(file_path) as f:
            data = json.load(f)

        hook = PostgresHook(postgres_conn_id="poi_upd_db")
        with closing(hook.get_conn()) as conn, conn, conn.cursor() as cur:
            cur.execute(
                """INSERT INTO staging.raw_snapshot (run_id, fetched_at, source_name, row_count, raw_data, status)
                VALUES (%s, %s, %s, %s, %s, %s)""",
                (str(uuid.uuid4()), datetime.now(timezone.utc), "f_jkkregister_curr", len(data), json.dumps(data), "SUCCESS"),
            )

        print(f"Laaditud {len(data)} jäätmekäitluskohta staging tabelisse")
        return len(data)

    @task
    def load_jkk_intermediate() -> None:
        """
        Käivitab andmebaasi protseduuri andmete laadimiseks staging -> intermediate.
        """
        from airflow.providers.postgres.hooks.postgres import PostgresHook
        from contextlib import closing

        hook = PostgresHook(postgres_conn_id="poi_upd_db")
        with closing(hook.get_conn()) as conn, conn, conn.cursor() as cur:
            cur.execute(
                """CALL intermediate.refresh_jkk_curr_clean();"""
            )
    # -----------------------------------------------------------------------
    # Sõltuvuste defineerimine
    # -----------------------------------------------------------------------

    # Extract ja load
    jkk_data = extract_jkk_data()
    jkk_staging_loaded = load_jkk_staging(jkk_data)

    jkk_intermediate_loaded = load_jkk_intermediate()
    jkk_staging_loaded >> jkk_intermediate_loaded

jkk_poi_update_pipeline()

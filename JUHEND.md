
### Seadistamine

#### Konteineri poi-upd loomine
1. Käivita Docker Desktop (muidu annab terminal vea, et käsk docker on tundmatu)

2. Kopeeri `.env.example` failist `.env`:

```bash
cp .env.example .env
```

3. Vajadusel muuda `.env` failis kasutajanimed ja paroolid.

4. Käivita teenused (läheb kaua):

```bash
docker compose -p poi-upd up -d
```

> **NB!** `.env` fail sisaldab paroole ja **ei tohi** satuda Giti repositooriumisse. Fail on lisatud `.gitignore`-sse.

5. Oota kuni teenused on valmis ja kontrolli, kas kõik töötab:

```bash
docker compose -p poi-upd ps
```

#### Dockeri töö peatamine (ei kustuta konteinerit)

```bash
docker compose -p poi-upd stop
```

#### Uuesti dockeri konteineri käivitamine

```bash
docker compose -p poi-upd restart
```

#### Kui tahad konteineri täiesti ära kustutada

```bash
docker compose -p poi-upd down -v
```

### Teenused

| Teenus | Konteiner | Kirjeldus |
|--------|-----------|-----------|
| PostgreSQL | `poi-upd-pgdb` | Andmebaas (pgduckdb) |
| airflow-db | `poi-upd-airflow-db` | Airflow metaandmebaas
| airflow-init | `poi-upd-airflow-init` | ühekordne initsialiseerimine
| airflow-apiserver | `poi-upd-airflow-api` | Airflow UI ja REST API (port 8080)
| airflow-scheduler | `poi-upd-airflow-scheduler` | DAG-ide käivitamine
| airflow-dag-processor | `poi-upd-airflow-dagproc` | DAG-ide parsimine
| Python | `poi-upd-python` | Python 3.12 koos `psycopg2` ja `requests` teekidega |
| pgAdmin | `poi-upd-pgadmin` | Veebipõhine andmebaasihaldur |
| Metabase | `poi-upd-metabase` | Metabase juhtimislaua tegemiseks |

### Ühendused

Vaikimisi väärtused (`.env.example` põhjal):

| Teenus | Kasutaja | Parool | Port |
|--------|----------|--------|------|
| PostgreSQL | `projektitoo` | `projektitoo` | 5432 |
| pgAdmin | `admin@example.com` | `admin` | 5050 |
| Airflow | `airflow`| `airflow` | 8080 |
| Metabase | `metabase`| `metabase` | 3001 |

pgAdmini saab lahti võtta aadressil:
[http://localhost:5050](http://localhost:5050)

pgAdminis andmebaasiga ühenduse lisamiseks kasuta hosti `poi-upd-db`.

Airflow saab lahti võtta aadressil: [http://localhost:8080](http://localhost:8080)

Matabase saab lahti võtta aadressil [http://localhost:3001](http://localhost:3001)

#### Ühenduse loomine kohaliku masina QGIS-ga

Sea ühenduse parameetrid:
- host: localhost
- port: 55432
- database: projektitoo  
auth - basic: 
- user name: .env failist: {POSTGRES_USER}
- password: .env failist: {POSTGRES_PASSWORD}


### Esimene andmebaasi käivitus

Meie repos on **init** katalooga ja sinna sisse saame panna schemade tabelite (csv sissetõmbamise) ja protseduuride tekitamise .sql failid. Konteineri käivitamisel jooksutatakse need automaatselt.
See on Dockeris seadistatus andmebaasi konteineri osas:`/docker-entrypoint-initdb.d`:


## Lihtne ETL ühenduse katsetamiseks

Skript põhineb 1. edasijõudnute praktikumi näitel (etl_simple.py).
Loeb jäätmekäitluskohtade registri andmetest ainult veerud objekti_nimetus ja jkk_kood.
url = "https://keskkonnaandmed.envir.ee/f_jkkregister_curr?select=objekti_nimetus,jkk_kood"

Loob andmebaasi tabeli ja täidab selle andmetega.

```bash
docker exec -it poi-upd-python sh -c "python /scripts/poi-upd-f_jkkregister_curr.py"
```

17.05.2026 - Laadis 2953 rida
20.05.2026 - Laadis 2956 rida
24.05.2026 - Laadis 2957 rida

## Andmete sissetõmbamine staging.raw_snapshot tabelisse

```bash
docker exec -it poi-upd-python sh -c "python /scripts/poi-upd-f_jkkregister_curr_ingest.py"
```

Nüüd saab seda teha ka Airflowga.
Airflog DAG on projekti kataloogis /airflow/dags/jkk-poi-upd-pipeline.py


## Andmete laadimine intermediate.clean_current_run tabelisse
Protseduuri kood: /init/02_load_clean_current_run.sql
Protseduuri saab välja kutsuda käsuga

```sql
CALL intermediate.load_clean_current_run();
```

## Andmete konverteerimine intermediate.jkk_curr_clean tabelisse

```bash
docker exec -it poi-upd-pgdb psql -U projektitoo -d projektitoo -v ON_ERROR_STOP=1 -c "CALL intermediate.refresh_jkk_curr_clean();"
```
Lisasin siia Dockeri kirjelduse, käsud käivitamiseks ja esimese test skripti API ühenduse testimiseks.  
17.05.2026 - Laadis 2953 rida f_jkkregister_curr tabelisse (Õie)

### Seadistamine

#### Konteineri poi-upd loomine
1. Käivita Docker Desktop (muidu annab terminal vea, et käsk docker on tundmatu)

2. Kopeeri `.env.example` failist `.env`:

```bash
cp .env.example .env
```

3. Vajadusel muuda `.env` failis kasutajanimed ja paroolid.

4. Käivita teenused:

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
| PostgreSQL | `poi-upd-analytics-db` | Andmebaas (pgduckdb) |
| airflow-db | `poi-upd-airflow-db` | Airflow metaandmebaas
| airflow-init | `poi-upd-airflow-init` | ühekordne initsialiseerimine
| airflow-apiserver | `poi-upd-airflow-api` | Airflow UI ja REST API (port 8080)
| airflow-scheduler | `poi-upd-airflow-scheduler` | DAG-ide käivitamine
| airflow-dag-processor | `poi-upd-airflow-dagproc` | DAG-ide parsimine
| Python | `poi-upd-python` | Python 3.12 koos `psycopg2` ja `requests` teekidega |
| pgAdmin | `poi-upd-pgadmin` | Veebipõhine andmebaasihaldur |

### Ühendused

Vaikimisi väärtused (`.env.example` põhjal):

| Teenus | Kasutaja | Parool | Port |
|--------|----------|--------|------|
| PostgreSQL | `projektitoo` | `projektitoo` | 5432 |
| pgAdmin | `admin@example.com` | `admin` | 5050 |
| Airflow | `airflow`| `airflow` | 8080 |

pgAdmini saab lahti võtta aadressil:
[http://localhost:5050](http://localhost:5050)

pgAdminis andmebaasiga ühenduse lisamiseks kasuta hosti `analytics-db`.

Airflow saab lahti võtta aadressil: [http://localhost:8080](http://localhost:8080)


## Lihtne ETL ühenduse katsetamiseks

Skript põhineb 1. edasijõudnute praktikumi näitel (etl_simple.py).
Loeb jäätmekäitluskohtade registri andmetest ainult veerud objekti_nimetus ja jkk_kood.
url = "https://keskkonnaandmed.envir.ee/f_jkkregister_curr?select=objekti_nimetus,jkk_kood"

Loob andmebaasi tabeli ja täidab selle andmetega.

```bash
docker exec -it poi-upd-python sh -c "python /scripts/poi-upd-f_jkkregister_curr.py"
```

17.05.2026 - Laadis 2953 rida
# Arhitektuur

## Äriküsimus

Ärivajadus on hoida jäätmekäitlusregistri põhised huvipunktide andmed ettevõtte POI andmebaasis maksimaalselt ajakohasena võimalikult vähese käsitööga. Lahendus peab lisaks sisestusvamis muudatuste ette valmistamisele andma ülevaate nende käsitlemise seisust, et spetsialist saaks hinnata töömahtu, andmete ajakohasust ja andmehoolduse prioriteete.

## Mõõdikud

1. **Lahendamata muudatuste arv ja osakaal**  
Näitab, mitu jäätmekäitlusregistri objekti on tuvastatud POI andmebaasi jaoks uue, muutunud või eemaldatud objektina, kuid ei ole veel sihtandmebaasis käsitletud.

2. **Lahendamata muudatuste jaotus tüübi järgi**  
Näitab, kas lahendamata muudatused on seotud lisandunud objektide, eemaldatud objektide, atribuudimuutuste või asukohamuutustega.

3. **Lahendamata muudatuste ruumiline paiknemine**  
Näitab kaardil, kus lahendamata muudatused paiknevad, et spetsialist saaks hinnata töö piirkondlikku jaotust ja prioriteetsust.

## Andmeallikad

Keskkonnaregister avaandmed:
https://keskkonnaandmed.envir.ee/f_jkkregister_curr
Püü täpsustab milline(millsed) tabelid
ilmselt sobiks see kõige paremini: f_jkkregister_curr (Jäätmekäitluskohtade register)
https://keskkonnaandmed.envir.ee/f_jkkregister_curr

| Allikas | Tüüp | Ajas muutuv? | Roll |
|---------|------|--------------|------|
| Jäätmekäitlusregister | Avalik PostgREST/JSON API | Jah, registriandmed uuenevad jooksvalt | Peamine andmeallikas, kust võetakse jäätmekäitlusega seotud objektide hetkeseis |
| algne POI seoste tabel | Ühekordne algseadistuse tabel CSV formaadis | Ei, staatiline | Aitab esmakordsel andmevoo loomisel siduda olemasolevad registriobjektid ettevõtte POI andmebaasi objektidega |

## Andmevoog

Esialgsed arhitektuuri mõtted:
- Apache AirFlow
- PostgreSQL, funktsioonid/protseduurid seal
- Metabase


## Andmevoog

```mermaid
flowchart LR
    source[Jäätmekäitlusregister<br/>PostgREST JSON API]

    subgraph etl[Praktikumi käigus arendatav ETL töövoog]
        raw[(staging.raw_snapshot)]
        stg[(staging.register_clean)]
        diff[(intermediate.register_diff)]
        full[(production.full_register)]
        changes[(production.poi_changes)]
        dash[Metabase dashboard]
        airflow[Airflow + Python]
        sql[PostgreSQL / PostGIS SQL]

        airflow -->|pärib andmed| raw
        raw -->|parsimine ja puhastus| stg
        stg -->|võrdlus eelmise seisuga| diff
        diff -->|uuendab registri hetkeseisu| full
        diff -->|lisab uued muutused| changes
        full -->|KPI-d ja ülevaated| dash
        changes -->|muutuste tööjärg| dash
    end

    subgraph external[Päris tööprotsessi osa, mida täielikult ei arendata ega demonstreerita]
        qgis[QGIS<br/>spetsialisti töölaud]
        poi[(Ettevõtte POI andmebaas)]
    end

    source -->|HTTP GET / JSON| airflow
    sql --> full
    sql --> changes

    full -->|vaatamine, seoste haldus,<br/>staatuse muutmine, geomeetria täpsustus| qgis
    changes -->|muudatuste kontroll ja kinnitamine| qgis
    qgis -->|kinnitatud muudatuste sisestus| poi

    classDef demo fill:#dff3ff,stroke:#2b6cb0,stroke-width:1.5px,color:#000;
    classDef external fill:#eeeeee,stroke:#888888,stroke-width:1px,color:#000;

    class raw,stg,diff,full,changes,dash,airflow,sql demo;
    class qgis,poi external;
```
```mermaid
flowchart LR
    source[Jäätmekäitlusregister<br/>PostgREST JSON API] --> airflow[Apache Airflow]
    airflow --> ingest[Python sissevõtu skript]
    ingest --> staging[(staging<br/>registri hetkeseis)]
    staging --> transform[PostgreSQL/PostGIS<br/>transformatsioonid]
    transform --> full[(full tabel<br/>registri seis + töövoo väljad)]
    transform --> changes[(muudatuste tabelid<br/>uued, eemaldatud, muutunud)]
    full --> qgis[QGIS<br/>spetsialisti töölaud]
    changes --> qgis
    full --> dashboard[Metabase dashboard]
    changes --> dashboard
    full --> quality[Andmekvaliteedi kontrollid]
    changes --> quality
```

```mermaid
flowchart LR
    source[Andmeallikas] --> ingest[Sissevõtt]
    ingest --> staging[(staging)]
    staging --> transform[Transformatsioon]
    transform --> mart[(mart)]
    mart --> dashboard[Näidikulaud]
    mart --> quality[Andmekvaliteedi testid]
    scheduler[Scheduler] --> ingest
```

> Täpsusta diagrammi vastavalt oma projektile — lisa rohkem andmeallikaid, mudeleid või teenuseid.

## Andmebaasi kihid

| Kiht | Roll |
|------|------|
| `staging` | Hoiab allika andmeid töötlemata kujul. |
| `mart` | Hoiab transformeeritud ja ärilogikat sisaldavaid tabeleid. |

## Tööjaotus

| Roll | Vastutus | Täitja |
|------|----------|--------|
| Andmeallika omanik | Kirjutab sissevõtu loogika, hoiab API-t töös | [Nimi] |
| Transformatsioonide omanik | Kirjutab mart kihi mudelid ja mõõdikute arvutuse | [Nimi] |
| Kvaliteedi omanik | Kirjutab testid ja vaatab läbi ebaõnnestunud kontrollid | [Nimi] |
| Näidikulaua omanik | Ehitab näidikulaua ja seob selle äriküsimusega | [Nimi] |

## Riskid

| Risk | Mõju | Maandus |
|------|------|---------|
| [Risk 1 — näiteks: API ei vasta] | [Mis juhtub?] | [Kuidas maandad?] |
| [Risk 2] | [Mis juhtub?] | [Kuidas maandad?] |
| [Risk 3] | [Mis juhtub?] | [Kuidas maandad?] |

## Privaatsus ja turve

[Kirjelda, millised isiku- või tundlikud andmed teie projektis esinevad (kui üldse) ja kuidas neid kaitsete. Isikuandmed peavad olema anonümiseeritud. Andmebaasi paroolid peavad tulema `.env` failist.]

# Edenemisraport

## Mis on valmis

- [x] Docker Compose käivitab kõik teenused
- [x] Andmeid saadakse allikast kätte
- [x] Andmed laetakse `staging` kihti
- [x] Vähemalt üks transformatsioon toimib
- [x] Vähemalt üks näidikulaud on nähtaval
- [x] Vähemalt üks andmekvaliteedi test läbib

Docker Compose käivitab teenused: PostgreSQL, Airflow, Python, pgAdmin, Metabase.
Loeme PostgREST API-st jäätmekäitluskohtade registri andmed ning salvestame need idempotentselt PostgreSQL‑i staging‑kihis asuvasse tabelisse staging.raw_snapshot, koos metaandmetega (run_id, timestamp, allika nimi, ridade arv ja täielik JSON‑snapshot). 
Airflow DAG jkk-poi-upd-pipeline orkestreerib jäätmekäitluskohtade (JKK) andmete öise uuenduse: API‑st laaditakse värske JSON‑snapshot, see salvestatakse PostgreSQL‑i staging‑kihti, seejärel käivitatakse andmebaasi protseduurid, mis uuendavad intermediate kihi puhastatud tabeli (jkk_curr_clean) ning märgivad production kihis eemaldatud objektid. 
Puhastamise käigus muudetakse stagingu toor‑snapshot ühtlaseks, duplikaatideta ja normaliseeritud andmestikuks, kus vigased või puuduvad väärtused korrastatakse ning alles jäävad ainult analüüsiks ja edasiseks laadimiseks sobivad väljad.
Andmebaasi protseduur ehitab puhastatud andmestikust production‑kihi lõpliku tabeli jkk_full, kirjutades vana sisu täielikult üle värske ja korrastatud jooksuga.
NB! Transformatsioonid on lahendatud andmebaasi protseduuride kaudu, mida orkestreerib Airflow. Oleme selle lähenemise valinud teadlikult, sest organisatsioonil on tugev kompetents ja kogemus protseduuripõhise äriloogika arendamisel.
Metabase keskkonnas loodud näidikulaual on eemaldatud objektide arv ning kontrollimist vajavate objektide arv ja osakaal.

## Järgmised sammud

- Vaja on täiendada protseduure nii, et muudatuste tuvastamine, eemaldamiste käsitlemine ja lõppseisu uuendamine töötaksid ühtse, veakindla protsessina.
- Orkestreerimine tuleb koondada üheks keskseks käivitusprotseduuriks, mis tagab tervikliku jooksu ja andmekvaliteedi kontrollid.  
- Dashboardi püsivus tuleb lahendada — kas SQL salvestus, eksport, API, backup või muu mehhanism — et tulemus ei kaoks ja oleks esitletav.

## Mis takistab

- oskused
- aeg

## Kontrollpunkt

Käsk, millega saab kontrollida, et töövoog töötab:

```bash
docker exec poi-upd-airflow-scheduler \
    airflow dags trigger jkk-poi-upd-pipeline
```

Oodatav tulemus: production kihil on tabelid jkk_full ja jkk_removed

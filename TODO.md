# JOOKSEV

## TODO

## Üldine production-refresh põhimõte

Production-kihi uuendamine peab toimuma ühe tervikliku andmebaasitoiminguna.

Uuendustsükli kolm põhisammu on:

1. eemaldatud objektide tuvastamine;
2. muutunud objektide tuvastamine;
3. `production.jkk_full` uuendamine.

Need sammud peavad käituma ühe tervikuna.

Kui eemaldatud objektide ja muutuste tuvastamine õnnestub, aga `jkk_full` uuendamine ebaõnnestub, ei tohi ka eemaldatud objektide ega muutuste info production-tabelitesse alles jääda.

Põhimõte:

`Üks jooksutus kas õnnestub tervikuna või ei muuda production-seisu üldse.`

Selleks tuleb teha wrapper-protseduur `production.refresh_jkk_production()`, mis kutsub õiges järjekorras välja alamprotseduurid.

Alamprotseduurid:

* `production.load_jkk_removed()`
* `production.load_jkk_changed()`
* `production.move_jkk_curr_to_jkk_full()`

ei tohi sisaldada `COMMIT` ega `ROLLBACK` käske.

Transaction'i terviklikkust juhib wrapper-protseduur ja seda käivitav andmebaasiühendus.

Airflow peaks hiljem käivitama ainult ühe production-kihi käsu:

`CALL production.refresh_jkk_production();`

Airflow ei peaks eraldi orkestreerima `removed`, `changed` ja `full update` samme.

## 1. Teha valmis `production.load_jkk_changed()`

TEHTUD

Eesmärk on tuvastada olemasolevate objektide muutused vana production-seisu ja uue intermediate-seisu vahel.

Võrdlus peab käima tabelite `production.jkk_full` ja `intermediate.jkk_curr_clean` vahel.

Võrdlusvõti on `jkk_kood_ext`.

Tuvastada tuleb muutused järgmistes väljades:

* `nimi`
* `brand`
* `liigisona`
* `lipikud`
* `geom`, kui asukoha muutus on üle 30 m

Tulemused tuleb lisada tabelisse `production.jkk_changes`.

Lisada tuleb duplikaatide vältimine, et sama lahendamata muutust ei lisataks iga jooksutusega uuesti.

Protseduur ei tohi ise teha `COMMIT` ega `ROLLBACK`.

Kui protseduuris tekib viga, peab see liikuma edasi wrapper-protseduurini, et kogu production-refresh katkeks.

## 2. Parandada `production.load_jkk_removed()` loogikaerinevused

Olemasolev `production.load_jkk_removed()` on põhiloogika mõttes olemas, aga vajab täpsustamist.

Täiendada tuleb järgmised kohad:

- [x] võrdlus peaks arvestama `jkk_kood_ext` väärtust, mitte `jkk_kood` väärtust; TEHTUD
- [x] `remove_resolved_date` peab olema `staatus = -1` korral `current_date`, muudel juhtudel `NULL`; TEHTUD
- [ ] lisada tuleb duplikaatide vältimine, et sama lahendamata eemaldust ei lisataks igal jooksutusel uuesti.

Protseduur ei tohi ise teha `COMMIT` ega `ROLLBACK`.

Kui protseduuris tekib viga, peab see liikuma edasi wrapper-protseduurini, et kogu production-refresh katkeks.

## 3. Kirjutada `production.move_jkk_curr_to_jkk_full()` ümber

TEHTUD

Praegune lahendus ei sobi lõplikuks production-uuenduseks.

Uus loogika peab võtma sisendiks `intermediate.jkk_curr_clean`.

Vanast `production.jkk_full` tabelist tuleb säilitada käsitsi hallatavad väljad:

* `poi_id`
* `staatus`
* `kommentaar`
* `added_date`
* `resolved_date`
* `geom_mod`

Uutele objektidele tuleb määrata algväärtused:

* `poi_id = NULL`
* `staatus = 1`
* `kommentaar = NULL`
* `added_date = current_date`
* `resolved_date = NULL`
* `geom_mod = geom`

Kui objektile ei teki `kat_id` väärtust, siis tuleb rakendada kõrvalejätmise loogikat:

* `poi_id = -1`
* `staatus = -1`
* `resolved_date = current_date`

Kui olemasoleva objekti registrigeomeetria on muutunud üle 30 m, tuleb uuendada ka `geom_mod`, sest sellisel juhul ei ole varasem käsitsi korrigeeritud geomeetria enam usaldusväärne.

`jkk_full` uuendamine peab eemaldama objektid, mida uues seisus enam ei ole, aga alles pärast seda, kui removed ja changed info on tuvastatud.

Protseduur ei tohi ise teha `COMMIT` ega `ROLLBACK`.

Kui protseduuris tekib viga, peab see liikuma edasi wrapper-protseduurini, et kogu production-refresh katkeks.


## 4. Teha wrapper-protseduur `production.refresh_jkk_production()`

TEHTUD
Testisin, et removed kihi uuendus ROLLBACKitakse, kui changed kihiga tekib mingi jama. Airflows on näha baasi veateade. (Õie)

Production-kihi uuendamine peab olema üks terviklik andmebaasitoiming.

Wrapper-protseduur peaks tegema samas järjekorras:

1. `CALL production.load_jkk_removed();`
2. `CALL production.load_jkk_changed();`
3. `CALL production.move_jkk_curr_to_jkk_full();`

Need kolm sammu peavad moodustama ühe terviku.

Kui üks samm ebaõnnestub, peab kogu production-refresh katkema.

Wrapper ei pea ise sisaldama `COMMIT` ega `ROLLBACK` käske, kui seda käivitatakse ühe SQL-käsuna tavapärase andmebaasiühenduse kaudu.

Oluline on, et alamprotseduurid ei teeks ise transaction'i lõpetamist ning ei peidaks vigu ära.

Kui veateadet on vaja logida, tuleb vea järel kasutada `RAISE`, et viga liiguks edasi ja kogu transaction katkeks.


## 5. Lisada kontrollid enne `jkk_full` lõplikku uuendamist

TEHTUD

Enne vana `jkk_full` asendamist tuleb kontrollida, et uus seis on kasutatav.

Kontrollida vähemalt:

- [x] `jkk_kood_ext` ei ole tühi; - TEHTUD
- [x] `jkk_kood_ext` ei dubleeru; - TEHTUD
- [x] `staatus` väärtus on lubatud väärtus; - TEHTUD
- [ ] `staatus = -1` korral on `poi_id = -1`; Ei saa rakendada, sest kui POI baasis olemasolev POI muutub arhiveerituks, siis tal on korraga nii POI_ID kui ka määratakse staatus =-1;
- [x] `staatus IN (-1, 2)` korral on `resolved_date` täidetud;
- [x] aktiivsetel objektidel on geomeetria olemas. - TEHTUD

Kui kontroll ei läbi, tuleb protseduur katkestada `RAISE EXCEPTION` abil.

Kontrollid peavad toimuma enne seda, kui `production.jkk_full` sisu asendatakse.

## 6. Siduda production-refresh Airflow DAG-iga

TEHTUD

Airflow tuleks siduda alles siis, kui andmebaasis töötab üks terviklik production-refresh protseduur.

Airflow DAG-i production-samm peaks kutsuma ainult:

`CALL production.refresh_jkk_production();`

Airflow ei peaks eraldi orkestreerima samme:

* `load_jkk_removed`
* `load_jkk_changed`
* `move_jkk_curr_to_jkk_full`

Rollback ja production-loogika peaksid jääma andmebaasi poolele.

See teeb Airflow töö lihtsamaks: Airflow kontrollib ainult seda, kas production-refresh tervikuna õnnestus või ebaõnnestus.

## 7. Lisada andmekvaliteedi testid

Lisada SQL-põhised kontrollid, mida saab käsitsi või Airflow kaudu käivitada.
Neid asju enne jkk_changed ja jkk_full tabeli ülekirjutamist kontrollitakse. Kas on eraldi veel vaja kontrollida? (Õie)

Võimalikud testid:

* `jkk_kood_ext` unikaalsus tabelis `production.jkk_full`;
* lubatud `staatus` väärtused;
* `kat_id` puudumisel `staatus = -1`;
* `staatus = -1` korral `poi_id = -1`; Ei saa rakendada, sest kui POI baasis olemasolev POI muutub arhiveerituks, siis tal on korraga nii POI_ID kui ka määratakse staatus =-1;
* aktiivsetel objektidel `geom` olemasolu;
* lahendamata removed-kirjete duplikaatide puudumine;
* lahendamata changed-kirjete duplikaatide puudumine.

Need testid ei pea tingimata olema esimene asi, aga need peaksid olemas olema enne, kui lahendus loetakse valmis production-töövooks.

## 8. Otsustada, kuidas käsitleda Metabase dashboardi püsivust

Metabase dashboard töötab lokaalses arenduskeskkonnas, aga tuleb otsustada, kas ja kuidas seda teha teistele jagatavaks ning automaatselt taastatavaks.

Praegune arusaam:

Metabase tasuta versioonis ei ole mugavat dashboardi koodiks eksportimise ja uuesti importimise lahendust. Valmis dashboardi serialization on Metabase Pro / Enterprise funktsionaalsus.

Võimalikud lahendused:

1. jätta dashboard demo jaoks lokaalsesse Metabase instance'isse;
2. salvestada dashboardi taga olevad SQL-päringud reposse;
3. kasutada Metabase API-t, et luua skript, mis tekitab ühenduse PostgreSQL andmebaasiga ning loob küsimused ja dashboardid automaatselt;
4. säilitada Metabase rakenduse andmebaasi volume või backup, kui eesmärk on ainult lokaalse tööseisu säilitamine.

Otsustamist vajab, milline tase on projekti jaoks piisav:

* kas piisab sellest, et demo saab teha ühe masina Metabase pealt;
* kas piisab sellest, et SQL-päringud on repos olemas;
* või peab dashboard tekkima automaatselt pärast Docker Compose käivitamist.

Kui valida API-põhine lahendus, tuleb arvestada eraldi tööga. Lihtsa automaatse ülesseadmise saab tõenäoliselt teha väikese skriptina, aga viimistletud ja töökindel lahendus võtab rohkem aega.

Hetkel jätta see otsustuspunktiks, mitte kohe realiseeritavaks kohustuseks.

## 9. Koristada dokumentatsioon pärast transformatsioonide valmimist

Kui production-loogika on valmis, tuleb dokumentatsioon viia tegeliku lahendusega kooskõlla.

Uuendada vähemalt järgmised failid:

* `docs/03_tulemid_kirjeldus_kodeerimine.md`
* `docs/arhitektuur.md`
* `README.md`
* `docs/progress.md`

Eemaldada tuleb aegunud kirjeldused, mallitekstid ja vahepealsed oletused.

Dokumentatsioonis tuleb ühtlustada geomeetria muutuse piir ning kasutada läbivalt 30 m.

## 10. Lisada clean tabeli `brand` veeru tranformatsioonifunktsioon

Funktsioon olemas, saaks rakendada, laetud üles: https://github.com/6ie/andmeinseneeria-projektitoo-2026/blob/main/scripts/todo_or_not_todo/_create_function_clean_comp_name.sql

See todo nice-to-have, ei ole hullu, kui ei jõua.


# ESIALGNE

## Projektitöö TO DO kirjeldused sprindi kaupa

Seda saame järjepidamise mõttes jooksvalt täitma hakata.

### 18.05 - 24.05: Planeerimine ja arhitektuur

**Eesmärk:**

-   Leppida kokku äriküsimus ja mõõdikud.
-   Kaardistada andmeallikad ja kontrollida, et ligipääsud töötavad.
-   Joonistada arhitektuuriskeem.
-   Jagada ülesanded grupiliikmete vahel.
-   Alustada esimeste tehniliste katsetustega (kas API töötab, kas saame andmebaasi ühenduda).

**Mida esitada (24.05. P 23:59):**

1.  Repos fail `docs/arhitektuur.md`, mis sisaldab:
    -   Äriküsimust ja 2-3 mõõdikut.
    -   Arhitektuuriskeemi (Mermaid, Excalidraw, draw.io, käsitsi joonis + foto).
    -   Andmeallikate loetelu ja muutuvuse kirjeldust.
    -   Tööjaotust (kes mille eest vastutab).
    -   2-3 riski.
2.  Individuaalne vahetagasiside Moodle assignmentis (5 minutit, konfidentsiaalne).


### 25.05 - 31.05: Esimene töötav andmevoog

## 

**Eesmärk:**

-   Ehitada ühe andmevoo täielikult välja: üks allikas, andmete sissevõtt, üks transformatsioon, üks visuaal.
-   Selle eesmärk: leida tehnilised probleemid varakult.
-   Pole vaja, et oleks olemas kõik allikad ja kõik testid. Oluline näha, kus tekivad võimalikud pudelikaelad.

**Mida esitada (31.05 P 23:59):**

1.  Repos:
    -   Toimiv kood (vähemalt üks allikas → transformatsioon → visuaal).
    -   Fail `docs/progress.md` (5 rida): mis on valmis, mis on järgmised sammud, mis takistab.
2.  Individuaalne vahetagasiside Moodle assignmentis.


### 01.06 - 07.06: Projekti lõpetamine

**Eesmärk:**

-   Lisada puuduvad andmeallikad ja transformatsioonid.
-   Kirjutada andmekvaliteedi testid (vähemalt 3 tk).
-   Viimistleda näidikulauda (vähemalt 2 KPI-d).
-   Täita README ette antud malli põhjal.
-   Salvestada 10-minutiline video (esitlus + demo).

**Mida esitada (07.06 P 23:59):**

1.  Repos:
    -   Täielik projekt vastavalt 8 kohustuslikule nõudele.
    -   Täidetud README malli põhjal.
2.  Video: 10 minutit, jagatud lingi kaudu (nt YouTube unlisted, Google Drive, Onedrive).
3.  Moodle assignment: link videole, link repole. Kui repo on privaatne, lisage juhendajatele ligipääs.
4.  Individuaalne vahetagasiside Moodle assignmentis.

### 08.06 - 14.06: Tagasiside teistele

**Eesmärk:**

-   Hiljemalt esmaspäeva hommikul saate Moodle's teada, mis 2 grupi videot ja repot teil tagasisidestada tuleb.
-   Vaatate videod, sirvite repod.
-   Esitate tagasiside Moodle assignmentis.

**Mida esitada (14.06 P 23:59):**

Iga grupi kohta vastate 6 punktile. Iga vastus peab olema sisuline ja konkreetne, viidates just selle grupi tööle. Üldised vastused ("tubli", "hea töö") ei kvalifitseeru ja palutakse ümber teha.

1.  **Äriküsimus ja väärtus.** Kas grupi äriküsimus on selge ja kas dashboard vastab sellele? Kas kasutaksid päriselt?
2.  **Andmevoog.** Kas andmetoru on terviklik (allikad → transformatsioon → dashboard)? Kas ajas muutuvus tuleb välja?
3.  **Andmekvaliteet.** Kas testid katavad olulisi probleeme? Mis võiks veel lisada?
4.  **Tehniline lahendus.** Mis tundus tark valik? Mis oleks ise teisiti teinud?
5.  **Selgus ja esitlus.** Kas video on arusaadav? Mis jäi segaseks?
6.  **Mida tegi see grupp paremini? Mida saaks see grupp teie grupilt õppida?** Kahepoolne refleksioon, konkreetsed asjad.
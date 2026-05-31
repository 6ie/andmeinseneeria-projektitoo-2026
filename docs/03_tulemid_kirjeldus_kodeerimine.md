# Tulemtabelite kirjeldus

## Eesmärk

See dokument kirjeldab JKK andmetöötluse `production` kihi tabeleid ja seda, kuidas need saadakse `intermediate` kihist.

JKK registri algandmete päritolu, sisendväljade valik ja tegevuskoodide kategooriatesse teisendamine on kirjeldatud dokumendis [`02_andmed_kirjeldus_kodeerimine.md`](02_andmed_kirjeldus_kodeerimine.md). 

## Production kihi üldine roll

`Production` on andmebaasi kiht, kus hoitakse JKK registri andmetöötluse tulemust, mida kasutab spetsialist sihtbaasi korrastamiseks ning hoitakse infot seoste ja tööjärje osas.

Selle kihis asuvad tabelid:

| Tabel | Roll |
|---|---|
| `production.jkk_full` | JKK registri objektide viimane seis koos seoste ja järje pidamise infoga |
| `production.jkk_removed` | JKK registrist kadunud või arhiveeritud objektide kumulatiivne kontrolltabel. |
| `production.jkk_changes` | JKK registri objektide atribuudi- ja geomeetriamuutuste kontrolltabel. |

## Sisend production kihile

Production kihi uuendamise sisenditeks on viimase jooksu `intermediate.jkk_curr_clean` tabel ja olemasoleva `production.jkk_full` tabeli eelmine seis.

See vahetabel (`intermediate.jkk_curr_clean`) sisaldab viimase eduka JKK API tõmmise põhjal puhastatud ja klassifitseeritud andmeid. Selles on juba tehtud:

| Tegevus | Tulemus |
|---|---|
| JKK registri JSON-i teisendamine kahedimensionaalseks tabeliks | Iga objekt on esitatud andmebaasi ühe või mitme reana. |
| Tekstide ja andmetüüpide korrastamine | Väljad on kasutatavad võrdlusteks ja laadimiseks. |
| Kategooria määramine | Täidetud on `kat_id`, kui objekt sobitub sihtkategooriasse. |
| Liigisõna ja lipikute määramine | Täidetud on `liigisona` ja `lipikud`, kui need on reeglite järgi leitavad. |
| Laiendatud välise koodi loomine | Täidetud on `jkk_kood_ext`. |
| Registrigeomeetria loomine | `geom` arvutatakse koordinaatidest. |

Täpsemaid põhimõtteid vaata dokumendist: [`02_andmed_kirjeldus_kodeerimine.md`](02_andmed_kirjeldus_kodeerimine.md)

## Tabel: `production.jkk_full`

### Otstarve

Tabelis hoitakse neid objekte, mis on olemas viimases registri seisus. See tabel on tööalus, mille abil saab näha, millised JKK objektid on olemas, milline on nende seos POI andmebaasiga ning kas objekt vajab edasist tegevust.


### Tabeli veergude kirjeldus

| Väli | Tüüp | Päritolu | Kirjeldus | Väärtusvaru / reeglid |
|---|---|---|---|---|
| `oid` | `bigint` | Andmebaas | Tabeli tehniline primaarvõti. | Automaatselt genereeritav väärtus.|
| `objekti_nimetus` | `text` | JKK register | Objekti nimetus registris. | Vabatekstima muutmata kujul |
| `jkk_kood` | `text` | JKK register | JKK registri objekti tunnus. Peamine väline tunnus registriandmete võrdlemisel. | Tavaliselt kujul `JKK...`.  Registris unikaalne, siin mitte.|
| `jkk_olukord` | `text` | JKK register | Objekti olukord JKK registris. | Väärtused: `Töötav`, `Arhiveeritud`|
| `kaitaja_nimi` | `text` | JKK register | Objekti käitaja nimi. | Vabatekstima muutmata kujul |
| `kaitaja_kood` | `text` | JKK register | Käitaja registrikood või muu registris olev tunnus. | Vabatekstima muutmata kujul |
| `aadress` | `text` | JKK register | Objekti aadress registris. | Vabatekstima muutmata kujul |
| `teised_aadressid` | `text` | JKK register | Objektiga seotud muud aadressid. | Vabatekst või tühi väärtus muutmata kujul |
| `x_koordinaat` | `integer` | JKK register | Registri X-koordinaat L-EST97 süsteemis. | Täisarv meetrites, EPSG:3301. |
| `y_koordinaat` | `integer` | JKK register | Registri Y-koordinaat L-EST97 süsteemis. | Täisarv meetrites, EPSG:3301. |
| `tegevus` | `text` | JKK register | Objekti tegevuskood või komaga eraldatud tegevuskoodide loend. | JKK tegevuskoodid, näiteks `U1`, `U5`, `U10`, `U13`, `U16`. |
| `tegevus_selg` | `text` | JKK register | Tegevuskoodi tekstiline selgitus. | Väärtused vastavad JKK tegevuskoodide selgitustele. |
| `tegevuse_tapsustus` | `text` | JKK register | Tegevuse täpsustus registris. | Vabatekst ote registrist |
| `tegevuse_algus` | `date` | JKK register | Tegevuse alguskuupäev. | Kuupäev või tühi väärtus. |
| `tegevuse_lopp` | `date` | JKK register | Tegevuse lõppkuupäev. | Kuupäev või tühi väärtus. Võib olla tulevikus. |
| `muudetud` | `text` | JKK register | Registrikirje muutmise aeg JKK registris. | Tekstina hoitav ajatempel registrist. |
| `komplekstegevus` | `text` | JKK register | Objekti komplekstegevuse kood või koodide loend. | Väärtusvaru: `K1`, `K2`, `K3`; võib olla täitmata.|
| `komplekstegevus_selg` | `text` | JKK register | Komplekstegevuse tekstiline selgitus. | Väärtusvaru: `Jäätmekäitluskeskus`, `Jäätmejaam`, `Lisa nimistus puuduv komplekstegevus`; võib olla täitmata.|
| `jaatmete_kaitlemine` | `text` | JKK register | Info selle kohta, kelle jäätmeid objektis käideldakse. | Väärtusvaru: `oma`, `teiste`; võib olla täitmata. |
| `jkk_kood_ext` | `text` | Transformatsioon | Ühendidentifikaator. Võimaldab eristada sama JKK objekti eri sihtkategooria ridu. | Kui `kat_id` on olemas, moodustatakse kujul `jkk_kood || '_' || kat_id`. Kui `kat_id` puudub, jääb väärtuseks `jkk_kood`. |
| `nimi` | `text` | Transformatsioon | Puhastatud objekti nimi. | Aluseks `objekti_nimetus`. |
| `lyhinimi` | `text` | Transformatsioon | Puhastatud objekti lühinimi. | Kui `objekti_nimetus` on kuni 40 märki, võib kasutada seda; kui nimi on pikem, jäääb tühjaks ja lahendatakse sihtsüsteemis käsitsi. |
| `brand` | `text` | Transformatsioon | Standardiseeritud ettevõtte nimi sihtsüsteemi jaoks. | Aluseks `kaitaja_nimi`. |
| `kat_id` | `integer` | Transformatsioon | Sihtbaasi kategooria ID. | Väärtusvaru: `2207` prügila, `2208` jäätmekäitluskoht/jäätmejaam, `2606` jõujaam või põletustehas, `3120` autolammutus, `2607` tööstus- või tootmishoone. Võib olla `NULL`, kui objektile kategooriat ei leita. Määramise reeglid kirjeldatud 02_andmed_kirjeldus_kodeerimine.md|
| `liigisona` | `text` | Transformatsioon | Objekti tüüpi kirjeldav nimetus. | Väärtusvaru: `Prügila`, `Suletud prügila`, `Jäätmekäitluskeskus`, `Jäätmejaam`, `Jäätmekäitluskoht`, `Jäätmepõletustehas`, `Koospõletustehas`, `Autolammutuskoda`. Võib olla `NULL`. Määramise reeglid kirjeldatud 02_andmed_kirjeldus_kodeerimine.md |
| `lipikud` | `text` | Transformatsioon | Täiendav kirjeldav info objekti tegevuse või alamliigi kohta. | Väärtuste loend, nt: `Tavajäätmeprügila`, `Ohtlike jäätmete prügila`, `Püsijäätmeprügila`, `Sortimisliin, -tehas`, `Ümberlaadimisjaam, vaheladu`, `Ohtlike jäätmete käitluskoht` jne. Mitme väärtuse korral eraldatakse väärtused semikooloniga. Määramise reeglid kirjeldatud 02_andmed_kirjeldus_kodeerimine.md |
| `poi_id` | `integer` | Spetsialisti hallatav | Seotud POI objekti ID sihtandmebaasis. | Positiivne täisarv tähendab olemasolevat POI objekti. `-1` tähendab, et objekt on teadlikult POI vaatest kõrvale jäetud. `NULL` tähendab, et seos ei ole veel määratud ehk vajab spetsialisti tähelepanu. |
| `staatus` | `integer` | Spetsialisti hallatav | Objekti käsitlemise seis. | Väärtusvaru: 1 - kontrollimta objekt; 2 - kontrollitud seotud objekt; -1 - kontrollitud sidumata objekt  |
| `kommentaar` | `text` | Spetsialisti hallatav | Spetsialisti märkus, otsuse põhjendus või muu käsitlemise info. | Vabatekst. |
| `added_date` | `date` | Süsteemi hallatav | Kuupäev, millal objekt tabelisse lisati. | Kuupäev. Täidetakse automaatselt uue rea lisamisel. |
| `resolved_date` | `date` | Spetsialisti hallatav | Kuupäev, millal objekt loeti lahendatuks. | Kuupäev või tühi väärtus. Täidetakse siis, kui `staatus` muutub väärtuseks `2` või `-1`. |
| `geom` | `geometry(Point, 3301)` | Transformatsioon | Registri koordinaatidest loodud punktgeomeetria. | EPSG:3301 punkt. Arvutatakse `x_koordinaat` ja `y_koordinaat` väärtuste põhjal. |
| `geom_mod` | `geometry(Point, 3301)` | Spetsialisti hallatav | Geomeetria, mida saab vajadusel käsitsi korrigeerida. | EPSG:3301 punkt. Uue objekti lisandumisel sama, mis registris. olemasolevate objektide puhul - juhul kui registri geomeetria muutub rohkem, kui 50m siis üle kirjutada registri geomeetriaga, kui vähem, siis säilitada objekti küles olev geomeetria. |

### Kasutatavad väärtusvarud

#### `staatus` välja väärtusvaru

| Väärtus | Tähendus |
|---:|---|
| `1` | Vaikeväärtus uue objekti lisandumisel. Objekt vajab käsitlemist sihtsüsteemis (lisamine, sidumine, otsust, et ei kohaldu). |
| `2` | Objekt on sihtbaai POI objektiga seotud. |
| `-1` | Objekt ei ole sihtbaai POI vaates vajalik ja jäetakse teadliku otsusega kõrvale. |

#### `poi_id` välja väärtusvaru

| Väärtus | Tähendus |
|---:|---|
| Positiivne täisarv | Seotud POI objekti ID sihtandmebaasis. |
| `-1` | Objekt on teadlikult POI vaatest kõrvale jäetud. |
| `NULL` | Pbjekt on üle sihtsüsteemi vaates käsitlemata |

#### `kat_id` välja väärtusvaru

| Väärtus | Tähendus |
|---:|---|
| `2207` | Prügila |
| `2208` | Jäätmekäitluskeskus, jäätmejaam või jäätmekäitluskoht |
| `2606` | Jõujaam |
| `3120` | Autolammutuskoda |
| `2607` | Tööstus- või tootmishoone |
| `NULL` | Objektile ei määratud sihtkategooriat |

#### `liigisona` välja väärtusvaru

| Väärtus | Selgitus |
|---|---|
| `Prügila` | Töötav prügila |
| `Suletud prügila` | Suletud prügila |
| `Jäätmekäitluskeskus` | Komplekstegevuse või tegevuse põhjal tuvastatud jäätmekäitluskeskus |
| `Jäätmejaam` | Komplekstegevuse või tegevuse põhjal tuvastatud jäätmejaam |
| `Jäätmekäitluskoht` | Üldisem jäätmekäitluskoha tüüp |
| `Jäätmepõletustehas` | Jäätmepõletusega seotud koht |
| `Koospõletustehas` | Koospõletusega seotud objekt |
| `Autolammutuskoda` | Autolammutuse |
| `NULL` | Liigisõna ei määratud. |

#### `jkk_olukord` välja väärtusvaru

| Väärtus | Tähendus production loogikas |
|---|---|
| `Töötav` | Objekt on registri järgi töötav. |
| `Arhiveeritud` | Objekt on registri järgi arhiveeritud. |


#### `jaatmete_kaitlemine` välja väärtusvaru

| Väärtus | Tähendus |
|---|---|
| `oma` | Käideldakse oma jäätmeid. |
| `teiste` | Käideldakse teiste jäätmeid. |
| `NULL` | Info puudub või ei ole registris täidetud. |

### Saamine intermediate kihist

`jkk_full` moodustatakse `intermediate.jkk_curr_clean` põhjal.

Registri alginfo transformatsioonid on rakendatud esimesel etapil ja jkk_full tabeli moodustamisel uusi teisendusi ei tehta. Siin lisanduvad jkk_full tabelisse veerud, mida on vaja sihtbaasiga sidumiseks ja järje pidamiseks. Lisaveerge tuleb tabeli uuendamise käigus vastavalt seosele jkk_kood_ext veerule alati säilitada. Tabeli uuendamisel kopeeritakse kõik objektid jkk_curr_clean tabelist ja lisatakse neile eelmisest jkk_full tabelist vastavalt jkk_kood_ext seosele väärtused veergudesse:
* `poi_id` (null)
* `staatus` (1)
* `kommentaar` (null)
* `added_date` (current_date)
* `resolved_date` (null)
* `geom_mod` (geom)

Juhul kui eelmises jkk_full tabeli seisus objekti ei olnud, siis täidetakse veerud vaikeväärtustega (vaikeväärtused loetelus sulgudes).

Eraldi tähelepanu vajab `geom_mod` veerg. Kui eelmise jkk_full tabeli geom veeru väärtus ja uue jkk_curr_clean tabeli sama objekti geom asukohtade vahe on suurem, kui 30m tuleb ka geom_mod veerg uuesti geom väärtusega üle kirjutada.

## Tabel: `production.jkk_removed`

### Otstarve

`production.jkk_removed` on kumulatiivne kontrolltabel objektide jaoks, mis on registri järgi arhiveeritud või registri objektide hulgast eemaldatud. Tabeli abil eemaldatakse sihtbaasist vastavad objektid, kuid lõplik otsus vastavate POI kustutamiste osas jääb spetsialistile, kes peab muutuse sisuliselt üle vaatama ja kinnitama. Tabelis hoitakse lisaks jkk_full tabelis leidunud atribuutidele ka infot muutuse staatuse osas.

### Tabeli sisu

`jkk_removed` sisaldab kõiki samu veerge, nagu `jkk_full`, kuid sellele lisanduvad eemaldamise käsitlemise väljad:

| Väli | Kirjeldus |
|---|---|
| `removed_date` | Kuupäev, millal objekt tuvastati eemaldamist või arhiveerimist vajavana. |
| `remove_resolved_date` | Kuupäev, millal eemaldamise või arhiveerimise töö loeti lahendatuks. Sisuliselt on saab selle veeru järgi ka järge pidada, kas objekt on juba üle kontrollitud sihtsüsteemi/spetialisti poolt. |


### Tabeli uuendamine

`jkk_removed` tekib kahe tabeli võrdluses:

| Võrdluspool | Roll |
|---|---|
| `production.jkk_full` | Eelmise jooksu registri seis koos lisaveergudega. |
| `intermediate.jkk_curr_clean` | Viimase jooksu registriseis. |

Eemaldamise protseduur otsib objekte, mis olid `jkk_full` tabelis olemas, kuid mis on registris arhiveeritud või mille tunnust viimases intermediate tabelis enam ei leidu.
Igal jooksul lisatakse jkk_removed tabelisse uued kirjed koos kõikide atribuutidega jkk_full tabelist, mis päringule vastavad ja täidetakse veerud, mida jkk_full tabelis ei olnud vaikeväärtustega vastavalt:

| Väli | Vaikeväärtused uue objekti lsiamisel |
|---|---|
|`removed_date` | `current_date`|
|`remove_resolved_date` | kui jkk_full objektil oli `staatus in (1,2)` >> `null`, kui `staatus=-1` >> `current_date`*|

\* objektid, millel `staatus=-1` ei ole sihtsüsteemi vaates jälgitavad ja nende objektide eemaldamist ei ole vaja spetisalistil üle vaadata ning selle tõttu märgitakse need automaatselt kui lahendatud objektideks. Samas arhiveerimise või registrist kadumise fakt siiski registreeritakse, et vajadusel saaks spetsialist olukorda paremini hinnata.


Kui sama `jkk_kood` on registris jätkuvalt olemas, kuid varasem `jkk_kood_ext` väärtus enam viimases intermediate seisus ei teki, käsitletakse seda samuti objekti kadumisena. Sellisel juhul lisatakse kadunud kategooriapõhine rida `jkk_removed` tabelisse, kuid tegemist ei pruugi olla registri objekti täieliku kadumisega.

## Tabel: `production.jkk_changes`

`production.jkk_changes` on kumulatiivne kontrolltabel objektide jaoks, mis on jätkuvalt registris olemas, kuid mille mõni sihtbaasi seisukohalt oluline tunnus on muutunud. Tabelisse ei lisata uusi objekte ega registrist kadunud objekte. Uued objektid jõuavad `jkk_full` tabelisse ja eemaldatud või arhiveeritud objektid `jkk_removed` tabelisse.

Muutuseid kontrollitakse eelmise `production.jkk_full` seisu ja viimase `intermediate.jkk_curr_clean` seisu võrdluses. Võrdluse aluseks on `jkk_kood_ext`, sest üks JKK registri objekt võib anda mitu production rida juhul, kui objekt seostub mitme sihtkategooriaga.

Kuna `kat_id` on osa `jkk_kood_ext` väärtusest, ei käsitleta kategooria muutust selles tabelis tavalise atribuudi muutusena. Kui sama JKK objekt saab uue kategooria, tekib sellest uus `jkk_kood_ext` väärtus. Sellisel juhul käsitletakse olukorda ühe kategooriapõhise rea kadumise ja teise lisandumisena, mitte sama rea `kat_id` muutusena.

### Tabeli veergude kirjeldus

| Väli | Tüüp | Päritolu | Kirjeldus |
|---|---|---|---|
| `oid` | `bigint` | Andmebaas | Tabeli tehniline primaarvõti. Automaatselt genereeritav väärtus. |
| `objekti_nimetus` | `text` | `intermediate.jkk_curr_clean` | Objekti nimetus registri viimases seisus. Abistav väli spetsialistile muutuse kontrollimisel. |
| `jkk_kood_ext` | `text` | Transformatsioon | Production rea ühendidentifikaator. Võrdluse põhiväli `jkk_full` ja `jkk_curr_clean` vahel. |
| `nimi_change_status` | `integer` | Sihtsüsteemi / spetsialisti hallatav | Näitab, kas objekti puhastatud nimi muutus ja kas muutus on üle kontrollitud. |
| `nimi_old` | `text` | `production.jkk_full` | Objekti nimi eelmises seisus. |
| `nimi_new` | `text` | `intermediate.jkk_curr_clean` | Objekti nimi viimases registriseisus. |
| `brand_change_status` | `integer` | Sihtsüsteemi / spetsialisti hallatav | Näitab, kas objekti haldaja nimi muutus ja kas muutus on üle kontrollitud. |
| `brand_old` | `text` | `production.jkk_full` | Objekti haldaja väärtus eelmises seisus. |
| `brand_new` | `text` | `intermediate.jkk_curr_clean` | Objekti haldaja väärtus viimases registriseisus. |
| `liigisona_change_status` | `integer` | Sihtsüsteemi / spetsialisti hallatav | Näitab, kas objekti liigisõna muutus ja kas muutus on üle kontrollitud. |
| `liigisona_old` | `text` | `production.jkk_full` | Objekti liigisõna eelmises seisus. |
| `liigisona_new` | `text` | `intermediate.jkk_curr_clean` | Objekti liigisõna viimases registriseisus. |
| `lipikud_change_status` | `integer` | Sihtsüsteemi / spetsialisti hallatav | Näitab, kas objekti lipikute väärtus muutus ja kas muutus on üle kontrollitud. |
| `lipikud_old` | `text` | `production.jkk_full` | Objekti lipikud eelmises seisus. |
| `lipikud_new` | `text` | `intermediate.jkk_curr_clean` | Objekti lipikud viimases registriseisus. |
| `geom_change_status` | `integer` | Sihtsüsteemi / spetsialisti hallatav | Näitab, kas registri geomeetria muutus ja kas muutus on üle kontrollitud. |
| `geom_change` | `geometry(LineString, 3301)` | Transformatsioon | Joon eelmise ja uue registrigeomeetria vahel. Täidetakse geomeetriamuutuse korral, et spetsialist näeks liikumise suunda ja ulatust. |
| `kommentaar` | `text` | Spetsialisti hallatav | Spetsialisti märkus, otsuse põhjendus või muu muutuse käsitlemise info. |
| `change_date` | `date` | Süsteemi hallatav | Kuupäev, millal muutus tuvastati. Täidetakse uue muutuse lisamisel automaatselt. |
| `resolved_date` | `date` | Spetsialisti hallatav | Kuupäev, millal muutus loeti lahendatuks. Täidetakse siis, kui muutus on sihtsüsteemi vaates üle kontrollitud. |
| `geom` | `geometry(Point, 3301)` | `intermediate.jkk_curr_clean` | Objekti uus registrigeomeetria. Kasutatakse muutuse ruumiliseks kuvamiseks ja kontrollimiseks. |

Muutuse staatuse väljade (`nimi_change_status`, `brand_change_status`, `liigisona_change_status`, `lipikud_change_status`, `geom_change_status`) ühine väärtusvaru:

| Väärtus | Tähendus |
|---:|---|
| `0` | Vastav väärtus ei muutunud. Vaikeväärtus. |
| `1` | Vastav väärtus muutus ja vajab sihtsüsteemi vaates kontrolli. |
| `2` | Vastav muutus on kontrollitud. |

### Tabeli uuendamine

`jkk_changes` tekib kahe tabeli võrdluses:

| Võrdluspool | Roll |
|---|---|
| `production.jkk_full` | Eelmise jooksu seis koos spetsialisti hallatavate väärtustega. |
| `intermediate.jkk_curr_clean` | Viimase jooksu registriseis. |

Tabelisse lisatakse kirjed ainult nende objektide kohta, mis on mõlemas tabelis olemas, kuid millel on muutunud vähemalt üks jälgitav tunnus:

| Võrdlus | Tulemus |
|---|---|
| `jkk_full.nimi` erineb `jkk_curr_clean.nimi` väärtusest | Täidetakse `nimi_old`, `nimi_new` ja `nimi_change_status = 1`. |
| `jkk_full.brand` erineb `jkk_curr_clean.brand` väärtusest | Täidetakse `brand_old`, `brand_new` ja `brand_change_status = 1`. |
| `jkk_full.liigisona` erineb `jkk_curr_clean.liigisona` väärtusest | Täidetakse `liigisona_old`, `liigisona_new` ja `liigisona_change_status = 1`. |
| `jkk_full.lipikud` erineb `jkk_curr_clean.lipikud` väärtusest | Täidetakse `lipikud_old`, `lipikud_new` ja `lipikud_change_status = 1`. |
| `jkk_full.geom` ja `jkk_curr_clean.geom` asukohtade vahe on > 30m | Täidetakse `geom`, `geom_change` ja `geom_change_status = 1`. |

Kui mõni kontrollitav tunnus ei muutunud, saab vastav muutuse staatuse väli väärtuseks `0`. Kui muutus on üle kontrollitud, muudab spetsialist vastava staatuse väärtuseks `2`. 

Väli `resolved_date` täidetakse siis, kui real ei ole enam ühtegi kontrollimata muutust ehk ükski `*_change_status` väli ei ole väärtusega `1`.

Geomeetriamuutused registreeritakse ainult üle 30m nihke korral. Muutuse korral salvestatakse `geom` väljale uus registri asukoht ning `geom_change` väljale joon vanast asukohast uude asukohta. 

Uusi objekte sellesse tabelisse ei lisata. Kui objekt on uues intermediate seisus olemas, kuid puudus eelmises `jkk_full` tabelis, lisatakse see `jkk_full` tabelisse vaikeväärtustega. Kui objekt oli eelmises `jkk_full` tabelis olemas, kuid puudub uuest intermediate seisust või on registris arhiveeritud, lisatakse see `jkk_removed` tabelisse.

## Production kihi laadimise üldjärjekord

Production kihi laadimine peab toimuma pärast seda, kui `intermediate.jkk_curr_clean` on viimase API tõmmise põhjal uuendatud.

| Samm | Kirjeldus |
|---:|---|
| 1 | Uuendatakse `intermediate.jkk_curr_clean`. |
| 2 | Võrreldakse senist `production.jkk_full` seisu uue intermediate seisuga. |
| 3 | Lisatakse eemaldamist vajavad objektid `production.jkk_removed` tabelisse. |
| 4 | Lisatakse kontrolli vajavad muutused `production.jkk_changes` tabelisse. |
| 5 | Uuendatakse `production.jkk_full`, säilitades käsitsi hallatavad väljad. |

Järjekord on oluline, sest eemaldamised ja muutused tuleb tuvastada enne seda, kui `jkk_full` tabel uue registriseisu põhjal üle kirjutatakse.

Production kihi kolme tabelit tuleb käsitleda ühe tervikuna. Uut seisu ei tohiks salvestada osaliselt. Kui `jkk_full`, `jkk_removed` või `jkk_changes` uuendamine ebaõnnestub, ei tohi ükski neist tabelitest jääda pooleldi uuendatud seisu. Selleks tuleb production kihi uuendamine teha ühe andmebaasitransaktsioonina.

Kui mõni samm ebaõnnestub, peab alles jääma eelmine terviklik production seis. Sellisel juhul saab vea parandada ja töövoo uuesti käivitada ilma, et tabelitesse jääks vastuoluline vahepealne seis.

## Tabelitevaheline loogika

| Juhtum | Sihttabel | Selgitus |
|---|---|---|
| Objekt on uues intermediate seisus olemas aga production kihis puudus | `jkk_full` | Uus objekt lisatakse käsitlemiseks. |
| Objekt on uues intermediate seisus olemas ja oli production kihis samuti olemas | `jkk_full` | Uuendatakse registrist sõltuvad väljad, käsitsi hallatavad väljad säilitatakse. |
| Objekt oli production kihis olemas aga puudub uuest intermediate seisust | `jkk_removed` | Objekt vajab eemaldamise või arhiveerimise kontrolli. |
| Objekt oli production kihis olemas ja registris on nüüd arhiveeritud | `jkk_removed` | Objekt vajab eemaldamise või arhiveerimise kontrolli. |
| Olemasoleval objektil muutus nimi, liigisõna, lipikud, haldaja või geomeetria | `jkk_changes` | Muutus vajab kontrollimist. |
| Objektile ei leitud kategooriat | `jkk_full` | Objekt jääb nähtavaks, kuid saab staatuseks `-1`. |

## TODO

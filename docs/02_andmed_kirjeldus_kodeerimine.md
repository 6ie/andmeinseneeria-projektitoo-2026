# Algandmete kirjeldus

## Eesmärk

See dokument kirjeldab projekti algandmeid, nende päritolu, struktuuri ja kasutust andmetöötluse töövoos.

Algandmete kirjeldus on vajalik selleks, et oleks arusaadav:

* milliseid andmeid töövoog kasutab;
* kust andmed pärinevad;
* millised väljad on olulised;
* kuidas andmed seotakse olemasolevate POI objektidega;
* millised on teadaolevad probleemid või piirangud.

## Algandmete ülevaade

| Andmestik | Allikas | Vorming | Kasutus |
|---|---|---|---|
| JKK register | API | JSON | Peamine lähteandmestik |
| Esialgsed POI seosed | CSV fail | CSV | Olemasolevate POI objektide sidumine JKK objektidega |

## JKK registri andmed

### Allikas

JKK registri andmed päritakse API kaudu.

Andmed sisaldavad jäätmekäitluskohtade objekte koos registri tunnuste, asukohaandmete ja tegevuste kirjeldustega.

### Kasutus töövoos

JKK register on projekti põhiallikas. Iga töövoo käivitamisel laaditakse registrist hetkeandmed staging kihti.

Neid andmeid kasutatakse:

* kehtiva objektide seisu moodustamiseks;
* uute objektide tuvastamiseks;
* eemaldatud objektide tuvastamiseks;
* atribuudimuutuste jälgimiseks;
* asukohamuutuste jälgimiseks.

### JKK sisendi veerud

| Veeru nimi | Näide | Selgitus | Kaasame? | Kommentaar |
|---|---|---|---|---|
| `kaitise_kood` | `null` | andmetes tühi | ei |  |
| `objekti_nimetus` | `Paikuse katlamaja` | JKK objekti nimetus registris. | jah | >> full tabel nimi, lyhinimi |
| `jkk_kood` | `JKK6700287` | JKK registri objekti unikaalne kood. | jah | >> full tabel valine_kood. Peamine väline identifikaator. Kasutatakse objektide võrdlemisel ja POI seose loomisel.  |
| `aadress` | `Pärnu maakond, Pärnu linn, Paikuse alev, Tehnika tn 1` | Objekti aadress registris. | jah | lisainfoks spetsialistile |
| `ehak_kood` | `5864` | Asustus- või haldusüksuse EHAK kood. | ei |  |
| `emtak_kood` | `0146` | Objekti tegevusala EMTAK kood. | ei |  |
| `emtak_nimetus` | `Seakasvatus - EMTAK 2008` | EMTAK koodi tekstiline nimetus. | jah | lisainfoks spetsialistile |
| `x_koordinaat` | `6470358` | Laius, epsg 3301 | jah | >> full tabel geomeetria alus |
| `y_koordinaat` | `535962` | Pikkus, epsg 3301  | jah | >> full tabel geomeetria alus |
| `longitude` | `24.6145882299699` | Pikkuskraad WGS84  | ei | *|
| `latitude` | `58.3722328208281` | Laiuskraad WGS84  | ei | *|
| `kataster` | `56801:001:0755` | Katastri number | ei | * |
| `eprtr_pohitegevus` | `null` | andmetes tühi | ei | |
| `eprtr_lisategevused` | `null` | andmetes tühi | ei |  |
| `keskkonnalubade_ numbrid_str` | `RE.JÄ/523290` | Keskkonnalubade numbrid tekstina. | ei |  |
| `keskkonnalubade_ numbrid_arr` | `["RE.JÄ/523290"]` | Keskkonnalubade numbrid massiivina. | ei | |
| `kaitaja_nimi` | `SW ENERGIA OÜ` | Käitaja nimi (sh fie puhul inimese nimi). | jah | >> full tabel brand (ettevõtte nimi) |
| `kaitaja_kood` | `11963782` | Käitaja registrikood (sh fie puhul isikukood). | jah | lisainfoks spetsialistile |
| `komplekstegevus` | `K1` | Väärtusvaru: `K1`,`K2`,`K3` Sisaldab ka `null` väärtuseid| jah | >> full tabel kat_id kodeerimine|
| `komplekstegevus_selg` | `Jäätmejaam` | Väärtusvaru: `Jäätmekäitluskeskus`,`Jäätmejaam`,`Lisa nimistus puuduv komplekstegevus` | jah | >> full tabel liigisõna kodeerimine |
| `komplekst_nimi_et` | `null` | andmetes tühi | ei |  |
| `komplekst_nimi_en` | `null` | andmetes tühi | ei |  |
| `tegevus` | `U1,U10` | Väärtusvaru eraldi tabelina | jah | >> full tabel kat_id kodeerimine |
| `tegevus_selg` | `Koospõletustehas` | JKK tegevuse tekstiline selgitus. | jah | >> full tabel liigisõna kodeerimine  |
| `tyybile_vastav _nimi_ee` | `null` |  | ei | |
| `tyybile_vastav _nimi_en` | `null` |  | ei | |
| `tegevuse_tapsustus` | `Vanarehvide kasutamine silohoidlate katmisel (R3m)` | Tegevuse täpsustus. | jah | lisainfoks spetsialistile |
| `jaatmete_kaitlemine` | `Teiste` | Väärtusvaru: `oma`,`teiste` Sisaldab ka `null` väärtuseid | jah | lisainfoks spetsialistile |
| `tegevuse_algus` | `2024-12-17` | Tegevuse alguskuupäev. | jah | lisainfoks spetsialistile |
| `tegevuse_lopp` | `2064-06-30` | Tegevuse lõppkuupäev. | jah | lisainfoks spetsialistile |
| `jkk_olukord` | `Töötav` | Väärtusvaru: `töötav`,`arhiveerutud` Täidetud 100% | jah | >> määrab objekti kaasamise  |
| `kehtivus_staatus` | `Kehtiv` | Väärtusvaru: `kehtiv`,`kehtetu` Täidetud 100% Sisult sama info, mis jkk_olukord | ei |  |
| `muudetud` | `2026-03-03T20:47:28.305786 +02:00` | Registrikirje muutmise aeg. | jah | lisainfoks spetsialistile |
| `eprtr_kood` | `null` | andmetes tühi | ei |  |
| `teised_aadressid` | `null` | Objektiga seotud muud aadressid. | jah | lisainfoks spetsialistile |
| `teised_katastrid` | `null` | Objektiga seotud muud katastriüksused. | ei |  |
| `z_inspire_id` | `JKK6700287` | sisult sama, mis jkk_kood | ei |  |
| `ov_kood` | `0624` | Omavalitsuse kood. | ei |  |
| `ov_nimi` | `Pärnu linn` | Omavalitsuse nimi. | ei |  |
| `mk_kood` | `0068` | Maakonna kood. | ei | |
| `mk_nimi` | `Pärnu maakond` | Maakonna nimi. | ei |  |

# Tegevuste kodeerimine kategooriateks

Tegevused ja komplekstegevused kodeeritakse ümber kategooriateks, nende järgi täidetakse liigisonad ja lipikud.

Sihtsüsteemi kategooriad, mida registri andmed puudutavad:  
2207 - Prügila  
2208 - Jäätmejaam  
2606 - Jõujaam  
3120 - Autolammutus  
2607 - Tööstushoone/Tootmishoone  

| komplekstegevus | selgitus | `kat_id` | `liigisona` | `lipikud` | kommentaar
|---|---|---|---|---|---|
|K1|Jäätmekäitluskeskus|2208 |`Jäätmekäitluskeskus`|-|-|
|K2|Jäätmekäitluskeskus|2208 |`Jäätmejaam`|-|-|
|K3|Lisa nimistus puuduv komplekstegevus|2208 |`Jäätmekäitluskoht`|-|-|


| tegevus | selgitus | `kat_id` | `liigisona` | `lipikud` | kommentaar
|---|---|---|---|---|---|
| U1 | Tavajäätmeprügila | 2207 | `Prügila`,`Suletud prügila`| Tavajäätmeprügila | jkk_olukord='Töötav' > `Prügila`, jkk_olukord='Arhiveeritud' > `Suletud prügila` |
| U2 | Ohtlike jäätmete prügila | 2207 |  `Prügila`,`Suletud prügila` | Ohtlike jäätmete prügila |jkk_olukord='Töötav' > `Prügila`, jkk_olukord='Arhiveeritud' > `Suletud prügila` |  
| U3 | Püsijäätmeprügila | 2207 | `Prügila`,`Suletud prügila`| Püsijäätmeprügila | jkk_olukord='Töötav' > `Prügila`, jkk_olukord='Arhiveeritud' > `Suletud prügila` |
| U4 | Kaevandamisjäätmete hoidla | - | - | - | ei kaasa |
| U5 | Sortimisliin, -tehas | 2208 | Jäätmekäitluskoht | Sortimisliin, -tehas |
| U6 | Ümberlaadimisjaam, vaheladu | 2208 | Jäätmekäitluskoht | Ümberlaadimisjaam, vaheladu |
| U7 | Jäätmepõletustehas | 2606 | Jäätmepõletustehas | - |
| U8 | Koospõletustehas | 2606 | Koospõletustehas | - |
| U9 | Bioloogiline töötlus | - | - | - | ei kaasa
| U10 | Ohtlike jäätmete käitluskoht | 2208 | Jäätmekäitluskoht | Ohtlike jäätmete käitluskoht |  |
| U11 | Metallijäätmete käitluskoht | 2208 | Jäätmekäitluskoht | Metallijäätmete käitluskoht |  |
| U12 | Elektroonikaromude käitluskoht | 2208 | Jäätmekäitluskoht | Elektroonikaromude käitluskoht |  |
| U13 | Autolammutuskoda | 3120 | Autolammutuskoda | - |  |
| U14 | Vanarehvide käitluskoht | - | - | - | ei kaasa (tihti silo-hoidlad) |
| U15 | Mobiilne käitluskoht | - | - | - | ei kaasa (pole kindlat asukohta) |
| U16 | Tavajäätmete käitluskoht | 2208 | Jäätmekäitluskoht | Tavajäätmete käitluskoht |  |
| U17 | Lisa nimistus puuduv tegevus | 2208 | Jäätmekäitluskoht |  |  |

## Esialgne POI seoste CSV

### Fail

`data/init_jkk_poi_seos.csv`

### Veerud

| veerg | selgitus |
|---|---|
| poi_id | poi id sihtsüsteemis | 
| kat_id | kategooria id sihtsüsteemis | 
| x | x koordinaat meetritres - epsg 3301 | 
| y | y koordinaat meetritres - epsg 3301 | 


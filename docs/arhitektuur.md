# Arhitektuur

## Äriküsimus

Ärivajadus on hoida jäätmekäitlusregistri põhised huvipunktide andmed ettevõtte POI andmebaasis maksimaalselt ajakohasena võimalikult vähese käsitööga. Lahendus peab lisaks sisestusvalmis muudatuste ette valmistamisele andma ülevaate nende käsitlemise seisust, et spetsialist saaks hinnata töömahtu, andmete ajakohasust ja andmehoolduse prioriteete.

## Mõõdikud

1. **Lahendamata muudatuste arv ja osakaal**  
Näitab, mitu jäätmekäitlusregistri objekti on tuvastatud POI andmebaasi jaoks uue, muutunud või eemaldatud objektina, kuid ei ole veel sihtandmebaasis käsitletud.

2. **Lahendamata muudatuste jaotus tüübi järgi**  
Näitab, kas lahendamata muudatused on seotud lisandunud objektide, eemaldatud objektide, atribuudimuutuste või asukohamuutustega.

3. **Lahendamata muudatuste ruumiline paiknemine**  
Näitab kaardil, kus lahendamata muudatused paiknevad, et spetsialist saaks hinnata töö piirkondlikku jaotust ja prioriteetsust. Kui jõuame selleni.

## Andmeallikad

Keskkonnaregisteri jäämetkäitluskohtade register avaandmed:
https://keskkonnaandmed.envir.ee/f_jkkregister_curr


| Allikas | Tüüp | Ajas muutuv? | Roll |
|---------|------|--------------|------|
| Jäätmekäitluskohtade register | Avalik PostgREST/JSON API | Jah, registriandmed uuenevad jooksvalt | Peamine andmeallikas, kust võetakse jäätmekäitlusega seotud objektide hetkeseis |
| Algne POI seoste tabel | Ühekordne algseadistuse tabel CSV formaadis | Ei, staatiline | Aitab esmakordsel andmevoo loomisel siduda olemasolevad registriobjektid ettevõtte POI andmebaasi objektidega |


## Andmevoog

![Arhitektuuriskeem](arhitektuuriskeem.drawio.svg)


## Andmebaasi kihid

| Kiht | Roll | Näidistabelid |
|------|------|---------------|
| `staging` | Hoiab API-st saadud toorandmeid koos jooksu identifikaatori ja laadimise ajaga. Seda kihti kasutatakse auditeerimiseks, vigade otsimiseks ja vajadusel sama jooksu uuesti töötlemiseks. | `staging.raw_snapshot` |
| `intermediate` | Hoiab viimase jooksu töödeldud (tabeli kujule viidud, puhastatud, ümber kodeeritud)registriseisu. Selles kihis on andmed valmis võrdluseks eelmise seisuga. | `intermediate.clean_current_run` |
| `production` | Hoiab spetsialisti tööks vajalikke püsivaid tabeleid. Siia jõuavad registriobjektide koondseis ja sisestusvalmis muudatuste tööjärg. Siin hallatakse ka muutuste sisestamise staatuseid ja seoseid sihtandmebaasi objektidega | `production.jkk_full`, `production.jkk_changes` |

### staging kiht

`staging` kihis salvestatakse jäätmekäitlusregistri API-st saadud toorandmed. Iga automaatne töövoo käivitus saab oma `run_id` väärtuse ja laadimise aja.

Toorandmete säilitamine võimaldab hiljem kontrollida, millise registriseisu põhjal muudatused tuvastati. Praktikumi projektis võib toorandmeid säilitada kogu projekti jooksul. Päris lahenduses võiks säilitamise aega piirata, näiteks hoida alles viimased 30 päeva või viimased N jooksu.

### intermediate kiht

`intermediate` kihis viiakse jooksu andmed kahemõõtmelise tabeli kujul, milles on andmed normaliseeritud ja võrdluseks sobivale kujule viidud. See kiht ei ole mõeldud kasutaja käsitsi tööks, vaid ETL protsessi vahetulemuseks.

Selles kihis hoitakse üldjuhul ainult viimase jooksu puhastatud seisu. Seda võrreldakse `production.jkk_full` tabelis oleva varasema seisuga, et tuvastada uued, eemaldatud ja muutunud objektid.


### production kiht

`production` kihis asuvad tabelid, mida kasutatakse spetsialisti tööks ja dashboardi koostamiseks. 

Põhitabelid on:
- `jkk_full` Kõigi kunagi nähtud huvipakkuvate registriobjektide koondtabel. 
- `jkk_changes` Sisestusvalmis muudatuste tööjärg, kuhu lisatakse uued, eemaldatud ja muutunud objektid.

Mõlemas tabelis on koos automaatselt ETL poolt hallatavad veerud ja spetsialisti hallatavad täpsustavad ja sihtbaasiga siduvad veergud.

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

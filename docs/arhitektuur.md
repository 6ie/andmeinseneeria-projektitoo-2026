# Arhitektuur

## Äriküsimus

Ärivajadus on hoida jäätmekäitlusregistri põhised huvipunktide andmed ettevõtte POI andmebaasis maksimaalselt ajakohasena võimalikult vähese käsitööga. Lahendus peab lisaks sisestusvalmis muudatuste ette valmistamisele andma ülevaate nende käsitlemise seisust, et spetsialist saaks hinnata töömahtu, andmete ajakohasust ja andmehoolduse prioriteete.

## Mõõdikud

1. **Lahendamata muudatuste arv ja osakaal**  
Näitab, mitu jäätmekäitlusregistri objekti on tuvastatud POI andmebaasi jaoks uue, muutunud või eemaldatud objektina, kuid ei ole veel sihtandmebaasis käsitletud.

2. **Lahendamata muudatuste jaotus tüübi järgi**  
Näitab, kas lahendamata muudatused on seotud lisandunud objektide, eemaldatud objektide, atribuudimuutuste või asukohamuutustega.

3. **Lahendamata muudatuste ruumiline paiknemine**  
Näitab kaardil, kus lahendamata muudatused paiknevad, et spetsialist saaks hinnata töö piirkondlikku jaotust ja prioriteetsust. Mõõdik lisatakse juhul, kui projekti ajakava seda võimaldab.

## Andmeallikad


| Allikas | Tüüp | Ajas muutuv? | Roll |
|---------|------|--------------|------|
| Jäätmekäitluskohtade register* | Avalik PostgREST/JSON API | Jah, registriandmed uuenevad jooksvalt** | Peamine andmeallikas, kust võetakse jäätmekäitlusega seotud objektide hetkeseis |
| Algne POI ja JKKR seoste tabel | Ühekordne algseadistuse tabel CSV formaadis | Ei, staatiline*** | Aitab esmakordsel andmevoo loomisel siduda olemasolevad registriobjektid ettevõtte POI andmebaasi objektidega |

\* Keskkonnaportaali jäämetkäitluskohtade registri avaandmed:
https://keskkonnaandmed.envir.ee/f_jkkregister_curr  
** andmete sissevõtu testid: 17-05-2026 2953 kirjet, 20-05-2026 2956 kirjet.  
*** äripoole andmete kaitsmiseks projektitöö skoobis kasutame staatilist, vähendatud andmestikku, mis on piisav võrdlusbaasi loomiseks.

## Andmevoog

![Arhitektuuriskeem](arhitektuuriskeem.drawio.svg)


## Andmebaasi kihid

| Kiht | Roll | Näidistabelid |
|------|------|---------------|
| `staging` | Hoiab API-st saadud toorandmeid koos jooksu identifikaatori ja laadimise ajaga. Seda kihti kasutatakse auditeerimiseks, vigade otsimiseks ja vajadusel sama jooksu uuesti töötlemiseks. | `staging.raw_snapshot` |
| `intermediate` | Hoiab viimase jooksu töödeldud (tabeli kujule viidud, puhastatud, ümber kodeeritud) registriseisu. Selles kihis on andmed valmis võrdluseks eelmise seisuga. | `intermediate.clean_current_run` |
| `production` | Hoiab spetsialisti tööks vajalikke püsivaid tabeleid. Siia jõuavad registriobjektide viimane seis ja sisestusvalmis muudatuste tööjärg. Siin hallatakse ka muutuste sisestamise staatuseid ja seoseid sihtandmebaasi objektidega | `production.jkk_full`, `production.jkk_removed`, `production.jkk_changes` |

### staging kiht

`staging` kihis salvestatakse jäätmekäitlusregistri API-st saadud toorandmed. Iga automaatne töövoo käivitus saab oma `run_id` väärtuse ja laadimise aja.

Toorandmete säilitamine võimaldab hiljem kontrollida, millise registriseisu põhjal muudatused tuvastati. Praktikumi projektis võib toorandmeid säilitada kogu projekti jooksul. Päris lahenduses võiks säilitamise aega piirata, näiteks hoida alles viimased 30 päeva või viimased N jooksu.

### intermediate kiht

`intermediate` kihis viiakse jooksu andmed kahemõõtmelise tabeli kujul, milles on andmed normaliseeritud ja võrdluseks sobivale kujule viidud. See kiht ei ole mõeldud kasutaja käsitsi tööks, vaid ETL protsessi vahetulemuseks.

Enne kihi ülekirjutamiset uue jooksu andmetega, peavad läbima andmete terviklikkuse ja asukohatäpsuse testid:
- Värskei API vastus peab sisaldama vähemalt 90% objekte võrreldes eelmise korra andmetega
- Värskeimas API vastuses ei tohi olla rohkem kui 25% objektidest puuduva geomeetiaga või asuda väljaspool Eestit

Selles kihis hoitakse üldjuhul ainult viimase jooksu puhastatud seisu. Seda võrreldakse `production.jkk_full` tabelis oleva varasema seisuga, et tuvastada uued, eemaldatud ja muutunud objektid.

### production kiht

`production` kihis asuvad tabelid, mida kasutatakse spetsialisti tööks ja dashboardi koostamiseks. 

Põhitabelid on:
- `jkk_full` Registriobjektide viimane kehtiv seis. Siin hoitakse ainult hetkel registris olemasolevaid objekte. 
- `jkk_removed` Kumulatiivne tabel registrist eemaldatud objektide kohta. Objekt lisatakse siia siis, kui seda uues registriseisus enam ei leita.
- `jkk_changes` Tööjärg objektidele, millel on tuvastatud sihtbaasi jaoks oluline atribuudimuutus või asukohamuutus. Uusi ja eemaldatud objekte siia ei kanta.

Nendes tabelites on koos automaatselt ETL poolt hallatavad veerud ja spetsialisti hallatavad täpsustavad ja sihtbaasiga siduvad veerud.

Algne jäätmekäitluskohtade registri ja sihtbaasi POI objektide seoste CSV laetakse algseadistuse käigus production kihti abistava seoste tabelina. Seda ei käsitleta jooksvalt uueneva allikana, vaid stardiseisuna, mille põhjal saab olemasolevad registriobjektid siduda ettevõtte POI andmebaasi objektidega.

Kui kogu andmetoru töö läbib vigadeta, siis viimase asjana kirjutatakse `jkk_full` kiht üle värskeima registri seisuga.
Production kihi kontrollid enne  `jkk_full` kihi ülekirjutamist:
- jkk_kood_ext ei tohi olla NULL või tühi
- jkk_kood_ext peab olema unikaalne
- staatus veeru lubatud väärtused on -1, 1, 2
- kui staatus IN (-1,2), siis resolved_date peab olema täidetud
- kehtival objektil (staatus != -1) peab olema geomeetria

## Tööjaotus

| Nimi | Roll |
|------|------|
| Õie | Andmeallika omanik (sissevõtu loogika), orkestreerimine, andmekvaliteedi testid |
| Püü | Transformatsioonide omanik (puhastamine, muutuste tuvastamine), andmekvaliteedi testid |
| Lea | Näidikulaua omanik  ja administratiivtöö |

## Riskid

| Risk | Mõju | Maandus |
|------|------|---------|
| API vastus on tühi json | Andmeid ei ole | Väljastatakse hoiatus ja peatatakse töövoog |
| API vastus on osaline | Võib tekkida eksitav tulemus, et tuleks suur osa andmetest sihtbaasis kustutada | Kirjete arvu loogikakontroll (kontroll peaks toimima ka mitme järjestikuse osalise vastuse puhul), päise, veerunimede, 'not null' kontroll |
| Töövoog ei jookse edukalt lõpuni | Võrdlusbaas (full baas) täidetakse osaliselt ning edasised võrdlused on ekslikud | Uuendused tehakse alles pärast kontrollide läbimist; vea korral säilitatakse eelmine korrektne seis |

## Privaatsus ja turve

Projektis ei töödelda tundlikke ega eriliigilisi isikuandmeid. Äriandmete kaitse on tagatud ühekordse ja piiratud mahuga andmeväljavõtte kasutamisega, mis ei võimalda juurdepääsu tootmiskeskkonna täielikule andmestikule. Kõik rakenduse toimimiseks vajalikud konfidentsiaalsed ligipääsuandmed — sealhulgas andmebaasi paroolid ja muud süsteemisaladused — hoitakse lokaalselt .env failis.

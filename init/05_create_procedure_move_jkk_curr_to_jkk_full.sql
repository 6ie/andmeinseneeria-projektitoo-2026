CREATE OR REPLACE PROCEDURE production.move_jkk_curr_to_jkk_full()
LANGUAGE plpgsql
AS $$
BEGIN

    -- TEMP tabel uute andmetega, mis on kodeeritud vastavalt jkk_full kihi nõuetele
    CREATE TEMP TABLE tmp_new_jkk_full ON COMMIT DROP AS
    SELECT
        -- Otse API-st pärinevad väljad
        curr.objekti_nimetus,
        curr.jkk_kood,
        curr.jkk_olukord,
        curr.kaitaja_nimi,
        curr.kaitaja_kood,
        curr.aadress,
        curr.teised_aadressid,
        curr.x_koordinaat,
        curr.y_koordinaat,
        curr.tegevus,
        curr.tegevus_selg,
        curr.tegevuse_tapsustus,
        curr.tegevuse_algus,
        curr.tegevuse_lopp,
        curr.muudetud,
        curr.komplekstegevus,
        curr.komplekstegevus_selg,
        curr.jaatmete_kaitlemine,

        -- Järeltöödeldud väljad
        curr.jkk_kood_ext,
        curr.nimi,
        CASE 
            WHEN char_length(curr.nimi) > 40 THEN NULL 
            ELSE curr.lyhinimi 
        END AS lyhinimi,
        curr.brand,
        curr.kat_id,
        curr.liigisona,
        curr.lipikud,

        --sihtsüsteemi/spetsialistide poolt hallatavad väljad
        --Säilitab algse kihi väljad, kui need on olemas,
        --või määrab vaikimisi väärtused
        CASE
            WHEN prev.poi_id IS NOT NULL AND prev.poi_id != -1 THEN prev.poi_id
            WHEN curr.kat_id IS NULL THEN -1
            ELSE NULL
        END AS poi_id,

        CASE
            WHEN curr.kat_id IS NULL THEN -1
            WHEN curr.jkk_olukord = 'Arhiveeritud' THEN -1
            WHEN prev.poi_id IS NOT NULL AND prev.poi_id != -1 THEN 2
            ELSE 1
        END AS staatus,

        prev.kommentaar AS kommentaar,

        COALESCE(prev.added_date, CURRENT_DATE) AS added_date,

        CASE
            WHEN curr.kat_id IS NULL THEN CURRENT_DATE
            WHEN curr.jkk_olukord = 'Arhiveeritud' THEN CURRENT_DATE
            ELSE NULL
        END AS resolved_date,

        -- registri geomeetria
        curr.geom AS geom,

        -- Kui eelmise jkk_full tabeli geom veeru väärtus 
        -- ja uue jkk_curr_clean tabeli sama objekti geom asukohtade vahe on suurem, 
        --kui 30m tuleb ka geom_mod veerg uuesti geom väärtusega üle kirjutada.
        COALESCE(
            CASE
                WHEN prev.oid IS NULL THEN curr.geom
                WHEN prev.geom IS NOT NULL AND curr.geom IS NOT NULL AND ST_Distance(prev.geom, curr.geom) > 30 THEN curr.geom
                ELSE COALESCE(prev.geom_mod, curr.geom)
            END,
            curr.geom
        ) AS geom_mod

    FROM intermediate.jkk_curr_clean curr
    LEFT JOIN production.jkk_full prev
        ON curr.jkk_kood_ext = prev.jkk_kood_ext;

    -- Kontrollid enne production.jkk_full kihi ülekirjutamist 
    -- 1) jkk_kood_ext ei tohi olla NULL või tühi
    IF (SELECT COUNT(*) FROM tmp_new_jkk_full WHERE jkk_kood_ext IS NULL OR trim(jkk_kood_ext) = '') > 0 THEN
        RAISE EXCEPTION 'ERROR: Uutes andmetes on leitud NULL või tühi jkk_kood_ext';
    END IF;

    -- 2) jkk_kood_ext peab olema unikaalne
    IF (SELECT COUNT(*) FROM (
            SELECT jkk_kood_ext FROM tmp_new_jkk_full GROUP BY jkk_kood_ext HAVING COUNT(*) > 1
        ) t) > 0 THEN
        RAISE EXCEPTION 'ERROR: Uutes andmetes on leitud korduv jkk_kood_ext';
    END IF;

    -- 3) staatus peab olema -1, 1, 2
    IF (SELECT COUNT(*) FROM tmp_new_jkk_full WHERE staatus NOT IN (-1,1,2)) > 0 THEN
        RAISE EXCEPTION 'ERROR: Uutes andmetes on leitud keelatud staatus väärtus';
    END IF;

    -- 4) Kui staatus = -1, siis poi_id peab olema -1
    -- Ei saa rakendada, sest kui POI baasis olemasolev POI muutub arhiveerituks, 
    -- siis tal on korraga nii POI_ID, mis kantakse vanast seisust üle,
    -- kui ka staatus =-1, mis määratakse Arhiveeritud seisundi järgi.
    --IF (SELECT COUNT(*) FROM tmp_new_jkk_full WHERE staatus = -1 AND poi_id IS DISTINCT FROM -1) > 0 THEN
    --    RAISE EXCEPTION 'ERROR: staatus = -1, kuid poi_id != -1';
    --END IF;

    -- 5) Kehtival objektil (staatus not -1) peab olema geomeetria
    IF (SELECT COUNT(*) FROM tmp_new_jkk_full WHERE staatus != -1 AND geom IS NULL) > 0 THEN
        RAISE EXCEPTION 'ERROR: Kehtival objektil (staatus != -1) peab olema geomeetria';
    END IF;

    -- Asenda production.jkk_full uute andmetega
    TRUNCATE TABLE production.jkk_full RESTART IDENTITY;

    INSERT INTO production.jkk_full (
        -- Otse API-st pärinevad väljad
        objekti_nimetus,
        jkk_kood,
        jkk_olukord,
        kaitaja_nimi,
        kaitaja_kood,
        aadress,
        teised_aadressid,
        x_koordinaat,
        y_koordinaat,
        tegevus,
        tegevus_selg,
        tegevuse_tapsustus,
        tegevuse_algus,
        tegevuse_lopp,
        muudetud,
        komplekstegevus,
        komplekstegevus_selg,
        jaatmete_kaitlemine,

        -- Järeltöödeldud väljad
        jkk_kood_ext,
        nimi,
        lyhinimi,
        brand,
        kat_id,
        liigisona,
        lipikud,

        -- sihtsüsteemi/spetsialistide poolt hallatavad väljad
        poi_id,
        staatus,
        kommentaar,
        added_date,
        resolved_date,
        geom,
        geom_mod
    )
    SELECT * FROM tmp_new_jkk_full;

    -- Logiteated
    RAISE NOTICE 'Uuendati kiht production.jkk_full. Ridade arv: %', (SELECT COUNT(*) FROM production.jkk_full);
    RAISE NOTICE 'POI andmetega seotud ridade arv: %', (SELECT COUNT(*) FROM production.jkk_full WHERE poi_id IS NOT NULL AND poi_id <> -1);


END;
$$;

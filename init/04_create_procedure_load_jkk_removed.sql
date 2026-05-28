CREATE OR REPLACE PROCEDURE production.load_jkk_removed()
LANGUAGE plpgsql
AS $$

DECLARE
    countrows INTEGER;

BEGIN

    INSERT INTO production.jkk_removed (
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
        kehtivus_staatus, 
        jkk_kood_ext,
        nimi,
        lyhinimi,
        brand,
        kat_id,
        liigisona,
        lipikud,
        poi_id,
        staatus,
        kommentaar,
        added_date,
        resolved_date,
        removed_date,
        remove_resolved_date,
        geom,
        geom_mod
    )
    SELECT 
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
        kehtivus_staatus, 
        jkk_kood_ext,
        nimi,
        lyhinimi,
        brand,
        kat_id,
        liigisona,
        lipikud,
        poi_id,
        staatus,
        kommentaar,
        added_date,
        resolved_date,
        NOW()::TIMESTAMPTZ AS removed_date,
        NULL::date AS remove_resolved_date,
        geom,
        geom_mod
    FROM production.jkk_full
    -- jkk olukord on muutunud kehtivast arhiveerituks
    WHERE staatus = 2
        AND jkk_olukord != 'Arhiveeritud'
        AND jkk_kood IN (SELECT jkk_kood 
                         FROM intermediate.jkk_curr_clean
                         WHERE jkk_olukord = 'Arhiveeritud')
    
    UNION ALL

    SELECT 
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
        kehtivus_staatus, 
        jkk_kood_ext,
        nimi,
        lyhinimi,
        brand,
        kat_id,
        liigisona,
        lipikud,
        poi_id,
        staatus,
        kommentaar,
        added_date,
        resolved_date,
        NOW()::TIMESTAMPTZ AS removed_date,
        NULL::date AS remove_resolved_date,
        geom,
        geom_mod
    FROM production.jkk_full
    -- jkk objekt on registrist eemaldatud
    WHERE staatus = 2
        AND jkk_kood NOT IN (SELECT jkk_kood 
                           FROM intermediate.jkk_curr_clean)
    ;

    GET DIAGNOSTICS countrows = ROW_COUNT;
    
    RAISE NOTICE 'Kustutatud JKK objektide arv: %', countrows;
    RAISE NOTICE 'Kustutamist vajavate POIde arv on kokku: %',
        (SELECT COUNT(*)
         FROM production.jkk_removed
         WHERE remove_resolved_date IS NULL);

END;
$$;
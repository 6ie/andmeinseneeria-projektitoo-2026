CREATE OR REPLACE PROCEDURE intermediate.load_clean_current_run()
LANGUAGE plpgsql
AS $$
BEGIN

    TRUNCATE TABLE intermediate.clean_current_run;

    INSERT INTO intermediate.clean_current_run (
        kaitise_kood,
        objekti_nimetus,
        jkk_kood,
        aadress,
        ehak_kood,
        emtak_kood,
        emtak_nimetus,
        x_koordinaat,
        y_koordinaat,
        longitude,
        latitude,
        kataster,
        eprtr_pohitegevus,
        eprtr_lisategevused,
        keskkonnalubade_numbrid_str,
        keskkonnalubade_numbrid_arr,
        kaitaja_nimi,
        kaitaja_kood,
        komplekstegevus,
        komplekstegevus_selg,
        komplekst_nimi_et,
        komplekst_nimi_en,
        tegevus,
        tegevus_selg,
        tyybile_vastav_nimi_ee,
        tyybile_vastav_nimi_en,
        tegevuse_tapsustus,
        jaatmete_kaitlemine,
        tegevuse_algus,
        tegevuse_lopp,
        jkk_olukord,
        kehtivus_staatus,
        muudetud,
        eprtr_kood,
        teised_aadressid,
        teised_katastrid,
        z_inspire_id,
        ov_kood,
        ov_nimi,
        mk_kood,
        mk_nimi
    )
    SELECT
        obj ->> 'kaitise_kood',
        obj ->> 'objekti_nimetus',
        obj ->> 'jkk_kood',
        obj ->> 'aadress',
        obj ->> 'ehak_kood',
        obj ->> 'emtak_kood',
        obj ->> 'emtak_nimetus',
        NULLIF(obj ->> 'x_koordinaat', '')::INTEGER,
        NULLIF(obj ->> 'y_koordinaat', '')::INTEGER,
        NULLIF(obj ->> 'longitude', '')::NUMERIC(13,11),
        NULLIF(obj ->> 'latitude', '')::NUMERIC(15,13),
        obj ->> 'kataster',
        obj ->> 'eprtr_pohitegevus',
        obj ->> 'eprtr_lisategevused',
        obj ->> 'keskkonnalubade_numbrid_str',
        CASE
            WHEN jsonb_typeof(obj -> 'keskkonnalubade_numbrid_arr') = 'array' 
                THEN ARRAY(SELECT jsonb_array_elements_text(
                                  obj -> 'keskkonnalubade_numbrid_arr')      
                           )
            ELSE NULL
        END,
        obj ->> 'kaitaja_nimi',
        obj ->> 'kaitaja_kood',
        obj ->> 'komplekstegevus',
        obj ->> 'komplekstegevus_selg',
        obj ->> 'komplekst_nimi_et',
        obj ->> 'komplekst_nimi_en',
        obj ->> 'tegevus',
        obj ->> 'tegevus_selg',
        obj ->> 'tyybile_vastav_nimi_ee',
        obj ->> 'tyybile_vastav_nimi_en',
        obj ->> 'tegevuse_tapsustus',
        obj ->> 'jaatmete_kaitlemine',
        NULLIF(obj ->> 'tegevuse_algus', '')::DATE,
        NULLIF(obj ->> 'tegevuse_lopp', '')::DATE,
        obj ->> 'jkk_olukord',
        obj ->> 'kehtivus_staatus',
        NULLIF(obj ->> 'muudetud', '')::TIMESTAMPTZ,
        obj ->> 'eprtr_kood',
        obj ->> 'teised_aadressid',
        obj ->> 'teised_katastrid',
        obj ->> 'z_inspire_id',
        obj ->> 'ov_kood',
        obj ->> 'ov_nimi',
        obj ->> 'mk_kood',
        obj ->> 'mk_nimi'

    FROM staging.raw_snapshot p
    CROSS JOIN LATERAL jsonb_array_elements(p.raw_data) AS obj
    WHERE p.source_name = 'f_jkkregister_curr'
      AND p.status = 'SUCCESS'
      AND p.fetched_at = (SELECT MAX(p2.fetched_at)
                          FROM staging.raw_snapshot p2
                          WHERE p2.source_name = 'f_jkkregister_curr'
                          AND p2.status = 'SUCCESS'
                          )
;

END;
$$;
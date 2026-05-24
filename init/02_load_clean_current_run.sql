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
    FROM (
        SELECT
            btrim(regexp_replace(obj ->> 'objekti_nimetus', '\s+', ' ', 'g')) AS objekti_nimetus,
            btrim(regexp_replace(obj ->> 'kaitise_kood', '\s+', ' ', 'g')) AS kaitise_kood,
            btrim(regexp_replace(obj ->> 'jkk_kood', '\s+', ' ', 'g')) AS jkk_kood,
            btrim(regexp_replace(obj ->> 'aadress', '\s+', ' ', 'g')) AS aadress,
            btrim(regexp_replace(obj ->> 'ehak_kood', '\s+', ' ', 'g')) AS ehak_kood,
            btrim(regexp_replace(obj ->> 'emtak_kood', '\s+', ' ', 'g')) AS emtak_kood,
            btrim(regexp_replace(obj ->> 'emtak_nimetus', '\s+', ' ', 'g')) AS emtak_nimetus,
            NULLIF(obj ->> 'x_koordinaat', '')::INTEGER AS x_koordinaat,
            NULLIF(obj ->> 'y_koordinaat', '')::INTEGER AS y_koordinaat,
            NULLIF(obj ->> 'longitude', '')::NUMERIC(13,11) AS longitude,
            NULLIF(obj ->> 'latitude', '')::NUMERIC(15,13) AS latitude,
            btrim(regexp_replace(obj ->> 'kataster', '\s+', ' ', 'g')) AS kataster,
            btrim(regexp_replace(obj ->> 'eprtr_pohitegevus', '\s+', ' ', 'g')) AS eprtr_pohitegevus,
            btrim(regexp_replace(obj ->> 'eprtr_lisategevused', '\s+', ' ', 'g')) AS eprtr_lisategevused,
            btrim(regexp_replace(obj ->> 'keskkonnalubade_numbrid_str', '\s+', ' ', 'g')) AS keskkonnalubade_numbrid_str,
            CASE
                WHEN jsonb_typeof(obj -> 'keskkonnalubade_numbrid_arr') = 'array' 
                    THEN ARRAY(SELECT jsonb_array_elements_text(
                                    obj -> 'keskkonnalubade_numbrid_arr')      
                            )
                ELSE NULL
            END AS keskkonnalubade_numbrid_arr,
            btrim(regexp_replace(obj ->> 'kaitaja_nimi', '\s+', ' ', 'g')) AS kaitaja_nimi,
            btrim(regexp_replace(obj ->> 'kaitaja_kood', '\s+', ' ', 'g')) AS kaitaja_kood,
            btrim(regexp_replace(obj ->> 'komplekstegevus', '\s+', ' ', 'g')) AS komplekstegevus,
            btrim(regexp_replace(obj ->> 'komplekstegevus_selg', '\s+', ' ', 'g')) AS komplekstegevus_selg,
            btrim(regexp_replace(obj ->> 'komplekst_nimi_et', '\s+', ' ', 'g')) AS komplekst_nimi_et,
            btrim(regexp_replace(obj ->> 'komplekst_nimi_en', '\s+', ' ', 'g')) AS komplekst_nimi_en,
            btrim(regexp_replace(obj ->> 'tegevus', '\s+', ' ', 'g')) AS tegevus,
            btrim(regexp_replace(obj ->> 'tegevus_selg', '\s+', ' ', 'g')) AS tegevus_selg,
            btrim(regexp_replace(obj ->> 'tyybile_vastav_nimi_ee', '\s+', ' ', 'g')) AS tyybile_vastav_nimi_ee,
            btrim(regexp_replace(obj ->> 'tyybile_vastav_nimi_en', '\s+', ' ', 'g')) AS tyybile_vastav_nimi_en,
            btrim(regexp_replace(obj ->> 'tegevuse_tapsustus', '\s+', ' ', 'g')) AS tegevuse_tapsustus,
            btrim(regexp_replace(obj ->> 'jaatmete_kaitlemine', '\s+', ' ', 'g')) AS jaatmete_kaitlemine,
            NULLIF(obj ->> 'tegevuse_algus', '')::DATE AS tegevuse_algus,
            NULLIF(obj ->> 'tegevuse_lopp', '')::DATE AS tegevuse_lopp,
            btrim(regexp_replace(obj ->> 'jkk_olukord', '\s+', ' ', 'g')) AS jkk_olukord,
            btrim(regexp_replace(obj ->> 'kehtivus_staatus', '\s+', ' ', 'g')) AS kehtivus_staatus,
            NULLIF(obj ->> 'muudetud', '')::TIMESTAMPTZ AS muudetud,
            btrim(regexp_replace(obj ->> 'eprtr_kood', '\s+', ' ', 'g')) AS eprtr_kood,
            btrim(regexp_replace(obj ->> 'teised_aadressid', '\s+', ' ', 'g')) AS teised_aadressid,
            btrim(regexp_replace(obj ->> 'teised_katastrid', '\s+', ' ', 'g')) AS teised_katastrid,
            btrim(regexp_replace(obj ->> 'z_inspire_id', '\s+', ' ', 'g')) AS z_inspire_id,
            btrim(regexp_replace(obj ->> 'ov_kood', '\s+', ' ', 'g')) AS ov_kood,
            btrim(regexp_replace(obj ->> 'ov_nimi', '\s+', ' ', 'g')) AS ov_nimi,
            btrim(regexp_replace(obj ->> 'mk_kood', '\s+', ' ', 'g')) AS mk_kood,
            btrim(regexp_replace(obj ->> 'mk_nimi', '\s+', ' ', 'g')) AS mk_nimi,
            ROW_NUMBER() OVER (
                PARTITION BY obj ->> 'jkk_kood'
                ORDER BY NULLIF(obj ->> 'muudetud', '')::timestamptz DESC
            ) AS rn --jkk_koodi põhjal järjestame ja nummerdame, et hiljem duplikaate eemaldada
        FROM staging.raw_snapshot p
        CROSS JOIN LATERAL jsonb_array_elements(p.raw_data) AS obj
        WHERE p.source_name = 'f_jkkregister_curr'
        AND p.status = 'SUCCESS'
        AND p.fetched_at = (SELECT MAX(p2.fetched_at)
                            FROM staging.raw_snapshot p2
                            WHERE p2.source_name = 'f_jkkregister_curr'
                            AND p2.status = 'SUCCESS'
                            )
    ) duplikaatideta
    WHERE duplikaatideta.rn = 1
;

END;
$$;
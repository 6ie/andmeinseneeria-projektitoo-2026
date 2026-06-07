-- Ajutine arendusfail.
-- Loob algse production.jkk_full seisu /data kaustas olevate failide põhjal.
--
-- Sisendid:
--   /data/f_jkkregister_curr_20260506.json
--   /data/init_jkk_poi_seos.csv
--
-- Tulemus:
--   production.jkk_full on täidetud
--   staging.raw_snapshot jääb puhtaks
--   intermediate.jkk_curr_clean jääb puhtaks
--   CSV abiseos ei jää andmebaasi püsivalt alles

CREATE TEMP TABLE temp_init_jkk_poi_seos (
    poi_id integer,
    valine_kood text,
    kat_id integer,
    x integer,
    y integer
);

COPY temp_init_jkk_poi_seos (poi_id, valine_kood, kat_id, x, y)
FROM '/data/init_jkk_poi_seos.csv'
WITH (
    FORMAT csv,
    HEADER true,
    ENCODING 'UTF8'
);

DO $$
DECLARE
    v_run_id uuid := '00000000-0000-0000-0000-202605060001';
    v_raw jsonb;
    v_raw_count integer;
    v_clean_count integer;
    v_full_count integer;
    v_linked_count integer;
BEGIN
    -------------------------------------------------------------------------
    -- 1. JSON -> staging.raw_snapshot
    -------------------------------------------------------------------------

    v_raw := pg_read_file('/data/f_jkkregister_curr_20260506.json')::jsonb;
    v_raw_count := jsonb_array_length(v_raw);

    INSERT INTO staging.raw_snapshot (
        run_id,
        fetched_at,
        source_name,
        row_count,
        raw_data,
        status,
        message
    )
    VALUES (
        v_run_id,
        '2026-05-06 00:00:00+00'::timestamptz,
        'f_jkkregister_curr',
        v_raw_count,
        v_raw,
        'SUCCESS',
        'Temporary initial seed from /data/f_jkkregister_curr_20260506.json'
    )
    ON CONFLICT (run_id) DO UPDATE
    SET
        fetched_at = EXCLUDED.fetched_at,
        source_name = EXCLUDED.source_name,
        row_count = EXCLUDED.row_count,
        raw_data = EXCLUDED.raw_data,
        status = EXCLUDED.status,
        message = EXCLUDED.message;

    -------------------------------------------------------------------------
    -- 2. Kasuta päris API töövoo puhastusprotseduuri
    -------------------------------------------------------------------------

    CALL intermediate.refresh_jkk_curr_clean();

    SELECT COUNT(*) INTO v_clean_count
    FROM intermediate.jkk_curr_clean;

    -------------------------------------------------------------------------
    -- 3. intermediate + CSV temp table -> production.jkk_full
    -------------------------------------------------------------------------

    TRUNCATE TABLE production.jkk_full RESTART IDENTITY;

    INSERT INTO production.jkk_full (
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
        geom,
        geom_mod
    )
    SELECT
        c.objekti_nimetus,
        c.jkk_kood,
        c.jkk_olukord,
        c.kaitaja_nimi,
        c.kaitaja_kood,
        c.aadress,
        c.teised_aadressid,
        c.x_koordinaat,
        c.y_koordinaat,
        c.tegevus,
        c.tegevus_selg,
        c.tegevuse_tapsustus,
        c.tegevuse_algus,
        c.tegevuse_lopp,
        c.muudetud,
        c.komplekstegevus,
        c.komplekstegevus_selg,
        c.jaatmete_kaitlemine,

        c.jkk_kood_ext,
        c.nimi,

        CASE
            WHEN char_length(c.nimi) > 40 THEN NULL
            ELSE c.lyhinimi
        END AS lyhinimi,

        c.brand,
        c.kat_id,
        c.liigisona,
        c.lipikud,

        CASE
            -- Kui objekt ei saanud kat_id väärtust, siis teda POI-na ei käsitleta.
            WHEN c.kat_id IS NULL THEN -1
            ELSE s.poi_id
        END AS poi_id,

        CASE
            -- Ilma kat_id-ta objektid märgime mittevaadeldavaks.
            WHEN c.kat_id IS NULL THEN -1

            -- Kehtetud JKK objektid märgime samuti mitteaktiivseks.
            WHEN c.jkk_olukord = 'Arhiveeritud' THEN -1

            -- Kui objekt on olemasoleva POI-ga seotud, siis staatus = 2.
            WHEN s.poi_id IS NOT NULL THEN 2

            -- Uus või sidumata, aga kategooriaga objekt.
            ELSE 1
        END AS staatus,

        NULL AS kommentaar,
        CURRENT_DATE AS added_date,
        CASE
            -- Sama loogika nagu staatus = -1
            WHEN c.kat_id IS NULL THEN CURRENT_DATE
            WHEN c.jkk_olukord = 'Arhiveeritud' THEN CURRENT_DATE

            -- Sama loogika nagu staatus = 2
            WHEN s.poi_id IS NOT NULL THEN CURRENT_DATE

            -- staatus = 1 jääb lahendamata
            ELSE NULL
        END AS resolved_date,

        c.geom,

        COALESCE(
            CASE
                WHEN s.x IS NOT NULL AND s.y IS NOT NULL THEN
                    ST_SetSRID(ST_MakePoint(s.x, s.y), 3301)
                ELSE NULL
            END,
            c.geom
        ) AS geom_mod

    FROM intermediate.jkk_curr_clean c
    LEFT JOIN temp_init_jkk_poi_seos s
        ON c.jkk_kood = s.valine_kood
    AND c.kat_id = s.kat_id;

    -------------------------------------------------------------------------
    -- 4. Korista abietapid puhtaks
    -------------------------------------------------------------------------

    DELETE FROM staging.raw_snapshot
    WHERE run_id = v_run_id;

    TRUNCATE TABLE intermediate.jkk_curr_clean RESTART IDENTITY;

    -------------------------------------------------------------------------
    -- 5. Logiteated
    -------------------------------------------------------------------------

    SELECT COUNT(*) INTO v_full_count
    FROM production.jkk_full;

    SELECT COUNT(*) INTO v_linked_count
    FROM production.jkk_full
    WHERE poi_id IS NOT NULL
    AND poi_id <> -1;

    RAISE NOTICE 'Temporary initial production load completed.';
    RAISE NOTICE 'Raw JSON rows read: %', v_raw_count;
    RAISE NOTICE 'Intermediate rows used before cleanup: %', v_clean_count;
    RAISE NOTICE 'Production full rows: %', v_full_count;
    RAISE NOTICE 'Production full rows linked to POI: %', v_linked_count;
END $$;

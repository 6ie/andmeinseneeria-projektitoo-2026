CREATE OR REPLACE PROCEDURE intermediate.refresh_jkk_curr_clean()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE intermediate.jkk_curr_clean RESTART IDENTITY;

    WITH latest_snapshot AS (
        SELECT raw_data
        FROM staging.raw_snapshot
        WHERE source_name = 'f_jkkregister_curr'
          AND status = 'SUCCESS'
        ORDER BY fetched_at DESC
        LIMIT 1
    ),
    json_rows AS (
        SELECT item
        FROM latest_snapshot,
             jsonb_array_elements(raw_data) AS item
    )
    INSERT INTO intermediate.jkk_curr_clean (
        objekti_nimetus,
        jkk_kood,
        kaitaja_nimi,
        kaitaja_kood,
        x_koordinaat,
        y_koordinaat,
        jkk_kood_ext,
        nimi,
        lyhinimi,
        brand,
        kat_id,
        liigisona,
        lipikud
    )
    SELECT
        btrim(regexp_replace(item->>'objekti_nimetus', '\s+', ' ', 'g')) AS objekti_nimetus,
        btrim(regexp_replace(item->>'jkk_kood', '\s+', ' ', 'g')) AS jkk_kood,
        btrim(regexp_replace(item->>'kaitaja_nimi', '\s+', ' ', 'g')) AS kaitaja_nimi,
        btrim(regexp_replace(item->>'kaitaja_kood', '\s+', ' ', 'g')) AS kaitaja_kood,
        NULLIF(item->>'x_koordinaat', '')::integer AS x_koordinaat,
        NULLIF(item->>'y_koordinaat', '')::integer AS y_koordinaat,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    FROM json_rows;
END;
$$;
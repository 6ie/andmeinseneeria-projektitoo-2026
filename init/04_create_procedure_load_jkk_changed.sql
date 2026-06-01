CREATE OR REPLACE PROCEDURE production.load_jkk_changed()
LANGUAGE plpgsql
AS $$

DECLARE
    countrows INTEGER;

BEGIN

    WITH changed_rows AS (
        SELECT
            curr.objekti_nimetus,
            curr.jkk_kood_ext,
            CASE WHEN prev.nimi IS DISTINCT FROM curr.nimi THEN 1 ELSE 0 END AS nimi_change_status,
            CASE WHEN prev.nimi IS DISTINCT FROM curr.nimi THEN prev.nimi ELSE NULL END AS nimi_old,
            CASE WHEN prev.nimi IS DISTINCT FROM curr.nimi THEN curr.nimi ELSE NULL END AS nimi_new,
            CASE WHEN prev.brand IS DISTINCT FROM curr.brand THEN 1 ELSE 0 END AS brand_change_status,
            CASE WHEN prev.brand IS DISTINCT FROM curr.brand THEN prev.brand ELSE NULL END AS brand_old,
            CASE WHEN prev.brand IS DISTINCT FROM curr.brand THEN curr.brand ELSE NULL END AS brand_new,
            CASE WHEN prev.liigisona IS DISTINCT FROM curr.liigisona THEN 1 ELSE 0 END AS liigisona_change_status,
            CASE WHEN prev.liigisona IS DISTINCT FROM curr.liigisona THEN prev.liigisona ELSE NULL END AS liigisona_old,
            CASE WHEN prev.liigisona IS DISTINCT FROM curr.liigisona THEN curr.liigisona ELSE NULL END AS liigisona_new,
            CASE WHEN prev.lipikud IS DISTINCT FROM curr.lipikud THEN 1 ELSE 0 END AS lipikud_change_status,
            CASE WHEN prev.lipikud IS DISTINCT FROM curr.lipikud THEN prev.lipikud ELSE NULL END AS lipikud_old,
            CASE WHEN prev.lipikud IS DISTINCT FROM curr.lipikud THEN curr.lipikud ELSE NULL END AS lipikud_new,
            CASE
                WHEN prev.geom IS NOT NULL
                     AND curr.geom IS NOT NULL
                     AND ST_Distance(prev.geom, curr.geom) > 30
                THEN 1
                ELSE 0
            END AS geom_change_status,
            CASE
                WHEN prev.geom IS NOT NULL
                     AND curr.geom IS NOT NULL
                     AND ST_Distance(prev.geom, curr.geom) > 30
                THEN ST_MakeLine(prev.geom, curr.geom)
                ELSE NULL
            END AS geom_change,
            curr.geom AS geom
        FROM intermediate.jkk_curr_clean curr
        INNER JOIN production.jkk_full prev
            ON curr.jkk_kood_ext = prev.jkk_kood_ext
        WHERE
            prev.nimi IS DISTINCT FROM curr.nimi
            OR prev.brand IS DISTINCT FROM curr.brand
            OR prev.liigisona IS DISTINCT FROM curr.liigisona
            OR prev.lipikud IS DISTINCT FROM curr.lipikud
            OR (
                prev.geom IS NOT NULL
                AND curr.geom IS NOT NULL
                AND ST_Distance(prev.geom, curr.geom) > 30
            )
    )
    INSERT INTO production.jkk_changes (
        objekti_nimetus,
        jkk_kood_ext,
        nimi_change_status,
        nimi_old,
        nimi_new,
        brand_change_status,
        brand_old,
        brand_new,
        liigisona_change_status,
        liigisona_old,
        liigisona_new,
        lipikud_change_status,
        lipikud_old,
        lipikud_new,
        geom_change_status,
        geom_change,
        kommentaar,
        change_date,
        resolved_date,
        geom
    )
    SELECT
        cr.objekti_nimetus,
        cr.jkk_kood_ext,
        cr.nimi_change_status,
        cr.nimi_old,
        cr.nimi_new,
        cr.brand_change_status,
        cr.brand_old,
        cr.brand_new,
        cr.liigisona_change_status,
        cr.liigisona_old,
        cr.liigisona_new,
        cr.lipikud_change_status,
        cr.lipikud_old,
        cr.lipikud_new,
        cr.geom_change_status,
        cr.geom_change,
        NULL::text AS kommentaar,
        CURRENT_DATE AS change_date,
        NULL::date AS resolved_date,
        cr.geom
    FROM changed_rows cr

    -- Ei sisesta, kui juba sama lahendamata muudatus on olemas, et vältida duplikaate.
    WHERE NOT EXISTS (
        SELECT 1
        FROM production.jkk_changes existing
        WHERE existing.jkk_kood_ext = cr.jkk_kood_ext
          AND existing.resolved_date IS NULL
          AND existing.nimi_old IS NOT DISTINCT FROM cr.nimi_old
          AND existing.nimi_new IS NOT DISTINCT FROM cr.nimi_new
          AND existing.brand_old IS NOT DISTINCT FROM cr.brand_old
          AND existing.brand_new IS NOT DISTINCT FROM cr.brand_new
          AND existing.liigisona_old IS NOT DISTINCT FROM cr.liigisona_old
          AND existing.liigisona_new IS NOT DISTINCT FROM cr.liigisona_new
          AND existing.lipikud_old IS NOT DISTINCT FROM cr.lipikud_old
          AND existing.lipikud_new IS NOT DISTINCT FROM cr.lipikud_new
          AND existing.geom_change_status = cr.geom_change_status
          AND (
                (cr.geom_change IS NULL AND existing.geom_change IS NULL)
             OR (cr.geom_change IS NOT NULL AND ST_Equals(existing.geom_change, cr.geom_change))
          )
    );
    GET DIAGNOSTICS countrows = ROW_COUNT;
    RAISE NOTICE 'Muutustega JKK objektide arv: %', countrows;

    RAISE NOTICE 'Muutmist vajavate POIde arv on kokku: %',
        (SELECT COUNT(*)
         FROM production.jkk_changes
         WHERE resolved_date IS NULL);

END;
$$;
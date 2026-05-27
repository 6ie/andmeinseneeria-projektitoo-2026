/*
Värskendab intermediate.jkk_curr_clean tabeli viimase õnnestunud JKK API tõmmise põhjal.
Puhastab lähteandmed, määrab tegevus- ja komplekstegevuse koodide ja nime põhjal kat_id/liigisõna/lipikud ning jätab alles ka objektid, millele kat_id ei leita.
*/
CREATE OR REPLACE PROCEDURE intermediate.refresh_jkk_curr_clean()
LANGUAGE plpgsql
AS $$

DECLARE
    countrows INTEGER;

BEGIN
    TRUNCATE TABLE intermediate.jkk_curr_clean RESTART IDENTITY;

    WITH latest_snapshot AS (
        -- Viimasest õnnestunud JKK API tõmmisest saadud JSON-i massiiv
        SELECT raw_data
        FROM staging.raw_snapshot
        WHERE source_name = 'f_jkkregister_curr'
          AND status = 'SUCCESS'
        ORDER BY fetched_at DESC
        LIMIT 1
    ),

    json_rows AS (
        -- JSON massiivi igast elemendist rea tegemine
        SELECT
            row_number() OVER () AS src_row_id,
            item
        FROM latest_snapshot,
             jsonb_array_elements(raw_data) AS item
    ),

    clean_rows AS (
        -- Otse JKK-st tulevate väljade puhastus.
        SELECT
            src_row_id,

            NULLIF(btrim(regexp_replace(item->>'objekti_nimetus', '\s+', ' ', 'g')), '') AS objekti_nimetus,
            NULLIF(btrim(regexp_replace(item->>'jkk_kood', '\s+', ' ', 'g')), '') AS jkk_kood,
            NULLIF(btrim(regexp_replace(item->>'jkk_olukord', '\s+', ' ', 'g')), '') AS jkk_olukord,
            NULLIF(btrim(regexp_replace(item->>'kaitaja_nimi', '\s+', ' ', 'g')), '') AS kaitaja_nimi,
            NULLIF(btrim(regexp_replace(item->>'kaitaja_kood', '\s+', ' ', 'g')), '') AS kaitaja_kood,
            NULLIF(btrim(regexp_replace(item->>'aadress', '\s+', ' ', 'g')), '') AS aadress,
            NULLIF(btrim(regexp_replace(item->>'teised_aadressid', '\s+', ' ', 'g')), '') AS teised_aadressid,

            NULLIF(btrim(item->>'x_koordinaat'), '')::integer AS x_koordinaat,
            NULLIF(btrim(item->>'y_koordinaat'), '')::integer AS y_koordinaat,

            NULLIF(btrim(regexp_replace(item->>'tegevus', '\s+', ' ', 'g')), '') AS tegevus,
            NULLIF(btrim(regexp_replace(item->>'tegevus_selg', '\s+', ' ', 'g')), '') AS tegevus_selg,
            NULLIF(btrim(regexp_replace(item->>'tegevuse_tapsustus', '\s+', ' ', 'g')), '') AS tegevuse_tapsustus,

            NULLIF(btrim(item->>'tegevuse_algus'), '')::date AS tegevuse_algus,
            NULLIF(btrim(item->>'tegevuse_lopp'), '')::date AS tegevuse_lopp,

            NULLIF(btrim(regexp_replace(item->>'muudetud', '\s+', ' ', 'g')), '') AS muudetud,
            NULLIF(btrim(regexp_replace(item->>'komplekstegevus', '\s+', ' ', 'g')), '') AS komplekstegevus,
            NULLIF(btrim(regexp_replace(item->>'komplekstegevus_selg', '\s+', ' ', 'g')), '') AS komplekstegevus_selg,
            NULLIF(btrim(regexp_replace(item->>'jaatmete_kaitlemine', '\s+', ' ', 'g')), '') AS jaatmete_kaitlemine,
            NULLIF(btrim(regexp_replace(item->>'kehtivus_staatus', '\s+', ' ', 'g')), '') AS kehtivus_staatus
        FROM json_rows
    ),

    code_mapping AS (
        -- Tegevuse ja komplekstegevuse koodide teisendus sihtbaasi kategooriateks, liigisõnadeks ja lipikuteks.
        SELECT *
        FROM (
            VALUES
                ('K1', 2208, 'Jäätmekäitluskeskus', NULL),
                ('K2', 2208, 'Jäätmejaam', NULL),
                ('K3', 2208, 'Jäätmekäitluskoht', NULL),

                ('U1', 2207, NULL, 'Tavajäätmeprügila'),
                ('U2', 2207, NULL, 'Ohtlike jäätmete prügila'),
                ('U3', 2207, NULL, 'Püsijäätmeprügila'),

                ('U5', 2208, 'Jäätmekäitluskoht', 'Sortimisliin, -tehas'),
                ('U6', 2208, 'Jäätmekäitluskoht', 'Ümberlaadimisjaam, vaheladu'),

                ('U7', 2606, 'Jäätmepõletustehas', NULL),
                ('U8', 2606, 'Koospõletustehas', NULL),

                ('U10', 2208, 'Jäätmekäitluskoht', 'Ohtlike jäätmete käitluskoht'),
                ('U11', 2208, 'Jäätmekäitluskoht', 'Metallijäätmete käitluskoht'),
                ('U12', 2208, 'Jäätmekäitluskoht', 'Elektroonikaromude käitluskoht'),

                ('U13', 3120, 'Autolammutuskoda', NULL),

                ('U16', 2208, 'Jäätmekäitluskoht', 'Tavajäätmete käitluskoht'),
                ('U17', 2208, 'Jäätmekäitluskoht', NULL)
        ) AS m(code_value, kat_id, liigisona_base, lipikud_base)
    ),

    code_rows AS (
        -- Tegevus ja komplekstegevus koodide ridadeks jagamine.
        -- Objekt jääb alles ka siis, kui koode pole.
        SELECT
            cr.src_row_id,
            codes.code_value
        FROM clean_rows cr
        LEFT JOIN LATERAL (
            SELECT NULLIF(btrim(s.code_value), '') AS code_value
            FROM regexp_split_to_table(
                concat_ws(',', cr.tegevus, cr.komplekstegevus),
                '\s*,\s*'
            ) AS s(code_value)
            WHERE NULLIF(btrim(s.code_value), '') IS NOT NULL
        ) AS codes
        ON TRUE
    ),

    mapped_code_rows AS (
        -- Koodid vastendamine.
        -- Objekt jääb alles ka siis, kui kood ei leia vastet.
        SELECT
            cr.src_row_id,
            cr.code_value,
            cm.kat_id AS kat_id_mapped,

            CASE
                WHEN cr.code_value IN ('U1', 'U2', 'U3')
                    AND lower(cle.jkk_olukord) = 'töötav'
                    THEN 'Prügila'

                WHEN cr.code_value IN ('U1', 'U2', 'U3')
                    AND lower(cle.jkk_olukord) IN ('arhiveeritud', 'arhiveerutud')
                    THEN 'Suletud prügila'

                WHEN cr.code_value IN ('U1', 'U2', 'U3')
                    THEN 'Prügila'

                ELSE cm.liigisona_base
            END AS liigisona_mapped,

            cm.lipikud_base AS lipikud_mapped
        FROM code_rows cr
        JOIN clean_rows cle
        ON cle.src_row_id = cr.src_row_id
        LEFT JOIN code_mapping cm
        ON cm.code_value = cr.code_value
    ),

    adjusted_code_rows AS (
        -- Rakendame nimepõhised erandid ainult nendele ridadele,
        -- mis oleksid muidu saanud kat_id = 2208 (jäätmekäitluskoht).
        SELECT
            mcr.src_row_id,

            CASE
                -- Pinnasetäitekohtade välja filtreerimine
                WHEN mcr.kat_id_mapped = 2208
                 AND cle.objekti_nimetus ILIKE '%pinnasetäitekoht%'
                    THEN NULL

                -- Kui 2208 objekt viitab nime järgi pigem põllumajandusele,
                -- liigub ta kat_id = 2607 alla.
                WHEN mcr.kat_id_mapped = 2208
                 AND cle.objekti_nimetus ILIKE ANY (
                    ARRAY[
                        '%sigala%',
                        '%farm%',
                        '%laut%',
                        '%lauda%',
                        '%kanala%',
                        '%talu%',
                        '%põllud%',
                        '%silo%'
                    ]
                 )
                    THEN 2607

                ELSE mcr.kat_id_mapped
            END AS kat_id,

            CASE
                -- Kui eemaldame 2208 mappingu või muudame selle 2607 peale,
                -- siis ei kanna vana 2208 liigisõna edasi.
                -- TODO: Siis peaks ka liigisõna muutma > 'Põllumajandushoone' vms ? peaks uurima
                WHEN mcr.kat_id_mapped = 2208
                 AND cle.objekti_nimetus ILIKE '%pinnasetäitekoht%'
                    THEN NULL

                WHEN mcr.kat_id_mapped = 2208
                 AND cle.objekti_nimetus ILIKE ANY (
                    ARRAY[
                        '%sigala%',
                        '%farm%',
                        '%laut%',
                        '%lauda%',
                        '%kanala%',
                        '%talu%',
                        '%põllud%',
                        '%silo%'
                    ]
                 )
                    THEN NULL

                ELSE mcr.liigisona_mapped
            END AS liigisona,

            CASE
                -- Sama põhimõte lipikutega: 2208 lipikuid ei vii 2607 alla kaasa.
                -- TODO: Siis peaks ka liigisõna muutma > 'Põllumajandushoone' vms ? peaks uurima
                WHEN mcr.kat_id_mapped = 2208
                 AND cle.objekti_nimetus ILIKE '%pinnasetäitekoht%'
                    THEN NULL

                WHEN mcr.kat_id_mapped = 2208
                 AND cle.objekti_nimetus ILIKE ANY (
                    ARRAY[
                        '%sigala%',
                        '%farm%',
                        '%laut%',
                        '%lauda%',
                        '%kanala%',
                        '%talu%',
                        '%põllud%',
                        '%silo%'
                    ]
                 )
                    THEN NULL

                ELSE mcr.lipikud_mapped
            END AS lipikud
        FROM mapped_code_rows mcr
        JOIN clean_rows cle
        ON cle.src_row_id = mcr.src_row_id
    ),

    valid_category_rows AS (
        -- Jätame alles ainult päriselt määratud kategooriad.
        SELECT
            src_row_id,
            kat_id,
            liigisona,
            lipikud
        FROM adjusted_code_rows
        WHERE kat_id IS NOT NULL
    ),

    fallback_rows AS (
        -- Kui objektil ei tekkinud ühtegi kat_id väärtust,
        -- lisame ühe rea kat_id = NULL.
        SELECT
            cr.src_row_id,
            NULL::integer AS kat_id,
            NULL::text AS liigisona,
            NULL::text AS lipikud
        FROM clean_rows cr
        WHERE NOT EXISTS (
            SELECT 1
            FROM valid_category_rows vcr
            WHERE vcr.src_row_id = cr.src_row_id
        )
    ),

    classification_rows AS (
        -- Siin on koos:
        -- 1. kõik leitud kategooriad
        -- 2. fallback read objektidele, millel kategooriat ei tekkinud
        SELECT * FROM valid_category_rows
        UNION ALL
        SELECT * FROM fallback_rows
    ),

    classification_rows_with_priority AS (
        -- Kui sama kat_id alla tekib mitu liigisõna,
        -- valime tähtsuse järjekorra alusel ühe.
        SELECT
            *,

            CASE liigisona
                WHEN 'Jäätmekäitluskeskus' THEN 1
                WHEN 'Jäätmejaam' THEN 2
                WHEN 'Jäätmekäitluskoht' THEN 3
                WHEN 'Koospõletustehas' THEN 4
                WHEN 'Jäätmepõletustehas' THEN 5
                WHEN 'Autolammutuskoda' THEN 6
                ELSE 99
            END AS liigisona_priority
        FROM classification_rows
    ),

    grouped_classification AS (
        -- Agregeerime ainult arvutatud klassifikatsiooni välju.
        -- Algseid JKK välju siin enam ei agregeerita.
        SELECT
            src_row_id,
            kat_id,

            (
                array_agg(liigisona ORDER BY liigisona_priority, liigisona)
                FILTER (WHERE liigisona IS NOT NULL)
            )[1] AS liigisona,

            string_agg(DISTINCT lipikud, '; ' ORDER BY lipikud)
                FILTER (WHERE lipikud IS NOT NULL) AS lipikud
        FROM classification_rows_with_priority
        GROUP BY
            src_row_id,
            kat_id
    ),

    output_rows AS (
        -- Liidame arvutatud klassifikatsiooni tagasi algsete JKK väljade külge.
        -- Üks JKK objekt võib anda mitu väljundrida, kui talle tekib mitu kat_id väärtust.
        SELECT
            cr.objekti_nimetus,
            cr.jkk_kood,
            cr.jkk_olukord,
            cr.kaitaja_nimi,
            cr.kaitaja_kood,
            cr.aadress,
            cr.teised_aadressid,
            cr.x_koordinaat,
            cr.y_koordinaat,
            cr.tegevus,
            cr.tegevus_selg,
            cr.tegevuse_tapsustus,
            cr.tegevuse_algus,
            cr.tegevuse_lopp,
            cr.muudetud,
            cr.komplekstegevus,
            cr.komplekstegevus_selg,
            cr.jaatmete_kaitlemine,
            cr.kehtivus_staatus,

            gc.kat_id,
            gc.liigisona,
            gc.lipikud
        FROM clean_rows cr
        JOIN grouped_classification gc
        ON gc.src_row_id = cr.src_row_id
    )

    INSERT INTO intermediate.jkk_curr_clean (
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
        lipikud
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

        CASE
            WHEN jkk_kood IS NULL THEN NULL
            WHEN kat_id IS NULL THEN jkk_kood
            ELSE jkk_kood || '_' || kat_id::text
        END AS jkk_kood_ext,

        objekti_nimetus AS nimi,
        objekti_nimetus AS lyhinimi,
        kaitaja_nimi AS brand,
        kat_id,
        liigisona,
        lipikud
    FROM output_rows;
    
    GET DIAGNOSTICS countrows = ROW_COUNT;
    RAISE NOTICE 'Intermediate.jkk_curr_clean tabelisse laetud ridade arv: %', countrows;

END;
$$;
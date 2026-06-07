DO $$
DECLARE
    cols text;
    sql text;
BEGIN
    /*
      Creates real debug table:
      staging.jkk_2d

      One row = one JSON object from latest successful API snapshot.
      One column = one JSON key found in the JSON objects.

      Column order:
      1. json_row_nr
      2. keys from first JSON row, in the order PostgreSQL returns them
      3. extra keys found only in later rows
    */

    WITH latest_snapshot AS (
        SELECT raw_data
        FROM staging.raw_snapshot
        WHERE source_name = 'f_jkkregister_curr'
          AND status = 'SUCCESS'
        ORDER BY fetched_at DESC
        LIMIT 1
    ),
    json_rows AS (
        SELECT
            ordinality AS json_row_nr,
            item
        FROM latest_snapshot,
             jsonb_array_elements(raw_data) WITH ORDINALITY AS arr(item, ordinality)
    ),
    first_row_keys AS (
        SELECT
            e.key,
            e.ordinality AS key_order
        FROM json_rows jr
        CROSS JOIN LATERAL jsonb_each(jr.item) WITH ORDINALITY AS e(key, value, ordinality)
        WHERE jr.json_row_nr = 1
    ),
    all_keys AS (
        SELECT DISTINCT
            e.key
        FROM json_rows jr
        CROSS JOIN LATERAL jsonb_each(jr.item) AS e(key, value)
    ),
    ordered_keys AS (
        SELECT
            ak.key,
            COALESCE(
                frk.key_order,
                1000000 + row_number() OVER (ORDER BY ak.key)
            ) AS key_order
        FROM all_keys ak
        LEFT JOIN first_row_keys frk
            ON frk.key = ak.key
    )
    SELECT string_agg(
        format(
            'max(value #>> ''{}'') FILTER (WHERE key = %L) AS %I',
            key,
            key
        ),
        E',\n            '
        ORDER BY key_order
    )
    INTO cols
    FROM ordered_keys;

    IF cols IS NULL THEN
        RAISE NOTICE 'No JSON keys found.';
        RETURN;
    END IF;

    DROP TABLE IF EXISTS staging.jkk_2d;

    sql := format($f$
        CREATE TABLE staging.jkk_2d AS
        WITH latest_snapshot AS (
            SELECT raw_data
            FROM staging.raw_snapshot
            WHERE source_name = 'f_jkkregister_curr'
              AND status = 'SUCCESS'
            ORDER BY fetched_at DESC
            LIMIT 1
        ),
        json_rows AS (
            SELECT
                ordinality AS json_row_nr,
                item
            FROM latest_snapshot,
                 jsonb_array_elements(raw_data) WITH ORDINALITY AS arr(item, ordinality)
        ),
        kv AS (
            SELECT
                json_row_nr,
                e.key,
                e.value
            FROM json_rows
            CROSS JOIN LATERAL jsonb_each(item) AS e(key, value)
        )
        SELECT
            json_row_nr,
            %s
        FROM kv
        GROUP BY json_row_nr
        ORDER BY json_row_nr
    $f$, cols);

    EXECUTE sql;

    RAISE NOTICE 'Created table staging.jkk_2d';
END $$;
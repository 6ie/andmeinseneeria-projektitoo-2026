DROP TABLE IF EXISTS staging.jkk_emtak_mapping;

CREATE TABLE staging.jkk_emtak_mapping AS
WITH paired AS (
    SELECT
        trim(c.code) AS emtak_kood,
        trim(n.nimetus) AS emtak_nimetus
    FROM staging.jkk_2d j
    CROSS JOIN LATERAL unnest(string_to_array(j.emtak_kood, ',')) 
        WITH ORDINALITY AS c(code, ord)
    LEFT JOIN LATERAL unnest(string_to_array(j.emtak_nimetus, ';')) 
        WITH ORDINALITY AS n(nimetus, ord)
        ON n.ord = c.ord
    WHERE j.emtak_kood IS NOT NULL
)
SELECT DISTINCT
    emtak_kood,
    emtak_nimetus
FROM paired
WHERE emtak_kood IS NOT NULL
ORDER BY emtak_kood, emtak_nimetus;
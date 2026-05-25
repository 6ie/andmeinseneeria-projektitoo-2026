DROP TABLE IF EXISTS staging.jkk_tegevus_mapping;

CREATE TABLE staging.jkk_tegevus_mapping AS
WITH paired AS (
    SELECT
        trim(c.code) AS tegevus_kood,
        trim(s.selgitus) AS tegevus_selgitus
    FROM staging.jkk_2d j
    CROSS JOIN LATERAL unnest(string_to_array(j.tegevus, ',')) 
        WITH ORDINALITY AS c(code, ord)
    LEFT JOIN LATERAL unnest(string_to_array(j.tegevus_selg, ';')) 
        WITH ORDINALITY AS s(selgitus, ord)
        ON s.ord = c.ord
    WHERE j.tegevus IS NOT NULL
)
SELECT DISTINCT
    tegevus_kood,
    tegevus_selgitus
FROM paired
WHERE tegevus_kood IS NOT NULL
ORDER BY tegevus_kood, tegevus_selgitus;
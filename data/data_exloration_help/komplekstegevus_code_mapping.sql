DROP TABLE IF EXISTS staging.jkk_komplekstegevus_mapping;

CREATE TABLE staging.jkk_komplekstegevus_mapping AS
WITH paired AS (
    SELECT
        trim(c.code) AS komplekstegevus_kood,
        trim(s.selgitus) AS komplekstegevus_selgitus
    FROM staging.jkk_2d j
    CROSS JOIN LATERAL unnest(string_to_array(j.komplekstegevus, ',')) 
        WITH ORDINALITY AS c(code, ord)
    LEFT JOIN LATERAL unnest(string_to_array(j.komplekstegevus_selg, ';')) 
        WITH ORDINALITY AS s(selgitus, ord)
        ON s.ord = c.ord
    WHERE j.komplekstegevus IS NOT NULL
)
SELECT DISTINCT
    komplekstegevus_kood,
    komplekstegevus_selgitus
FROM paired
WHERE komplekstegevus_kood IS NOT NULL
ORDER BY komplekstegevus_kood, komplekstegevus_selgitus;
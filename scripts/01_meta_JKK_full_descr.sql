/*
JKK objektide jaotus kontrollimise, POI seose ja sihtbaasi sobivuse järgi.

Päring koondab kõik production.jkk_full tabeli objektid nelja põhikategooriasse:
1. sihtbaasi jaoks mittevajalikud objektid;
2. kontrollitud ja POI-ga seotud objektid;
3. üle vaadatud, aga sihtbaasi mittesobivad objektid;
4. kontrollimata objektid.

Tulemus sobib Metabase’i sektordiagrammi jaoks.

Metabase visualization:
Dimension: kategooria
Measure: arv
*/

SELECT
    kategooria,
    count(*) AS arv
FROM (
    SELECT
        CASE
            WHEN staatus = -1 THEN 'Sihtbaasi jaoks kasutu'
            WHEN staatus = 2 AND poi_id IS NOT NULL AND poi_id <> -1 THEN 'Kontrollitud, seotud'
            WHEN staatus = 2 AND coalesce(poi_id, -1) = -1 THEN 'Kontrollitud, sidumata'
            WHEN staatus = 1 THEN 'Kontrollimata'
            ELSE 'Muu / vigane staatus'
        END AS kategooria,

        CASE
            WHEN staatus = -1 THEN 1
            WHEN staatus = 2 AND poi_id IS NOT NULL AND poi_id <> -1 THEN 2
            WHEN staatus = 2 AND coalesce(poi_id, -1) = -1 THEN 3
            WHEN staatus = 1 THEN 4
            ELSE 99
        END AS sort_order
    FROM production.jkk_full
) x
GROUP BY
    kategooria,
    sort_order
ORDER BY
    sort_order;
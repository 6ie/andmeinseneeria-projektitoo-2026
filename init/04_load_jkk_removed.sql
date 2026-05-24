CREATE OR REPLACE PROCEDURE production.load_jkk_removed()
LANGUAGE plpgsql
AS $$

DECLARE
    countrows INTEGER;

BEGIN

    INSERT INTO production.jkk_removed (
        jkk_kood,
        --poi_id,
        deleted_at,
        staatus
    )
    SELECT 
        jkk_kood,
        NOW()::TIMESTAMPTZ AS deleted_at,
        'KUSTUTADA' AS staatus
    FROM intermediate.clean_current_run
    WHERE jkk_kood NOT IN (SELECT jkk_kood FROM production.jkk_full);

    GET DIAGNOSTICS countrows = ROW_COUNT;
    
    RAISE NOTICE 'Kustutatud JKK objektide arv: %', countrows;
    RAISE NOTICE 'Kustutamist vajavate POIde arv on kokku: %',
        (SELECT COUNT(*)
         FROM production.jkk_removed
         WHERE staatus = 'KUSTUTADA');

END;
$$;
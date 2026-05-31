CREATE OR REPLACE PROCEDURE production.refresh_jkk_production()
LANGUAGE plpgsql
AS $$
BEGIN

    CALL production.load_jkk_removed();
    CALL production.load_jkk_changed();
    CALL production.move_jkk_curr_to_jkk_full();

    RAISE NOTICE 'SUCCESS: JKK POIde uuendus on lõpetatud.';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: JKK POIde uuendus katkestati: %', SQLERRM;
        RAISE;
END;
$$;
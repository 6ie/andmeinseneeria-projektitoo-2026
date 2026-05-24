CREATE OR REPLACE PROCEDURE production.move_jkk_curr_to_jkk_full()
LANGUAGE plpgsql
AS $$
BEGIN

    TRUNCATE TABLE production.jkk_full;

    INSERT INTO production.jkk_full
    SELECT *
    FROM intermediate.clean_current_run;

    RAISE NOTICE 'JKK andmete vana seis on uuega üle kirjutatud. Ridade arv: %',
        (SELECT COUNT(*) FROM production.jkk_full);

END;
$$;

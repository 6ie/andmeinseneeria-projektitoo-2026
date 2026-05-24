CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS intermediate;
CREATE SCHEMA IF NOT EXISTS production;

CREATE TABLE IF NOT EXISTS staging.raw_snapshot (
    run_id uuid PRIMARY KEY,
    fetched_at timestamptz NOT NULL,
    source_name text NOT NULL,
    row_count int,
    raw_data jsonb NOT NULL,
    status text NOT NULL,
    message text
);

CREATE TABLE intermediate.clean_current_run (
    id SERIAL PRIMARY KEY,
    kaitise_kood                TEXT,
    objekti_nimetus             TEXT,
    jkk_kood                    TEXT,
    aadress                     TEXT,
    ehak_kood                   TEXT,
    emtak_kood                  TEXT,
    emtak_nimetus               TEXT,
    x_koordinaat                INTEGER,
    y_koordinaat                INTEGER,
    longitude                   NUMERIC(13,11),
    latitude                    NUMERIC(15,13),
    kataster                    TEXT,
    eprtr_pohitegevus           TEXT,
    eprtr_lisategevused         TEXT,
    keskkonnalubade_numbrid_str TEXT,
    keskkonnalubade_numbrid_arr TEXT[],
    kaitaja_nimi                TEXT,
    kaitaja_kood                TEXT,
    komplekstegevus             TEXT,
    komplekstegevus_selg        TEXT,
    komplekst_nimi_et           TEXT,
    komplekst_nimi_en           TEXT,
    tegevus                     TEXT,
    tegevus_selg                TEXT,
    tyybile_vastav_nimi_ee      TEXT,
    tyybile_vastav_nimi_en      TEXT,
    tegevuse_tapsustus          TEXT,
    jaatmete_kaitlemine         TEXT,
    tegevuse_algus              DATE,
    tegevuse_lopp               DATE,
    jkk_olukord                 TEXT,
    kehtivus_staatus            TEXT,
    muudetud                    TIMESTAMPTZ,
    eprtr_kood                  TEXT,
    teised_aadressid            TEXT,
    teised_katastrid            TEXT,
    z_inspire_id                TEXT,
    ov_kood                     TEXT,
    ov_nimi                     TEXT,
    mk_kood                     TEXT,
    mk_nimi                     TEXT,
    created_at                  TIMESTAMPTZ DEFAULT NOW()
);
-- FUNCTION: xxx.norm_compname(text, text)

-- DROP FUNCTION IF EXISTS xxx.norm_compname(text, text);

CREATE OR REPLACE FUNCTION xxx.norm_compname(
	s text,
	mode text DEFAULT 'nimi'::text)
    RETURNS text
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
WITH
-- 0) inputs
inp AS (
  SELECT COALESCE(s,'') AS v, lower(COALESCE(mode,'nimi')) AS m
),

-- 1) strip quotes (ASCII & typographic) without using literal quotes
rm_quotes AS (
  SELECT translate(
           v,
           chr(34) || chr(39) || chr(171) || chr(187) || chr(8216) || chr(8217) || chr(8220) || chr(8221) || chr(8222),
           ''
         ) AS v, m
  FROM inp
),

-- 2) normalize titles
titles AS (
  SELECT
    regexp_replace(
      regexp_replace(v, '\m(?:dr|doktor)\M\.?', 'Dr.', 'gi'),
      'Dr\.(?=[[:alpha:]])', 'Dr. ', 'g'
    ) AS v,
    m
  FROM rm_quotes
),

-- 3) legal forms: brand = standardize; nimi = remove (case-insensitive)
lf1 AS ( -- Osaühing
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mOsaühing\M\.?', 'OÜ', 'gi')
              ELSE regexp_replace(v, '\mOsaühing\M\.?', '',   'gi') END AS v, m
  FROM titles
),
lf2 AS ( -- OÜ
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mOÜ\M\.?', 'OÜ', 'gi')
              ELSE regexp_replace(v, '\mOÜ\M\.?', '',   'gi') END AS v, m
  FROM lf1
),
lf3 AS ( -- Aktsiaselts
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mAktsiaselts\M\.?', 'AS', 'gi')
              ELSE regexp_replace(v, '\mAktsiaselts\M\.?', '',   'gi') END AS v, m
  FROM lf2
),
lf4 AS ( -- AS
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mAS\M\.?', 'AS', 'gi')
              ELSE regexp_replace(v, '\mAS\M\.?', '',   'gi') END AS v, m
  FROM lf3
),
lf5 AS ( -- Sihtasutus
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mSihtasutus\M\.?', 'SA', 'gi')
              ELSE regexp_replace(v, '\mSihtasutus\M\.?', '',   'gi') END AS v, m
  FROM lf4
),
lf6 AS ( -- SA
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mSA\M\.?', 'SA', 'gi')
              ELSE regexp_replace(v, '\mSA\M\.?', '',   'gi') END AS v, m
  FROM lf5
),
lf7 AS ( -- Usaldusühing
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mUsaldusühing\M\.?', 'UÜ', 'gi')
              ELSE regexp_replace(v, '\mUsaldusühing\M\.?', '',   'gi') END AS v, m
  FROM lf6
),
lf8 AS ( -- UÜ
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mUÜ\M\.?', 'UÜ', 'gi')
              ELSE regexp_replace(v, '\mUÜ\M\.?', '',   'gi') END AS v, m
  FROM lf7
),
lf9 AS ( -- Täisühing
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mTäisühing\M\.?', 'TÜ', 'gi')
              ELSE regexp_replace(v, '\mTäisühing\M\.?', '',   'gi') END AS v, m
  FROM lf8
),
lf10 AS ( -- TÜ
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mTÜ\M\.?', 'TÜ', 'gi')
              ELSE regexp_replace(v, '\mTÜ\M\.?', '',   'gi') END AS v, m
  FROM lf9
),
lf11 AS ( -- FIE
  SELECT CASE WHEN m='brand' THEN regexp_replace(v, '\mFIE\M\.?', 'FIE', 'gi')
              ELSE regexp_replace(v, '\mFIE\M\.?', '',   'gi') END AS v, m
  FROM lf10
),

-- 4) spacing & punctuation (preserve dots for initials like A.M.V.K.)
collapse AS (
  SELECT btrim(
           regexp_replace(
             regexp_replace(v, '[\s,;:]+' , ' ', 'g'),  -- note: no dot here
             '\s{2,}', ' ', 'g'
           )
         ) AS v, m
  FROM lf11
),

-- 5) token-wise casing:
--    - keep tokens length <= 3 as-is (no lowercasing)
--    - keep tokens containing "." or "&" as-is (e.g., A&M, A.Randmets)
--    - otherwise InitCap words longer than 3 chars
tc AS (
  SELECT (
    SELECT string_agg(
             CASE
               WHEN length(tok) <= 3 THEN tok
               WHEN tok ~ '[.&]'      THEN tok
               WHEN length(tok) > 3   THEN initcap(tok)
               ELSE tok
             END,
             ' '
           )
    FROM regexp_split_to_table(v, '\s+') AS tok
  ) AS v, m
  FROM collapse
)

SELECT COALESCE((SELECT v FROM tc), '');
$BODY$;

ALTER FUNCTION xxx.norm_compname(text, text)
    OWNER TO rab_tootmine;

GRANT EXECUTE ON FUNCTION xxx.norm_compname(text, text) TO PUBLIC;

GRANT EXECUTE ON FUNCTION xxx.norm_compname(text, text) TO rab_ro;

GRANT EXECUTE ON FUNCTION xxx.norm_compname(text, text) TO rab_rw WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION xxx.norm_compname(text, text) TO rab_tootmine;

COMMENT ON FUNCTION xxx.norm_compname(text, text)
    IS 'Normalizes Estonian company names by:
 • Stripping quotes
 • Normalizing titles (dr/doktor → Dr.)
 • Removing or standardizing legal forms (OÜ, AS, SA, etc.)
 • Cleaning spaces/punctuation and applying consistent casing.
Use mode=''nimi'' to remove legal forms, mode=''brand'' to keep them standardized.';

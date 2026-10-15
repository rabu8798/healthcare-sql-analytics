-- =============================================================
-- 01 · Living patient population by age band and gender
-- Business question: What does our active patient panel look like?
-- Techniques: CASE bucketing, conditional aggregation, as-of date
-- Note: Synthea data ends Nov 2021, so ages are calculated as of the
--       last encounter date in the data rather than today.
-- =============================================================
USE synthea;

WITH as_of AS (
    SELECT DATE(MAX(start_ts)) AS as_of_date FROM encounters
),
ages AS (
    SELECT p.patient_id,
           p.gender,
           TIMESTAMPDIFF(YEAR, p.birthdate, a.as_of_date) AS age
    FROM patients p
    CROSS JOIN as_of a
    WHERE p.deathdate IS NULL
)
SELECT
    CASE
        WHEN age < 18 THEN '0-17'
        WHEN age < 35 THEN '18-34'
        WHEN age < 50 THEN '35-49'
        WHEN age < 65 THEN '50-64'
        ELSE '65+'
    END                                   AS age_band,
    SUM(gender = 'F')                     AS female,
    SUM(gender = 'M')                     AS male,
    COUNT(*)                              AS total,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_panel
FROM ages
GROUP BY age_band
ORDER BY age_band;

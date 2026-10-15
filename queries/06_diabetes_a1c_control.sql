-- =============================================================
-- 06 · Diabetes registry: most recent HbA1c and control status
-- Business question: Which diabetic patients are out of control
--                    (latest HbA1c > 9%) and need outreach?
-- Techniques: ROW_NUMBER() to get the latest lab per patient,
--             CTE chaining, LOINC code filtering (4548-4)
-- =============================================================
USE synthea;

WITH diabetic AS (
    SELECT DISTINCT c.patient_id
    FROM conditions c
    JOIN patients p ON p.patient_id = c.patient_id
    WHERE c.code = '44054006'            -- SNOMED: Diabetes
      AND p.deathdate IS NULL
),
latest_a1c AS (
    SELECT
        o.patient_id,
        o.obs_ts,
        CAST(o.value AS DECIMAL(5,1)) AS a1c,
        ROW_NUMBER() OVER (PARTITION BY o.patient_id
                           ORDER BY o.obs_ts DESC) AS rn
    FROM observations o
    JOIN diabetic d ON d.patient_id = o.patient_id
    WHERE o.code = '4548-4'              -- LOINC: Hemoglobin A1c
)
SELECT
    CASE
        WHEN a1c IS NULL THEN '4. No A1c on file'
        WHEN a1c < 7.0   THEN '1. Controlled (<7%)'
        WHEN a1c <= 9.0  THEN '2. Above goal (7-9%)'
        ELSE                  '3. Poor control (>9%)'
    END                                  AS control_status,
    COUNT(*)                             AS patients,
    ROUND(AVG(a1c), 1)                   AS avg_latest_a1c
FROM diabetic d
LEFT JOIN latest_a1c l
       ON l.patient_id = d.patient_id AND l.rn = 1
GROUP BY control_status
ORDER BY control_status;

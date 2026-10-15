-- =============================================================
-- 04 · 30-day inpatient readmission rate by year
-- Business question: How often are patients readmitted within 30
--                    days of an inpatient discharge? (A core CMS
--                    quality measure.)
-- Techniques: LEAD() window function partitioned by patient,
--             DATEDIFF on discharge -> next admit
-- Simplification: counts any inpatient return; the CMS measure adds
--             exclusions (planned admissions, transfers, etc.)
-- =============================================================
USE synthea;

WITH inpatient AS (
    SELECT
        patient_id,
        encounter_id,
        start_ts                                        AS admit_ts,
        stop_ts                                         AS discharge_ts,
        LEAD(start_ts) OVER (PARTITION BY patient_id
                             ORDER BY start_ts)         AS next_admit_ts
    FROM encounters
    WHERE encounter_class = 'inpatient'
),
flagged AS (
    SELECT
        YEAR(discharge_ts) AS discharge_year,
        CASE WHEN next_admit_ts IS NOT NULL
              AND DATEDIFF(next_admit_ts, discharge_ts) BETWEEN 0 AND 30
             THEN 1 ELSE 0 END AS readmit_30d
    FROM inpatient
)
SELECT
    discharge_year,
    COUNT(*)                          AS discharges,
    SUM(readmit_30d)                  AS readmissions_30d,
    ROUND(100 * AVG(readmit_30d), 1)  AS readmit_rate_pct
FROM flagged
WHERE discharge_year >= 2015
GROUP BY discharge_year
ORDER BY discharge_year;

-- -------------------------------------------------------------
-- 04b · Who drives the readmissions?
-- The 2019 spike above looked suspicious, so this query checks
-- whether a small number of patients account for most of it.
-- Finding: a handful of patients with recurring scheduled
-- admissions produce most "readmissions" — exactly the kind of
-- case the real CMS measure removes as "planned readmissions".
-- -------------------------------------------------------------
WITH inpatient AS (
    SELECT patient_id, stop_ts AS discharge_ts,
           LEAD(start_ts) OVER (PARTITION BY patient_id ORDER BY start_ts) AS next_admit_ts
    FROM encounters
    WHERE encounter_class = 'inpatient'
),
per_patient AS (
    SELECT patient_id,
           SUM(DATEDIFF(next_admit_ts, discharge_ts) BETWEEN 0 AND 30) AS readmits
    FROM inpatient
    WHERE YEAR(discharge_ts) BETWEEN 2015 AND 2021
    GROUP BY patient_id
    HAVING readmits > 0
),
ranked AS (
    SELECT patient_id, readmits,
           ROW_NUMBER() OVER (ORDER BY readmits DESC)                     AS patient_rank,
           SUM(readmits) OVER (ORDER BY readmits DESC, patient_id)        AS running_total,
           SUM(readmits) OVER ()                                          AS grand_total
    FROM per_patient
)
SELECT patient_rank,
       LEFT(patient_id, 8)                          AS patient_ref,
       readmits,
       ROUND(100 * running_total / grand_total, 1)  AS cumulative_pct_of_all_readmits
FROM ranked
WHERE patient_rank <= 10
ORDER BY patient_rank;

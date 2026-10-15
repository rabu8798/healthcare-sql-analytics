-- =============================================================
-- 08 · Provider workload and specialty benchmarking (2021)
-- Business question: How does each provider's volume compare with
--                    peers in the same specialty?
-- Techniques: multiple window functions (AVG OVER, PERCENT_RANK),
--             multi-table JOIN across providers/organizations
-- =============================================================
USE synthea;

WITH workload AS (
    SELECT
        pr.provider_id,
        pr.name           AS provider,
        pr.speciality,
        o.name            AS organization,
        COUNT(*)          AS encounters_2021,
        COUNT(DISTINCT e.patient_id) AS unique_patients
    FROM encounters e
    JOIN providers     pr ON pr.provider_id = e.provider_id
    JOIN organizations o  ON o.organization_id = pr.organization_id
    WHERE e.start_ts >= '2021-01-01'
    GROUP BY pr.provider_id, pr.name, pr.speciality, o.name
)
SELECT
    provider,
    speciality,
    organization,
    encounters_2021,
    unique_patients,
    ROUND(AVG(encounters_2021) OVER (PARTITION BY speciality), 1)        AS specialty_avg,
    ROUND(100 * PERCENT_RANK() OVER (PARTITION BY speciality
                                     ORDER BY encounters_2021), 0)       AS specialty_percentile
FROM workload
ORDER BY encounters_2021 DESC
LIMIT 15;

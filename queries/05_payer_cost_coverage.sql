-- =============================================================
-- 05 · Encounter cost and payer coverage by payer
-- Business question: Which payers cover the most volume, and how
--                    much cost is left to patients?
-- Techniques: LEFT JOIN, COALESCE for uninsured, ratio math,
--             RANK() window function
-- =============================================================
USE synthea;

SELECT
    COALESCE(p.name, 'Unknown')                          AS payer,
    COUNT(*)                                             AS encounters,
    ROUND(SUM(e.total_claim_cost), 0)                    AS total_claim_cost,
    ROUND(SUM(e.payer_coverage), 0)                      AS paid_by_payer,
    ROUND(SUM(e.total_claim_cost - e.payer_coverage), 0) AS patient_responsibility,
    ROUND(100 * SUM(e.payer_coverage)
          / NULLIF(SUM(e.total_claim_cost), 0), 1)       AS coverage_pct,
    RANK() OVER (ORDER BY COUNT(*) DESC)                 AS volume_rank
FROM encounters e
LEFT JOIN payers p ON p.payer_id = e.payer_id
WHERE e.start_ts >= '2019-01-01'
GROUP BY p.name
ORDER BY encounters DESC;

-- =============================================================
-- 03 · Most prevalent active chronic conditions (living patients)
-- Business question: Which ongoing conditions drive our panel's
--                    care needs?
-- Techniques: filtering "active" records (no stop date), distinct
--             patient counts, prevalence rate via scalar subquery
-- =============================================================
USE synthea;

SELECT
    c.code,
    c.description,
    COUNT(DISTINCT c.patient_id)                                    AS patients,
    ROUND(100 * COUNT(DISTINCT c.patient_id)
          / (SELECT COUNT(*) FROM patients WHERE deathdate IS NULL), 1) AS prevalence_pct
FROM conditions c
JOIN patients p ON p.patient_id = c.patient_id
WHERE c.stop_date IS NULL          -- still active
  AND p.deathdate IS NULL          -- living patients only
  AND c.description NOT LIKE '%(finding)%'
  AND c.description NOT LIKE '%(situation)%'
  AND c.description NOT LIKE '%(person)%'
GROUP BY c.code, c.description
ORDER BY patients DESC
LIMIT 15;

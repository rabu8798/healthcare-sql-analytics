-- =============================================================
-- 02 · Monthly encounter volume by setting, last 12 months
-- Business question: How is utilization trending by care setting?
-- Techniques: date truncation, conditional aggregation (pivot)
-- =============================================================
USE synthea;

WITH bounds AS (
    SELECT DATE_SUB(DATE_FORMAT(MAX(start_ts), '%Y-%m-01'), INTERVAL 11 MONTH) AS start_month
    FROM encounters
)
SELECT
    DATE_FORMAT(e.start_ts, '%Y-%m')              AS month,
    SUM(e.encounter_class = 'wellness')           AS wellness,
    SUM(e.encounter_class = 'ambulatory')         AS ambulatory,
    SUM(e.encounter_class = 'outpatient')         AS outpatient,
    SUM(e.encounter_class = 'urgentcare')         AS urgent_care,
    SUM(e.encounter_class = 'emergency')          AS emergency,
    SUM(e.encounter_class = 'inpatient')          AS inpatient,
    COUNT(*)                                      AS total
FROM encounters e
CROSS JOIN bounds b
WHERE e.start_ts >= b.start_month
GROUP BY month
ORDER BY month;

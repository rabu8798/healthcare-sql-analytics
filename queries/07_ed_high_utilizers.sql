-- =============================================================
-- 07 · Emergency department high utilizers (last 24 months)
-- Business question: Which patients use the ED most often, and
--                    what do they have in common? (Care management
--                    teams use lists like this for outreach.)
-- Techniques: HAVING, GROUP_CONCAT, correlated subquery, as-of date
-- =============================================================
USE synthea;

WITH as_of AS (SELECT MAX(start_ts) AS as_of_ts FROM encounters),
ed AS (
    SELECT e.patient_id, COUNT(*) AS ed_visits,
           MAX(e.start_ts) AS last_ed_visit
    FROM encounters e CROSS JOIN as_of a
    WHERE e.encounter_class = 'emergency'
      AND e.start_ts >= DATE_SUB(a.as_of_ts, INTERVAL 24 MONTH)
    GROUP BY e.patient_id
    HAVING COUNT(*) >= 3
)
SELECT
    LEFT(ed.patient_id, 8)                                  AS patient_ref,
    TIMESTAMPDIFF(YEAR, p.birthdate, ed.last_ed_visit)      AS age,
    p.gender,
    ed.ed_visits,
    DATE(ed.last_ed_visit)                                  AS last_ed_visit,
    (SELECT COUNT(DISTINCT c.code) FROM conditions c
      WHERE c.patient_id = ed.patient_id
        AND c.stop_date IS NULL)                            AS active_conditions,
    (SELECT GROUP_CONCAT(DISTINCT e2.reason_description ORDER BY e2.reason_description SEPARATOR '; ')
       FROM encounters e2
      WHERE e2.patient_id = ed.patient_id
        AND e2.encounter_class = 'emergency'
        AND e2.reason_description IS NOT NULL)              AS ed_reasons
FROM ed
JOIN patients p ON p.patient_id = ed.patient_id
ORDER BY ed.ed_visits DESC, last_ed_visit DESC
LIMIT 15;

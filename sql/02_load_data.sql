-- =============================================================
-- Load Synthea CSVs into the schema.
-- Run from the repo root so the relative paths resolve:
--   mysql --local-infile=1 -u root -p < sql/02_load_data.sql
-- (Server side, once:  SET GLOBAL local_infile = 1;)
-- =============================================================
USE synthea;

LOAD DATA LOCAL INFILE 'data/csv/patients.csv' INTO TABLE patients
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(patient_id, birthdate, @deathdate, @ssn, @drivers, @passport, @prefix, first_name, last_name,
 @suffix, @maiden, @marital, race, ethnicity, gender, @birthplace, @address, city, state, county,
 zip, @lat, @lon, healthcare_expenses, healthcare_coverage)
SET deathdate = NULLIF(@deathdate, ''),
    marital   = NULLIF(@marital, '');

LOAD DATA LOCAL INFILE 'data/csv/organizations.csv' INTO TABLE organizations
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(organization_id, name, @address, city, state, zip, @lat, @lon, @phone, @revenue, utilization);

LOAD DATA LOCAL INFILE 'data/csv/providers.csv' INTO TABLE providers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(provider_id, organization_id, name, gender, speciality, @address, @city, @state, @zip, @lat, @lon, utilization);

LOAD DATA LOCAL INFILE 'data/csv/payers.csv' INTO TABLE payers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(payer_id, name, @address, @city, @state, @zip, @phone, amount_covered, amount_uncovered,
 @revenue, @ce, @ue, @cm, @um, @cp, @up, @ci, @ui, unique_customers, @qols, @mm);

LOAD DATA LOCAL INFILE 'data/csv/encounters.csv' INTO TABLE encounters
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(encounter_id, @start, @stop, patient_id, organization_id, provider_id, payer_id, encounter_class,
 code, description, base_encounter_cost, total_claim_cost, payer_coverage, @reason_code, @reason_desc)
SET start_ts           = STR_TO_DATE(@start, '%Y-%m-%dT%H:%i:%sZ'),
    stop_ts            = STR_TO_DATE(NULLIF(@stop, ''), '%Y-%m-%dT%H:%i:%sZ'),
    reason_code        = NULLIF(@reason_code, ''),
    reason_description = NULLIF(TRIM(TRAILING '\r' FROM @reason_desc), '');

LOAD DATA LOCAL INFILE 'data/csv/conditions.csv' INTO TABLE conditions
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(start_date, @stop, patient_id, encounter_id, code, description)
SET stop_date = NULLIF(@stop, '');

LOAD DATA LOCAL INFILE 'data/csv/medications.csv' INTO TABLE medications
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@start, @stop, patient_id, payer_id, encounter_id, code, description, base_cost, payer_coverage,
 dispenses, total_cost, @reason_code, @reason_desc)
SET start_ts           = STR_TO_DATE(@start, '%Y-%m-%dT%H:%i:%sZ'),
    stop_ts            = STR_TO_DATE(NULLIF(@stop, ''), '%Y-%m-%dT%H:%i:%sZ'),
    reason_code        = NULLIF(@reason_code, ''),
    reason_description = NULLIF(TRIM(TRAILING '\r' FROM @reason_desc), '');

LOAD DATA LOCAL INFILE 'data/csv/observations.csv' INTO TABLE observations
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@ts, patient_id, @enc, @category, code, description, value, units, @vtype)
SET obs_ts       = STR_TO_DATE(@ts, '%Y-%m-%dT%H:%i:%sZ'),
    encounter_id = NULLIF(@enc, ''),
    category     = NULLIF(@category, ''),
    value_type   = TRIM(TRAILING '\r' FROM @vtype);

-- Row-count sanity check
SELECT 'patients' AS tbl, COUNT(*) AS n FROM patients
UNION ALL SELECT 'organizations', COUNT(*) FROM organizations
UNION ALL SELECT 'providers',     COUNT(*) FROM providers
UNION ALL SELECT 'payers',        COUNT(*) FROM payers
UNION ALL SELECT 'encounters',    COUNT(*) FROM encounters
UNION ALL SELECT 'conditions',    COUNT(*) FROM conditions
UNION ALL SELECT 'medications',   COUNT(*) FROM medications
UNION ALL SELECT 'observations',  COUNT(*) FROM observations;

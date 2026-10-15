-- =============================================================
-- Healthcare SQL Analytics — Schema
-- Database: MySQL 8 / MariaDB 10.6+
-- Source:   Synthea synthetic patient data (CSV export, Nov 2021 sample)
-- Note:     All data is synthetic. Identifier columns (SSN, driver's
--           license, passport) are deliberately NOT loaded — the same
--           minimum-necessary habit you'd apply to real PHI.
-- =============================================================

DROP DATABASE IF EXISTS synthea;
CREATE DATABASE synthea;
USE synthea;

CREATE TABLE patients (
    patient_id          CHAR(36)      PRIMARY KEY,
    birthdate           DATE          NOT NULL,
    deathdate           DATE          NULL,
    first_name          VARCHAR(50),
    last_name           VARCHAR(50),
    marital             CHAR(1),
    race                VARCHAR(20),
    ethnicity           VARCHAR(20),
    gender              CHAR(1),
    city                VARCHAR(50),
    state               VARCHAR(30),
    county              VARCHAR(50),
    zip                 VARCHAR(10),
    healthcare_expenses DECIMAL(14,2),
    healthcare_coverage DECIMAL(14,2)
);

CREATE TABLE organizations (
    organization_id CHAR(36) PRIMARY KEY,
    name            VARCHAR(120),
    city            VARCHAR(50),
    state           CHAR(2),
    zip             VARCHAR(10),
    utilization     INT
);

CREATE TABLE providers (
    provider_id     CHAR(36) PRIMARY KEY,
    organization_id CHAR(36),
    name            VARCHAR(80),
    gender          CHAR(1),
    speciality      VARCHAR(60),
    utilization     INT,
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id)
);

CREATE TABLE payers (
    payer_id          CHAR(36) PRIMARY KEY,
    name              VARCHAR(60),
    amount_covered    DECIMAL(14,2),
    amount_uncovered  DECIMAL(14,2),
    unique_customers  INT
);

CREATE TABLE encounters (
    encounter_id        CHAR(36) PRIMARY KEY,
    start_ts            DATETIME NOT NULL,
    stop_ts             DATETIME,
    patient_id          CHAR(36) NOT NULL,
    organization_id     CHAR(36),
    provider_id         CHAR(36),
    payer_id            CHAR(36),
    encounter_class     VARCHAR(20),
    code                VARCHAR(20),
    description         VARCHAR(200),
    base_encounter_cost DECIMAL(12,2),
    total_claim_cost    DECIMAL(12,2),
    payer_coverage      DECIMAL(12,2),
    reason_code         VARCHAR(20),
    reason_description  VARCHAR(200),
    FOREIGN KEY (patient_id)      REFERENCES patients(patient_id),
    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id),
    FOREIGN KEY (provider_id)     REFERENCES providers(provider_id),
    FOREIGN KEY (payer_id)        REFERENCES payers(payer_id),
    INDEX ix_enc_patient_start (patient_id, start_ts),
    INDEX ix_enc_class (encounter_class)
);

CREATE TABLE conditions (
    start_date   DATE,
    stop_date    DATE,
    patient_id   CHAR(36),
    encounter_id CHAR(36),
    code         VARCHAR(20),
    description  VARCHAR(200),
    INDEX ix_cond_patient (patient_id),
    INDEX ix_cond_code (code)
);

CREATE TABLE medications (
    start_ts           DATETIME,
    stop_ts            DATETIME,
    patient_id         CHAR(36),
    payer_id           CHAR(36),
    encounter_id       CHAR(36),
    code               VARCHAR(20),
    description        VARCHAR(255),
    base_cost          DECIMAL(12,2),
    payer_coverage     DECIMAL(12,2),
    dispenses          INT,
    total_cost         DECIMAL(14,2),
    reason_code        VARCHAR(20),
    reason_description VARCHAR(200),
    INDEX ix_med_patient (patient_id)
);

CREATE TABLE observations (
    obs_ts       DATETIME,
    patient_id   CHAR(36),
    encounter_id CHAR(36),
    category     VARCHAR(30),
    code         VARCHAR(20),
    description  VARCHAR(255),
    value        VARCHAR(255),
    units        VARCHAR(40),
    value_type   VARCHAR(10),
    INDEX ix_obs_patient_code (patient_id, code)
);

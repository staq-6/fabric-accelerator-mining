-- =============================================================================
-- Mining Accelerator — Shifts Table
-- Normal table — mirrored to Microsoft Fabric via Snowflake Mirroring
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_REF;

CREATE OR REPLACE TABLE SHIFTS (
    shift_id            VARCHAR(36)     NOT NULL DEFAULT UUID_STRING()  COMMENT 'Surrogate key',
    shift_code          VARCHAR(20)     NOT NULL                        COMMENT 'Short code e.g. DAY-A, NIGHT-B',
    shift_name          VARCHAR(50)     NOT NULL                        COMMENT 'Descriptive name e.g. Day Shift A',
    shift_type          VARCHAR(10)     NOT NULL                        COMMENT 'DAY | NIGHT | AFTERNOON',
    site_code           VARCHAR(20)     NOT NULL,
    start_time          TIME            NOT NULL                        COMMENT 'Nominal shift start time (local)',
    end_time            TIME            NOT NULL                        COMMENT 'Nominal shift end time (local)',
    duration_hours      NUMBER(4,2)     NOT NULL                        COMMENT 'Planned duration in hours',
    crew_code           VARCHAR(10)                                     COMMENT 'Crew rotation identifier (A/B/C/D)',
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_shifts PRIMARY KEY (shift_id),
    CONSTRAINT uq_shift_code UNIQUE (shift_code, site_code)
)
COMMENT = 'Shift configuration and schedule definitions';

ALTER TABLE SHIFTS SET CHANGE_TRACKING = TRUE;


-- =============================================================================
-- Shift Instances — actual scheduled shift occurrences
-- =============================================================================

CREATE OR REPLACE TABLE SHIFT_INSTANCES (
    shift_instance_id   VARCHAR(36)     NOT NULL DEFAULT UUID_STRING(),
    shift_id            VARCHAR(36)     NOT NULL,
    shift_date          DATE            NOT NULL                        COMMENT 'Calendar date of the shift',
    actual_start_ts     TIMESTAMP_NTZ                                   COMMENT 'Actual start timestamp',
    actual_end_ts       TIMESTAMP_NTZ                                   COMMENT 'Actual end timestamp',
    supervisor_id       VARCHAR(36)                                     COMMENT 'FK to OPERATORS.operator_id',
    planned_crew_size   INT,
    actual_crew_size    INT,
    weather_condition   VARCHAR(50)                                     COMMENT 'Clear | Dusty | Rain | Fog | Extreme Heat | Wet Ground',
    blast_scheduled     BOOLEAN         DEFAULT FALSE,
    blast_actual        BOOLEAN         DEFAULT FALSE,
    shift_notes         VARCHAR(2000),
    shift_status        VARCHAR(20)     NOT NULL DEFAULT 'PLANNED'      COMMENT 'PLANNED | IN_PROGRESS | COMPLETED | CANCELLED',
    created_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_shift_instances PRIMARY KEY (shift_instance_id),
    CONSTRAINT uq_shift_date UNIQUE (shift_id, shift_date),
    CONSTRAINT fk_shift_instances_shift FOREIGN KEY (shift_id) REFERENCES SHIFTS(shift_id)
)
COMMENT = 'Actual scheduled and completed shift instances';

ALTER TABLE SHIFT_INSTANCES SET CHANGE_TRACKING = TRUE;

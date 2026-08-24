-- =============================================================================
-- Mining Accelerator — Operators Table
-- Normal table — mirrored to Microsoft Fabric via Snowflake Mirroring
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_REF;

CREATE OR REPLACE TABLE OPERATORS (
    operator_id         VARCHAR(36)     NOT NULL DEFAULT UUID_STRING(),
    operator_code       VARCHAR(20)     NOT NULL                        COMMENT 'Short operator code e.g. OP-0042',
    first_name          VARCHAR(50)     NOT NULL,
    last_name           VARCHAR(50)     NOT NULL,
    employee_number     VARCHAR(20)                                     COMMENT 'HR system employee number',
    job_title           VARCHAR(100),
    operator_class      VARCHAR(50)     NOT NULL                        COMMENT 'HAUL_TRUCK_OPERATOR | EXCAVATOR_OPERATOR | DOZER_OPERATOR | DRILL_OPERATOR | MAINTENANCE_TECH | SUPERVISOR | BLASTER',
    competency_level    VARCHAR(20)     NOT NULL DEFAULT 'STANDARD'     COMMENT 'TRAINEE | STANDARD | SENIOR | MASTER',
    site_code           VARCHAR(20)     NOT NULL,
    crew_code           VARCHAR(10),
    hire_date           DATE,
    total_hours_operated NUMBER(10,2)   DEFAULT 0                       COMMENT 'Cumulative hours operated (updated periodically)',
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    -- Licences and certifications (stored as array JSON)
    certifications      VARIANT                                         COMMENT 'JSON array of certification codes and expiry dates',
    -- Authorised equipment classes (JSON array)
    authorised_equipment VARIANT                                        COMMENT 'JSON array of equipment_class values this operator is authorised for',
    created_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_operators PRIMARY KEY (operator_id),
    CONSTRAINT uq_operator_code UNIQUE (operator_code, site_code)
)
COMMENT = 'Workforce registry — operators and maintenance personnel';

ALTER TABLE OPERATORS SET CHANGE_TRACKING = TRUE;

-- Operator shift assignments
CREATE OR REPLACE TABLE OPERATOR_SHIFT_ASSIGNMENTS (
    assignment_id       VARCHAR(36)     NOT NULL DEFAULT UUID_STRING(),
    shift_instance_id   VARCHAR(36)     NOT NULL,
    operator_id         VARCHAR(36)     NOT NULL,
    equipment_id        VARCHAR(36)                                     COMMENT 'Pre-assigned equipment for this shift (may change during shift)',
    role_in_shift       VARCHAR(50)                                     COMMENT 'OPERATOR | SUPERVISOR | RELIEF | MAINTENANCE',
    assigned_at         TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_operator_shift PRIMARY KEY (assignment_id),
    CONSTRAINT uq_operator_shift UNIQUE (shift_instance_id, operator_id)
)
COMMENT = 'Assignment of operators to shift instances and equipment';

ALTER TABLE OPERATOR_SHIFT_ASSIGNMENTS SET CHANGE_TRACKING = TRUE;

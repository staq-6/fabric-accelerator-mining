-- =============================================================================
-- Mining Accelerator — Maintenance Records Table
-- Normal table — mirrored to Microsoft Fabric via Snowflake Mirroring
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_HIST;

CREATE OR REPLACE TABLE MAINTENANCE_RECORDS (
    maintenance_id          VARCHAR(36)     NOT NULL DEFAULT UUID_STRING(),
    work_order_number       VARCHAR(30)     NOT NULL                        COMMENT 'CMMS work order number',
    equipment_id            VARCHAR(36)     NOT NULL,
    site_code               VARCHAR(20)     NOT NULL,

    -- Classification
    maintenance_type        VARCHAR(30)     NOT NULL                        COMMENT 'PREVENTIVE | CORRECTIVE | PREDICTIVE | BREAKDOWN | INSPECTION | OVERHAUL',
    maintenance_category    VARCHAR(50)                                     COMMENT 'MECHANICAL | ELECTRICAL | HYDRAULIC | STRUCTURAL | TYRES | LUBRICATION | INSPECTION',
    priority                VARCHAR(10)     NOT NULL DEFAULT 'MEDIUM'       COMMENT 'CRITICAL | HIGH | MEDIUM | LOW',
    failure_mode            VARCHAR(100)                                     COMMENT 'Primary failure mode/cause description',
    failure_code            VARCHAR(20)                                      COMMENT 'CMMS failure code',
    fault_description       VARCHAR(2000),

    -- Timing
    fault_reported_ts       TIMESTAMP_NTZ                                    COMMENT 'When fault was reported',
    work_started_ts         TIMESTAMP_NTZ,
    work_completed_ts       TIMESTAMP_NTZ,
    equipment_returned_ts   TIMESTAMP_NTZ                                    COMMENT 'When equipment returned to service',
    planned_duration_hrs    NUMBER(8,2),
    actual_duration_hrs     NUMBER(8,2)                                      COMMENT 'Total time equipment was unavailable',
    repair_time_hrs         NUMBER(8,2)                                      COMMENT 'Active repair time (excludes waiting for parts)',

    -- Resource
    lead_technician_id      VARCHAR(36)                                      COMMENT 'FK to OPERATORS.operator_id',
    technician_ids          VARIANT                                          COMMENT 'JSON array of all technician operator_ids',
    contractor_company      VARCHAR(100),

    -- Parts and cost
    parts_used              VARIANT                                          COMMENT 'JSON array of {part_number, description, quantity, unit_cost}',
    total_parts_cost        NUMBER(14,2),
    total_labour_cost       NUMBER(14,2),
    total_cost              NUMBER(14,2),

    -- Equipment state at time of maintenance
    engine_hours_at_event   NUMBER(10,2)                                     COMMENT 'Engine hours reading when fault occurred',
    odometer_km_at_event    NUMBER(10,2),

    -- Outcomes
    maintenance_status      VARCHAR(20)     NOT NULL DEFAULT 'OPEN'          COMMENT 'OPEN | IN_PROGRESS | PENDING_PARTS | COMPLETED | CANCELLED',
    root_cause              VARCHAR(2000),
    corrective_action       VARCHAR(2000),
    is_repeat_failure       BOOLEAN         DEFAULT FALSE,
    related_maintenance_id  VARCHAR(36)                                       COMMENT 'Previous maintenance event for repeat failure tracing',

    -- Audit
    created_at              TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    updated_at              TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    created_by              VARCHAR(100),

    CONSTRAINT pk_maintenance PRIMARY KEY (maintenance_id),
    CONSTRAINT uq_work_order UNIQUE (work_order_number)
)
COMMENT = 'Historical maintenance records, work orders, and breakdown events';

ALTER TABLE MAINTENANCE_RECORDS SET CHANGE_TRACKING = TRUE;

-- =============================================================================
-- Mining Accelerator — Equipment Master Table
-- Normal table — mirrored to Microsoft Fabric via Snowflake Mirroring
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_REF;

CREATE OR REPLACE TABLE EQUIPMENT (
    equipment_id        VARCHAR(36)     NOT NULL DEFAULT UUID_STRING()  COMMENT 'Surrogate key (UUID)',
    equipment_code      VARCHAR(20)     NOT NULL                        COMMENT 'Short operational code e.g. EX-001, HD-042',
    equipment_name      VARCHAR(100)    NOT NULL                        COMMENT 'Full descriptive name',
    equipment_class     VARCHAR(50)     NOT NULL                        COMMENT 'EXCAVATOR | HAUL_TRUCK | DOZER | GRADER | CONVEYOR_BELT | CRUSHER | DRILL | WATER_TRUCK | FEEDER | SCREEN',
    equipment_type      VARCHAR(50)     NOT NULL                        COMMENT 'Specific model/type within class e.g. 793F, PC8000',
    manufacturer        VARCHAR(100)                                    COMMENT 'OEM manufacturer',
    model_number        VARCHAR(50)                                     COMMENT 'OEM model number',
    serial_number       VARCHAR(50)                                     COMMENT 'OEM serial number',
    year_manufactured   INT                                             COMMENT 'Year of manufacture',
    year_commissioned   INT                                             COMMENT 'Year equipment was commissioned on site',
    site_code           VARCHAR(20)     NOT NULL                        COMMENT 'Mine site code',
    fleet_number        VARCHAR(20)                                     COMMENT 'Fleet management number',

    -- Capacity specs
    payload_capacity_t  NUMBER(10,2)                                    COMMENT 'Rated payload capacity in tonnes (vehicles)',
    bucket_capacity_m3  NUMBER(10,2)                                    COMMENT 'Bucket/dipper capacity in cubic metres (excavators)',
    belt_width_mm       INT                                             COMMENT 'Belt width in mm (conveyors)',
    belt_length_m       NUMBER(10,2)                                    COMMENT 'Belt length in metres (conveyors)',
    nominal_throughput_tph NUMBER(10,2)                                 COMMENT 'Nominal throughput in tonnes per hour (crushers/conveyors)',
    engine_power_kw     NUMBER(10,2)                                    COMMENT 'Engine/motor rated power in kW',
    fuel_type           VARCHAR(20)                                     COMMENT 'DIESEL | ELECTRIC | HYBRID | LNG',

    -- Status and classification
    equipment_status    VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE'       COMMENT 'ACTIVE | STANDBY | MAINTENANCE | DECOMMISSIONED',
    is_mobile           BOOLEAN         NOT NULL DEFAULT TRUE            COMMENT 'TRUE for vehicles/mobile plant',
    is_fixed_plant      BOOLEAN         NOT NULL DEFAULT FALSE           COMMENT 'TRUE for crushers, conveyors, feeders',
    gps_enabled         BOOLEAN         NOT NULL DEFAULT TRUE            COMMENT 'Whether GPS/telematics is fitted',
    telematics_unit_id  VARCHAR(50)                                     COMMENT 'Telematics device serial number',

    -- Maintenance thresholds
    pm_interval_hours   INT             NOT NULL DEFAULT 250             COMMENT 'Preventive maintenance interval in engine hours',
    major_service_hours INT             NOT NULL DEFAULT 2500            COMMENT 'Major service interval in engine hours',

    -- Audit
    created_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    created_by          VARCHAR(100),
    updated_by          VARCHAR(100),
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_equipment PRIMARY KEY (equipment_id),
    CONSTRAINT uq_equipment_code UNIQUE (equipment_code, site_code)
)
COMMENT = 'Master registry of all plant and mobile equipment on site';

-- Change tracking for Fabric Mirroring
ALTER TABLE EQUIPMENT SET CHANGE_TRACKING = TRUE;
-- Note: Snowflake optimises queries via micro-partitioning; secondary indexes are not supported on standard tables

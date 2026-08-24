-- =============================================================================
-- Mining Accelerator — Crusher Telemetry (Iceberg Table)
-- Stored on OneLake via Snowflake External Volume
-- Covers primary, secondary, and tertiary crushers
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_STREAM;

CREATE OR REPLACE ICEBERG TABLE CRUSHER_TELEMETRY (
    telemetry_id                STRING     NOT NULL,
    equipment_id                STRING     NOT NULL,
    equipment_code              STRING     NOT NULL,
    crusher_type                STRING     NOT NULL                    COMMENT 'PRIMARY_JAW | PRIMARY_GYRATORY | SECONDARY_CONE | TERTIARY_CONE | HPGR | SIZER | IMPACTOR',
    crusher_stage               STRING     NOT NULL                    COMMENT 'PRIMARY | SECONDARY | TERTIARY',
    location_id                 STRING,
    shift_instance_id           STRING,

    event_ts                    TIMESTAMP_LTZ   NOT NULL,
    ingestion_ts                TIMESTAMP_LTZ   NOT NULL,

    -- Operating status
    crusher_running             BOOLEAN         NOT NULL,
    availability_state          STRING     NOT NULL  COMMENT 'RUNNING | STOPPED | STANDBY | CHOKED | FAULT | MAINTENANCE',
    cavity_level_pct            NUMBER(6,2)                                 COMMENT 'Crusher cavity/chamber fill level %',
    choking_detected            BOOLEAN,

    -- Throughput
    feed_rate_tph               NUMBER(10,2)                                COMMENT 'Feed rate to crusher tph',
    product_rate_tph            NUMBER(10,2)                                COMMENT 'Product throughput tph',
    cumulative_tonnage_t        NUMBER(16,3)                                COMMENT 'Cumulative feed tonnes since commissioning',
    material_type_id            STRING,
    feed_f80_mm                 NUMBER(8,2)                                 COMMENT 'Feed F80 particle size mm',
    product_p80_mm              NUMBER(8,2)                                 COMMENT 'Product P80 particle size mm',
    reduction_ratio             NUMBER(8,3)                                 COMMENT 'Reduction ratio',

    -- Power and electrical
    main_drive_power_kw         NUMBER(10,2)    NOT NULL,
    main_drive_current_a        NUMBER(10,2),
    main_motor_temp_c           NUMBER(6,2),
    main_drive_voltage_v        NUMBER(8,2),
    specific_energy_kwh_t       NUMBER(8,4),

    -- Mechanical — gyratory / jaw specific
    css_mm                      NUMBER(8,2)                                 COMMENT 'Closed side setting mm',
    oss_mm                      NUMBER(8,2)                                 COMMENT 'Open side setting mm',
    eccentric_speed_rpm         INT,
    throw_mm                    NUMBER(6,2)                                 COMMENT 'Throw in mm',
    mantle_wear_pct             NUMBER(6,2)                                 COMMENT 'Mantle wear % of usable life',
    concave_wear_pct            NUMBER(6,2),
    liner_wear_mm               NUMBER(6,2),

    -- Lubrication
    lube_oil_pressure_kpa       NUMBER(8,2),
    lube_oil_temp_c             NUMBER(6,2),
    lube_oil_flow_lpm           NUMBER(8,2),
    lube_oil_level_pct          NUMBER(6,2),
    lube_oil_contamination_ppm  INT                                         COMMENT 'Particle count ppm in oil',

    -- Hydraulics (for CSS adjustment and tramp release)
    hydraulic_pressure_kpa      NUMBER(8,2),
    hydraulic_oil_temp_c        NUMBER(6,2),
    tramp_release_active        BOOLEAN               COMMENT 'Tramp release system active (uncrushable detected)',
    tramp_release_count         INT                   COMMENT 'Tramp release events since last reset',

    -- Vibration
    bearing_vibration_de_mm_s   NUMBER(8,3)                                COMMENT 'Drive end bearing vibration mm/s RMS',
    bearing_vibration_nde_mm_s  NUMBER(8,3)                                COMMENT 'Non-drive end bearing vibration mm/s RMS',
    frame_vibration_mm_s        NUMBER(8,3),

    -- Temperature
    bearing_temp_de_c           NUMBER(6,2),
    bearing_temp_nde_c          NUMBER(6,2),
    pinion_bearing_temp_c       NUMBER(6,2),

    -- Feeder / conveyor interface
    feed_conveyor_id            STRING                                 COMMENT 'FK to EQUIPMENT — incoming feed conveyor',
    discharge_conveyor_id       STRING                                 COMMENT 'FK to EQUIPMENT — outgoing product conveyor',
    feed_bin_level_pct          NUMBER(6,2),

    -- Alarms
    active_fault_codes          STRING,
    fault_count                 INT,
    high_priority_alarm         BOOLEAN,

    CONSTRAINT pk_crusher_telemetry PRIMARY KEY (telemetry_id)
)
    EXTERNAL_VOLUME = 'ONELAKE_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'crusher_telemetry/'
    COMMENT = 'High-frequency crusher telemetry — stored as Iceberg on OneLake'
    CLUSTER BY (equipment_id, DATE_TRUNC('hour', event_ts));

-- =============================================================================
-- Mining Accelerator — Conveyor Belt Telemetry (Iceberg Table)
-- Stored on OneLake via Snowflake External Volume
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_STREAM;

CREATE OR REPLACE ICEBERG TABLE CONVEYOR_BELT_TELEMETRY (
    telemetry_id            STRING     NOT NULL,
    equipment_id            STRING     NOT NULL                        COMMENT 'FK to EQUIPMENT (conveyor)',
    equipment_code          STRING     NOT NULL,
    location_id             STRING                                     COMMENT 'FK to LOCATIONS',
    shift_instance_id       STRING,

    event_ts                TIMESTAMP_LTZ   NOT NULL,
    ingestion_ts            TIMESTAMP_LTZ   NOT NULL,

    -- Belt operations
    belt_running            BOOLEAN         NOT NULL,
    belt_speed_ms           NUMBER(6,3)     NOT NULL              COMMENT 'Belt surface speed in m/s',
    belt_speed_setpoint_ms  NUMBER(6,3)                                     COMMENT 'Speed setpoint',
    belt_direction          STRING               COMMENT 'FORWARD | REVERSE',

    -- Load and throughput
    belt_load_tpm           NUMBER(10,3)                                    COMMENT 'Instantaneous load in tonnes per metre',
    throughput_tph          NUMBER(10,2)                                    COMMENT 'Instantaneous throughput tonnes per hour',
    tonnage_carried_t       NUMBER(14,3)                                    COMMENT 'Cumulative tonnage since last reset',
    material_type_id        STRING                                     COMMENT 'Material currently on belt',

    -- Power and drive
    drive_power_kw          NUMBER(10,2)                                    COMMENT 'Total drive power draw kW',
    drive_current_a         NUMBER(10,2),
    drive_voltage_v         NUMBER(8,2),
    motor_temp_c            NUMBER(6,2),
    motor_rpm               INT,
    drive_frequency_hz      NUMBER(6,2)                                     COMMENT 'VFD output frequency',
    specific_energy_kwh_t   NUMBER(8,4)                                     COMMENT 'Energy per tonne kWh/t',

    -- Mechanical health
    belt_tension_kn         NUMBER(10,2)                                    COMMENT 'Belt tension at head pulley kN',
    belt_sag_mm             NUMBER(8,2)                                     COMMENT 'Belt sag between idlers mm',
    idler_vibration_mm_s    NUMBER(8,3)                                     COMMENT 'Idler bearing vibration mm/s RMS',
    head_pulley_temp_c      NUMBER(6,2),
    tail_pulley_temp_c      NUMBER(6,2),
    belt_slip_pct           NUMBER(6,2)                                     COMMENT 'Belt slip as % of drive rpm',
    belt_wear_pct           NUMBER(6,2)                                     COMMENT 'Estimated belt wear % of life',
    belt_mistracking_mm     NUMBER(6,2)                                     COMMENT 'Belt tracking deviation in mm',

    -- Feeders and hoppers
    hopper_level_pct        NUMBER(6,2)                                     COMMENT 'Feed hopper fill level %',
    feed_rate_tph           NUMBER(10,2)                                    COMMENT 'Feed rate into belt tph',
    skirtboard_wear_pct     NUMBER(6,2),

    -- Safety and alarms
    emergency_stop_active   BOOLEAN,
    belt_rip_detected       BOOLEAN,
    spillage_detected       BOOLEAN,
    fire_detected           BOOLEAN,
    overload_detected       BOOLEAN,
    active_fault_codes      STRING,
    fault_count             INT,

    -- Availability
    availability_state      STRING     NOT NULL      COMMENT 'RUNNING | STOPPED | STANDBY | FAULT | MAINTENANCE',

    CONSTRAINT pk_conveyor_telemetry PRIMARY KEY (telemetry_id)
)
    EXTERNAL_VOLUME = 'ONELAKE_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'conveyor_belt_telemetry/'
    COMMENT = 'High-frequency conveyor belt telemetry — stored as Iceberg on OneLake'
    CLUSTER BY (equipment_id, DATE_TRUNC('hour', event_ts));

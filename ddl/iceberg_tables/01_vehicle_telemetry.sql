-- =============================================================================
-- Mining Accelerator — Vehicle Telemetry (Iceberg Table)
-- Stored on OneLake via Snowflake External Volume
-- High-frequency GPS + sensor data from haul trucks, excavators, dozers
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_STREAM;

CREATE OR REPLACE ICEBERG TABLE VEHICLE_TELEMETRY (
    -- Identity
    telemetry_id            STRING     NOT NULL                        COMMENT 'UUID for each telemetry record',
    equipment_id            STRING     NOT NULL                        COMMENT 'FK to EQUIPMENT.equipment_id',
    equipment_code          STRING     NOT NULL                        COMMENT 'Denormalised equipment code for query performance',
    equipment_class         STRING     NOT NULL                        COMMENT 'HAUL_TRUCK | EXCAVATOR | DOZER | GRADER | WATER_TRUCK',
    operator_id             STRING                                     COMMENT 'FK to OPERATORS.operator_id (may be NULL if no operator logged on)',
    shift_instance_id       STRING                                     COMMENT 'FK to SHIFT_INSTANCES.shift_instance_id',

    -- Timestamp
    event_ts                TIMESTAMP_LTZ   NOT NULL                        COMMENT 'UTC timestamp of telemetry record',
    event_ts_local          TIMESTAMP_LTZ                                   COMMENT 'Local site time',
    ingestion_ts            TIMESTAMP_LTZ   NOT NULL COMMENT 'When record was written to Iceberg',

    -- GPS Position (WGS84)
    latitude                NUMBER(10,7)    NOT NULL,
    longitude               NUMBER(10,7)    NOT NULL,
    elevation_m             NUMBER(8,2),
    gps_accuracy_m          NUMBER(6,2)                                     COMMENT 'GPS fix accuracy in metres',
    heading_deg             NUMBER(6,2)                                     COMMENT 'Compass heading 0-360 degrees',
    speed_kmh               NUMBER(8,2)     NOT NULL,
    speed_ms                NUMBER(8,3),

    -- Location context
    current_location_id     STRING                                     COMMENT 'Derived FK to LOCATIONS.location_id',
    current_zone            STRING                                     COMMENT 'DIG_FACE | STOCKPILE | HAUL_ROAD | DUMP | CRUSHER | FUEL_BAY | WORKSHOP | IDLE_BAY',
    previous_location_id    STRING,
    nearest_landmark        STRING                                     COMMENT 'Nearest named feature on site',

    -- Motion state
    vehicle_state           STRING     NOT NULL                        COMMENT 'LOADING | HAULING_LOADED | DUMPING | HAULING_EMPTY | SPOTTING | QUEUING | IDLE | STANDBY | REFUELLING | MAINTENANCE | PARKED',
    is_loaded               BOOLEAN         NOT NULL,

    -- Payload
    payload_t               NUMBER(10,3)                                    COMMENT 'Measured payload in tonnes (from onboard weighing)',
    payload_status          STRING                                     COMMENT 'EMPTY | PARTIAL | LOADED | OVERLOADED',
    overload_pct            NUMBER(6,2)                                     COMMENT 'Percentage over rated payload (positive = overloaded)',

    -- Engine metrics
    engine_hours            NUMBER(12,2)                                    COMMENT 'Cumulative engine hours',
    engine_rpm              INT,
    engine_load_pct         NUMBER(6,2)                                     COMMENT 'Engine load as % of rated',
    engine_coolant_temp_c   NUMBER(6,2),
    engine_oil_temp_c       NUMBER(6,2),
    engine_oil_pressure_kpa NUMBER(8,2),
    exhaust_temp_c          NUMBER(6,2),
    fuel_level_pct          NUMBER(6,2),
    fuel_consumption_lph    NUMBER(8,2)                                     COMMENT 'Instantaneous fuel consumption L/hr',
    fuel_consumed_l         NUMBER(10,3)                                    COMMENT 'Fuel consumed since last reset',

    -- Powertrain
    gear_position           STRING                                     COMMENT 'R | N | 1-8 | F',
    transmission_oil_temp_c NUMBER(6,2),
    brake_temp_fl_c         NUMBER(6,2)                                     COMMENT 'Front left brake temp °C',
    brake_temp_fr_c         NUMBER(6,2),
    brake_temp_rl_c         NUMBER(6,2),
    brake_temp_rr_c         NUMBER(6,2),
    retard_active           BOOLEAN                   COMMENT 'Dynamic retarder active',
    tyre_pressure_fl_kpa    NUMBER(7,2),
    tyre_pressure_fr_kpa    NUMBER(7,2),
    tyre_pressure_rl_kpa    NUMBER(7,2),
    tyre_pressure_rr_kpa    NUMBER(7,2),
    tyre_temp_fl_c          NUMBER(6,2),
    tyre_temp_rr_c          NUMBER(6,2),

    -- Hydraulics (excavators/dozers)
    hydraulic_oil_temp_c    NUMBER(6,2),
    hydraulic_pressure_kpa  NUMBER(8,2),
    swing_angle_deg         NUMBER(7,2)                                     COMMENT 'Excavator swing angle',
    bucket_angle_deg        NUMBER(7,2),
    boom_angle_deg          NUMBER(7,2),
    arm_angle_deg           NUMBER(7,2),

    -- Alarms and faults
    active_fault_codes      STRING                                         COMMENT 'JSON array of active DTC/fault codes',
    fault_count             INT,
    high_priority_alarm     BOOLEAN,

    -- Cycle metrics (populated on dump event)
    cycle_start_ts          TIMESTAMP_LTZ,
    load_location_id        STRING                                     COMMENT 'Where loaded from',
    dump_location_id        STRING                                     COMMENT 'Where dumped',
    material_type_id        STRING                                     COMMENT 'Material loaded',
    cycle_payload_t         NUMBER(10,3),
    haul_distance_m         NUMBER(10,2),
    cycle_duration_s        INT,

    -- Signal quality
    signal_source           STRING                   COMMENT 'GPS | GNSS | DEAD_RECKONING | WIFI | MANUAL',
    signal_strength_dbm     INT,
    record_quality          STRING                  COMMENT 'GOOD | DEGRADED | ESTIMATED | MISSING',

    CONSTRAINT pk_vehicle_telemetry PRIMARY KEY (telemetry_id)
)
    EXTERNAL_VOLUME = 'ONELAKE_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'vehicle_telemetry/'
    COMMENT = 'High-frequency vehicle GPS + sensor telemetry — stored as Iceberg on OneLake'
    CLUSTER BY (equipment_id, DATE_TRUNC('hour', event_ts));

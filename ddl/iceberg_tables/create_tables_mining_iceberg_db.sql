-- =============================================================================
-- Mining Accelerator — Iceberg Tables in MINING_ICEBERG database
-- Run this in Snowsight after creating the MINING_ICEBERG database
-- with Fabric catalog connection
-- =============================================================================

USE DATABASE MINING_ICEBERG;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE MINING_WH;

USE SCHEMA PUBLIC;

-- ============================================================
-- VEHICLE TELEMETRY
-- ============================================================
CREATE OR REPLACE ICEBERG TABLE VEHICLE_TELEMETRY (
    telemetry_id            STRING        NOT NULL,
    equipment_id            STRING        NOT NULL,
    equipment_code          STRING        NOT NULL,
    equipment_class         STRING        NOT NULL,
    operator_id             STRING,
    shift_instance_id       STRING,
    event_ts                TIMESTAMP_LTZ NOT NULL,
    ingestion_ts            TIMESTAMP_LTZ NOT NULL,
    latitude                NUMBER(10,7)  NOT NULL,
    longitude               NUMBER(10,7)  NOT NULL,
    elevation_m             NUMBER(8,2),
    gps_accuracy_m          NUMBER(6,2),
    heading_deg             NUMBER(6,2),
    speed_kmh               NUMBER(8,2),
    speed_ms                NUMBER(8,3),
    current_location_id     STRING,
    current_zone            STRING,
    previous_location_id    STRING,
    nearest_landmark        STRING,
    vehicle_state           STRING        NOT NULL,
    is_loaded               BOOLEAN       NOT NULL,
    payload_t               NUMBER(10,3),
    payload_status          STRING,
    overload_pct            NUMBER(6,2),
    engine_hours            NUMBER(12,2),
    engine_rpm              INT,
    engine_load_pct         NUMBER(6,2),
    engine_coolant_temp_c   NUMBER(6,2),
    engine_oil_temp_c       NUMBER(6,2),
    engine_oil_pressure_kpa NUMBER(8,2),
    exhaust_temp_c          NUMBER(6,2),
    fuel_level_pct          NUMBER(6,2),
    fuel_consumption_lph    NUMBER(8,2),
    fuel_consumed_l         NUMBER(10,3),
    gear_position           STRING,
    transmission_oil_temp_c NUMBER(6,2),
    brake_temp_fl_c         NUMBER(6,2),
    brake_temp_fr_c         NUMBER(6,2),
    brake_temp_rl_c         NUMBER(6,2),
    brake_temp_rr_c         NUMBER(6,2),
    retard_active           BOOLEAN,
    tyre_pressure_fl_kpa    NUMBER(7,2),
    tyre_pressure_fr_kpa    NUMBER(7,2),
    tyre_pressure_rl_kpa    NUMBER(7,2),
    tyre_pressure_rr_kpa    NUMBER(7,2),
    tyre_temp_fl_c          NUMBER(6,2),
    tyre_temp_rr_c          NUMBER(6,2),
    hydraulic_oil_temp_c    NUMBER(6,2),
    hydraulic_pressure_kpa  NUMBER(8,2),
    swing_angle_deg         NUMBER(7,2),
    bucket_angle_deg        NUMBER(7,2),
    boom_angle_deg          NUMBER(7,2),
    arm_angle_deg           NUMBER(7,2),
    active_fault_codes      STRING,
    fault_count             INT,
    high_priority_alarm     BOOLEAN,
    cycle_start_ts          TIMESTAMP_LTZ,
    load_location_id        STRING,
    dump_location_id        STRING,
    material_type_id        STRING,
    cycle_payload_t         NUMBER(10,3),
    haul_distance_m         NUMBER(10,2),
    cycle_duration_s        INT,
    signal_source           STRING,
    signal_strength_dbm     INT,
    record_quality          STRING,
    CONSTRAINT pk_vehicle_telemetry PRIMARY KEY (telemetry_id)
)
    EXTERNAL_VOLUME = 'MINING_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'vehicle_telemetry/';


-- ============================================================
-- CONVEYOR BELT TELEMETRY
-- ============================================================
CREATE OR REPLACE ICEBERG TABLE CONVEYOR_BELT_TELEMETRY (
    telemetry_id                STRING        NOT NULL,
    equipment_id                STRING        NOT NULL,
    equipment_code              STRING        NOT NULL,
    location_id                 STRING,
    shift_instance_id           STRING,
    event_ts                    TIMESTAMP_LTZ NOT NULL,
    ingestion_ts                TIMESTAMP_LTZ NOT NULL,
    belt_running                BOOLEAN       NOT NULL,
    belt_speed_ms               NUMBER(6,3)   NOT NULL,
    belt_speed_setpoint_ms      NUMBER(6,3),
    belt_direction              STRING,
    belt_load_tpm               NUMBER(10,3),
    throughput_tph              NUMBER(10,2),
    tonnage_carried_t           NUMBER(14,3),
    material_type_id            STRING,
    drive_power_kw              NUMBER(10,2),
    drive_current_a             NUMBER(10,2),
    drive_voltage_v             NUMBER(8,2),
    motor_temp_c                NUMBER(6,2),
    motor_rpm                   INT,
    drive_frequency_hz          NUMBER(6,2),
    specific_energy_kwh_t       NUMBER(8,4),
    belt_tension_kn             NUMBER(10,2),
    belt_sag_mm                 NUMBER(8,2),
    idler_vibration_mm_s        NUMBER(8,3),
    head_pulley_temp_c          NUMBER(6,2),
    tail_pulley_temp_c          NUMBER(6,2),
    belt_slip_pct               NUMBER(6,2),
    belt_wear_pct               NUMBER(6,2),
    belt_mistracking_mm         NUMBER(6,2),
    hopper_level_pct            NUMBER(6,2),
    feed_rate_tph               NUMBER(10,2),
    skirtboard_wear_pct         NUMBER(6,2),
    emergency_stop_active       BOOLEAN,
    belt_rip_detected           BOOLEAN,
    spillage_detected           BOOLEAN,
    fire_detected               BOOLEAN,
    overload_detected           BOOLEAN,
    active_fault_codes          STRING,
    fault_count                 INT,
    availability_state          STRING        NOT NULL,
    CONSTRAINT pk_conveyor_telemetry PRIMARY KEY (telemetry_id)
)
    EXTERNAL_VOLUME = 'MINING_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'conveyor_belt_telemetry/';


-- ============================================================
-- CRUSHER TELEMETRY
-- ============================================================
CREATE OR REPLACE ICEBERG TABLE CRUSHER_TELEMETRY (
    telemetry_id                STRING        NOT NULL,
    equipment_id                STRING        NOT NULL,
    equipment_code              STRING        NOT NULL,
    crusher_type                STRING        NOT NULL,
    crusher_stage               STRING        NOT NULL,
    location_id                 STRING,
    shift_instance_id           STRING,
    event_ts                    TIMESTAMP_LTZ NOT NULL,
    ingestion_ts                TIMESTAMP_LTZ NOT NULL,
    crusher_running             BOOLEAN       NOT NULL,
    availability_state          STRING        NOT NULL,
    cavity_level_pct            NUMBER(6,2),
    choking_detected            BOOLEAN,
    feed_rate_tph               NUMBER(10,2),
    product_rate_tph            NUMBER(10,2),
    cumulative_tonnage_t        NUMBER(16,3),
    material_type_id            STRING,
    feed_f80_mm                 NUMBER(8,2),
    product_p80_mm              NUMBER(8,2),
    reduction_ratio             NUMBER(8,3),
    main_drive_power_kw         NUMBER(10,2)  NOT NULL,
    main_drive_current_a        NUMBER(10,2),
    main_motor_temp_c           NUMBER(6,2),
    main_drive_voltage_v        NUMBER(8,2),
    specific_energy_kwh_t       NUMBER(8,4),
    css_mm                      NUMBER(8,2),
    oss_mm                      NUMBER(8,2),
    eccentric_speed_rpm         INT,
    throw_mm                    NUMBER(6,2),
    mantle_wear_pct             NUMBER(6,2),
    concave_wear_pct            NUMBER(6,2),
    liner_wear_mm               NUMBER(6,2),
    lube_oil_pressure_kpa       NUMBER(8,2),
    lube_oil_temp_c             NUMBER(6,2),
    lube_oil_flow_lpm           NUMBER(8,2),
    lube_oil_level_pct          NUMBER(6,2),
    lube_oil_contamination_ppm  INT,
    hydraulic_pressure_kpa      NUMBER(8,2),
    hydraulic_oil_temp_c        NUMBER(6,2),
    tramp_release_active        BOOLEAN,
    tramp_release_count         INT,
    bearing_vibration_de_mm_s   NUMBER(8,3),
    bearing_vibration_nde_mm_s  NUMBER(8,3),
    frame_vibration_mm_s        NUMBER(8,3),
    bearing_temp_de_c           NUMBER(6,2),
    bearing_temp_nde_c          NUMBER(6,2),
    pinion_bearing_temp_c       NUMBER(6,2),
    feed_conveyor_id            STRING,
    discharge_conveyor_id       STRING,
    feed_bin_level_pct          NUMBER(6,2),
    active_fault_codes          STRING,
    fault_count                 INT,
    high_priority_alarm         BOOLEAN,
    is_available                NUMBER(3,1),
    CONSTRAINT pk_crusher_telemetry PRIMARY KEY (telemetry_id)
)
    EXTERNAL_VOLUME = 'MINING_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'crusher_telemetry/';


-- ============================================================
-- DIG FACE OPERATIONS
-- ============================================================
CREATE OR REPLACE ICEBERG TABLE DIG_FACE_OPERATIONS (
    operation_id            STRING        NOT NULL,
    location_id             STRING        NOT NULL,
    shift_instance_id       STRING,
    equipment_id            STRING        NOT NULL,
    operator_id             STRING,
    event_ts                TIMESTAMP_LTZ NOT NULL,
    ingestion_ts            TIMESTAMP_LTZ NOT NULL,
    operation_type          STRING        NOT NULL,
    operation_status        STRING        NOT NULL,
    blast_id                STRING,
    blast_hole_count        INT,
    explosive_type          STRING,
    explosive_mass_kg       NUMBER(10,2),
    powder_factor_kg_t      NUMBER(8,4),
    blast_pattern           STRING,
    bench_height_m          NUMBER(6,2),
    material_type_id        STRING,
    insitu_volume_m3        NUMBER(12,3),
    loose_volume_m3         NUMBER(12,3),
    estimated_tonnes        NUMBER(14,3),
    measured_grade_fepct    NUMBER(6,3),
    dig_rate_bcm_hr         NUMBER(10,2),
    face_latitude           NUMBER(10,7),
    face_longitude          NUMBER(10,7),
    face_elevation_m        NUMBER(8,2),
    face_azimuth_deg        NUMBER(6,2),
    advance_distance_m      NUMBER(8,2),
    load_count              INT,
    trucks_loaded           STRING,
    avg_spot_time_s         NUMBER(8,2),
    avg_load_time_s         NUMBER(8,2),
    avg_payload_t           NUMBER(10,3),
    primary_dump_location_id STRING,
    operation_start_ts      TIMESTAMP_LTZ,
    operation_end_ts        TIMESTAMP_LTZ,
    duration_minutes        NUMBER(10,2),
    CONSTRAINT pk_dig_face_ops PRIMARY KEY (operation_id)
)
    EXTERNAL_VOLUME = 'MINING_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'dig_face_operations/';


-- ============================================================
-- STOCKPILE VOLUMES
-- ============================================================
CREATE OR REPLACE ICEBERG TABLE STOCKPILE_VOLUMES (
    survey_id               STRING        NOT NULL,
    location_id             STRING        NOT NULL,
    shift_instance_id       STRING,
    survey_ts               TIMESTAMP_LTZ NOT NULL,
    ingestion_ts            TIMESTAMP_LTZ NOT NULL,
    survey_method           STRING        NOT NULL,
    survey_quality          STRING        NOT NULL,
    survey_accuracy_pct     NUMBER(6,2),
    surveyed_by             STRING,
    volume_m3               NUMBER(14,3)  NOT NULL,
    bulk_density_t_m3       NUMBER(6,3),
    estimated_tonnes        NUMBER(16,3),
    design_capacity_m3      NUMBER(14,3),
    utilisation_pct         NUMBER(6,2),
    volume_added_m3         NUMBER(14,3),
    volume_reclaimed_m3     NUMBER(14,3),
    net_movement_m3         NUMBER(14,3),
    material_type_id        STRING,
    blended_material        BOOLEAN,
    material_breakdown      STRING,
    avg_grade_fepct         NUMBER(6,3),
    grade_min               NUMBER(8,4),
    grade_max               NUMBER(8,4),
    last_sampled_ts         TIMESTAMP_LTZ,
    centroid_latitude       NUMBER(10,7),
    centroid_longitude      NUMBER(10,7),
    peak_elevation_m        NUMBER(8,2),
    CONSTRAINT pk_stockpile_volumes PRIMARY KEY (survey_id)
)
    EXTERNAL_VOLUME = 'MINING_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'stockpile_volumes/';


-- ============================================================
-- PRODUCT MOVEMENT
-- ============================================================
CREATE OR REPLACE ICEBERG TABLE PRODUCT_MOVEMENT (
    movement_id             STRING        NOT NULL,
    parent_movement_id      STRING,
    movement_chain_id       STRING,
    shift_instance_id       STRING,
    event_ts                TIMESTAMP_LTZ NOT NULL,
    ingestion_ts            TIMESTAMP_LTZ NOT NULL,
    movement_type           STRING        NOT NULL,
    movement_status         STRING        NOT NULL,
    source_location_id      STRING        NOT NULL,
    source_location_type    STRING,
    dest_location_id        STRING        NOT NULL,
    dest_location_type      STRING,
    primary_equipment_id    STRING,
    secondary_equipment_id  STRING,
    operator_id             STRING,
    material_type_id        STRING        NOT NULL,
    gross_tonnes            NUMBER(14,3)  NOT NULL,
    net_tonnes              NUMBER(14,3),
    moisture_pct            NUMBER(6,3),
    volume_m3               NUMBER(12,3),
    bulk_density_t_m3       NUMBER(6,3),
    grade_fepct             NUMBER(6,3),
    grade_al2o3_pct         NUMBER(6,3),
    grade_sio2_pct          NUMBER(6,3),
    grade_p_pct             NUMBER(6,3),
    grade_loi_pct           NUMBER(6,3),
    weighing_method         STRING,
    measurement_accuracy    STRING,
    movement_start_ts       TIMESTAMP_LTZ,
    movement_end_ts         TIMESTAMP_LTZ,
    duration_minutes        NUMBER(10,2),
    haul_distance_m         NUMBER(10,2),
    haul_time_min           NUMBER(8,2),
    cycle_number            INT,
    truck_load_number       INT,
    is_reconciled           BOOLEAN,
    reconciliation_id       STRING,
    variance_tonnes         NUMBER(14,3),
    CONSTRAINT pk_product_movement PRIMARY KEY (movement_id)
)
    EXTERNAL_VOLUME = 'MINING_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'product_movement/';


-- Verify tables created
SHOW ICEBERG TABLES IN SCHEMA MINING_ICEBERG.PUBLIC;

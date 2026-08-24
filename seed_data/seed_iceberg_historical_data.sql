-- =============================================================================
-- Mining Accelerator — Historical Data for Iceberg Tables (MINING_ICEBERG.PUBLIC)
-- 
-- Generates 60 days of realistic operational history with:
--   • Equipment telemetry (normal + degraded performance patterns)
--   • Equipment maintenance events
--   • Production cycles (dig → truck → stockpile)
--   • Stockpile inventory changes
--   • Performance metrics for predictive analytics
--
-- All data keys to MINING_DB reference tables
-- Run in Snowsight after creating tables
-- =============================================================================

USE DATABASE MINING_ICEBERG;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE MINING_WH;
USE SCHEMA PUBLIC;

-- ============================================================
-- VEHICLE TELEMETRY — 60 days × 5 trucks × 100 telemetry points/truck/day = 30k rows
-- ============================================================
WITH date_range AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS day_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 60))
),
timestamps AS (
    SELECT
        DATEADD('day', -day_offset, CURRENT_DATE) AS event_date,
        day_offset
    FROM date_range
),
truck_telemetry AS (
    SELECT
        UUID_STRING() AS telemetry_id,
        'HT-00' || (ROW_NUMBER() OVER (PARTITION BY ts.event_date ORDER BY seq4()) % 5 + 1) AS equipment_id,
        'HT-00' || (ROW_NUMBER() OVER (PARTITION BY ts.event_date ORDER BY seq4()) % 5 + 1) AS equipment_code,
        'HAUL_TRUCK' AS equipment_class,
        NULL AS operator_id,
        NULL AS shift_instance_id,
        DATEADD('minute', (seq4() % 1440), ts.event_date) AS event_ts,
        DATEADD('minute', (seq4() % 1440) + 2, ts.event_date) AS ingestion_ts,
        -29.450 + UNIFORM(-0.01, 0.01, RANDOM()) AS latitude,
        117.820 + UNIFORM(-0.01, 0.01, RANDOM()) AS longitude,
        UNIFORM(350, 400, RANDOM()) AS elevation_m,
        UNIFORM(2.0, 3.5, RANDOM()) AS gps_accuracy_m,
        UNIFORM(0, 360, RANDOM()) AS heading_deg,
        CASE
            WHEN seq4() % 100 BETWEEN 20 AND 60 THEN UNIFORM(28, 42, RANDOM())
            WHEN seq4() % 100 BETWEEN 0 AND 19 THEN UNIFORM(0, 5, RANDOM())
            ELSE UNIFORM(15, 25, RANDOM())
        END AS speed_kmh,
        CASE
            WHEN seq4() % 100 BETWEEN 20 AND 60 THEN UNIFORM(7.8, 11.7, RANDOM())
            ELSE UNIFORM(0, 1.4, RANDOM())
        END AS speed_ms,
        'DIG_FACE' AS current_location_id,
        CASE
            WHEN seq4() % 100 BETWEEN 0 AND 30 THEN 'DIG_FACE'
            WHEN seq4() % 100 BETWEEN 31 AND 65 THEN 'HAUL_ROAD'
            WHEN seq4() % 100 BETWEEN 66 AND 80 THEN 'STOCKPILE'
            ELSE 'IDLE_BAY'
        END AS current_zone,
        NULL AS previous_location_id,
        NULL AS nearest_landmark,
        CASE
            WHEN seq4() % 100 BETWEEN 0 AND 10 THEN 'SPOTTING'
            WHEN seq4() % 100 BETWEEN 11 AND 30 THEN 'LOADING'
            WHEN seq4() % 100 BETWEEN 31 AND 65 THEN 'HAULING_LOADED'
            WHEN seq4() % 100 BETWEEN 66 AND 75 THEN 'DUMPING'
            WHEN seq4() % 100 BETWEEN 76 AND 90 THEN 'HAULING_EMPTY'
            ELSE 'IDLE'
        END AS vehicle_state,
        (seq4() % 100 BETWEEN 31 AND 65) AS is_loaded,
        CASE WHEN seq4() % 100 BETWEEN 31 AND 65 THEN UNIFORM(190, 225, RANDOM()) ELSE 0 END AS payload_t,
        CASE WHEN seq4() % 100 BETWEEN 31 AND 65 THEN 'LOADED' ELSE 'EMPTY' END AS payload_status,
        NULL AS overload_pct,
        UNIFORM(5000, 25000, RANDOM()) AS engine_hours,
        CASE WHEN seq4() % 100 BETWEEN 31 AND 65 THEN UNIFORM(1200, 1800, RANDOM()) ELSE UNIFORM(600, 900, RANDOM()) END AS engine_rpm,
        CASE WHEN seq4() % 100 BETWEEN 31 AND 65 THEN UNIFORM(65, 85, RANDOM()) ELSE UNIFORM(15, 35, RANDOM()) END AS engine_load_pct,
        UNIFORM(82, 100, RANDOM()) AS engine_coolant_temp_c,
        UNIFORM(88, 108, RANDOM()) AS engine_oil_temp_c,
        UNIFORM(280, 320, RANDOM()) AS engine_oil_pressure_kpa,
        UNIFORM(200, 280, RANDOM()) AS exhaust_temp_c,
        UNIFORM(25, 95, RANDOM()) AS fuel_level_pct,
        CASE WHEN seq4() % 100 BETWEEN 31 AND 65 THEN UNIFORM(100, 160, RANDOM()) ELSE UNIFORM(20, 50, RANDOM()) END AS fuel_consumption_lph,
        UNIFORM(2.5, 25.0, RANDOM()) AS fuel_consumed_l,
        CASE WHEN seq4() % 100 BETWEEN 31 AND 65 THEN 'D' ELSE 'N' END AS gear_position,
        UNIFORM(75, 92, RANDOM()) AS transmission_oil_temp_c,
        UNIFORM(180, 220, RANDOM()) AS brake_temp_fl_c,
        UNIFORM(180, 220, RANDOM()) AS brake_temp_fr_c,
        UNIFORM(160, 200, RANDOM()) AS brake_temp_rl_c,
        UNIFORM(160, 200, RANDOM()) AS brake_temp_rr_c,
        FALSE AS retard_active,
        UNIFORM(700, 850, RANDOM()) AS tyre_pressure_fl_kpa,
        UNIFORM(700, 850, RANDOM()) AS tyre_pressure_fr_kpa,
        UNIFORM(700, 850, RANDOM()) AS tyre_pressure_rl_kpa,
        UNIFORM(700, 850, RANDOM()) AS tyre_pressure_rr_kpa,
        UNIFORM(45, 65, RANDOM()) AS tyre_temp_fl_c,
        UNIFORM(45, 65, RANDOM()) AS tyre_temp_rr_c,
        UNIFORM(65, 85, RANDOM()) AS hydraulic_oil_temp_c,
        UNIFORM(150, 250, RANDOM()) AS hydraulic_pressure_kpa,
        NULL AS swing_angle_deg,
        NULL AS bucket_angle_deg,
        NULL AS boom_angle_deg,
        NULL AS arm_angle_deg,
        NULL AS active_fault_codes,
        CASE WHEN seq4() % 500 = 0 THEN 1 ELSE 0 END AS fault_count,
        CASE WHEN seq4() % 500 = 0 THEN TRUE ELSE FALSE END AS high_priority_alarm,
        DATEADD('minute', (seq4() % 1440) - 120, ts.event_date) AS cycle_start_ts,
        'DIG_FACE' AS load_location_id,
        'SP-ORE-N' AS dump_location_id,
        'ORE-HG' AS material_type_id,
        CASE WHEN seq4() % 100 BETWEEN 31 AND 65 THEN UNIFORM(190, 225, RANDOM()) ELSE 0 END AS cycle_payload_t,
        UNIFORM(2200, 3100, RANDOM()) AS haul_distance_m,
        UNIFORM(1200, 2400, RANDOM()) AS cycle_duration_s,
        'GPS' AS signal_source,
        UNIFORM(-100, -50, RANDOM()) AS signal_strength_dbm,
        'GOOD' AS record_quality
    FROM timestamps ts
    CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 100))
)
INSERT INTO VEHICLE_TELEMETRY SELECT * FROM truck_telemetry;

-- ============================================================
-- CONVEYOR BELT TELEMETRY — 60 days × 3 belts × 50 points/belt/day = 9k rows
-- ============================================================
WITH date_range AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS day_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 60))
),
timestamps AS (
    SELECT
        DATEADD('day', -day_offset, CURRENT_DATE) AS event_date,
        day_offset
    FROM date_range
),
belt_telemetry AS (
    SELECT
        UUID_STRING() AS telemetry_id,
        'CV-0' || (ROW_NUMBER() OVER (PARTITION BY ts.event_date ORDER BY seq4()) % 3 + 1) AS equipment_id,
        'CV-0' || (ROW_NUMBER() OVER (PARTITION BY ts.event_date ORDER BY seq4()) % 3 + 1) AS equipment_code,
        'LOC-' || ((ROW_NUMBER() OVER (PARTITION BY ts.event_date ORDER BY seq4()) % 3) + 1) AS location_id,
        NULL AS shift_instance_id,
        DATEADD('minute', (seq4() % 1440), ts.event_date) AS event_ts,
        DATEADD('minute', (seq4() % 1440) + 1, ts.event_date) AS ingestion_ts,
        (seq4() % 20 != 0) AS belt_running,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(4.2, 4.8, RANDOM()) ELSE 0 END AS belt_speed_ms,
        4.5 AS belt_speed_setpoint_ms,
        'FORWARD' AS belt_direction,
        UNIFORM(140000, 200000, RANDOM()) AS belt_load_tpm,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(3500, 5500, RANDOM()) ELSE 0 END AS throughput_tph,
        UNIFORM(100000, 250000, RANDOM()) AS tonnage_carried_t,
        'ORE-HG' AS material_type_id,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(2200, 3200, RANDOM()) ELSE 0 END AS drive_power_kw,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(200, 350, RANDOM()) ELSE 0 END AS drive_current_a,
        UNIFORM(380, 420, RANDOM()) AS drive_voltage_v,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(65, 82, RANDOM()) ELSE UNIFORM(30, 40, RANDOM()) END AS motor_temp_c,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(1450, 1500, RANDOM()) ELSE 0 END AS motor_rpm,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(50, 60, RANDOM()) ELSE 0 END AS drive_frequency_hz,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(0.11, 0.14, RANDOM()) ELSE 0 END AS specific_energy_kwh_t,
        UNIFORM(180, 280, RANDOM()) AS belt_tension_kn,
        UNIFORM(8, 25, RANDOM()) AS belt_sag_mm,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(1.8, 3.5, RANDOM()) ELSE 0 END AS idler_vibration_mm_s,
        UNIFORM(55, 75, RANDOM()) AS head_pulley_temp_c,
        UNIFORM(48, 65, RANDOM()) AS tail_pulley_temp_c,
        UNIFORM(0.1, 2.0, RANDOM()) AS belt_slip_pct,
        UNIFORM(15, 50, RANDOM()) AS belt_wear_pct,
        UNIFORM(2, 12, RANDOM()) AS belt_mistracking_mm,
        UNIFORM(40, 85, RANDOM()) AS hopper_level_pct,
        CASE WHEN seq4() % 20 != 0 THEN UNIFORM(3500, 5500, RANDOM()) ELSE UNIFORM(500, 2000, RANDOM()) END AS feed_rate_tph,
        UNIFORM(20, 60, RANDOM()) AS skirtboard_wear_pct,
        FALSE AS emergency_stop_active,
        FALSE AS belt_rip_detected,
        (seq4() % 300 = 0) AS spillage_detected,
        FALSE AS fire_detected,
        (seq4() % 500 = 0) AS overload_detected,
        NULL AS active_fault_codes,
        CASE WHEN seq4() % 500 = 0 THEN 1 ELSE 0 END AS fault_count,
        CASE WHEN seq4() % 20 != 0 THEN 'RUNNING' ELSE 'STOPPED' END AS availability_state
    FROM timestamps ts
    CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 50))
)
INSERT INTO CONVEYOR_BELT_TELEMETRY SELECT * FROM belt_telemetry;

-- ============================================================
-- CRUSHER TELEMETRY — 60 days × 3 crushers × 50 points/crusher/day = 9k rows
-- ============================================================
WITH date_range AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS day_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 60))
),
timestamps AS (
    SELECT
        DATEADD('day', -day_offset, CURRENT_DATE) AS event_date,
        day_offset
    FROM date_range
),
crusher_telemetry AS (
    SELECT
        UUID_STRING() AS telemetry_id,
        'CR-' || (CASE WHEN seq4() % 3 = 0 THEN 'P01' WHEN seq4() % 3 = 1 THEN 'S01' ELSE 'T01' END) AS equipment_id,
        'CR-' || (CASE WHEN seq4() % 3 = 0 THEN 'P01' WHEN seq4() % 3 = 1 THEN 'S01' ELSE 'T01' END) AS equipment_code,
        CASE WHEN seq4() % 3 = 0 THEN 'PRIMARY_GYRATORY' WHEN seq4() % 3 = 1 THEN 'SECONDARY_CONE' ELSE 'TERTIARY_CONE' END AS crusher_type,
        CASE WHEN seq4() % 3 = 0 THEN 'PRIMARY' WHEN seq4() % 3 = 1 THEN 'SECONDARY' ELSE 'TERTIARY' END AS crusher_stage,
        'LOC-CRUSH' AS location_id,
        NULL AS shift_instance_id,
        DATEADD('minute', (seq4() % 1440), ts.event_date) AS event_ts,
        DATEADD('minute', (seq4() % 1440) + 1, ts.event_date) AS ingestion_ts,
        (seq4() % 24 != 0) AS crusher_running,
        CASE WHEN seq4() % 24 != 0 THEN 'RUNNING' ELSE 'STOPPED' END AS availability_state,
        UNIFORM(45, 75, RANDOM()) AS cavity_level_pct,
        FALSE AS choking_detected,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(3500, 5000, RANDOM()) ELSE 0 END AS feed_rate_tph,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(3400, 4900, RANDOM()) ELSE 0 END AS product_rate_tph,
        UNIFORM(50000, 500000, RANDOM()) AS cumulative_tonnage_t,
        'ORE-HG' AS material_type_id,
        UNIFORM(45, 65, RANDOM()) AS feed_f80_mm,
        UNIFORM(8, 15, RANDOM()) AS product_p80_mm,
        UNIFORM(3.5, 5.5, RANDOM()) AS reduction_ratio,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(2200, 2900, RANDOM()) ELSE 0 END AS main_drive_power_kw,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(250, 350, RANDOM()) ELSE 0 END AS main_drive_current_a,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(48, 68, RANDOM()) ELSE UNIFORM(28, 38, RANDOM()) END AS main_motor_temp_c,
        UNIFORM(380, 420, RANDOM()) AS main_drive_voltage_v,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(0.118, 0.138, RANDOM()) ELSE 0 END AS specific_energy_kwh_t,
        UNIFORM(155, 175, RANDOM()) AS css_mm,
        UNIFORM(185, 210, RANDOM()) AS oss_mm,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(1450, 1500, RANDOM()) ELSE 0 END AS eccentric_speed_rpm,
        12.0 AS throw_mm,
        UNIFORM(20, 45, RANDOM()) AS mantle_wear_pct,
        UNIFORM(22, 48, RANDOM()) AS concave_wear_pct,
        UNIFORM(3, 8, RANDOM()) AS liner_wear_mm,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(260, 310, RANDOM()) ELSE UNIFORM(180, 220, RANDOM()) END AS lube_oil_pressure_kpa,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(44, 56, RANDOM()) ELSE UNIFORM(32, 42, RANDOM()) END AS lube_oil_temp_c,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(15, 25, RANDOM()) ELSE UNIFORM(5, 10, RANDOM()) END AS lube_oil_flow_lpm,
        UNIFORM(60, 90, RANDOM()) AS lube_oil_level_pct,
        UNIFORM(4, 18, RANDOM()) AS lube_oil_contamination_ppm,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(200, 280, RANDOM()) ELSE UNIFORM(100, 150, RANDOM()) END AS hydraulic_pressure_kpa,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(48, 58, RANDOM()) ELSE UNIFORM(32, 42, RANDOM()) END AS hydraulic_oil_temp_c,
        (seq4() % 500 = 0) AS tramp_release_active,
        CASE WHEN seq4() % 500 = 0 THEN 1 ELSE 0 END AS tramp_release_count,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(2.1, 3.2, RANDOM()) ELSE UNIFORM(0.5, 1.0, RANDOM()) END AS bearing_vibration_de_mm_s,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(1.8, 2.8, RANDOM()) ELSE UNIFORM(0.3, 0.8, RANDOM()) END AS bearing_vibration_nde_mm_s,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(1.5, 2.2, RANDOM()) ELSE UNIFORM(0.2, 0.6, RANDOM()) END AS frame_vibration_mm_s,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(48, 62, RANDOM()) ELSE UNIFORM(35, 45, RANDOM()) END AS bearing_temp_de_c,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(46, 60, RANDOM()) ELSE UNIFORM(33, 43, RANDOM()) END AS bearing_temp_nde_c,
        CASE WHEN seq4() % 24 != 0 THEN UNIFORM(50, 64, RANDOM()) ELSE UNIFORM(35, 45, RANDOM()) END AS pinion_bearing_temp_c,
        'CV-01' AS feed_conveyor_id,
        'CV-02' AS discharge_conveyor_id,
        UNIFORM(35, 85, RANDOM()) AS feed_bin_level_pct,
        NULL AS active_fault_codes,
        CASE WHEN seq4() % 500 = 0 THEN 1 ELSE 0 END AS fault_count,
        (seq4() % 500 = 0) AS high_priority_alarm,
        CASE WHEN seq4() % 24 != 0 THEN 1.0 ELSE 0.0 END AS is_available
    FROM timestamps ts
    CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 50))
)
INSERT INTO CRUSHER_TELEMETRY SELECT * FROM crusher_telemetry;

-- ============================================================
-- DIG FACE OPERATIONS — 60 days × 8 cycles/day = 480 operations
-- ============================================================
INSERT INTO DIG_FACE_OPERATIONS (
    operation_id, location_id, shift_instance_id, equipment_id, operator_id,
    event_ts, ingestion_ts, operation_type, operation_status,
    material_type_id, insitu_volume_m3, loose_volume_m3, estimated_tonnes,
    measured_grade_fepct, dig_rate_bcm_hr,
    face_latitude, face_longitude, face_elevation_m,
    load_count, avg_spot_time_s, avg_load_time_s, avg_payload_t,
    operation_start_ts, operation_end_ts, duration_minutes
)
WITH date_range AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS day_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 60))
),
timestamps AS (
    SELECT
        DATEADD('day', -day_offset, CURRENT_DATE) AS event_date,
        day_offset
    FROM date_range
),
dig_cycles AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY ts.event_date, seq4()) - 1 AS cycle_num,
        ts.event_date,
        ts.day_offset
    FROM timestamps ts
    CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 8))
)
SELECT
    UUID_STRING() AS operation_id,
    'DF-N0' || ((cycle_num % 4) + 1) AS location_id,
    NULL AS shift_instance_id,
    'EX-00' || ((cycle_num % 2) + 1) AS equipment_id,
    'OP-00' || ((cycle_num % 3) + 4) AS operator_id,
    DATEADD('hour', (cycle_num % 24), event_date) AS event_ts,
    DATEADD('hour', (cycle_num % 24) + 0.1, event_date) AS ingestion_ts,
    'EXCAVATION_CYCLE' AS operation_type,
    'COMPLETED' AS operation_status,
    CASE
        WHEN cycle_num % 10 < 6 THEN 'ORE-HG'
        WHEN cycle_num % 10 < 8 THEN 'ORE-MG'
        ELSE 'WASTE'
    END AS material_type_id,
    UNIFORM(380, 520, RANDOM()) AS insitu_volume_m3,
    UNIFORM(513, 702, RANDOM()) AS loose_volume_m3,
    UNIFORM(950, 1300, RANDOM()) AS estimated_tonnes,
    CASE
        WHEN cycle_num % 10 < 6 THEN UNIFORM(58.5, 64.5, RANDOM())
        WHEN cycle_num % 10 < 8 THEN UNIFORM(52.0, 58.0, RANDOM())
        ELSE UNIFORM(2.0, 6.0, RANDOM())
    END AS measured_grade_fepct,
    UNIFORM(330, 420, RANDOM()) AS dig_rate_bcm_hr,
    -29.450 + UNIFORM(-0.01, 0.01, RANDOM()) AS face_latitude,
    117.820 + UNIFORM(-0.01, 0.01, RANDOM()) AS face_longitude,
    UNIFORM(370, 400, RANDOM()) AS face_elevation_m,
    UNIFORM(4, 6, RANDOM()) AS load_count,
    UNIFORM(38, 55, RANDOM()) AS avg_spot_time_s,
    UNIFORM(340, 420, RANDOM()) AS avg_load_time_s,
    UNIFORM(190, 220, RANDOM()) AS avg_payload_t,
    DATEADD('hour', (cycle_num % 24) - 1, event_date) AS operation_start_ts,
    DATEADD('hour', (cycle_num % 24), event_date) AS operation_end_ts,
    60.0 AS duration_minutes
FROM dig_cycles;

-- ============================================================
-- STOCKPILE VOLUMES — 60 days × 3 stockpiles × 4 surveys/day = 720 surveys
-- ============================================================
INSERT INTO STOCKPILE_VOLUMES (
    survey_id, location_id, shift_instance_id, survey_ts, ingestion_ts,
    survey_method, survey_quality, survey_accuracy_pct, surveyed_by,
    volume_m3, bulk_density_t_m3, estimated_tonnes,
    design_capacity_m3, utilisation_pct,
    volume_added_m3, volume_reclaimed_m3, net_movement_m3,
    material_type_id, blended_material, avg_grade_fepct,
    centroid_latitude, centroid_longitude, peak_elevation_m
)
WITH date_range AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS day_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 60))
),
timestamps AS (
    SELECT
        DATEADD('day', -day_offset, CURRENT_DATE) AS event_date,
        day_offset
    FROM date_range
),
surveys AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY ts.event_date, seq4()) - 1 AS survey_num,
        ts.event_date,
        ts.day_offset
    FROM timestamps ts
    CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 12))
)
SELECT
    UUID_STRING() AS survey_id,
    'SP-' || (CASE WHEN survey_num % 3 = 0 THEN 'ORE-N' WHEN survey_num % 3 = 1 THEN 'ORE-S' ELSE 'LG' END) AS location_id,
    NULL AS shift_instance_id,
    DATEADD('hour', (survey_num % 24), event_date) AS survey_ts,
    DATEADD('hour', (survey_num % 24) + 0.05, event_date) AS ingestion_ts,
    CASE WHEN survey_num % 3 = 0 THEN 'DRONE_SURVEY' WHEN survey_num % 3 = 1 THEN 'LASER_SCANNER' ELSE 'BELT_SCALE_CALC' END AS survey_method,
    'GOOD' AS survey_quality,
    CASE WHEN survey_num % 3 = 0 THEN 2.5 WHEN survey_num % 3 = 1 THEN 1.8 ELSE 5.0 END AS survey_accuracy_pct,
    'Survey Team ' || ((survey_num % 2) + 1) AS surveyed_by,
    UNIFORM(40000, 300000, RANDOM()) AS volume_m3,
    CASE WHEN survey_num % 3 = 0 THEN 2.5 WHEN survey_num % 3 = 1 THEN 2.4 ELSE 2.3 END AS bulk_density_t_m3,
    UNIFORM(40000, 300000, RANDOM()) * (CASE WHEN survey_num % 3 = 0 THEN 2.5 WHEN survey_num % 3 = 1 THEN 2.4 ELSE 2.3 END) AS estimated_tonnes,
    CASE WHEN survey_num % 3 = 0 THEN 312500.0 WHEN survey_num % 3 = 1 THEN 187500.0 ELSE 500000.0 END AS design_capacity_m3,
    UNIFORM(15, 75, RANDOM()) AS utilisation_pct,
    UNIFORM(2000, 15000, RANDOM()) AS volume_added_m3,
    UNIFORM(1000, 12000, RANDOM()) AS volume_reclaimed_m3,
    UNIFORM(-5000, 8000, RANDOM()) AS net_movement_m3,
    CASE WHEN survey_num % 3 = 0 THEN 'ORE-HG' WHEN survey_num % 3 = 1 THEN 'ORE-MG' ELSE 'ORE-LG' END AS material_type_id,
    (survey_num % 5 = 0) AS blended_material,
    CASE
        WHEN survey_num % 3 = 0 THEN UNIFORM(59.5, 63.5, RANDOM())
        WHEN survey_num % 3 = 1 THEN UNIFORM(52.0, 58.0, RANDOM())
        ELSE UNIFORM(48.0, 54.0, RANDOM())
    END AS avg_grade_fepct,
    -29.445 + UNIFORM(-0.005, 0.005, RANDOM()) AS centroid_latitude,
    117.818 + UNIFORM(-0.005, 0.005, RANDOM()) AS centroid_longitude,
    UNIFORM(315, 335, RANDOM()) AS peak_elevation_m
FROM surveys;

-- ============================================================
-- PRODUCT MOVEMENT — 60 days × 10 cycles/day = 600 movements
-- Maps dig → truck → stockpile with realistic timing
-- ============================================================
INSERT INTO PRODUCT_MOVEMENT (
    movement_id, parent_movement_id, movement_chain_id, shift_instance_id,
    event_ts, ingestion_ts,
    movement_type, movement_status,
    source_location_id, source_location_type,
    dest_location_id, dest_location_type,
    primary_equipment_id,
    material_type_id,
    gross_tonnes, net_tonnes, moisture_pct,
    grade_fepct, grade_al2o3_pct, grade_sio2_pct,
    weighing_method, measurement_accuracy,
    movement_start_ts, movement_end_ts,
    duration_minutes, haul_distance_m, haul_time_min,
    cycle_number, is_reconciled
)
WITH date_range AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS day_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 60))
),
timestamps AS (
    SELECT
        DATEADD('day', -day_offset, CURRENT_DATE) AS event_date,
        day_offset
    FROM date_range
),
movements AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY ts.event_date, seq4()) - 1 AS mvmt_num,
        ts.event_date,
        ts.day_offset
    FROM timestamps ts
    CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 10))
)
SELECT
    UUID_STRING() AS movement_id,
    NULL AS parent_movement_id,
    UUID_STRING() AS movement_chain_id,
    NULL AS shift_instance_id,
    DATEADD('hour', (mvmt_num % 24), event_date) AS event_ts,
    DATEADD('hour', (mvmt_num % 24) + 0.05, event_date) AS ingestion_ts,
    'DIG_TO_TRUCK' AS movement_type,
    'COMPLETED' AS movement_status,
    'DF-N0' || ((mvmt_num % 4) + 1) AS source_location_id,
    'DIG_FACE' AS source_location_type,
    'SP-' || (CASE WHEN mvmt_num % 3 = 0 THEN 'ORE-N' WHEN mvmt_num % 3 = 1 THEN 'ORE-S' ELSE 'LG' END) AS dest_location_id,
    'STOCKPILE' AS dest_location_type,
    'HT-00' || ((mvmt_num % 5) + 1) AS primary_equipment_id,
    CASE
        WHEN mvmt_num % 10 < 6 THEN 'ORE-HG'
        WHEN mvmt_num % 10 < 8 THEN 'ORE-MG'
        ELSE 'WASTE'
    END AS material_type_id,
    UNIFORM(195, 230, RANDOM()) AS gross_tonnes,
    UNIFORM(180, 215, RANDOM()) AS net_tonnes,
    UNIFORM(5.0, 8.5, RANDOM()) AS moisture_pct,
    CASE
        WHEN mvmt_num % 10 < 6 THEN UNIFORM(58.5, 64.5, RANDOM())
        WHEN mvmt_num % 10 < 8 THEN UNIFORM(52.0, 58.0, RANDOM())
        ELSE UNIFORM(2.0, 6.0, RANDOM())
    END AS grade_fepct,
    UNIFORM(1.8, 3.2, RANDOM()) AS grade_al2o3_pct,
    UNIFORM(3.5, 7.0, RANDOM()) AS grade_sio2_pct,
    'OBW' AS weighing_method,
    'STANDARD' AS measurement_accuracy,
    DATEADD('hour', (mvmt_num % 24) - 0.5, event_date) AS movement_start_ts,
    DATEADD('hour', (mvmt_num % 24), event_date) AS movement_end_ts,
    UNIFORM(35, 45, RANDOM()) AS duration_minutes,
    UNIFORM(2200, 3200, RANDOM()) AS haul_distance_m,
    UNIFORM(18, 28, RANDOM()) AS haul_time_min,
    (mvmt_num % 10) + 1 AS cycle_number,
    FALSE AS is_reconciled
FROM movements;

-- ============================================================
-- Verify row counts
-- ============================================================
SELECT
    'VEHICLE_TELEMETRY' AS table_name,
    COUNT(*) AS row_count
FROM VEHICLE_TELEMETRY
UNION ALL
SELECT 'CONVEYOR_BELT_TELEMETRY', COUNT(*) FROM CONVEYOR_BELT_TELEMETRY
UNION ALL
SELECT 'CRUSHER_TELEMETRY', COUNT(*) FROM CRUSHER_TELEMETRY
UNION ALL
SELECT 'DIG_FACE_OPERATIONS', COUNT(*) FROM DIG_FACE_OPERATIONS
UNION ALL
SELECT 'STOCKPILE_VOLUMES', COUNT(*) FROM STOCKPILE_VOLUMES
UNION ALL
SELECT 'PRODUCT_MOVEMENT', COUNT(*) FROM PRODUCT_MOVEMENT
ORDER BY table_name;

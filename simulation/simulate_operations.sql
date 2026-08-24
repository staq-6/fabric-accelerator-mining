-- =============================================================================
-- Mining Accelerator — Operations Simulation Stored Procedure
-- Generates realistic mining operations data for the Iceberg tables
-- Produces 90 days of historical data + ongoing simulation capability
-- =============================================================================

USE DATABASE MINING_DB;
USE WAREHOUSE MINING_WH;

-- ============================================================
-- Helper: Generate shift instances for past 90 days
-- ============================================================
USE SCHEMA OPS_REF;

CREATE OR REPLACE PROCEDURE GENERATE_SHIFT_INSTANCES(days_back INT)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    var sql_gen = `
    INSERT INTO SHIFT_INSTANCES
        (shift_id, shift_date, actual_start_ts, actual_end_ts,
         supervisor_id, planned_crew_size, actual_crew_size,
         weather_condition, blast_scheduled, blast_actual, shift_status)
    WITH date_series AS (
        SELECT DATEADD('day', -seq4(), CURRENT_DATE()) AS dt
        FROM TABLE(GENERATOR(ROWCOUNT => ${days_back}))
    ),
    shifts_ref AS (
        SELECT shift_id, shift_code, shift_type, start_time, end_time, crew_code
        FROM SHIFTS WHERE is_active = TRUE
    ),
    supervisors AS (
        SELECT operator_id, crew_code
        FROM OPERATORS WHERE operator_class = 'SUPERVISOR' AND is_active = TRUE
    )
    SELECT
        s.shift_id,
        d.dt AS shift_date,
        TIMESTAMP_FROM_PARTS(
            d.dt, s.start_time
        )                                                                AS actual_start_ts,
        DATEADD('hour', 12,
            TIMESTAMP_FROM_PARTS(d.dt, s.start_time)
        )                                                                AS actual_end_ts,
        sv.operator_id                                                   AS supervisor_id,
        18                                                               AS planned_crew_size,
        ROUND(18 * (0.90 + UNIFORM(0,0.10,RANDOM())))::INT             AS actual_crew_size,
        CASE WHEN UNIFORM(0,1,RANDOM()) < 0.60 THEN 'Clear'
             WHEN UNIFORM(0,1,RANDOM()) < 0.80 THEN 'Dusty'
             WHEN UNIFORM(0,1,RANDOM()) < 0.90 THEN 'Extreme Heat'
             ELSE 'Rain'
        END                                                              AS weather_condition,
        (UNIFORM(0,1,RANDOM()) < 0.30)::BOOLEAN                        AS blast_scheduled,
        (UNIFORM(0,1,RANDOM()) < 0.25)::BOOLEAN                        AS blast_actual,
        'COMPLETED'                                                      AS shift_status
    FROM date_series d
    CROSS JOIN shifts_ref s
    LEFT JOIN supervisors sv ON sv.crew_code = s.crew_code
    WHERE d.dt < CURRENT_DATE()
    `;
    snowflake.execute({sqlText: sql_gen});
    return "Shift instances generated for past " + days_back + " days";
$$;

CALL GENERATE_SHIFT_INSTANCES(90);


-- ============================================================
-- Simulate Vehicle Telemetry — stored proc for Iceberg table
-- Generates 1-minute interval telemetry for 90 days
-- ============================================================
USE SCHEMA OPS_STREAM;

CREATE OR REPLACE PROCEDURE SIMULATE_VEHICLE_TELEMETRY(days_back INT)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  result STRING DEFAULT '';
BEGIN
    -- Insert simulated telemetry using SQL generation
    INSERT INTO VEHICLE_TELEMETRY
    (telemetry_id, equipment_id, equipment_code, equipment_class,
     operator_id, shift_instance_id,
     event_ts, event_ts_local, ingestion_ts,
     latitude, longitude, elevation_m, heading_deg, speed_kmh,
     current_zone, vehicle_state, is_loaded,
     payload_t, payload_status,
     engine_hours, engine_rpm, engine_load_pct,
     engine_coolant_temp_c, engine_oil_temp_c,
     fuel_level_pct, fuel_consumption_lph,
     gear_position,
     brake_temp_fl_c, brake_temp_fr_c,
     tyre_pressure_fl_kpa, tyre_pressure_fr_kpa,
     tyre_pressure_rl_kpa, tyre_pressure_rr_kpa,
     fault_count, high_priority_alarm,
     vehicle_state, payload_status, signal_source, record_quality)

    WITH
    equip AS (
        SELECT equipment_id, equipment_code, equipment_class,
               ROW_NUMBER() OVER (ORDER BY equipment_code) AS rn
        FROM MINING_DB.OPS_REF.EQUIPMENT
        WHERE equipment_class IN ('HAUL_TRUCK','EXCAVATOR','DOZER','GRADER','WATER_TRUCK')
          AND equipment_status = 'ACTIVE'
    ),
    minutes AS (
        SELECT DATEADD('minute', -seq4(),
            DATEADD('day', 1, CURRENT_TIMESTAMP())) AS ts
        FROM TABLE(GENERATOR(ROWCOUNT => :days_back * 1440))
    ),
    ops AS (
        SELECT
            e.equipment_id,
            e.equipment_code,
            e.equipment_class,
            m.ts                                                        AS event_ts,
            -- Base position near dig face, with noise
            -29.450 + (e.rn * 0.001) + UNIFORM(-0.003, 0.003, RANDOM()) AS latitude,
             117.820 + (e.rn * 0.001) + UNIFORM(-0.003, 0.003, RANDOM()) AS longitude,
             370 + UNIFORM(-30, 30, RANDOM())::NUMBER(8,2)              AS elevation_m,
             UNIFORM(0, 360, RANDOM())::NUMBER(6,2)                     AS heading_deg,
             CASE e.equipment_class
                 WHEN 'HAUL_TRUCK'  THEN UNIFORM(0, 45, RANDOM())::NUMBER(8,2)
                 WHEN 'EXCAVATOR'   THEN 0.0
                 WHEN 'DOZER'       THEN UNIFORM(0, 8, RANDOM())::NUMBER(8,2)
                 ELSE UNIFORM(0, 20, RANDOM())::NUMBER(8,2)
             END                                                        AS speed_kmh,
             -- Cycle state based on minute of hour
             CASE
                 WHEN MINUTE(m.ts) BETWEEN 0  AND 5  THEN 'LOADING'
                 WHEN MINUTE(m.ts) BETWEEN 6  AND 20 THEN 'HAULING_LOADED'
                 WHEN MINUTE(m.ts) BETWEEN 21 AND 25 THEN 'DUMPING'
                 WHEN MINUTE(m.ts) BETWEEN 26 AND 38 THEN 'HAULING_EMPTY'
                 WHEN MINUTE(m.ts) BETWEEN 39 AND 44 THEN 'SPOTTING'
                 ELSE 'IDLE'
             END                                                        AS vehicle_state,
             (MINUTE(m.ts) BETWEEN 6 AND 25)::BOOLEAN                  AS is_loaded,
             CASE WHEN MINUTE(m.ts) BETWEEN 6 AND 25
                  THEN UNIFORM(180, 230, RANDOM())::NUMBER(10,3)
                  ELSE 0
             END                                                        AS payload_t,
             -- Engine metrics
             UNIFORM(10000, 25000, RANDOM())::NUMBER(12,2)             AS engine_hours,
             CASE WHEN speed_kmh > 5 THEN UNIFORM(1200,1800,RANDOM())
                  ELSE UNIFORM(600, 900, RANDOM())
             END::INT                                                    AS engine_rpm,
             UNIFORM(40, 95, RANDOM())::NUMBER(6,2)                    AS engine_load_pct,
             UNIFORM(82, 98, RANDOM())::NUMBER(6,2)                    AS engine_coolant_temp_c,
             UNIFORM(88, 105, RANDOM())::NUMBER(6,2)                   AS engine_oil_temp_c,
             UNIFORM(30, 95, RANDOM())::NUMBER(6,2)                    AS fuel_level_pct,
             UNIFORM(80, 180, RANDOM())::NUMBER(8,2)                   AS fuel_consumption_lph,
             UNIFORM(840, 860, RANDOM())::NUMBER(7,2)                  AS tyre_pressure_kpa,
             -- Fault simulation (1% fault rate)
             (UNIFORM(0,1,RANDOM()) < 0.01)::BOOLEAN                   AS has_fault,
             UNIFORM(1, 5, RANDOM())::INT                               AS fault_code_count
        FROM equip e
        CROSS JOIN minutes m
        WHERE HOUR(m.ts) BETWEEN 6 AND 18  -- Day shift simulation
           OR HOUR(m.ts) BETWEEN 18 AND 6  -- Night shift
    )
    SELECT
        UUID_STRING()                       AS telemetry_id,
        equipment_id,
        equipment_code,
        equipment_class,
        NULL                                AS operator_id,
        NULL                                AS shift_instance_id,
        event_ts,
        CONVERT_TIMEZONE('Australia/Perth', event_ts) AS event_ts_local,
        CURRENT_TIMESTAMP()                 AS ingestion_ts,
        latitude,
        longitude,
        elevation_m,
        heading_deg,
        speed_kmh,
        CASE vehicle_state
            WHEN 'LOADING'          THEN 'DIG_FACE'
            WHEN 'HAULING_LOADED'   THEN 'HAUL_ROAD'
            WHEN 'DUMPING'          THEN 'STOCKPILE'
            WHEN 'HAULING_EMPTY'    THEN 'HAUL_ROAD'
            WHEN 'SPOTTING'         THEN 'DIG_FACE'
            ELSE                         'IDLE_BAY'
        END                                 AS current_zone,
        vehicle_state,
        is_loaded,
        payload_t,
        CASE WHEN payload_t > 220 THEN 'LOADED'
             WHEN payload_t > 0   THEN 'PARTIAL'
             ELSE                      'EMPTY'
        END                                 AS payload_status,
        engine_hours,
        engine_rpm,
        engine_load_pct,
        engine_coolant_temp_c,
        engine_oil_temp_c,
        fuel_level_pct,
        fuel_consumption_lph,
        '4'                                 AS gear_position,
        UNIFORM(35, 55, RANDOM())::NUMBER(6,2) AS brake_temp_fl_c,
        UNIFORM(35, 55, RANDOM())::NUMBER(6,2) AS brake_temp_fr_c,
        tyre_pressure_kpa                   AS tyre_pressure_fl_kpa,
        tyre_pressure_kpa                   AS tyre_pressure_fr_kpa,
        tyre_pressure_kpa                   AS tyre_pressure_rl_kpa,
        tyre_pressure_kpa                   AS tyre_pressure_rr_kpa,
        IFF(has_fault, fault_code_count, 0) AS fault_count,
        has_fault                           AS high_priority_alarm,
        'GPS'                               AS signal_source,
        'GOOD'                              AS record_quality
    FROM ops;

    result := 'Vehicle telemetry simulation complete';
    RETURN result;
END;
$$;

-- NOTE: This generates a large volume of data (~10M+ rows). 
-- Run with reduced days for testing: CALL SIMULATE_VEHICLE_TELEMETRY(7);
-- CALL SIMULATE_VEHICLE_TELEMETRY(90);


-- ============================================================
-- Simulate Product Movement Events
-- ============================================================
CREATE OR REPLACE PROCEDURE SIMULATE_PRODUCT_MOVEMENT(days_back INT)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE result STRING DEFAULT '';
BEGIN
    INSERT INTO PRODUCT_MOVEMENT
    (movement_id, movement_chain_id, shift_instance_id,
     event_ts, ingestion_ts,
     movement_type, movement_status,
     source_location_id, source_location_type,
     dest_location_id, dest_location_type,
     primary_equipment_id, operator_id,
     material_type_id,
     gross_tonnes, net_tonnes, moisture_pct,
     grade_fepct, grade_al2o3_pct, grade_sio2_pct,
     weighing_method, measurement_accuracy,
     movement_start_ts, movement_end_ts, duration_minutes,
     haul_distance_m, haul_time_min, cycle_number)

    WITH
    trucks AS (
        SELECT equipment_id, equipment_code
        FROM MINING_DB.OPS_REF.EQUIPMENT
        WHERE equipment_class = 'HAUL_TRUCK' AND equipment_status = 'ACTIVE'
    ),
    dig_locations AS (
        SELECT location_id
        FROM MINING_DB.OPS_REF.LOCATIONS
        WHERE location_type = 'DIG_FACE' AND is_active = TRUE
        LIMIT 4
    ),
    stockpile_locs AS (
        SELECT location_id
        FROM MINING_DB.OPS_REF.LOCATIONS
        WHERE location_type = 'STOCKPILE' AND is_active = TRUE
        LIMIT 3
    ),
    material AS (
        SELECT material_type_id, material_code
        FROM MINING_DB.OPS_REF.MATERIAL_TYPES
        WHERE material_category IN ('ORE','ROM') AND is_active = TRUE
        LIMIT 3
    ),
    day_series AS (
        SELECT DATEADD('day', -seq4(), CURRENT_DATE()) AS dt,
               seq4() AS day_num
        FROM TABLE(GENERATOR(ROWCOUNT => :days_back))
    ),
    cycles AS (
        SELECT
            t.equipment_id,
            t.equipment_code,
            d.dt,
            seq4() AS cycle_num,
            -- 10–14 cycles per truck per shift
            DATEADD('minute',
                (seq4() % 14) * 45 + UNIFORM(0,5,RANDOM()),
                TIMESTAMP_FROM_PARTS(d.dt, '06:30')
            ) AS cycle_start
        FROM trucks t
        CROSS JOIN day_series d
        CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 12))
    )
    SELECT
        UUID_STRING()                                                           AS movement_id,
        UUID_STRING()                                                           AS movement_chain_id,
        NULL                                                                    AS shift_instance_id,
        cycle_start                                                             AS event_ts,
        CURRENT_TIMESTAMP()                                                     AS ingestion_ts,
        'DIG_TO_TRUCK'                                                          AS movement_type,
        'COMPLETED'                                                             AS movement_status,
        (SELECT location_id FROM dig_locations ORDER BY RANDOM() LIMIT 1)      AS source_location_id,
        'DIG_FACE'                                                              AS source_location_type,
        (SELECT location_id FROM stockpile_locs ORDER BY RANDOM() LIMIT 1)     AS dest_location_id,
        'STOCKPILE'                                                             AS dest_location_type,
        equipment_id                                                            AS primary_equipment_id,
        NULL                                                                    AS operator_id,
        (SELECT material_type_id FROM material ORDER BY RANDOM() LIMIT 1)      AS material_type_id,
        UNIFORM(190, 230, RANDOM())::NUMBER(14,3)                              AS gross_tonnes,
        UNIFORM(185, 225, RANDOM())::NUMBER(14,3)                              AS net_tonnes,
        UNIFORM(4.5, 8.5, RANDOM())::NUMBER(6,3)                              AS moisture_pct,
        UNIFORM(56.0, 64.5, RANDOM())::NUMBER(6,3)                            AS grade_fepct,
        UNIFORM(1.2, 3.5, RANDOM())::NUMBER(6,3)                              AS grade_al2o3_pct,
        UNIFORM(3.0, 7.5, RANDOM())::NUMBER(6,3)                              AS grade_sio2_pct,
        'OBW'                                                                   AS weighing_method,
        'STANDARD'                                                              AS measurement_accuracy,
        cycle_start                                                             AS movement_start_ts,
        DATEADD('minute', UNIFORM(35,45,RANDOM()), cycle_start)               AS movement_end_ts,
        UNIFORM(35.0, 45.0, RANDOM())::NUMBER(10,2)                           AS duration_minutes,
        UNIFORM(1200, 3500, RANDOM())::NUMBER(10,2)                           AS haul_distance_m,
        UNIFORM(18.0, 28.0, RANDOM())::NUMBER(8,2)                            AS haul_time_min,
        cycle_num::INT                                                          AS cycle_number
    FROM cycles;

    result := 'Product movement simulation complete';
    RETURN result;
END;
$$;

-- CALL SIMULATE_PRODUCT_MOVEMENT(90);

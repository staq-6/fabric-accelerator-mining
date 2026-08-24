"""
Insert sample rows into all 6 Iceberg tables so data appears in OneLake.
Run from: snowflake/scripts/
"""

import os, sys
from pathlib import Path
from dotenv import load_dotenv
import snowflake.connector
import getpass

load_dotenv(Path(__file__).parent.parent / "setup" / ".env")

_auth = os.environ.get("SNOWFLAKE_AUTHENTICATOR", "username_password_mfa").lower()
params = {
    "account":       os.environ["SNOWFLAKE_ACCOUNT"],
    "user":          os.environ["SNOWFLAKE_USER"],
    "warehouse":     os.environ.get("SNOWFLAKE_WAREHOUSE", "MINING_WH"),
    "role":          os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    "database":      "MINING_DB",
    "schema":        "OPS_STREAM",
    "authenticator": _auth,
}
if _auth == "password":
    params["password"] = os.environ["SNOWFLAKE_PASSWORD"]
elif _auth == "username_password_mfa":
    params["password"] = os.environ.get("SNOWFLAKE_PASSWORD") or getpass.getpass("Password: ")
    params["passcode"] = input("MFA code: ").strip()

INSERTS = {

"VEHICLE_TELEMETRY": """
INSERT INTO MINING_DB.OPS_STREAM.VEHICLE_TELEMETRY (
    telemetry_id, equipment_id, equipment_code, equipment_class,
    event_ts, ingestion_ts,
    latitude, longitude, elevation_m, heading_deg, speed_kmh,
    current_zone, vehicle_state, is_loaded,
    payload_t, payload_status,
    engine_hours, engine_rpm, engine_load_pct,
    engine_coolant_temp_c, engine_oil_temp_c,
    fuel_level_pct, fuel_consumption_lph,
    fault_count, high_priority_alarm,
    signal_source, record_quality
) VALUES (
    '11111111-0000-0000-0000-000000000001',
    'HT-001', 'HT-001', 'HAUL_TRUCK',
    CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(),
    -29.450000, 117.820000, 375.0, 45.0, 28.5,
    'HAUL_ROAD', 'HAULING_LOADED', TRUE,
    205.5, 'LOADED',
    12450.5, 1450, 78.2,
    88.5, 96.2,
    72.3, 125.4,
    0, FALSE,
    'GPS', 'GOOD'
)
""",

"CONVEYOR_BELT_TELEMETRY": """
INSERT INTO MINING_DB.OPS_STREAM.CONVEYOR_BELT_TELEMETRY (
    telemetry_id, equipment_id, equipment_code,
    event_ts, ingestion_ts,
    belt_running, belt_speed_ms, throughput_tph, tonnage_carried_t,
    drive_power_kw, motor_temp_c, specific_energy_kwh_t,
    belt_wear_pct, idler_vibration_mm_s, belt_mistracking_mm,
    emergency_stop_active, belt_rip_detected, spillage_detected,
    fire_detected, overload_detected, fault_count,
    availability_state
) VALUES (
    '22222222-0000-0000-0000-000000000001',
    'CV-01', 'CV-01',
    CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(),
    TRUE, 4.5, 4250.0, 185000.0,
    2800.0, 74.2, 0.118,
    22.5, 2.8, 4.2,
    FALSE, FALSE, FALSE,
    FALSE, FALSE, 0,
    'RUNNING'
)
""",

"CRUSHER_TELEMETRY": """
INSERT INTO MINING_DB.OPS_STREAM.CRUSHER_TELEMETRY (
    telemetry_id, equipment_id, equipment_code,
    crusher_type, crusher_stage,
    event_ts, ingestion_ts,
    crusher_running, availability_state, cavity_level_pct, choking_detected,
    feed_rate_tph, product_rate_tph,
    main_drive_power_kw, specific_energy_kwh_t,
    css_mm, mantle_wear_pct, concave_wear_pct,
    bearing_vibration_de_mm_s, bearing_temp_de_c,
    lube_oil_pressure_kpa, lube_oil_temp_c, lube_oil_contamination_ppm,
    tramp_release_active, tramp_release_count,
    fault_count, high_priority_alarm, is_available
) VALUES (
    '33333333-0000-0000-0000-000000000001',
    'CR-P01', 'CR-P01',
    'PRIMARY_GYRATORY', 'PRIMARY',
    CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(),
    TRUE, 'RUNNING', 62.0, FALSE,
    4800.0, 4750.0,
    2750.0, 0.125,
    165.0, 28.5, 30.2,
    2.1, 52.3,
    285.0, 48.5, 8,
    FALSE, 0,
    0, FALSE, 1.0
)
""",

"DIG_FACE_OPERATIONS": """
INSERT INTO MINING_DB.OPS_STREAM.DIG_FACE_OPERATIONS (
    operation_id, location_id, shift_instance_id,
    equipment_id, operator_id,
    event_ts, ingestion_ts,
    operation_type, operation_status,
    material_type_id,
    insitu_volume_m3, loose_volume_m3, estimated_tonnes,
    measured_grade_fepct, dig_rate_bcm_hr,
    face_latitude, face_longitude, face_elevation_m,
    load_count, avg_spot_time_s, avg_load_time_s, avg_payload_t,
    operation_start_ts, operation_end_ts, duration_minutes
) VALUES (
    '44444444-0000-0000-0000-000000000001',
    'DF-N01', NULL,
    'EX-001', 'OP-006',
    CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(),
    'EXCAVATION_CYCLE', 'COMPLETED',
    'ORE-HG',
    420.5, 567.7, 1050.0,
    61.8, 380.0,
    -29.450000, 117.820000, 378.5,
    5, 45.0, 380.0, 210.0,
    CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 35.5
)
""",

"STOCKPILE_VOLUMES": """
INSERT INTO MINING_DB.OPS_STREAM.STOCKPILE_VOLUMES (
    survey_id, location_id,
    survey_ts, ingestion_ts,
    survey_method, survey_quality, survey_accuracy_pct, surveyed_by,
    volume_m3, bulk_density_t_m3, estimated_tonnes,
    design_capacity_m3, utilisation_pct,
    volume_added_m3, volume_reclaimed_m3, net_movement_m3,
    material_type_id, blended_material,
    avg_grade_fepct,
    centroid_latitude, centroid_longitude, peak_elevation_m
) VALUES (
    '55555555-0000-0000-0000-000000000001',
    'SP-ORE-N',
    CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(),
    'DRONE_SURVEY', 'GOOD', 2.5, 'Survey Team A',
    125000.0, 2.5, 312500.0,
    312500.0, 40.0,
    8500.0, 6200.0, 2300.0,
    'ORE-HG', FALSE,
    61.5,
    -29.445000, 117.818000, 328.5
)
""",

"PRODUCT_MOVEMENT": """
INSERT INTO MINING_DB.OPS_STREAM.PRODUCT_MOVEMENT (
    movement_id, movement_chain_id, shift_instance_id,
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
) VALUES (
    '66666666-0000-0000-0000-000000000001',
    '66666666-0000-0000-0000-000000000002', NULL,
    CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(),
    'DIG_TO_TRUCK', 'COMPLETED',
    'DF-N01', 'DIG_FACE',
    'SP-ORE-N', 'STOCKPILE',
    'HT-001',
    'ORE-HG',
    207.5, 195.0, 6.0,
    61.8, 2.1, 4.8,
    'OBW', 'STANDARD',
    CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(),
    38.5, 2450.0, 22.0,
    1, FALSE
)
"""

}

def main():
    print("Connecting to Snowflake...")
    conn = snowflake.connector.connect(**params)
    cur  = conn.cursor()
    print("Connected\n")

    for table, sql in INSERTS.items():
        try:
            cur.execute(sql.strip())
            print(f"  ✓  Inserted sample row into {table}")
        except Exception as e:
            print(f"  ✗  {table}: {e}")

    cur.execute("SELECT 'VEHICLE_TELEMETRY' as tbl, COUNT(*) FROM MINING_DB.OPS_STREAM.VEHICLE_TELEMETRY UNION ALL SELECT 'CONVEYOR_BELT_TELEMETRY', COUNT(*) FROM MINING_DB.OPS_STREAM.CONVEYOR_BELT_TELEMETRY UNION ALL SELECT 'CRUSHER_TELEMETRY', COUNT(*) FROM MINING_DB.OPS_STREAM.CRUSHER_TELEMETRY UNION ALL SELECT 'DIG_FACE_OPERATIONS', COUNT(*) FROM MINING_DB.OPS_STREAM.DIG_FACE_OPERATIONS UNION ALL SELECT 'STOCKPILE_VOLUMES', COUNT(*) FROM MINING_DB.OPS_STREAM.STOCKPILE_VOLUMES UNION ALL SELECT 'PRODUCT_MOVEMENT', COUNT(*) FROM MINING_DB.OPS_STREAM.PRODUCT_MOVEMENT")
    print("\nRow counts:")
    for row in cur.fetchall():
        print(f"  {row[0]:<35} {row[1]} row(s)")

    cur.close()
    conn.close()
    print("\nDone — check OneLake Files/iceberg/ for Parquet files")

if __name__ == "__main__":
    main()

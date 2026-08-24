#!/usr/bin/env python3
"""
Mining Accelerator — Generate Historical Data for Iceberg Tables
Generates 60 days of realistic operational history with data coherence across tables.
Creates separate INSERT statements for each Iceberg table.
"""

import random
import uuid
import datetime
import json
from typing import List, Dict, Tuple
import os
from pathlib import Path

# Configuration
DAYS = 60
TRUCKS = 5
TELEMETRY_POINTS_PER_TRUCK_PER_DAY = 100
BELTS = 3
TELEMETRY_POINTS_PER_BELT_PER_DAY = 50
CRUSHERS = 3
TELEMETRY_POINTS_PER_CRUSHER_PER_DAY = 50
DIG_CYCLES_PER_DAY = 8
STOCKPILE_SURVEYS_PER_DAY = 12  # 4 surveys × 3 stockpiles
HAUL_MOVEMENTS_PER_DAY = 10

# Mining site locations
DIG_FACES = ["DF-N01", "DF-N02", "DF-N03", "DF-N04"]
STOCKPILES = ["SP-ORE-N", "SP-ORE-S", "SP-LG"]
EXCAVATORS = ["EX-001", "EX-002"]
TRUCK_IDS = [f"HT-00{i}" for i in range(1, TRUCKS + 1)]
BELT_IDS = [f"CV-0{i}" for i in range(1, BELTS + 1)]
CRUSHER_IDS = ["CR-P01", "CR-S01", "CR-T01"]
OPERATORS = ["OP-004", "OP-005", "OP-006"]
MATERIAL_TYPES = ["ORE-HG", "ORE-MG", "WASTE"]
MATERIAL_GRADES = {
    "ORE-HG": (58.5, 64.5),
    "ORE-MG": (52.0, 58.0),
    "WASTE": (2.0, 6.0)
}

class IcebergDataGenerator:
    def __init__(self, days: int = DAYS):
        self.days = days
        self.base_date = datetime.datetime.now() - datetime.timedelta(days=days)
        self.random = random.Random(42)  # Seed for reproducibility
        
    def random_float(self, min_val: float, max_val: float) -> float:
        """Generate random float in range"""
        return self.random.uniform(min_val, max_val)
    
    def random_int(self, min_val: int, max_val: int) -> int:
        """Generate random integer in range"""
        return self.random.randint(min_val, max_val)
    
    def random_choice(self, choices: List) -> any:
        """Random choice from list"""
        return self.random.choice(choices)
    
    def random_bool(self, probability: float = 0.5) -> bool:
        """Random boolean with given probability"""
        return self.random.random() < probability
    
    def generate_timestamp(self, day_offset: int, hour_offset: int = None) -> str:
        """Generate Snowflake TIMESTAMP_LTZ string"""
        ts = self.base_date + datetime.timedelta(days=day_offset)
        if hour_offset is not None:
            ts += datetime.timedelta(hours=hour_offset)
        return f"'{ts.strftime('%Y-%m-%d %H:%M:%S')}'"
    
    def generate_vehicle_telemetry(self) -> List[Dict]:
        """Generate ~30k VEHICLE_TELEMETRY rows"""
        rows = []
        for day in range(self.days):
            for truck_idx in range(TRUCKS):
                truck_id = TRUCK_IDS[truck_idx]
                for point in range(TELEMETRY_POINTS_PER_TRUCK_PER_DAY):
                    # Realistic vehicle states with correlated metrics
                    state_rand = self.random_int(0, 100)
                    if state_rand < 10:
                        vehicle_state = "SPOTTING"
                        speed_kmh = self.random_float(0, 5)
                        payload_t = 0
                    elif state_rand < 30:
                        vehicle_state = "LOADING"
                        speed_kmh = self.random_float(0, 5)
                        payload_t = 0
                    elif state_rand < 65:
                        vehicle_state = "HAULING_LOADED"
                        speed_kmh = self.random_float(28, 42)
                        payload_t = self.random_float(190, 225)
                    elif state_rand < 75:
                        vehicle_state = "DUMPING"
                        speed_kmh = self.random_float(0, 5)
                        payload_t = 0
                    elif state_rand < 90:
                        vehicle_state = "HAULING_EMPTY"
                        speed_kmh = self.random_float(15, 25)
                        payload_t = 0
                    else:
                        vehicle_state = "IDLE"
                        speed_kmh = 0
                        payload_t = 0
                    
                    row = {
                        "telemetry_id": str(uuid.uuid4()),
                        "equipment_id": truck_id,
                        "equipment_code": truck_id,
                        "equipment_class": "HAUL_TRUCK",
                        "operator_id": None,
                        "shift_instance_id": None,
                        "event_ts": self.generate_timestamp(day, point // 10),
                        "ingestion_ts": self.generate_timestamp(day, point // 10),
                        "latitude": f"{-29.450 + self.random_float(-0.01, 0.01):.6f}",
                        "longitude": f"{117.820 + self.random_float(-0.01, 0.01):.6f}",
                        "elevation_m": f"{self.random_float(350, 400):.2f}",
                        "gps_accuracy_m": f"{self.random_float(2.0, 3.5):.2f}",
                        "heading_deg": f"{self.random_float(0, 360):.1f}",
                        "speed_kmh": f"{speed_kmh:.2f}",
                        "speed_ms": f"{speed_kmh / 3.6:.2f}",
                        "current_location_id": "DIG_FACE",
                        "current_zone": self.random_choice(["DIG_FACE", "HAUL_ROAD", "STOCKPILE", "IDLE_BAY"]),
                        "previous_location_id": None,
                        "nearest_landmark": None,
                        "vehicle_state": vehicle_state,
                        "is_loaded": "true" if payload_t > 0 else "false",
                        "payload_t": f"{payload_t:.2f}",
                        "payload_status": "LOADED" if payload_t > 0 else "EMPTY",
                        "overload_pct": None,
                        "engine_hours": f"{self.random_int(5000, 25000)}",
                        "engine_rpm": f"{self.random_int(1200, 1800) if payload_t > 0 else self.random_int(600, 900)}",
                        "engine_load_pct": f"{self.random_float(65, 85) if payload_t > 0 else self.random_float(15, 35):.2f}",
                        "engine_coolant_temp_c": f"{self.random_float(82, 100):.2f}",
                        "engine_oil_temp_c": f"{self.random_float(88, 108):.2f}",
                        "engine_oil_pressure_kpa": f"{self.random_float(280, 320):.2f}",
                        "exhaust_temp_c": f"{self.random_float(200, 280):.2f}",
                        "fuel_level_pct": f"{self.random_float(25, 95):.2f}",
                        "fuel_consumption_lph": f"{self.random_float(100, 160) if payload_t > 0 else self.random_float(20, 50):.2f}",
                        "fuel_consumed_l": f"{self.random_float(2.5, 25.0):.2f}",
                        "gear_position": "D" if payload_t > 0 else "N",
                        "transmission_oil_temp_c": f"{self.random_float(75, 92):.2f}",
                        "brake_temp_fl_c": f"{self.random_float(180, 220):.2f}",
                        "brake_temp_fr_c": f"{self.random_float(180, 220):.2f}",
                        "brake_temp_rl_c": f"{self.random_float(160, 200):.2f}",
                        "brake_temp_rr_c": f"{self.random_float(160, 200):.2f}",
                        "retard_active": "false",
                        "tyre_pressure_fl_kpa": f"{self.random_float(700, 850):.2f}",
                        "tyre_pressure_fr_kpa": f"{self.random_float(700, 850):.2f}",
                        "tyre_pressure_rl_kpa": f"{self.random_float(700, 850):.2f}",
                        "tyre_pressure_rr_kpa": f"{self.random_float(700, 850):.2f}",
                        "tyre_temp_fl_c": f"{self.random_float(45, 65):.2f}",
                        "tyre_temp_rr_c": f"{self.random_float(45, 65):.2f}",
                        "hydraulic_oil_temp_c": f"{self.random_float(65, 85):.2f}",
                        "hydraulic_pressure_kpa": f"{self.random_float(150, 250):.2f}",
                        "swing_angle_deg": None,
                        "bucket_angle_deg": None,
                        "boom_angle_deg": None,
                        "arm_angle_deg": None,
                        "active_fault_codes": None,
                        "fault_count": "1" if self.random_int(1, 500) == 1 else "0",
                        "high_priority_alarm": "true" if self.random_int(1, 500) == 1 else "false",
                        "cycle_start_ts": self.generate_timestamp(day, self.random_int(0, 23)),
                        "load_location_id": "DIG_FACE",
                        "dump_location_id": self.random_choice(STOCKPILES),
                        "material_type_id": self.random_choice(MATERIAL_TYPES),
                        "cycle_payload_t": f"{self.random_float(190, 225) if payload_t > 0 else 0:.2f}",
                        "haul_distance_m": f"{self.random_float(2200, 3100):.2f}",
                        "cycle_duration_s": f"{self.random_int(1200, 2400)}",
                        "signal_source": "GPS",
                        "signal_strength_dbm": f"{self.random_float(-100, -50):.2f}",
                        "record_quality": "GOOD"
                    }
                    rows.append(row)
        return rows
    
    def generate_conveyor_telemetry(self) -> List[Dict]:
        """Generate ~9k CONVEYOR_BELT_TELEMETRY rows"""
        rows = []
        for day in range(self.days):
            for belt_idx, belt_id in enumerate(BELT_IDS):
                for point in range(TELEMETRY_POINTS_PER_BELT_PER_DAY):
                    belt_running = self.random_int(1, 20) != 1  # 95% running
                    
                    row = {
                        "telemetry_id": str(uuid.uuid4()),
                        "equipment_id": belt_id,
                        "equipment_code": belt_id,
                        "location_id": f"LOC-{belt_idx + 1}",
                        "shift_instance_id": None,
                        "event_ts": self.generate_timestamp(day, point // 2),
                        "ingestion_ts": self.generate_timestamp(day, point // 2),
                        "belt_running": "true" if belt_running else "false",
                        "belt_speed_ms": f"{self.random_float(4.2, 4.8) if belt_running else 0:.2f}",
                        "belt_speed_setpoint_ms": "4.5",
                        "belt_direction": "FORWARD",
                        "belt_load_tpm": f"{self.random_float(140000, 200000):.2f}",
                        "throughput_tph": f"{self.random_float(3500, 5500) if belt_running else 0:.2f}",
                        "tonnage_carried_t": f"{self.random_float(100000, 250000):.2f}",
                        "material_type_id": "ORE-HG",
                        "drive_power_kw": f"{self.random_float(2200, 3200) if belt_running else 0:.2f}",
                        "drive_current_a": f"{self.random_float(200, 350) if belt_running else 0:.2f}",
                        "drive_voltage_v": f"{self.random_float(380, 420):.2f}",
                        "motor_temp_c": f"{self.random_float(65, 82) if belt_running else self.random_float(30, 40):.2f}",
                        "motor_rpm": f"{self.random_float(1450, 1500) if belt_running else 0:.2f}",
                        "drive_frequency_hz": f"{self.random_float(50, 60) if belt_running else 0:.2f}",
                        "specific_energy_kwh_t": f"{self.random_float(0.11, 0.14) if belt_running else 0:.4f}",
                        "belt_tension_kn": f"{self.random_float(180, 280):.2f}",
                        "belt_sag_mm": f"{self.random_float(8, 25):.2f}",
                        "idler_vibration_mm_s": f"{self.random_float(1.8, 3.5) if belt_running else 0:.2f}",
                        "head_pulley_temp_c": f"{self.random_float(55, 75):.2f}",
                        "tail_pulley_temp_c": f"{self.random_float(48, 65):.2f}",
                        "belt_slip_pct": f"{self.random_float(0.1, 2.0):.2f}",
                        "belt_wear_pct": f"{self.random_float(15, 50):.2f}",
                        "belt_mistracking_mm": f"{self.random_float(2, 12):.2f}",
                        "hopper_level_pct": f"{self.random_float(40, 85):.2f}",
                        "feed_rate_tph": f"{self.random_float(3500, 5500) if belt_running else self.random_float(500, 2000):.2f}",
                        "skirtboard_wear_pct": f"{self.random_float(20, 60):.2f}",
                        "emergency_stop_active": "false",
                        "belt_rip_detected": "false",
                        "spillage_detected": "true" if self.random_int(1, 300) == 1 else "false",
                        "fire_detected": "false",
                        "overload_detected": "true" if self.random_int(1, 500) == 1 else "false",
                        "active_fault_codes": None,
                        "fault_count": "1" if self.random_int(1, 500) == 1 else "0",
                        "availability_state": "RUNNING" if belt_running else "STOPPED"
                    }
                    rows.append(row)
        return rows
    
    def generate_crusher_telemetry(self) -> List[Dict]:
        """Generate ~9k CRUSHER_TELEMETRY rows"""
        rows = []
        crusher_types = {
            "CR-P01": ("PRIMARY_GYRATORY", "PRIMARY"),
            "CR-S01": ("SECONDARY_CONE", "SECONDARY"),
            "CR-T01": ("TERTIARY_CONE", "TERTIARY")
        }
        
        for day in range(self.days):
            for crusher_id, (crusher_type, stage) in crusher_types.items():
                for point in range(TELEMETRY_POINTS_PER_CRUSHER_PER_DAY):
                    crusher_running = self.random_int(1, 24) != 1  # ~96% running
                    
                    row = {
                        "telemetry_id": str(uuid.uuid4()),
                        "equipment_id": crusher_id,
                        "equipment_code": crusher_id,
                        "crusher_type": crusher_type,
                        "crusher_stage": stage,
                        "location_id": "LOC-CRUSH",
                        "shift_instance_id": None,
                        "event_ts": self.generate_timestamp(day, point // 2),
                        "ingestion_ts": self.generate_timestamp(day, point // 2),
                        "crusher_running": "true" if crusher_running else "false",
                        "availability_state": "RUNNING" if crusher_running else "STOPPED",
                        "cavity_level_pct": f"{self.random_float(45, 75):.2f}",
                        "choking_detected": "false",
                        "feed_rate_tph": f"{self.random_float(3500, 5000) if crusher_running else 0:.2f}",
                        "product_rate_tph": f"{self.random_float(3400, 4900) if crusher_running else 0:.2f}",
                        "cumulative_tonnage_t": f"{self.random_float(50000, 500000):.2f}",
                        "material_type_id": "ORE-HG",
                        "feed_f80_mm": f"{self.random_float(45, 65):.2f}",
                        "product_p80_mm": f"{self.random_float(8, 15):.2f}",
                        "reduction_ratio": f"{self.random_float(3.5, 5.5):.2f}",
                        "main_drive_power_kw": f"{self.random_float(2200, 2900) if crusher_running else 0:.2f}",
                        "main_drive_current_a": f"{self.random_float(250, 350) if crusher_running else 0:.2f}",
                        "main_motor_temp_c": f"{self.random_float(48, 68) if crusher_running else self.random_float(28, 38):.2f}",
                        "main_drive_voltage_v": f"{self.random_float(380, 420):.2f}",
                        "specific_energy_kwh_t": f"{self.random_float(0.118, 0.138) if crusher_running else 0:.4f}",
                        "css_mm": f"{self.random_float(155, 175):.2f}",
                        "oss_mm": f"{self.random_float(185, 210):.2f}",
                        "eccentric_speed_rpm": f"{self.random_float(1450, 1500) if crusher_running else 0:.2f}",
                        "throw_mm": "12.0",
                        "mantle_wear_pct": f"{self.random_float(20, 45):.2f}",
                        "concave_wear_pct": f"{self.random_float(22, 48):.2f}",
                        "liner_wear_mm": f"{self.random_float(3, 8):.2f}",
                        "lube_oil_pressure_kpa": f"{self.random_float(260, 310) if crusher_running else self.random_float(180, 220):.2f}",
                        "lube_oil_temp_c": f"{self.random_float(44, 56) if crusher_running else self.random_float(32, 42):.2f}",
                        "lube_oil_flow_lpm": f"{self.random_float(15, 25) if crusher_running else self.random_float(5, 10):.2f}",
                        "lube_oil_level_pct": f"{self.random_float(60, 90):.2f}",
                        "lube_oil_contamination_ppm": f"{self.random_float(4, 18):.2f}",
                        "hydraulic_pressure_kpa": f"{self.random_float(200, 280) if crusher_running else self.random_float(100, 150):.2f}",
                        "hydraulic_oil_temp_c": f"{self.random_float(48, 58) if crusher_running else self.random_float(32, 42):.2f}",
                        "tramp_release_active": "true" if self.random_int(1, 500) == 1 else "false",
                        "tramp_release_count": "1" if self.random_int(1, 500) == 1 else "0",
                        "bearing_vibration_de_mm_s": f"{self.random_float(2.1, 3.2) if crusher_running else self.random_float(0.5, 1.0):.2f}",
                        "bearing_vibration_nde_mm_s": f"{self.random_float(1.8, 2.8) if crusher_running else self.random_float(0.3, 0.8):.2f}",
                        "frame_vibration_mm_s": f"{self.random_float(1.5, 2.2) if crusher_running else self.random_float(0.2, 0.6):.2f}",
                        "bearing_temp_de_c": f"{self.random_float(48, 62) if crusher_running else self.random_float(35, 45):.2f}",
                        "bearing_temp_nde_c": f"{self.random_float(46, 60) if crusher_running else self.random_float(33, 43):.2f}",
                        "pinion_bearing_temp_c": f"{self.random_float(50, 64) if crusher_running else self.random_float(35, 45):.2f}",
                        "feed_conveyor_id": "CV-01",
                        "discharge_conveyor_id": "CV-02",
                        "feed_bin_level_pct": f"{self.random_float(35, 85):.2f}",
                        "active_fault_codes": None,
                        "fault_count": "1" if self.random_int(1, 500) == 1 else "0",
                        "high_priority_alarm": "true" if self.random_int(1, 500) == 1 else "false",
                        "is_available": "1.0" if crusher_running else "0.0"
                    }
                    rows.append(row)
        return rows
    
    def generate_dig_face_operations(self) -> List[Dict]:
        """Generate ~480 DIG_FACE_OPERATIONS rows"""
        rows = []
        for day in range(self.days):
            for cycle in range(DIG_CYCLES_PER_DAY):
                material_rand = self.random_int(1, 10)
                if material_rand <= 6:
                    material_type = "ORE-HG"
                    grade = self.random_float(58.5, 64.5)
                elif material_rand <= 8:
                    material_type = "ORE-MG"
                    grade = self.random_float(52.0, 58.0)
                else:
                    material_type = "WASTE"
                    grade = self.random_float(2.0, 6.0)
                
                row = {
                    "operation_id": str(uuid.uuid4()),
                    "location_id": self.random_choice(DIG_FACES),
                    "shift_instance_id": None,
                    "equipment_id": self.random_choice(EXCAVATORS),
                    "operator_id": self.random_choice(OPERATORS),
                    "event_ts": self.generate_timestamp(day, cycle),
                    "ingestion_ts": self.generate_timestamp(day, cycle),
                    "operation_type": "EXCAVATION_CYCLE",
                    "operation_status": "COMPLETED",
                    "material_type_id": material_type,
                    "insitu_volume_m3": f"{self.random_float(380, 520):.2f}",
                    "loose_volume_m3": f"{self.random_float(513, 702):.2f}",
                    "estimated_tonnes": f"{self.random_float(950, 1300):.2f}",
                    "measured_grade_fepct": f"{grade:.2f}",
                    "dig_rate_bcm_hr": f"{self.random_float(330, 420):.2f}",
                    "face_latitude": f"{-29.450 + self.random_float(-0.01, 0.01):.6f}",
                    "face_longitude": f"{117.820 + self.random_float(-0.01, 0.01):.6f}",
                    "face_elevation_m": f"{self.random_float(370, 400):.2f}",
                    "load_count": f"{self.random_int(4, 6)}",
                    "avg_spot_time_s": f"{self.random_float(38, 55):.2f}",
                    "avg_load_time_s": f"{self.random_float(340, 420):.2f}",
                    "avg_payload_t": f"{self.random_float(190, 220):.2f}",
                    "operation_start_ts": self.generate_timestamp(day, cycle - 1),
                    "operation_end_ts": self.generate_timestamp(day, cycle),
                    "duration_minutes": "60.0"
                }
                rows.append(row)
        return rows
    
    def generate_stockpile_volumes(self) -> List[Dict]:
        """Generate ~720 STOCKPILE_VOLUMES rows"""
        rows = []
        methods = ["DRONE_SURVEY", "LASER_SCANNER", "BELT_SCALE_CALC"]
        stockpile_capacities = {"SP-ORE-N": 312500, "SP-ORE-S": 187500, "SP-LG": 500000}
        stockpile_grades = {
            "SP-ORE-N": (59.5, 63.5),
            "SP-ORE-S": (52.0, 58.0),
            "SP-LG": (48.0, 54.0)
        }
        
        for day in range(self.days):
            for survey in range(STOCKPILE_SURVEYS_PER_DAY):
                stockpile = self.random_choice(STOCKPILES)
                method = self.random_choice(methods)
                volume_m3 = self.random_float(40000, 300000)
                bulk_density = 2.5 if stockpile == "SP-ORE-N" else (2.4 if stockpile == "SP-ORE-S" else 2.3)
                capacity = stockpile_capacities[stockpile]
                grade_range = stockpile_grades[stockpile]
                
                row = {
                    "survey_id": str(uuid.uuid4()),
                    "location_id": stockpile,
                    "shift_instance_id": None,
                    "survey_ts": self.generate_timestamp(day, survey),
                    "ingestion_ts": self.generate_timestamp(day, survey),
                    "survey_method": method,
                    "survey_quality": "GOOD",
                    "survey_accuracy_pct": "2.5" if method == "DRONE_SURVEY" else ("1.8" if method == "LASER_SCANNER" else "5.0"),
                    "surveyed_by": f"Survey Team {self.random_int(1, 2)}",
                    "volume_m3": f"{volume_m3:.2f}",
                    "bulk_density_t_m3": f"{bulk_density}",
                    "estimated_tonnes": f"{volume_m3 * bulk_density:.2f}",
                    "design_capacity_m3": f"{capacity}.0",
                    "utilisation_pct": f"{(volume_m3 / capacity * 100):.2f}",
                    "volume_added_m3": f"{self.random_float(2000, 15000):.2f}",
                    "volume_reclaimed_m3": f"{self.random_float(1000, 12000):.2f}",
                    "net_movement_m3": f"{self.random_float(-5000, 8000):.2f}",
                    "material_type_id": "ORE-HG" if stockpile == "SP-ORE-N" else ("ORE-MG" if stockpile == "SP-ORE-S" else "ORE-LG"),
                    "blended_material": "true" if self.random_int(1, 5) == 1 else "false",
                    "avg_grade_fepct": f"{self.random_float(grade_range[0], grade_range[1]):.2f}",
                    "centroid_latitude": f"{-29.445 + self.random_float(-0.005, 0.005):.6f}",
                    "centroid_longitude": f"{117.818 + self.random_float(-0.005, 0.005):.6f}",
                    "peak_elevation_m": f"{self.random_float(315, 335):.2f}"
                }
                rows.append(row)
        return rows
    
    def generate_product_movement(self) -> List[Dict]:
        """Generate ~600 PRODUCT_MOVEMENT rows"""
        rows = []
        for day in range(self.days):
            for cycle in range(HAUL_MOVEMENTS_PER_DAY):
                material_rand = self.random_int(1, 10)
                if material_rand <= 6:
                    material_type = "ORE-HG"
                    grade = self.random_float(58.5, 64.5)
                elif material_rand <= 8:
                    material_type = "ORE-MG"
                    grade = self.random_float(52.0, 58.0)
                else:
                    material_type = "WASTE"
                    grade = self.random_float(2.0, 6.0)
                
                row = {
                    "movement_id": str(uuid.uuid4()),
                    "parent_movement_id": None,
                    "movement_chain_id": str(uuid.uuid4()),
                    "shift_instance_id": None,
                    "event_ts": self.generate_timestamp(day, cycle),
                    "ingestion_ts": self.generate_timestamp(day, cycle),
                    "movement_type": "DIG_TO_TRUCK",
                    "movement_status": "COMPLETED",
                    "source_location_id": self.random_choice(DIG_FACES),
                    "source_location_type": "DIG_FACE",
                    "dest_location_id": self.random_choice(STOCKPILES),
                    "dest_location_type": "STOCKPILE",
                    "primary_equipment_id": self.random_choice(TRUCK_IDS),
                    "material_type_id": material_type,
                    "gross_tonnes": f"{self.random_float(195, 230):.2f}",
                    "net_tonnes": f"{self.random_float(180, 215):.2f}",
                    "moisture_pct": f"{self.random_float(5.0, 8.5):.2f}",
                    "grade_fepct": f"{grade:.2f}",
                    "grade_al2o3_pct": f"{self.random_float(1.8, 3.2):.2f}",
                    "grade_sio2_pct": f"{self.random_float(3.5, 7.0):.2f}",
                    "weighing_method": "OBW",
                    "measurement_accuracy": "STANDARD",
                    "movement_start_ts": self.generate_timestamp(day, cycle - 1),
                    "movement_end_ts": self.generate_timestamp(day, cycle),
                    "duration_minutes": f"{self.random_float(35, 45):.2f}",
                    "haul_distance_m": f"{self.random_float(2200, 3200):.2f}",
                    "haul_time_min": f"{self.random_float(18, 28):.2f}",
                    "cycle_number": f"{(cycle % 10) + 1}",
                    "is_reconciled": "false"
                }
                rows.append(row)
        return rows
    
    def generate_sql_insert(self, table_name: str, columns: List[str], rows: List[Dict]) -> str:
        """Generate SQL INSERT statements"""
        if not rows:
            return ""
        
        sql = f"INSERT INTO {table_name} (\n"
        sql += "    " + ", ".join(columns) + "\n"
        sql += ") VALUES\n"
        
        value_strs = []
        for row in rows:
            values = []
            for col in columns:
                val = row.get(col)
                if val is None:
                    values.append("NULL")
                elif isinstance(val, bool):
                    values.append("TRUE" if val else "FALSE")
                elif col.endswith("_ts"):  # Timestamp columns already quoted
                    values.append(val)
                elif col.endswith("_id"):  # ID columns (UUIDs, equipment IDs, etc.)
                    values.append(f"'{val}'")
                elif col in ["vehicle_state", "availability_state", "operation_type", "operation_status",
                             "material_type_id", "survey_method", "survey_quality", "movement_type", 
                             "movement_status", "source_location_type", "dest_location_type", "weighing_method",
                             "measurement_accuracy", "equipment_class", "crusher_type", "crusher_stage",
                             "belt_direction", "current_zone", "payload_status", "gear_position", 
                             "signal_source", "record_quality", "load_location_id", "dump_location_id",
                             "equipment_code"]:
                    values.append(f"'{val}'")
                elif col in ["surveyed_by"]:
                    values.append(f"'{val}'")
                else:
                    # Numeric values (already strings from row dict)
                    values.append(str(val) if val not in ["true", "false"] else ("TRUE" if val == "true" else "FALSE"))
            value_strs.append("(" + ", ".join(values) + ")")
        
        sql += ",\n".join(value_strs) + ";\n"
        return sql
    
    def generate_all_inserts(self, output_dir: str = None) -> Dict[str, str]:
        """Generate all INSERT statements and save to files"""
        os.makedirs(output_dir, exist_ok=True)
        
        print("Generating historical data...")
        
        print("  - Vehicle telemetry...")
        vehicle_rows = self.generate_vehicle_telemetry()
        vehicle_cols = [
            "telemetry_id", "equipment_id", "equipment_code", "equipment_class", "operator_id",
            "shift_instance_id", "event_ts", "ingestion_ts", "latitude", "longitude",
            "elevation_m", "gps_accuracy_m", "heading_deg", "speed_kmh", "speed_ms",
            "current_location_id", "current_zone", "previous_location_id", "nearest_landmark",
            "vehicle_state", "is_loaded", "payload_t", "payload_status", "overload_pct",
            "engine_hours", "engine_rpm", "engine_load_pct", "engine_coolant_temp_c",
            "engine_oil_temp_c", "engine_oil_pressure_kpa", "exhaust_temp_c", "fuel_level_pct",
            "fuel_consumption_lph", "fuel_consumed_l", "gear_position", "transmission_oil_temp_c",
            "brake_temp_fl_c", "brake_temp_fr_c", "brake_temp_rl_c", "brake_temp_rr_c",
            "retard_active", "tyre_pressure_fl_kpa", "tyre_pressure_fr_kpa", "tyre_pressure_rl_kpa",
            "tyre_pressure_rr_kpa", "tyre_temp_fl_c", "tyre_temp_rr_c", "hydraulic_oil_temp_c",
            "hydraulic_pressure_kpa", "swing_angle_deg", "bucket_angle_deg", "boom_angle_deg",
            "arm_angle_deg", "active_fault_codes", "fault_count", "high_priority_alarm",
            "cycle_start_ts", "load_location_id", "dump_location_id", "material_type_id",
            "cycle_payload_t", "haul_distance_m", "cycle_duration_s", "signal_source",
            "signal_strength_dbm", "record_quality"
        ]
        vehicle_sql = self.generate_sql_insert("VEHICLE_TELEMETRY", vehicle_cols, vehicle_rows)
        
        print(f"    Generated {len(vehicle_rows)} rows")
        
        print("  - Conveyor belt telemetry...")
        conveyor_rows = self.generate_conveyor_telemetry()
        conveyor_cols = [
            "telemetry_id", "equipment_id", "equipment_code", "location_id", "shift_instance_id",
            "event_ts", "ingestion_ts", "belt_running", "belt_speed_ms", "belt_speed_setpoint_ms",
            "belt_direction", "belt_load_tpm", "throughput_tph", "tonnage_carried_t", "material_type_id",
            "drive_power_kw", "drive_current_a", "drive_voltage_v", "motor_temp_c", "motor_rpm",
            "drive_frequency_hz", "specific_energy_kwh_t", "belt_tension_kn", "belt_sag_mm",
            "idler_vibration_mm_s", "head_pulley_temp_c", "tail_pulley_temp_c", "belt_slip_pct",
            "belt_wear_pct", "belt_mistracking_mm", "hopper_level_pct", "feed_rate_tph",
            "skirtboard_wear_pct", "emergency_stop_active", "belt_rip_detected", "spillage_detected",
            "fire_detected", "overload_detected", "active_fault_codes", "fault_count", "availability_state"
        ]
        conveyor_sql = self.generate_sql_insert("CONVEYOR_BELT_TELEMETRY", conveyor_cols, conveyor_rows)
        print(f"    Generated {len(conveyor_rows)} rows")
        
        print("  - Crusher telemetry...")
        crusher_rows = self.generate_crusher_telemetry()
        crusher_cols = [
            "telemetry_id", "equipment_id", "equipment_code", "crusher_type", "crusher_stage",
            "location_id", "shift_instance_id", "event_ts", "ingestion_ts", "crusher_running",
            "availability_state", "cavity_level_pct", "choking_detected", "feed_rate_tph",
            "product_rate_tph", "cumulative_tonnage_t", "material_type_id", "feed_f80_mm",
            "product_p80_mm", "reduction_ratio", "main_drive_power_kw", "main_drive_current_a",
            "main_motor_temp_c", "main_drive_voltage_v", "specific_energy_kwh_t", "css_mm", "oss_mm",
            "eccentric_speed_rpm", "throw_mm", "mantle_wear_pct", "concave_wear_pct", "liner_wear_mm",
            "lube_oil_pressure_kpa", "lube_oil_temp_c", "lube_oil_flow_lpm", "lube_oil_level_pct",
            "lube_oil_contamination_ppm", "hydraulic_pressure_kpa", "hydraulic_oil_temp_c",
            "tramp_release_active", "tramp_release_count", "bearing_vibration_de_mm_s",
            "bearing_vibration_nde_mm_s", "frame_vibration_mm_s", "bearing_temp_de_c",
            "bearing_temp_nde_c", "pinion_bearing_temp_c", "feed_conveyor_id", "discharge_conveyor_id",
            "feed_bin_level_pct", "active_fault_codes", "fault_count", "high_priority_alarm", "is_available"
        ]
        crusher_sql = self.generate_sql_insert("CRUSHER_TELEMETRY", crusher_cols, crusher_rows)
        print(f"    Generated {len(crusher_rows)} rows")
        
        print("  - Dig face operations...")
        dig_rows = self.generate_dig_face_operations()
        dig_cols = [
            "operation_id", "location_id", "shift_instance_id", "equipment_id", "operator_id",
            "event_ts", "ingestion_ts", "operation_type", "operation_status", "material_type_id",
            "insitu_volume_m3", "loose_volume_m3", "estimated_tonnes", "measured_grade_fepct",
            "dig_rate_bcm_hr", "face_latitude", "face_longitude", "face_elevation_m", "load_count",
            "avg_spot_time_s", "avg_load_time_s", "avg_payload_t", "operation_start_ts",
            "operation_end_ts", "duration_minutes"
        ]
        dig_sql = self.generate_sql_insert("DIG_FACE_OPERATIONS", dig_cols, dig_rows)
        print(f"    Generated {len(dig_rows)} rows")
        
        print("  - Stockpile volumes...")
        stockpile_rows = self.generate_stockpile_volumes()
        stockpile_cols = [
            "survey_id", "location_id", "shift_instance_id", "survey_ts", "ingestion_ts",
            "survey_method", "survey_quality", "survey_accuracy_pct", "surveyed_by", "volume_m3",
            "bulk_density_t_m3", "estimated_tonnes", "design_capacity_m3", "utilisation_pct",
            "volume_added_m3", "volume_reclaimed_m3", "net_movement_m3", "material_type_id",
            "blended_material", "avg_grade_fepct", "centroid_latitude", "centroid_longitude",
            "peak_elevation_m"
        ]
        stockpile_sql = self.generate_sql_insert("STOCKPILE_VOLUMES", stockpile_cols, stockpile_rows)
        print(f"    Generated {len(stockpile_rows)} rows")
        
        print("  - Product movement...")
        movement_rows = self.generate_product_movement()
        movement_cols = [
            "movement_id", "parent_movement_id", "movement_chain_id", "shift_instance_id",
            "event_ts", "ingestion_ts", "movement_type", "movement_status", "source_location_id",
            "source_location_type", "dest_location_id", "dest_location_type", "primary_equipment_id",
            "material_type_id", "gross_tonnes", "net_tonnes", "moisture_pct", "grade_fepct",
            "grade_al2o3_pct", "grade_sio2_pct", "weighing_method", "measurement_accuracy",
            "movement_start_ts", "movement_end_ts", "duration_minutes", "haul_distance_m",
            "haul_time_min", "cycle_number", "is_reconciled"
        ]
        movement_sql = self.generate_sql_insert("PRODUCT_MOVEMENT", movement_cols, movement_rows)
        print(f"    Generated {len(movement_rows)} rows")
        
        # Write to individual files
        results = {}
        
        with open(os.path.join(output_dir, "01_vehicle_telemetry.sql"), "w") as f:
            header = """USE DATABASE MINING_ICEBERG;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE MINING_WH;
USE SCHEMA PUBLIC;

-- Vehicle Telemetry: 60 days x 5 trucks x 100 points/day = ~30k rows
"""
            f.write(header + vehicle_sql)
            results["01_vehicle_telemetry.sql"] = len(vehicle_rows)
        
        with open(os.path.join(output_dir, "02_conveyor_belt_telemetry.sql"), "w") as f:
            header = """USE DATABASE MINING_ICEBERG;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE MINING_WH;
USE SCHEMA PUBLIC;

-- Conveyor Belt Telemetry: 60 days x 3 belts x 50 points/day = ~9k rows
"""
            f.write(header + conveyor_sql)
            results["02_conveyor_belt_telemetry.sql"] = len(conveyor_rows)
        
        with open(os.path.join(output_dir, "03_crusher_telemetry.sql"), "w") as f:
            header = """USE DATABASE MINING_ICEBERG;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE MINING_WH;
USE SCHEMA PUBLIC;

-- Crusher Telemetry: 60 days x 3 crushers x 50 points/day = ~9k rows
"""
            f.write(header + crusher_sql)
            results["03_crusher_telemetry.sql"] = len(crusher_rows)
        
        with open(os.path.join(output_dir, "04_dig_face_operations.sql"), "w") as f:
            header = """USE DATABASE MINING_ICEBERG;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE MINING_WH;
USE SCHEMA PUBLIC;

-- Dig Face Operations: 60 days x 8 cycles/day = ~480 rows
"""
            f.write(header + dig_sql)
            results["04_dig_face_operations.sql"] = len(dig_rows)
        
        with open(os.path.join(output_dir, "05_stockpile_volumes.sql"), "w") as f:
            header = """USE DATABASE MINING_ICEBERG;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE MINING_WH;
USE SCHEMA PUBLIC;

-- Stockpile Volumes: 60 days x 3 stockpiles x 4 surveys/day = ~720 rows
"""
            f.write(header + stockpile_sql)
            results["05_stockpile_volumes.sql"] = len(stockpile_rows)
        
        with open(os.path.join(output_dir, "06_product_movement.sql"), "w") as f:
            header = """USE DATABASE MINING_ICEBERG;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE MINING_WH;
USE SCHEMA PUBLIC;

-- Product Movement: 60 days x 10 movements/day = ~600 rows
"""
            f.write(header + movement_sql)
            results["06_product_movement.sql"] = len(movement_rows)
        
        return results

if __name__ == "__main__":
    gen = IcebergDataGenerator(days=60)
    results = gen.generate_all_inserts()
    
    print("\nGenerated SQL files:")
    total_rows = 0
    for filename, row_count in sorted(results.items()):
        print(f"  {filename}: {row_count:,} rows")
        total_rows += row_count
    
    print(f"\nTotal: {total_rows:,} rows across 6 tables")
    print("\nSQL files saved to ./snowflake/seed_data/")
    print("\nRun these in Snowsight in order:")
    for filename in sorted(results.keys()):
        print(f"  - {filename}")

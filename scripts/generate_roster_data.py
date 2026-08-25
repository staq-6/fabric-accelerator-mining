#!/usr/bin/env python3
"""
Generate roster data for SHIFT_INSTANCES, OPERATOR_SHIFT_ASSIGNMENTS, and MAINTENANCE_RECORDS
Matches actual Snowflake schema columns exactly
"""

import os
import uuid
import random
from datetime import datetime, timedelta
from typing import List, Dict
import json
from pathlib import Path

class RosterDataGenerator:
    def __init__(self, output_dir: str = None):
        if output_dir is None:
            output_dir = str(Path(__file__).parent.parent / "seed_data")
        self.output_dir = output_dir
        random.seed(42)
        # 60-day history ending today
        self.base_date = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=60)
        self.days = 60

        # Reference IDs — match exactly what seed_all.sql inserts
        self.shift_ids = [str(uuid.uuid4()) for _ in range(3)]  # DAY / AFT / NIGHT
        self.operator_ids = [f"OP-{i:03d}" for i in range(1, 19)] + ["OP-SUP-A", "OP-SUP-B"]  # 20 operators
        self.supervisor_ids = ["OP-SUP-A", "OP-SUP-B"]
        self.equipment_ids = [
            "HT-001", "HT-002", "HT-003", "HT-004", "HT-005",
            "CR-P01", "CR-S01", "CR-T01",
            "EX-001", "EX-002",
            "CV-01", "CV-02",
        ]
        self.sites = ["MINE-01"]
        self.weather = ["Clear", "Dusty", "Rain", "Fog", "Hot", "Windy"]
        self.roles = ["OPERATOR", "SUPERVISOR", "RELIEF", "MAINTENANCE"]

    def generate_shift_instances(self) -> tuple[List[Dict], str]:
        """Generate 3 shifts/day × 60 days = 180 rows"""
        rows = []

        for day_offset in range(self.days):
            shift_date = self.base_date + timedelta(days=day_offset)
            
            for shift_idx, shift_id in enumerate(self.shift_ids):
                # Start hour: 0=DAY, 1=AFT, 2=NIGHT
                start_hour = shift_idx * 8
                end_hour = start_hour + 8
                
                actual_start = shift_date.replace(hour=start_hour, minute=0, second=0)
                actual_end = actual_start + timedelta(hours=8)
                
                rows.append({
                    "shift_instance_id": str(uuid.uuid4()),
                    "shift_id": shift_id,
                    "shift_date": shift_date.strftime("%Y-%m-%d"),
                    "actual_start_ts": actual_start.strftime("%Y-%m-%d %H:%M:%S"),
                    "actual_end_ts": actual_end.strftime("%Y-%m-%d %H:%M:%S"),
                    "supervisor_id": random.choice(self.supervisor_ids),
                    "planned_crew_size": random.randint(8, 14),
                    "actual_crew_size": random.randint(7, 14),
                    "weather_condition": random.choice(self.weather),
                    "blast_scheduled": random.choice([True, False]),
                    "blast_actual": random.choice([True, False]),
                    "shift_notes": random.choice(["Normal operations", "High production day", "Equipment downtime", "Weather delays", "Training shift", "Record tonnage", "Maintenance window"]),
                    "shift_status": "COMPLETED" if day_offset < self.days - 1 else random.choice(["PLANNED", "IN_PROGRESS", "COMPLETED"])
                })
        
        # Generate SQL
        columns = [
            "shift_instance_id", "shift_id", "shift_date", "actual_start_ts", "actual_end_ts",
            "supervisor_id", "planned_crew_size", "actual_crew_size", "weather_condition",
            "blast_scheduled", "blast_actual", "shift_notes", "shift_status"
        ]
        sql = self.generate_sql_insert("SHIFT_INSTANCES", columns, rows)
        
        return rows, sql
    
    def generate_operator_shift_assignments(self, shift_instances: List[Dict]) -> tuple[List[Dict], str]:
        """Generate 6-10 operators per shift (realistic mining crew)"""
        rows = []
        non_supervisor_ops = [o for o in self.operator_ids if not o.startswith("OP-SUP")]

        for shift in shift_instances:
            shift_instance_id = shift["shift_instance_id"]
            num_ops = random.randint(6, 10)
            assigned_ops = random.sample(non_supervisor_ops, min(num_ops, len(non_supervisor_ops)))

            for operator_id in assigned_ops:
                rows.append({
                    "assignment_id": str(uuid.uuid4()),
                    "shift_instance_id": shift_instance_id,
                    "operator_id": operator_id,
                    "equipment_id": random.choice(self.equipment_ids),
                    "role_in_shift": random.choice(self.roles),
                    "assigned_at": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
                })
        
        # Generate SQL
        columns = ["assignment_id", "shift_instance_id", "operator_id", "equipment_id", "role_in_shift", "assigned_at"]
        sql = self.generate_sql_insert("OPERATOR_SHIFT_ASSIGNMENTS", columns, rows)
        
        return rows, sql
    
    def generate_maintenance_records(self) -> tuple[List[Dict], str]:
        """Generate 3-6 maintenance records per day × 60 days = ~250 rows"""
        rows = []

        maintenance_types = ["PREVENTIVE", "CORRECTIVE", "PREDICTIVE", "BREAKDOWN", "INSPECTION"]
        categories = ["MECHANICAL", "ELECTRICAL", "HYDRAULIC", "STRUCTURAL", "TYRES", "LUBRICATION"]
        priorities = ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
        statuses = ["OPEN", "IN_PROGRESS", "PENDING_PARTS", "COMPLETED", "CANCELLED"]
        failure_modes = [
            "Hydraulic leak", "Engine overheat", "Tire failure", "Electrical short",
            "Belt slippage", "Brake wear", "Coolant leak", "Oil contamination",
            "Sensor fault", "Structural crack", "Filter blockage", "Gear wear",
        ]

        for day_offset in range(self.days):
            shift_date = self.base_date + timedelta(days=day_offset)
            num_records = random.randint(3, 6)

            for _ in range(num_records):
                fault_reported = shift_date + timedelta(hours=random.randint(0, 23))
                work_started = fault_reported + timedelta(hours=random.randint(0, 2))
                planned_dur = round(random.uniform(1, 12), 2)
                actual_dur = round(planned_dur * random.uniform(0.8, 1.5), 2)
                work_completed = work_started + timedelta(hours=actual_dur)
                equipment_returned = work_completed + timedelta(hours=random.uniform(0, 1))

                # UUID-based work order — always unique, never collides on re-run
                wo_number = f"WO-{str(uuid.uuid4())[:8].upper()}"

                rows.append({
                    "maintenance_id": str(uuid.uuid4()),
                    "work_order_number": wo_number,
                    "equipment_id": random.choice(self.equipment_ids),
                    "site_code": random.choice(self.sites),
                    "maintenance_type": random.choice(maintenance_types),
                    "maintenance_category": random.choice(categories),
                    "priority": random.choice(priorities),
                    "failure_mode": random.choice(failure_modes),
                    "failure_code": f"FM-{random.randint(100, 999)}",
                    "fault_description": "Maintenance required",
                    "fault_reported_ts": fault_reported.strftime("%Y-%m-%d %H:%M:%S"),
                    "work_started_ts": work_started.strftime("%Y-%m-%d %H:%M:%S"),
                    "work_completed_ts": work_completed.strftime("%Y-%m-%d %H:%M:%S"),
                    "equipment_returned_ts": equipment_returned.strftime("%Y-%m-%d %H:%M:%S"),
                    "planned_duration_hrs": planned_dur,
                    "actual_duration_hrs": actual_dur,
                    "repair_time_hrs": round(actual_dur * random.uniform(0.6, 0.9), 2),
                    "lead_technician_id": random.choice(["OP-015", "OP-016"]),
                    "contractor_company": random.choice(["In-House", "ABC Contractors", "XYZ Services", "Local Repair"]),
                    "total_parts_cost": round(random.uniform(0, 1000), 2),
                    "total_labour_cost": round(planned_dur * 75, 2),
                    "total_cost": round(random.uniform(200, 2000), 2),
                    "engine_hours_at_event": round(random.uniform(5000, 25000), 2),
                    "odometer_km_at_event": round(random.uniform(50000, 250000), 2),
                    "maintenance_status": "COMPLETED" if day_offset < self.days - 7 else random.choice(statuses),
                    "root_cause": random.choice(["Normal wear", "Improper maintenance", "Design flaw", "Operator error"]),
                    "corrective_action": "Repaired and tested",
                    "is_repeat_failure": random.choice([True, False]),
                    "related_maintenance_id": None,
                    "created_at": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"),
                    "updated_at": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"),
                    "created_by": "system"
                })
        
        # Generate SQL - skip VARIANT columns (technician_ids, parts_used)
        columns = [
            "maintenance_id", "work_order_number", "equipment_id", "site_code",
            "maintenance_type", "maintenance_category", "priority", "failure_mode", "failure_code",
            "fault_description", "fault_reported_ts", "work_started_ts", "work_completed_ts",
            "equipment_returned_ts", "planned_duration_hrs", "actual_duration_hrs", "repair_time_hrs",
            "lead_technician_id", "contractor_company",
            "total_parts_cost", "total_labour_cost", "total_cost", "engine_hours_at_event",
            "odometer_km_at_event", "maintenance_status", "root_cause", "corrective_action",
            "is_repeat_failure", "related_maintenance_id", "created_at", "updated_at", "created_by"
        ]
        sql = self.generate_sql_insert("MAINTENANCE_RECORDS", columns, rows)
        
        return rows, sql
    
    def generate_sql_insert(self, table_name: str, columns: List[str], rows: List[Dict], batch_size: int = 500) -> str:
        """Generate batched SQL INSERT statements (batch_size rows per statement)"""
        if not rows:
            return ""

        def _format_value(col: str, val) -> str:
            if val is None:
                return "NULL"
            if isinstance(val, bool):
                return "TRUE" if val else "FALSE"
            if col.endswith("_ts") or col.endswith("_date") or col.endswith("_at"):
                return f"'{val}'"
            if col.endswith("_id") or col in ["equipment_id", "site_code", "operator_id", "shift_id", "contractor_company", "work_order_number"]:
                return f"'{val}'"
            if col in ["maintenance_type", "maintenance_category", "priority", "failure_mode", "failure_code",
                       "fault_description", "weather_condition", "shift_notes", "shift_status", "role_in_shift",
                       "maintenance_status", "root_cause", "corrective_action", "created_by"]:
                escaped = str(val).replace("'", "''")
                return f"'{escaped}'"
            if isinstance(val, (int, float)):
                return str(val)
            escaped = str(val).replace("'", "''")
            return f"'{escaped}'"

        col_list = "    " + ", ".join(columns)
        all_sql = []

        for i in range(0, len(rows), batch_size):
            batch = rows[i:i + batch_size]
            value_strs = []
            for row in batch:
                values = [_format_value(col, row.get(col)) for col in columns]
                value_strs.append("(" + ", ".join(values) + ")")
            all_sql.append(
                f"INSERT INTO {table_name} (\n{col_list}\n) VALUES\n"
                + ",\n".join(value_strs) + ";\n"
            )

        return "\n".join(all_sql)
    
    def run(self):
        """Generate all roster data"""
        print("Generating roster data...")
        
        # Generate shift instances
        print("  - Shift instances...")
        shifts, shift_sql = self.generate_shift_instances()
        print(f"    Generated {len(shifts)} shift instances")
        
        # Generate operator assignments
        print("  - Operator shift assignments...")
        assignments, assignment_sql = self.generate_operator_shift_assignments(shifts)
        print(f"    Generated {len(assignments)} operator assignments")
        
        # Generate maintenance records
        print("  - Maintenance records...")
        maintenance, maintenance_sql = self.generate_maintenance_records()
        print(f"    Generated {len(maintenance)} maintenance records")
        
        # Save to files
        with open(f"{self.output_dir}/07_shift_instances.sql", "w") as f:
            f.write("USE DATABASE MINING_DB;\n")
            f.write("USE ROLE ACCOUNTADMIN;\n")
            f.write("USE WAREHOUSE MINING_WH;\n")
            f.write("USE SCHEMA OPS_REF;\n\n")
            f.write("-- Shift Instances: 3 shifts/day × 60 days = 180 rows\n")
            f.write(shift_sql)
        
        with open(f"{self.output_dir}/08_operator_shift_assignments.sql", "w") as f:
            f.write("USE DATABASE MINING_DB;\n")
            f.write("USE ROLE ACCOUNTADMIN;\n")
            f.write("USE WAREHOUSE MINING_WH;\n")
            f.write("USE SCHEMA OPS_REF;\n\n")
            f.write("-- Operator Shift Assignments: 6-10 ops per shift × 180 shifts\n")
            f.write(assignment_sql)
        
        with open(f"{self.output_dir}/09_maintenance_records.sql", "w") as f:
            f.write("USE DATABASE MINING_DB;\n")
            f.write("USE ROLE ACCOUNTADMIN;\n")
            f.write("USE WAREHOUSE MINING_WH;\n")
            f.write("USE SCHEMA OPS_HIST;\n\n")
            f.write("-- Maintenance Records: 3-6 per day × 60 days = ~250 rows\n")
            f.write(maintenance_sql)
        
        print("\nGenerated SQL files:")
        print(f"  07_shift_instances.sql: {len(shifts)} rows")
        print(f"  08_operator_shift_assignments.sql: {len(assignments)} rows")
        print(f"  09_maintenance_records.sql: {len(maintenance)} rows")
        print(f"\nTotal: {len(shifts) + len(assignments) + len(maintenance)} rows")
        print(f"\nSQL files saved to ./{self.output_dir}/")

if __name__ == "__main__":
    generator = RosterDataGenerator()
    generator.run()

#!/usr/bin/env python3
"""
Mining Accelerator — Load Roster Data into MINING_DB
Executes shift instances, assignments, and maintenance records
Uses .env file for credentials (same pattern as insert_sample_data.py)
"""

import os
import sys
import getpass
import snowflake.connector
from pathlib import Path
from dotenv import load_dotenv

# Load .env from script directory
script_dir = Path(__file__).parent
parent_setup_dir = script_dir.parent / "setup"
env_path = parent_setup_dir / ".env"

print(f"Loading .env from: {env_path}")
if env_path.exists():
    load_dotenv(env_path)
else:
    print(f"Warning: .env not found at {env_path}, using environment variables")

# Connection parameters from .env or environment
_auth = os.environ.get("SNOWFLAKE_AUTHENTICATOR", "username_password_mfa").lower()
params = {
    "account":       os.environ["SNOWFLAKE_ACCOUNT"],
    "user":          os.environ["SNOWFLAKE_USER"],
    "warehouse":     os.environ.get("SNOWFLAKE_WAREHOUSE", "MINING_WH"),
    "role":          os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    "database":      "MINING_DB",
    "schema":        "OPS_REF",
    "authenticator": _auth,
}

# Handle authentication
if _auth == "password":
    params["password"] = os.environ["SNOWFLAKE_PASSWORD"]
elif _auth == "username_password_mfa":
    params["password"] = os.environ.get("SNOWFLAKE_PASSWORD") or getpass.getpass("Password: ")
    params["passcode"] = input("MFA code (from authenticator app): ").strip()

# SQL files to execute (in order)
SQL_FILES = [
    "07_shift_instances.sql",
    "08_operator_shift_assignments.sql",
    "09_maintenance_records.sql"
]

def load_sql_file(filepath: str) -> str:
    """Load SQL from file"""
    with open(filepath, 'r') as f:
        return f.read()

def execute_sql(cursor, sql: str, description: str = ""):
    """Execute SQL (which may have multiple statements separated by semicolons)"""
    try:
        print(f"\n📊 {description}...")
        # Split by semicolons and execute each statement separately
        statements = [s.strip() for s in sql.split(';') if s.strip()]
        for i, stmt in enumerate(statements):
            cursor.execute(stmt)
        print(f"   ✓ Success ({len(statements)} statements, {cursor.rowcount} rows affected)")
        return True
    except Exception as e:
        print(f"   ✗ Error: {str(e)}")
        return False

def main():
    print("=" * 70)
    print("Mining Accelerator — Load Roster Data to MINING_DB")
    print("=" * 70)
    
    # Connect to Snowflake
    print("\n🔗 Connecting to Snowflake...")
    print(f"   Account: {params['account']}")
    print(f"   User: {params['user']}")
    print(f"   Database: {params['database']}")
    print(f"   Warehouse: {params['warehouse']}")
    print(f"   Authenticator: {params['authenticator']}")
    
    try:
        conn = snowflake.connector.connect(**params)
        print("   ✓ Connected!")
    except Exception as e:
        print(f"   ✗ Connection failed: {str(e)}")
        sys.exit(1)
    
    cursor = conn.cursor()
    
    # Truncate tables first to remove duplicates
    print("\n🗑️  Truncating existing roster data...")
    try:
        cursor.execute("TRUNCATE TABLE MINING_DB.OPS_REF.SHIFT_INSTANCES")
        print("   ✓ SHIFT_INSTANCES truncated")
        cursor.execute("TRUNCATE TABLE MINING_DB.OPS_REF.OPERATOR_SHIFT_ASSIGNMENTS")
        print("   ✓ OPERATOR_SHIFT_ASSIGNMENTS truncated")
        cursor.execute("TRUNCATE TABLE MINING_DB.OPS_HIST.MAINTENANCE_RECORDS")
        print("   ✓ MAINTENANCE_RECORDS truncated")
    except Exception as e:
        print(f"   ✗ Truncate failed: {str(e)}")
        sys.exit(1)
    
    # Get the seed_data directory (sibling of scripts/)
    script_dir = Path(__file__).parent
    seed_data_dir = script_dir.parent / "seed_data"
    
    total_rows = 0
    failed_files = []
    
    try:
        # Execute each SQL file
        for sql_file in SQL_FILES:
            filepath = seed_data_dir / sql_file
            
            if not filepath.exists():
                print(f"\n⚠️  File not found: {sql_file}")
                failed_files.append(sql_file)
                continue
            
            # Load and execute SQL
            sql = load_sql_file(filepath)
            
            if not execute_sql(cursor, sql, f"Loading {sql_file}"):
                failed_files.append(sql_file)
        
        # Verify data was loaded
        print("\n" + "=" * 70)
        print("📈 Verifying Data Load...")
        print("=" * 70)
        
        verify_sql = """
        SELECT
            'SHIFT_INSTANCES' AS table_name,
            COUNT(*) AS row_count
        FROM MINING_DB.OPS_REF.SHIFT_INSTANCES
        UNION ALL
        SELECT 'OPERATOR_SHIFT_ASSIGNMENTS', COUNT(*) FROM MINING_DB.OPS_REF.OPERATOR_SHIFT_ASSIGNMENTS
        UNION ALL
        SELECT 'MAINTENANCE_RECORDS', COUNT(*) FROM MINING_DB.OPS_HIST.MAINTENANCE_RECORDS
        ORDER BY table_name
        """
        
        cursor.execute(verify_sql)
        results = cursor.fetchall()
        
        print("\n✅ Final Row Counts:")
        for table_name, row_count in results:
            print(f"   {table_name:35s} {row_count:>10,} rows")
            total_rows += row_count
        
        print(f"\n   TOTAL: {total_rows:,} rows across 3 tables")
        
    finally:
        cursor.close()
        conn.close()
    
    # Summary
    print("\n" + "=" * 70)
    if failed_files:
        print(f"⚠️  Completed with {len(failed_files)} error(s):")
        for f in failed_files:
            print(f"   - {f}")
        sys.exit(1)
    else:
        print("✅ All roster data loaded successfully!")
        print("\n📌 Roster tables now populated:")
        print("   - SHIFT_INSTANCES: Contains 60-day shift schedule")
        print("   - OPERATOR_SHIFT_ASSIGNMENTS: Operator assignments to shifts")
        print("   - MAINTENANCE_RECORDS: Equipment maintenance history")
        print("\nThese roster tables support fact tables in MINING_ICEBERG:")
        print("   - FK to SHIFT_INSTANCES in fact tables via shift_instance_id")
        print("   - FK to OPERATOR_SHIFT_ASSIGNMENTS for operator tracking")
        print("   - FK to EQUIPMENT in MAINTENANCE_RECORDS for maintenance lineage")
        print("=" * 70)
        sys.exit(0)

if __name__ == "__main__":
    main()

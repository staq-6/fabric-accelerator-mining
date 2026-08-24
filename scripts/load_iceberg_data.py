#!/usr/bin/env python3
"""
Mining Accelerator — Load Historical Data into Iceberg Tables
Executes the generated SQL files against Snowflake
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
    "database":      "MINING_ICEBERG",
    "schema":        "PUBLIC",
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
    "01_vehicle_telemetry.sql",
    "02_conveyor_belt_telemetry.sql",
    "03_crusher_telemetry.sql",
    "04_dig_face_operations.sql",
    "05_stockpile_volumes.sql",
    "06_product_movement.sql"
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
    print("Mining Accelerator — Load Historical Data to Iceberg Tables")
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
        ORDER BY table_name
        """
        
        cursor.execute(verify_sql)
        results = cursor.fetchall()
        
        print("\n✅ Final Row Counts:")
        for table_name, row_count in results:
            print(f"   {table_name:30s} {row_count:>10,} rows")
            total_rows += row_count
        
        print(f"\n   TOTAL: {total_rows:,} rows across 6 tables")
        
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
        print("✅ All data loaded successfully!")
        print("\n📌 Next Steps:")
        print("   1. Verify data in Snowsight or dbt")
        print("   2. Create dbt transformations to join MINING_DB → MINING_ICEBERG")
        print("   3. Build real-time streaming pipeline")
        print("   4. Configure Rayfin digital twin with Iceberg data")
        print("=" * 70)
        sys.exit(0)

if __name__ == "__main__":
    main()

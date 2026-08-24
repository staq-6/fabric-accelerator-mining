"""
Mining Accelerator — Snowflake Setup Runner
Executes all DDL and seed scripts in the correct order using snowflake-connector-python.

Usage:
    1. pip install -r requirements.txt
    2. Copy .env.example to .env and fill in your Snowflake credentials
    3. python run_setup.py                        (schema + tables + seeds + roster)
    4. python run_setup.py --only seeds            (re-run just reference seed data)
    5. python run_setup.py --only roster           (re-generate and reload roster data)
    6. python run_setup.py --only iceberg          (Iceberg DDL — requires Fabric catalog)
    7. python run_setup.py --only iceberg_data     (load pre-generated Iceberg INSERT files)
    8. python run_setup.py --only simulate         (run live simulation SQL)

Database names are read from .env:
    SNOWFLAKE_DATABASE         — normal tables db  (default: MINING_DB)
    SNOWFLAKE_ICEBERG_DATABASE — Iceberg db        (default: MINING_ICEBERG)
"""

import os
import sys
import re
import argparse
import getpass
from pathlib import Path

import snowflake.connector
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

HERE    = Path(__file__).parent
PROJECT = HERE.parent  # snowflake/

load_dotenv(HERE / ".env")

# ---------------------------------------------------------------------------
# Database name substitution — read from .env so any db name works
# ---------------------------------------------------------------------------
DB_NAME         = os.environ.get("SNOWFLAKE_DATABASE",         "MINING_DB")
ICEBERG_DB_NAME = os.environ.get("SNOWFLAKE_ICEBERG_DATABASE", "MINING_ICEBERG")
EXT_VOL_NAME    = os.environ.get("SNOWFLAKE_EXTERNAL_VOLUME",  "ONELAKE_ICEBERG_VOL")

_authenticator = os.environ.get("SNOWFLAKE_AUTHENTICATOR", "externalbrowser").lower()

SNOWFLAKE_PARAMS = {
    "account":       os.environ["SNOWFLAKE_ACCOUNT"],
    "user":          os.environ["SNOWFLAKE_USER"],
    "warehouse":     os.environ.get("SNOWFLAKE_WAREHOUSE", "MINING_WH"),
    "role":          os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    "authenticator": _authenticator,
}

if _authenticator == "password":
    # Plain password — no MFA
    SNOWFLAKE_PARAMS["password"] = os.environ["SNOWFLAKE_PASSWORD"]

elif _authenticator == "username_password_mfa":
    # Password + TOTP code entered at runtime
    SNOWFLAKE_PARAMS["password"] = os.environ.get("SNOWFLAKE_PASSWORD") or getpass.getpass("Snowflake password: ")
    totp = input("Enter your current MFA/TOTP code: ").strip()
    SNOWFLAKE_PARAMS["passcode"] = totp

# externalbrowser: no extra params — connector opens browser automatically

# Scripts executed in this exact order
SCRIPT_GROUPS = {
    "schema": [
        PROJECT / "ddl/normal_tables/00_schema_setup.sql",
    ],
    "normal_tables": [
        PROJECT / "ddl/normal_tables/01_equipment.sql",
        PROJECT / "ddl/normal_tables/02_shifts.sql",
        PROJECT / "ddl/normal_tables/03_operators.sql",
        PROJECT / "ddl/normal_tables/04_locations.sql",
        PROJECT / "ddl/normal_tables/05_material_types.sql",
        PROJECT / "ddl/normal_tables/06_maintenance_records.sql",
    ],
    "seeds": [
        PROJECT / "seed_data/seed_all.sql",
    ],
    "iceberg": [
        PROJECT / "ddl/iceberg_tables/00_iceberg_setup.sql",
        PROJECT / "ddl/iceberg_tables/01_vehicle_telemetry.sql",
        PROJECT / "ddl/iceberg_tables/02_conveyor_belt_telemetry.sql",
        PROJECT / "ddl/iceberg_tables/03_crusher_telemetry.sql",
        PROJECT / "ddl/iceberg_tables/04_dig_face_operations.sql",
        PROJECT / "ddl/iceberg_tables/05_stockpile_volumes.sql",
        PROJECT / "ddl/iceberg_tables/06_product_movement.sql",
    ],
    "simulate": [
        PROJECT / "simulation/simulate_operations.sql",
    ],
    "iceberg_data": [
        PROJECT / "seed_data/01_vehicle_telemetry.sql",
        PROJECT / "seed_data/02_conveyor_belt_telemetry.sql",
        PROJECT / "seed_data/03_crusher_telemetry.sql",
        PROJECT / "seed_data/04_dig_face_operations.sql",
        PROJECT / "seed_data/05_stockpile_volumes.sql",
        PROJECT / "seed_data/06_product_movement.sql",
    ],
    "roster": [
        PROJECT / "seed_data/07_shift_instances.sql",
        PROJECT / "seed_data/08_operator_shift_assignments.sql",
        PROJECT / "seed_data/09_maintenance_records.sql",
    ],
}

# Groups run in order when --only is not specified
# "roster" is handled inline (generates data in Python then executes directly)
DEFAULT_ORDER = ["schema", "normal_tables", "seeds", "roster"]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def split_statements(sql: str) -> list[str]:
    """
    Split a SQL file into individual statements on semicolons,
    skipping blank lines and single-line comments.
    Handles Snowflake $$ dollar-quoting for stored procedures.
    """
    statements = []
    current: list[str] = []
    in_dollar_quote = False

    for line in sql.splitlines():
        stripped = line.strip()

        # Toggle dollar-quote block
        if "$$" in stripped:
            in_dollar_quote = not in_dollar_quote

        # Skip standalone comments outside a block
        if not in_dollar_quote and stripped.startswith("--"):
            continue

        current.append(line)

        # End of statement
        if not in_dollar_quote and stripped.endswith(";"):
            stmt = "\n".join(current).strip().rstrip(";")
            if stmt and not stmt.startswith("--"):
                statements.append(stmt)
            current = []

    # Catch any trailing statement without a semicolon
    if current:
        stmt = "\n".join(current).strip()
        if stmt and not stmt.startswith("--"):
            statements.append(stmt)

    return statements


def _substitute_db_names(sql: str) -> str:
    """Replace hardcoded DB names with values from .env."""
    # Replace MINING_ICEBERG before MINING_DB to avoid partial match
    sql = sql.replace("MINING_ICEBERG",    ICEBERG_DB_NAME)
    sql = sql.replace("MINING_DB",         DB_NAME)
    sql = sql.replace("ONELAKE_ICEBERG_VOL", EXT_VOL_NAME)
    return sql


def run_script(cur, path: Path) -> int:
    """Execute all statements in a SQL file. Returns count of statements run."""
    print(f"\n  📄 {path.relative_to(PROJECT.parent)}")
    sql = _substitute_db_names(path.read_text(encoding="utf-8"))
    statements = split_statements(sql)
    executed = 0

    for i, stmt in enumerate(statements, 1):
        # Skip commented-out blocks (CREATE USER etc.)
        if re.match(r"^\s*--", stmt):
            continue
        # Skip empty
        if not stmt.strip():
            continue

        preview = stmt[:80].replace("\n", " ").strip()
        try:
            cur.execute(stmt)
            print(f"    [{i:>3}] ✓  {preview}...")
            executed += 1
        except snowflake.connector.errors.ProgrammingError as e:
            # Some DDL statements are idempotent — warn but continue
            if any(
                phrase in str(e).upper()
                for phrase in ["ALREADY EXISTS", "DUPLICATE", "IF NOT EXISTS"]
            ):
                print(f"    [{i:>3}] ⚠  {preview}... (skipped — already exists)")
            else:
                print(f"    [{i:>3}] ✗  {preview}...")
                print(f"           Error: {e}")
                raise

    return executed


def run_roster_inline(cur) -> int:
    """
    Generate roster data in Python and execute directly — no SQL files needed.
    Returns number of INSERT batches executed.
    """
    import sys as _sys
    _sys.path.insert(0, str(PROJECT / "scripts"))
    from generate_roster_data import RosterDataGenerator  # type: ignore

    print(f"\n  🔧 Generating roster data in-memory...")
    gen = RosterDataGenerator()  # output_dir not used — we exec directly

    shifts, shift_sql       = gen.generate_shift_instances()
    assignments, assign_sql = gen.generate_operator_shift_assignments(shifts)
    maintenance, maint_sql  = gen.generate_maintenance_records()

    print(f"      {len(shifts)} shift instances")
    print(f"      {len(assignments)} operator shift assignments")
    print(f"      {len(maintenance)} maintenance records")

    executed = 0

    def _exec_sql(sql_text: str, schema: str, label: str):
        nonlocal executed
        cur.execute(f"USE DATABASE {DB_NAME}")
        cur.execute(f"USE SCHEMA {schema}")
        stmts = [s.strip() for s in sql_text.split(";") if s.strip()]
        for stmt in stmts:
            preview = stmt[:80].replace("\n", " ")
            try:
                cur.execute(stmt)
                print(f"    [  +] ✓  {label}: {cur.rowcount} rows")
                executed += 1
            except Exception as e:
                print(f"    [  !] ✗  {label}: {e}")
                raise

    _exec_sql(shift_sql,  "OPS_REF",  "SHIFT_INSTANCES")
    _exec_sql(assign_sql, "OPS_REF",  "OPERATOR_SHIFT_ASSIGNMENTS")
    _exec_sql(maint_sql,  "OPS_HIST", "MAINTENANCE_RECORDS")

    return executed


def connect() -> snowflake.connector.SnowflakeConnection:
    print("Connecting to Snowflake...")
    print(f"  Account:   {SNOWFLAKE_PARAMS['account']}")
    print(f"  User:      {SNOWFLAKE_PARAMS['user']}")
    print(f"  Role:      {SNOWFLAKE_PARAMS['role']}")
    conn = snowflake.connector.connect(**SNOWFLAKE_PARAMS)
    print("  ✓ Connected\n")
    return conn


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Run Snowflake setup scripts")
    parser.add_argument(
        "--only",
        choices=list(SCRIPT_GROUPS.keys()) + ["roster"],
        help="Run only one script group instead of the full setup",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be executed without running anything",
    )
    args = parser.parse_args()

    groups_to_run = [args.only] if args.only else DEFAULT_ORDER

    # Inline groups are handled in Python — no SQL files to validate
    INLINE_GROUPS = {"roster"}

    # Validate all script files exist before connecting
    missing = []
    for group in groups_to_run:
        if group in INLINE_GROUPS:
            continue
        for path in SCRIPT_GROUPS[group]:
            if not path.exists():
                missing.append(str(path))

    if missing:
        print("ERROR — The following script files were not found:")
        for m in missing:
            print(f"  {m}")
        sys.exit(1)

    if args.dry_run:
        print("DRY RUN — scripts that would be executed:")
        for group in groups_to_run:
            print(f"\n[{group}]")
            if group in INLINE_GROUPS:
                print(f"  (inline Python generator — no SQL files)")
                continue
            for path in SCRIPT_GROUPS[group]:
                stmts = split_statements(_substitute_db_names(path.read_text(encoding="utf-8")))
                print(f"  {path.name}  ({len(stmts)} statements) → db={DB_NAME}")
        return

    # Connect and run
    conn = connect()
    cur  = conn.cursor()
    total_stmts = 0

    try:
        for group in groups_to_run:
            print(f"\n{'='*60}")
            print(f"  GROUP: {group.upper()}")
            print(f"{'='*60}")

            if group in INLINE_GROUPS:
                n = run_roster_inline(cur)
                total_stmts += n
                continue

            for path in SCRIPT_GROUPS[group]:
                n = run_script(cur, path)
                total_stmts += n

        print(f"\n{'='*60}")
        print(f"  ✅  Setup complete — {total_stmts} statements executed")
        print(f"{'='*60}\n")

    except Exception as e:
        print(f"\n❌  Setup failed: {e}")
        sys.exit(1)
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()

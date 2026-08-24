"""Quick verification — shows all MINING_* databases and row counts."""
import os, getpass
from dotenv import load_dotenv
from pathlib import Path
import snowflake.connector

load_dotenv(Path(__file__).parent / ".env")
auth = os.environ.get("SNOWFLAKE_AUTHENTICATOR", "username_password_mfa").lower()
p = {
    "account":       os.environ["SNOWFLAKE_ACCOUNT"],
    "user":          os.environ["SNOWFLAKE_USER"],
    "warehouse":     os.environ.get("SNOWFLAKE_WAREHOUSE", "MINING_WH"),
    "role":          os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    "authenticator": auth,
}
if auth == "password":
    p["password"] = os.environ["SNOWFLAKE_PASSWORD"]
elif auth == "username_password_mfa":
    p["password"] = os.environ.get("SNOWFLAKE_PASSWORD") or getpass.getpass("Password: ")
    p["passcode"] = input("MFA code: ").strip()

conn = snowflake.connector.connect(**p)
cur  = conn.cursor()

print("\n--- DATABASES ---")
cur.execute("SHOW DATABASES LIKE 'MINING%'")
for r in cur.fetchall():
    print(f"  {r[1]}")

print("\n--- TABLES IN MINING_DB (OPS_REF / OPS_HIST) ---")
cur.execute(
    "SELECT TABLE_SCHEMA, TABLE_NAME, ROW_COUNT "
    "FROM MINING_DB.INFORMATION_SCHEMA.TABLES "
    "WHERE TABLE_SCHEMA IN ('OPS_REF','OPS_HIST') "
    "ORDER BY TABLE_SCHEMA, TABLE_NAME"
)
rows = cur.fetchall()
if rows:
    for r in rows:
        print(f"  {r[0]}.{r[1]:<40} {r[2] or 0:>8,} rows")
else:
    print("  (no tables found — did setup run?)")

print("\n--- ICEBERG TABLES IN MINING_ICEBERG ---")
try:
    cur.execute(
        "SELECT TABLE_SCHEMA, TABLE_NAME, ROW_COUNT "
        "FROM MINING_ICEBERG.INFORMATION_SCHEMA.TABLES "
        "ORDER BY TABLE_NAME"
    )
    ice = cur.fetchall()
    if ice:
        for r in ice:
            print(f"  {r[0]}.{r[1]:<40} {r[2] or 0:>8,} rows")
    else:
        print("  (no tables found — run: py run_setup.py --only iceberg)")
except Exception as e:
    print(f"  MINING_ICEBERG not found ({e})")

conn.close()
print()

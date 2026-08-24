# Mining Accelerator — Snowflake Setup

End-to-end instructions for provisioning the Snowflake datasets used by the Microsoft Fabric Mining Accelerator. Follow the steps below to create all schemas, tables, reference data, and 60 days of realistic mock operational data.

---

## Folder structure

```
snowflake/
├── README.md                    ← you are here
├── .gitignore                   ← excludes .env and generated SQL files
├── ddl/
│   ├── normal_tables/           ← MINING_DB schemas + reference/operational tables
│   └── iceberg_tables/          ← MINING_ICEBERG Iceberg table DDL
├── seed_data/
│   ├── seed_all.sql             ← reference data for MINING_DB (equipment, locations, etc.)
│   ├── seed_iceberg_historical_data.sql  ← Snowsight-native alternative (uses GENERATOR)
│   └── 00_cleanup_roster.sql    ← truncates roster tables (re-run to reset)
├── scripts/
│   ├── generate_iceberg_data.py ← generates 01-06 seed SQL files (~50 k rows)
│   ├── load_iceberg_data.py     ← loads generated SQL into MINING_ICEBERG
│   ├── generate_roster_data.py  ← generates 07-09 seed SQL files (shifts, assignments, maintenance)
│   ├── load_roster_data.py      ← loads generated SQL into MINING_DB
│   └── insert_sample_data.py    ← inserts a small number of sample rows for quick verification
├── setup/
│   ├── .env.example             ← copy → .env and fill in credentials
│   ├── requirements.txt         ← Python dependencies
│   └── run_setup.py             ← main setup runner (DDL + seeds)
└── simulation/
    └── simulate_operations.sql  ← generates live-simulation rows in Snowsight
```

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Python 3.11+ | `python --version` |
| Snowflake account | With `ACCOUNTADMIN` role (or equivalent) |
| Snowflake warehouse | Default: `MINING_WH` — created by DDL scripts |
| Fabric OneLake integration | Required only for Iceberg mirroring; skip Step 4 if not needed |

Install Python dependencies (once):

```bash
pip install -r snowflake/setup/requirements.txt
```

---

## Step 1 — Configure credentials

```bash
cd snowflake/setup
cp .env.example .env
```

Edit `.env` and fill in your Snowflake account details:

```dotenv
SNOWFLAKE_ACCOUNT=XCBWHYD-PJ36074     # your account identifier
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password       # required for password / MFA auth
SNOWFLAKE_WAREHOUSE=MINING_WH
SNOWFLAKE_DATABASE=MINING_DB
SNOWFLAKE_ROLE=ACCOUNTADMIN

# Authentication method — choose one:
#   password              → plain password, no MFA
#   username_password_mfa → password + TOTP code prompted at runtime
#   externalbrowser       → browser-based SSO (recommended for enterprise)
SNOWFLAKE_AUTHENTICATOR=username_password_mfa
```

> **Security:** `.env` is listed in `.gitignore` and will never be committed.

---

## Step 2 — Create schemas and normal tables, load reference data

Run from the `snowflake/setup/` directory:

```bash
python run_setup.py
```

This executes three groups in order:

| Group | Scripts | What it does |
|---|---|---|
| `schema` | `ddl/normal_tables/00_schema_setup.sql` | Creates `MINING_DB`, warehouses, schemas |
| `normal_tables` | `ddl/normal_tables/01-06_*.sql` | Creates equipment, shift, operator, location, material and maintenance tables |
| `seeds` | `seed_data/seed_all.sql` | Inserts reference data (equipment fleet, locations, material types, operators, shifts) |

**Selective re-runs:**

```bash
python run_setup.py --only schema          # re-run only schema setup
python run_setup.py --only normal_tables   # re-run only table DDL
python run_setup.py --only seeds           # re-seed reference data only
python run_setup.py --dry-run              # print what would run without executing
```

---

## Step 3 — Create Iceberg tables

> Requires a Fabric OneLake catalog integration configured in your Snowflake account.  
> See `ddl/iceberg_tables/00_iceberg_setup.sql` for the integration setup.

```bash
python run_setup.py --only iceberg
```

This runs all scripts in `ddl/iceberg_tables/` to create the `MINING_ICEBERG` database and six Iceberg tables:

- `VEHICLE_TELEMETRY`
- `CONVEYOR_BELT_TELEMETRY`
- `CRUSHER_TELEMETRY`
- `DIG_FACE_OPERATIONS`
- `STOCKPILE_VOLUMES`
- `PRODUCT_MOVEMENT`

---

## Step 4 — Load mock data into Iceberg tables

Choose **one** of the following options:

### Option A — Python generator (recommended, ~50 k rows)

Run from the `snowflake/` root:

```bash
# 1. Generate the SQL INSERT files (writes to seed_data/)
python scripts/generate_iceberg_data.py

# 2. Load them into MINING_ICEBERG
python scripts/load_iceberg_data.py
```

Generates 60 days of realistic operational history:

| Table | Approx. rows |
|---|---|
| VEHICLE_TELEMETRY | ~30,000 |
| CONVEYOR_BELT_TELEMETRY | ~9,000 |
| CRUSHER_TELEMETRY | ~9,000 |
| DIG_FACE_OPERATIONS | ~480 |
| STOCKPILE_VOLUMES | ~720 |
| PRODUCT_MOVEMENT | ~600 |

### Option B — Snowsight SQL (uses native GENERATOR, no Python needed)

Open `seed_data/seed_iceberg_historical_data.sql` and run it directly in Snowsight.

### Option C — Quick sample inserts (5 rows per table)

```bash
python scripts/insert_sample_data.py
```

---

## Step 5 — Load roster and maintenance data

```bash
# 1. Generate SQL files (180 shifts, ~540 assignments, ~150 maintenance records)
python scripts/generate_roster_data.py

# 2. Load into MINING_DB
python scripts/load_roster_data.py
```

To reset and reload:

```bash
# Truncate roster tables first (SQL — run in Snowsight or via run_setup.py)
#   seed_data/00_cleanup_roster.sql
python scripts/generate_roster_data.py
python scripts/load_roster_data.py
```

---

## Step 6 (optional) — Simulate live operations

Open `simulation/simulate_operations.sql` in Snowsight and run it to add ongoing simulation rows to the Iceberg tables.

---

## Database structure

```
MINING_DB
├── OPS_REF      ← reference tables: EQUIPMENT, SHIFTS, OPERATORS, LOCATIONS, MATERIAL_TYPES
│                   SHIFT_INSTANCES, OPERATOR_SHIFT_ASSIGNMENTS
└── OPS_HIST     ← historical tables: MAINTENANCE_RECORDS

MINING_ICEBERG   ← Iceberg tables (exposed to Microsoft Fabric via OneLake catalog)
└── PUBLIC       ← VEHICLE_TELEMETRY, CONVEYOR_BELT_TELEMETRY, CRUSHER_TELEMETRY,
                    DIG_FACE_OPERATIONS, STOCKPILE_VOLUMES, PRODUCT_MOVEMENT
```

---

## Troubleshooting

| Error | Fix |
|---|---|
| `SNOWFLAKE_ACCOUNT not set` | Copy `.env.example` to `.env` and fill in credentials |
| `002003 (42S02): Table does not exist` | Run Step 2 before Step 4 |
| `MINING_ICEBERG does not exist` | Run `--only iceberg` (Step 3) first |
| MFA timeout | Use `SNOWFLAKE_AUTHENTICATOR=externalbrowser` for browser-based auth |
| Large INSERT timeout | Split into smaller batches or use Option B (Snowsight GENERATOR) |

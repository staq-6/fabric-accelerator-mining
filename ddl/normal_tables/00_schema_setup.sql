-- =============================================================================
-- Mining Accelerator — Snowflake Schema Setup
-- Normal tables (mirrored to Microsoft Fabric via Snowflake Mirroring)
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Database
CREATE DATABASE IF NOT EXISTS MINING_DB
    DATA_RETENTION_TIME_IN_DAYS = 7
    COMMENT = 'Mining operations database — normal tables mirrored to Fabric';

-- Schema for operational reference data
CREATE SCHEMA IF NOT EXISTS MINING_DB.OPS_REF
    DATA_RETENTION_TIME_IN_DAYS = 7
    COMMENT = 'Operational reference / master data — mirrored to Fabric';

-- Schema for historical operational transactions
CREATE SCHEMA IF NOT EXISTS MINING_DB.OPS_HIST
    DATA_RETENTION_TIME_IN_DAYS = 7
    COMMENT = 'Historical operational transactions — mirrored to Fabric';

-- Warehouse for ETL operations
CREATE WAREHOUSE IF NOT EXISTS MINING_WH
    WAREHOUSE_SIZE = MEDIUM
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Warehouse for mining data operations';

-- Dedicated role for Fabric mirroring
CREATE ROLE IF NOT EXISTS FABRIC_MIRROR_ROLE;
GRANT USAGE ON DATABASE MINING_DB TO ROLE FABRIC_MIRROR_ROLE;
GRANT USAGE ON SCHEMA MINING_DB.OPS_REF TO ROLE FABRIC_MIRROR_ROLE;
GRANT USAGE ON SCHEMA MINING_DB.OPS_HIST TO ROLE FABRIC_MIRROR_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA MINING_DB.OPS_REF TO ROLE FABRIC_MIRROR_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA MINING_DB.OPS_HIST TO ROLE FABRIC_MIRROR_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MINING_DB.OPS_REF TO ROLE FABRIC_MIRROR_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MINING_DB.OPS_HIST TO ROLE FABRIC_MIRROR_ROLE;
GRANT USAGE ON WAREHOUSE MINING_WH TO ROLE FABRIC_MIRROR_ROLE;

-- Service account for Fabric connector
-- CREATE USER FABRIC_MIRROR_SVC
--     PASSWORD = '<replace_with_secure_password>'
--     DEFAULT_ROLE = FABRIC_MIRROR_ROLE
--     DEFAULT_WAREHOUSE = MINING_WH
--     COMMENT = 'Service account for Fabric Snowflake Mirroring';
-- GRANT ROLE FABRIC_MIRROR_ROLE TO USER FABRIC_MIRROR_SVC;

USE DATABASE MINING_DB;
USE SCHEMA OPS_REF;

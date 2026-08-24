-- =============================================================================
-- Mining Accelerator — Iceberg Tables Setup
-- Iceberg tables stored on OneLake, accessed natively by Snowflake
-- External volume must point to the OneLake ADLS Gen2 container
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MINING_DB;

-- ----------------------------------------------------------------------------
-- External Volume — pointing at OneLake ADLS Gen2
-- Replace <STORAGE_BASE_URL> with the OneLake ADLS Gen2 DFS endpoint:
--   https://<onelake_account>.dfs.fabric.microsoft.com/<workspace_id>/<lakehouse_id>/Files/iceberg
-- ----------------------------------------------------------------------------
CREATE OR REPLACE EXTERNAL VOLUME ONELAKE_ICEBERG_VOL
    STORAGE_LOCATIONS = (
        (
            NAME = 'onelake-primary'
            STORAGE_PROVIDER = 'AZURE'
            STORAGE_BASE_URL = 'azure://onelake.blob.fabric.microsoft.com/1654bd28-8826-4b4d-9a51-6d84f219a3e9/7a30eda7-fb51-466e-b095-9005a0b0a87c/Files/iceberg/'
            AZURE_TENANT_ID = '6c71fd6b-0280-4b66-9637-305b5c557725'
        )
    )
    ALLOW_WRITES = TRUE
    COMMENT = 'External volume pointing at OneLake ADLS Gen2 for Iceberg tables';

-- Catalog integration for Iceberg REST catalog on Fabric
-- CREATE OR REPLACE CATALOG INTEGRATION FABRIC_ICEBERG_CATALOG
--     CATALOG_SOURCE = REST
--     CATALOG_NAMESPACE = 'mining'
--     REST_CONFIG = (
--         CATALOG_URI = 'https://api.fabric.microsoft.com/v1/workspaces/<WORKSPACE_ID>/lakehouses/<LAKEHOUSE_ID>/liveSynapse/tables'
--     )
--     REST_AUTHENTICATION = (
--         TYPE = BEARER
--         BEARER_TOKEN = '<FABRIC_TOKEN>'
--     )
--     ENABLED = TRUE;

-- Schema for Iceberg operational streaming data
CREATE SCHEMA IF NOT EXISTS MINING_DB.OPS_STREAM
    COMMENT = 'High-volume operational streaming data stored as Iceberg on OneLake';

-- Role for Iceberg access
GRANT USAGE ON SCHEMA MINING_DB.OPS_STREAM TO ROLE FABRIC_MIRROR_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA MINING_DB.OPS_STREAM TO ROLE FABRIC_MIRROR_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MINING_DB.OPS_STREAM TO ROLE FABRIC_MIRROR_ROLE;

USE SCHEMA OPS_STREAM;

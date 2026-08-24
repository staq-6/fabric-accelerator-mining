-- =============================================================================
-- Mining Accelerator — Locations Table
-- Normal table — mirrored to Microsoft Fabric via Snowflake Mirroring
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_REF;

CREATE OR REPLACE TABLE LOCATIONS (
    location_id         VARCHAR(36)     NOT NULL DEFAULT UUID_STRING(),
    location_code       VARCHAR(30)     NOT NULL                        COMMENT 'Short code e.g. DF-01, SP-NORTH, CR-01',
    location_name       VARCHAR(100)    NOT NULL,
    location_type       VARCHAR(30)     NOT NULL                        COMMENT 'DIG_FACE | STOCKPILE | CRUSHER | CONVEYOR_HEAD | CONVEYOR_TAIL | DUMP | ROM_PAD | WORKSHOP | FUEL_BAY | WASH_BAY',
    site_code           VARCHAR(20)     NOT NULL,
    pit_name            VARCHAR(50)                                     COMMENT 'Pit or mining area name',
    bench_level         VARCHAR(20)                                     COMMENT 'Bench RL e.g. RL380, RL400',
    -- Centroid coordinates (WGS84)
    latitude            NUMBER(10,7),
    longitude           NUMBER(10,7),
    elevation_m         NUMBER(8,2),
    -- Bounding polygon (GeoJSON)
    boundary_geojson    VARIANT                                         COMMENT 'GeoJSON polygon defining the location boundary',
    -- Capacity
    design_capacity_t   NUMBER(14,2)                                    COMMENT 'Design capacity in tonnes (stockpiles)',
    design_capacity_m3  NUMBER(14,2)                                    COMMENT 'Design capacity in cubic metres',
    -- Status
    location_status     VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE'       COMMENT 'ACTIVE | INACTIVE | RESTRICTED | BLASTING',
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    notes               VARCHAR(1000),
    created_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_locations PRIMARY KEY (location_id),
    CONSTRAINT uq_location_code UNIQUE (location_code, site_code)
)
COMMENT = 'Spatial zones on site — dig faces, stockpiles, crushers, dumps';

ALTER TABLE LOCATIONS SET CHANGE_TRACKING = TRUE;

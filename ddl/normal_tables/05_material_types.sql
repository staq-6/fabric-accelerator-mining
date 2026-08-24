-- =============================================================================
-- Mining Accelerator — Material Types Table
-- Normal table — mirrored to Microsoft Fabric via Snowflake Mirroring
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_REF;

CREATE OR REPLACE TABLE MATERIAL_TYPES (
    material_type_id    VARCHAR(36)     NOT NULL DEFAULT UUID_STRING(),
    material_code       VARCHAR(20)     NOT NULL,
    material_name       VARCHAR(100)    NOT NULL,
    material_category   VARCHAR(30)     NOT NULL                        COMMENT 'ORE | WASTE | OVERBURDEN | LOW_GRADE_ORE | ROM | PRODUCT',
    commodity           VARCHAR(50)                                     COMMENT 'IRON_ORE | COPPER | GOLD | COAL | BAUXITE | LIMESTONE',
    -- Grade thresholds (commodity-specific, stored as JSON for flexibility)
    grade_thresholds    VARIANT                                         COMMENT 'JSON with min/max grade thresholds per element',
    -- Physical properties
    density_t_m3        NUMBER(6,3)                                     COMMENT 'Bulk density in t/m3',
    swell_factor        NUMBER(5,3)     DEFAULT 1.0                     COMMENT 'Swell factor (in-situ to loose)',
    -- Processing
    is_saleable         BOOLEAN         DEFAULT FALSE,
    destination         VARCHAR(50)                                     COMMENT 'CRUSHER | STOCKPILE | WASTE_DUMP | EXPORT_STOCKPILE',
    processing_path     VARCHAR(100)                                    COMMENT 'Downstream processing route',
    -- Reporting
    reporting_category  VARCHAR(50)                                     COMMENT 'For grade/tonnage reconciliation reporting',
    colour_hex          VARCHAR(7)                                       COMMENT 'Hex colour for map/chart visualisation #RRGGBB',
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_material_types PRIMARY KEY (material_type_id),
    CONSTRAINT uq_material_code UNIQUE (material_code)
)
COMMENT = 'Classification of materials mined — ore grades, waste, overburden';

ALTER TABLE MATERIAL_TYPES SET CHANGE_TRACKING = TRUE;

-- =============================================================================
-- Mining Accelerator — Stockpile Volumes (Iceberg Table)
-- Stored on OneLake via Snowflake External Volume
-- Volumetric survey results from drone/scanner surveys
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_STREAM;

CREATE OR REPLACE ICEBERG TABLE STOCKPILE_VOLUMES (
    survey_id               STRING     NOT NULL,
    location_id             STRING     NOT NULL                        COMMENT 'FK to LOCATIONS (STOCKPILE zone)',
    shift_instance_id       STRING,

    survey_ts               TIMESTAMP_LTZ   NOT NULL                        COMMENT 'Timestamp of survey measurement',
    ingestion_ts            TIMESTAMP_LTZ   NOT NULL,

    -- Survey method
    survey_method           STRING     NOT NULL                        COMMENT 'DRONE_SURVEY | LASER_SCANNER | MANUAL_ESTIMATE | BELT_SCALE_CALC | RADAR',
    survey_quality          STRING     NOT NULL         COMMENT 'GOOD | ACCEPTABLE | ESTIMATED | POOR',
    survey_accuracy_pct     NUMBER(6,2)                                     COMMENT 'Estimated accuracy ±%',
    surveyed_by             STRING,

    -- Volume and tonnage
    volume_m3               NUMBER(14,3)    NOT NULL              COMMENT 'Current stockpile volume in cubic metres',
    bulk_density_t_m3       NUMBER(6,3)                                     COMMENT 'Applied bulk density',
    estimated_tonnes        NUMBER(16,3)                                    COMMENT 'Estimated tonnes = volume × bulk density',
    design_capacity_m3      NUMBER(14,3),
    utilisation_pct         NUMBER(6,2)                                     COMMENT 'volume / design_capacity × 100',

    -- Volume movement since last survey
    volume_added_m3         NUMBER(14,3)                       COMMENT 'Net volume added since last survey',
    volume_reclaimed_m3     NUMBER(14,3)                       COMMENT 'Net volume reclaimed since last survey',
    net_movement_m3         NUMBER(14,3),

    -- Material composition
    material_type_id        STRING                                     COMMENT 'Primary material type',
    blended_material         BOOLEAN                  COMMENT 'TRUE if stockpile contains blended material',
    material_breakdown      STRING                                         COMMENT 'JSON: [{material_type_id, volume_m3, pct}]',

    -- Grade info (from sampling)
    avg_grade_fepct         NUMBER(6,3)                                     COMMENT 'Average Fe% or relevant commodity grade',
    grade_min               NUMBER(8,4),
    grade_max               NUMBER(8,4),
    last_sampled_ts         TIMESTAMP_LTZ,

    -- Geometry centroid
    centroid_latitude       NUMBER(10,7),
    centroid_longitude      NUMBER(10,7),
    peak_elevation_m        NUMBER(8,2),

    CONSTRAINT pk_stockpile_volumes PRIMARY KEY (survey_id)
)
    EXTERNAL_VOLUME = 'ONELAKE_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'stockpile_volumes/'
    COMMENT = 'Stockpile volumetric surveys from drone/scanner — Iceberg on OneLake'
    CLUSTER BY (location_id, DATE_TRUNC('day', survey_ts));

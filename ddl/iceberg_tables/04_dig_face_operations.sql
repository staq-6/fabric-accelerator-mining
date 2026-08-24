-- =============================================================================
-- Mining Accelerator — Dig Face Operations (Iceberg Table)
-- Stored on OneLake via Snowflake External Volume
-- Tracks drill & blast events, excavation cycles at dig faces
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_STREAM;

CREATE OR REPLACE ICEBERG TABLE DIG_FACE_OPERATIONS (
    operation_id            STRING     NOT NULL,
    location_id             STRING     NOT NULL                        COMMENT 'FK to LOCATIONS (DIG_FACE zone)',
    shift_instance_id       STRING     NOT NULL,
    equipment_id            STRING     NOT NULL                        COMMENT 'Primary excavator/dig equipment',
    operator_id             STRING,

    event_ts                TIMESTAMP_LTZ   NOT NULL                        COMMENT 'Operation event timestamp',
    ingestion_ts            TIMESTAMP_LTZ   NOT NULL,

    -- Operation type
    operation_type          STRING     NOT NULL                        COMMENT 'BLAST | EXCAVATION_CYCLE | FACE_ADVANCE | BENCH_SETUP | SURVEY | DRILL',
    operation_status        STRING     NOT NULL  COMMENT 'PLANNED | IN_PROGRESS | COMPLETED | ABORTED',

    -- Blast event details
    blast_id                STRING                                     COMMENT 'Links to blast record for blast events',
    blast_hole_count        INT,
    explosive_type          STRING                                     COMMENT 'ANFO | Emulsion | HANFO | Booster',
    explosive_mass_kg       NUMBER(10,2),
    powder_factor_kg_t      NUMBER(8,4)                                     COMMENT 'kg explosive per tonne',
    blast_pattern           STRING                                     COMMENT 'Drill pattern type',
    bench_height_m          NUMBER(6,2),

    -- Dig/excavation details
    material_type_id        STRING                                     COMMENT 'FK to MATERIAL_TYPES',
    insitu_volume_m3        NUMBER(12,3)                                    COMMENT 'In-situ volume excavated m3',
    loose_volume_m3         NUMBER(12,3)                                    COMMENT 'Loose (bank) volume m3',
    estimated_tonnes        NUMBER(14,3)                                    COMMENT 'Estimated tonnes from volume × density',
    measured_grade_fepct    NUMBER(6,3)                                     COMMENT 'Fe% (iron ore) or relevant commodity grade',
    dig_rate_bcm_hr         NUMBER(10,2)                                    COMMENT 'Dig rate in bank cubic metres per hour',

    -- Face geometry
    face_latitude           NUMBER(10,7),
    face_longitude          NUMBER(10,7),
    face_elevation_m        NUMBER(8,2),
    face_azimuth_deg        NUMBER(6,2),
    advance_distance_m      NUMBER(8,2)                                     COMMENT 'Face advance distance in metres',

    -- Loading performance
    load_count              INT                       COMMENT 'Number of truck loads in this operation',
    trucks_loaded           STRING                                         COMMENT 'JSON array of vehicle_ids loaded in this cycle',
    avg_spot_time_s         NUMBER(8,2)                                     COMMENT 'Average truck spot time in seconds',
    avg_load_time_s         NUMBER(8,2)                                     COMMENT 'Average loading time per truck in seconds',
    avg_payload_t           NUMBER(10,3)                                    COMMENT 'Average payload per truck',

    -- Destination routing
    primary_dump_location_id STRING                                   COMMENT 'Primary destination (stockpile/dump)',

    -- Cycle completion
    operation_start_ts      TIMESTAMP_LTZ,
    operation_end_ts        TIMESTAMP_LTZ,
    duration_minutes        NUMBER(10,2),

    CONSTRAINT pk_dig_face_ops PRIMARY KEY (operation_id)
)
    EXTERNAL_VOLUME = 'ONELAKE_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'dig_face_operations/'
    COMMENT = 'Drill & blast events and excavation cycles at dig faces — Iceberg on OneLake'
    CLUSTER BY (location_id, DATE_TRUNC('day', event_ts));

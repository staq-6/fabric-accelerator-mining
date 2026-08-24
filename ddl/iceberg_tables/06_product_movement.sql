-- =============================================================================
-- Mining Accelerator — Product Movement (Iceberg Table)
-- Stored on OneLake via Snowflake External Volume
-- End-to-end material tracking: dig face → stockpile → conveyor → crusher → product
-- =============================================================================

USE DATABASE MINING_DB;
USE SCHEMA OPS_STREAM;

CREATE OR REPLACE ICEBERG TABLE PRODUCT_MOVEMENT (
    movement_id             STRING     NOT NULL,
    parent_movement_id      STRING                                     COMMENT 'Parent movement for chain tracking (NULL for first leg)',
    movement_chain_id       STRING                                     COMMENT 'Shared ID across all legs of the same material parcel',
    shift_instance_id       STRING     NOT NULL,

    event_ts                TIMESTAMP_LTZ   NOT NULL,
    ingestion_ts            TIMESTAMP_LTZ   NOT NULL,

    -- Movement classification
    movement_type           STRING     NOT NULL                        COMMENT 'DIG_TO_TRUCK | TRUCK_TO_STOCKPILE | TRUCK_TO_ROM | STOCKPILE_TO_CONVEYOR | CONVEYOR_TO_CRUSHER | CRUSHER_TO_PRODUCT_STOCKPILE | TRUCK_TO_DUMP | REHANDLE',
    movement_status         STRING     NOT NULL    COMMENT 'IN_PROGRESS | COMPLETED | CANCELLED',

    -- Source
    source_location_id      STRING     NOT NULL                        COMMENT 'FK to LOCATIONS — origin zone',
    source_location_type    STRING,

    -- Destination
    dest_location_id        STRING     NOT NULL                        COMMENT 'FK to LOCATIONS — destination zone',
    dest_location_type      STRING,

    -- Equipment involved
    primary_equipment_id    STRING                                     COMMENT 'Primary mover (e.g. haul truck)',
    secondary_equipment_id  STRING                                     COMMENT 'Secondary equipment (e.g. conveyor, loader)',
    operator_id             STRING,

    -- Material
    material_type_id        STRING     NOT NULL,
    gross_tonnes            NUMBER(14,3)    NOT NULL              COMMENT 'Gross tonnes moved',
    net_tonnes              NUMBER(14,3)                                    COMMENT 'Net dry tonnes',
    moisture_pct            NUMBER(6,3)                                     COMMENT 'Moisture %',
    volume_m3               NUMBER(12,3),
    bulk_density_t_m3       NUMBER(6,3),

    -- Grade
    grade_fepct             NUMBER(6,3)                                     COMMENT 'Fe% or commodity grade',
    grade_al2o3_pct         NUMBER(6,3),
    grade_sio2_pct          NUMBER(6,3),
    grade_p_pct             NUMBER(6,3),
    grade_loi_pct           NUMBER(6,3)                                     COMMENT 'Loss on ignition %',

    -- Measurement method
    weighing_method         STRING                                     COMMENT 'OBW | BELT_SCALE | TRUCK_SCALE | ESTIMATE | BATCH',
    measurement_accuracy    STRING              COMMENT 'LEGAL | STANDARD | ESTIMATED',

    -- Timing
    movement_start_ts       TIMESTAMP_LTZ,
    movement_end_ts         TIMESTAMP_LTZ,
    duration_minutes        NUMBER(10,2),
    haul_distance_m         NUMBER(10,2)                                    COMMENT 'Route distance for truck movements',
    haul_time_min           NUMBER(8,2),

    -- Cycle tracking
    cycle_number            INT                                             COMMENT 'Truck cycle number within shift',
    truck_load_number       INT                                             COMMENT 'Sequential truck load count',

    -- Reconciliation
    is_reconciled           BOOLEAN,
    reconciliation_id       STRING                                     COMMENT 'Links to mass balance reconciliation run',
    variance_tonnes         NUMBER(14,3)                                    COMMENT 'Variance from independent measurement',

    CONSTRAINT pk_product_movement PRIMARY KEY (movement_id)
)
    EXTERNAL_VOLUME = 'ONELAKE_ICEBERG_VOL'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'product_movement/'
    COMMENT = 'End-to-end material movement tracking dig-to-mill — Iceberg on OneLake'
    CLUSTER BY (source_location_id, DATE_TRUNC('day', event_ts));

-- =============================================================================
-- Mining Accelerator — Master Seed Data & Simulation
-- Inserts reference data + generates realistic operations simulation data
-- Run this AFTER all DDL scripts
-- =============================================================================

USE DATABASE MINING_DB;
USE WAREHOUSE MINING_WH;

-- ============================================================
-- SEED: LOCATIONS
-- ============================================================
USE SCHEMA OPS_REF;

INSERT INTO LOCATIONS (location_code, location_name, location_type, site_code, pit_name, bench_level,
    latitude, longitude, elevation_m, design_capacity_t, design_capacity_m3, location_status)
VALUES
    -- Dig Faces
    ('DF-N01', 'North Pit Dig Face 1', 'DIG_FACE', 'MINE-01', 'North Pit', 'RL380', -29.450000, 117.820000, 380, NULL, NULL, 'ACTIVE'),
    ('DF-N02', 'North Pit Dig Face 2', 'DIG_FACE', 'MINE-01', 'North Pit', 'RL360', -29.451500, 117.821000, 360, NULL, NULL, 'ACTIVE'),
    ('DF-S01', 'South Pit Dig Face 1', 'DIG_FACE', 'MINE-01', 'South Pit', 'RL400', -29.460000, 117.822000, 400, NULL, NULL, 'ACTIVE'),
    ('DF-S02', 'South Pit Dig Face 2', 'DIG_FACE', 'MINE-01', 'South Pit', 'RL380', -29.461000, 117.823000, 380, NULL, NULL, 'ACTIVE'),
    -- Stockpiles
    ('SP-ORE-N', 'North ROM Ore Stockpile', 'STOCKPILE', 'MINE-01', NULL, NULL, -29.445000, 117.818000, 320, 500000, 312500, 'ACTIVE'),
    ('SP-ORE-S', 'South ROM Ore Stockpile', 'STOCKPILE', 'MINE-01', NULL, NULL, -29.465000, 117.820000, 310, 300000, 187500, 'ACTIVE'),
    ('SP-LG',   'Low Grade Ore Stockpile',  'STOCKPILE', 'MINE-01', NULL, NULL, -29.448000, 117.817000, 315, 800000, 500000, 'ACTIVE'),
    ('SP-WAS',  'Waste Dump South',          'STOCKPILE', 'MINE-01', NULL, NULL, -29.470000, 117.815000, 290, NULL,   NULL,   'ACTIVE'),
    -- Crushers
    ('CR-P01', 'Primary Crusher 1', 'CRUSHER', 'MINE-01', NULL, NULL, -29.443000, 117.816000, 305, NULL, NULL, 'ACTIVE'),
    ('CR-S01', 'Secondary Crusher 1','CRUSHER', 'MINE-01', NULL, NULL, -29.443500, 117.816200, 300, NULL, NULL, 'ACTIVE'),
    ('CR-T01', 'Tertiary Crusher 1', 'CRUSHER', 'MINE-01', NULL, NULL, -29.444000, 117.816400, 295, NULL, NULL, 'ACTIVE'),
    -- Conveyor heads/tails
    ('CV-01-H', 'Conveyor 01 Head',   'CONVEYOR_HEAD', 'MINE-01', NULL, NULL, -29.444500, 117.816600, 290, NULL, NULL, 'ACTIVE'),
    ('CV-01-T', 'Conveyor 01 Tail',   'CONVEYOR_TAIL', 'MINE-01', NULL, NULL, -29.442000, 117.815000, 295, NULL, NULL, 'ACTIVE'),
    ('CV-02-H', 'Conveyor 02 Head',   'CONVEYOR_HEAD', 'MINE-01', NULL, NULL, -29.442500, 117.815500, 285, NULL, NULL, 'ACTIVE'),
    -- ROM Pad
    ('ROM-01',  'ROM Pad 1',          'ROM_PAD',       'MINE-01', NULL, NULL, -29.444000, 117.817000, 308, 50000, 31250, 'ACTIVE'),
    -- Facilities
    ('FUEL-01', 'Fuel Bay',           'FUEL_BAY',      'MINE-01', NULL, NULL, -29.441000, 117.812000, 298, NULL, NULL, 'ACTIVE'),
    ('WKSP-01', 'Main Workshop',      'WORKSHOP',      'MINE-01', NULL, NULL, -29.440000, 117.811000, 296, NULL, NULL, 'ACTIVE');


-- ============================================================
-- SEED: MATERIAL TYPES
-- ============================================================
INSERT INTO MATERIAL_TYPES (material_code, material_name, material_category, commodity,
    density_t_m3, swell_factor, is_saleable, destination, colour_hex)
VALUES
    ('ORE-HG',  'High Grade Iron Ore',   'ORE',          'IRON_ORE', 2.5, 1.35, TRUE,  'CRUSHER',          '#CC0000'),
    ('ORE-MG',  'Medium Grade Iron Ore', 'ORE',          'IRON_ORE', 2.4, 1.35, TRUE,  'STOCKPILE',        '#FF6600'),
    ('ORE-LG',  'Low Grade Iron Ore',    'LOW_GRADE_ORE','IRON_ORE', 2.3, 1.35, FALSE, 'STOCKPILE',        '#FFAA00'),
    ('WASTE',   'Waste Rock',            'WASTE',        NULL,       2.6, 1.30, FALSE, 'WASTE_DUMP',       '#999999'),
    ('OB',      'Overburden',            'OVERBURDEN',   NULL,       1.8, 1.25, FALSE, 'WASTE_DUMP',       '#996633'),
    ('ROM',     'Run of Mine',           'ROM',          'IRON_ORE', 2.5, 1.35, FALSE, 'CRUSHER',          '#FF3300'),
    ('PROD-SF', 'Sinter Feed Product',   'PRODUCT',      'IRON_ORE', 2.6, 1.20, TRUE,  'EXPORT_STOCKPILE', '#006600'),
    ('PROD-PF', 'Pellet Feed Product',   'PRODUCT',      'IRON_ORE', 2.7, 1.20, TRUE,  'EXPORT_STOCKPILE', '#003366');


-- ============================================================
-- SEED: EQUIPMENT — Mobile Fleet
-- ============================================================
INSERT INTO EQUIPMENT (equipment_code, equipment_name, equipment_class, equipment_type,
    manufacturer, model_number, year_manufactured, year_commissioned,
    site_code, fleet_number, payload_capacity_t, engine_power_kw,
    fuel_type, equipment_status, is_mobile, is_fixed_plant, gps_enabled,
    pm_interval_hours, major_service_hours)
VALUES
    -- Haul Trucks (10 units)
    ('HT-001','Haul Truck 001','HAUL_TRUCK','793F','Caterpillar','793F',2018,2019,'MINE-01','HT001',227,2983,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('HT-002','Haul Truck 002','HAUL_TRUCK','793F','Caterpillar','793F',2018,2019,'MINE-01','HT002',227,2983,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('HT-003','Haul Truck 003','HAUL_TRUCK','793F','Caterpillar','793F',2019,2020,'MINE-01','HT003',227,2983,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('HT-004','Haul Truck 004','HAUL_TRUCK','793F','Caterpillar','793F',2019,2020,'MINE-01','HT004',227,2983,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('HT-005','Haul Truck 005','HAUL_TRUCK','793F','Caterpillar','793F',2020,2021,'MINE-01','HT005',227,2983,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('HT-006','Haul Truck 006','HAUL_TRUCK','793F','Caterpillar','793F',2020,2021,'MINE-01','HT006',227,2983,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('HT-007','Haul Truck 007','HAUL_TRUCK','930E','Komatsu','930E-5',2021,2022,'MINE-01','HT007',290,3200,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('HT-008','Haul Truck 008','HAUL_TRUCK','930E','Komatsu','930E-5',2021,2022,'MINE-01','HT008',290,3200,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('HT-009','Haul Truck 009','HAUL_TRUCK','930E','Komatsu','930E-5',2022,2023,'MINE-01','HT009',290,3200,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('HT-010','Haul Truck 010','HAUL_TRUCK','930E','Komatsu','930E-5',2022,2023,'MINE-01','HT010',290,3200,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    -- Excavators (4 units)
    ('EX-001','Excavator 001','EXCAVATOR','PC8000','Komatsu','PC8000-11',2017,2018,'MINE-01','EX001',NULL,3880,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,500,5000),
    ('EX-002','Excavator 002','EXCAVATOR','PC8000','Komatsu','PC8000-11',2018,2019,'MINE-01','EX002',NULL,3880,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,500,5000),
    ('EX-003','Excavator 003','EXCAVATOR','6060','Liebherr','R 9400',2020,2021,'MINE-01','EX003',NULL,2238,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,500,5000),
    ('EX-004','Excavator 004','EXCAVATOR','6060','Liebherr','R 9400',2021,2022,'MINE-01','EX004',NULL,2238,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,500,5000),
    -- Dozers (3 units)
    ('DZ-001','Dozer 001','DOZER','D11T','Caterpillar','D11T',2019,2020,'MINE-01','DZ001',NULL,634,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('DZ-002','Dozer 002','DOZER','D11T','Caterpillar','D11T',2019,2020,'MINE-01','DZ002',NULL,634,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('DZ-003','Dozer 003','DOZER','D475A','Komatsu','D475A-8',2021,2022,'MINE-01','DZ003',NULL,820,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    -- Graders (2 units)
    ('GR-001','Grader 001','GRADER','16M3','Caterpillar','16M3',2020,2021,'MINE-01','GR001',NULL,276,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('GR-002','Grader 002','GRADER','16M3','Caterpillar','16M3',2021,2022,'MINE-01','GR002',NULL,276,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    -- Water Trucks (2 units)
    ('WT-001','Water Truck 001','WATER_TRUCK','777G','Caterpillar','777G',2019,2020,'MINE-01','WT001',95,597,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500),
    ('WT-002','Water Truck 002','WATER_TRUCK','777G','Caterpillar','777G',2020,2021,'MINE-01','WT002',95,597,'DIESEL','ACTIVE',TRUE,FALSE,TRUE,250,2500);

-- Fixed Plant
INSERT INTO EQUIPMENT (equipment_code, equipment_name, equipment_class, equipment_type,
    manufacturer, model_number, year_manufactured, year_commissioned,
    site_code, fleet_number, belt_width_mm, belt_length_m, nominal_throughput_tph,
    engine_power_kw, fuel_type, equipment_status, is_mobile, is_fixed_plant, gps_enabled,
    pm_interval_hours, major_service_hours)
VALUES
    ('CV-01','Conveyor Belt 01','CONVEYOR_BELT','Overland CV','Metso','OLC-2200',2015,2016,'MINE-01','CV001',2200,1850,5000,3200,'ELECTRIC','ACTIVE',FALSE,TRUE,FALSE,500,8760),
    ('CV-02','Conveyor Belt 02','CONVEYOR_BELT','Overland CV','Metso','OLC-1800',2017,2018,'MINE-01','CV002',1800,1200,3500,2000,'ELECTRIC','ACTIVE',FALSE,TRUE,FALSE,500,8760),
    ('CV-03','Conveyor Belt 03','CONVEYOR_BELT','Feeding CV','FLSmidth','STC-1200',2019,2020,'MINE-01','CV003',1200,400,1500,560,'ELECTRIC','ACTIVE',FALSE,TRUE,FALSE,500,8760);

INSERT INTO EQUIPMENT (equipment_code, equipment_name, equipment_class, equipment_type,
    manufacturer, model_number, year_manufactured, year_commissioned,
    site_code, fleet_number, nominal_throughput_tph, engine_power_kw,
    fuel_type, equipment_status, is_mobile, is_fixed_plant, gps_enabled,
    pm_interval_hours, major_service_hours)
VALUES
    ('CR-P01','Primary Crusher 1',  'CRUSHER','Gyratory',   'Metso','Superior 60-89',2010,2011,'MINE-01','CR-P01',5000,3000,'ELECTRIC','ACTIVE',FALSE,TRUE,FALSE,2000,17520),
    ('CR-S01','Secondary Crusher 1','CRUSHER','Cone Crusher','Sandvik','CH880i',    2012,2013,'MINE-01','CR-S01',2000,630, 'ELECTRIC','ACTIVE',FALSE,TRUE,FALSE,2000,17520),
    ('CR-T01','Tertiary Crusher 1', 'CRUSHER','Cone Crusher','Sandvik','CH660i',    2014,2015,'MINE-01','CR-T01',1200,400, 'ELECTRIC','ACTIVE',FALSE,TRUE,FALSE,2000,17520);


-- ============================================================
-- SEED: SHIFTS
-- ============================================================
INSERT INTO SHIFTS (shift_code, shift_name, shift_type, site_code, start_time, end_time, duration_hours, crew_code)
VALUES
    ('DAY-A',   'Day Shift A',       'DAY',   'MINE-01', '06:00', '18:00', 12, 'A'),
    ('DAY-B',   'Day Shift B',       'DAY',   'MINE-01', '06:00', '18:00', 12, 'B'),
    ('NIGHT-A', 'Night Shift A',     'NIGHT', 'MINE-01', '18:00', '06:00', 12, 'A'),
    ('NIGHT-B', 'Night Shift B',     'NIGHT', 'MINE-01', '18:00', '06:00', 12, 'B');


-- ============================================================
-- SEED: OPERATORS (sample — 20 operators)
-- ============================================================
INSERT INTO OPERATORS (operator_code, first_name, last_name, job_title, operator_class,
    competency_level, site_code, crew_code, hire_date)
VALUES
    ('OP-001','James','Mitchell','Haul Truck Operator','HAUL_TRUCK_OPERATOR','SENIOR','MINE-01','A','2015-03-01'),
    ('OP-002','Sarah','Williams','Haul Truck Operator','HAUL_TRUCK_OPERATOR','STANDARD','MINE-01','A','2018-07-15'),
    ('OP-003','Michael','Nguyen','Haul Truck Operator','HAUL_TRUCK_OPERATOR','STANDARD','MINE-01','B','2019-02-10'),
    ('OP-004','Emma','Thompson','Haul Truck Operator','HAUL_TRUCK_OPERATOR','STANDARD','MINE-01','B','2020-05-20'),
    ('OP-005','Robert','Johnson','Haul Truck Operator','HAUL_TRUCK_OPERATOR','SENIOR','MINE-01','A','2014-11-01'),
    ('OP-006','Lisa','Chen','Excavator Operator','EXCAVATOR_OPERATOR','MASTER','MINE-01','A','2012-06-01'),
    ('OP-007','David','Brown','Excavator Operator','EXCAVATOR_OPERATOR','SENIOR','MINE-01','B','2016-03-15'),
    ('OP-008','Jessica','Davis','Excavator Operator','EXCAVATOR_OPERATOR','STANDARD','MINE-01','A','2020-08-01'),
    ('OP-009','Kevin','Wilson','Dozer Operator','DOZER_OPERATOR','SENIOR','MINE-01','B','2017-01-10'),
    ('OP-010','Amanda','Garcia','Dozer Operator','DOZER_OPERATOR','STANDARD','MINE-01','A','2021-04-01'),
    ('OP-011','Christopher','Taylor','Haul Truck Operator','HAUL_TRUCK_OPERATOR','STANDARD','MINE-01','B','2021-09-15'),
    ('OP-012','Melissa','Anderson','Haul Truck Operator','HAUL_TRUCK_OPERATOR','SENIOR','MINE-01','A','2016-12-01'),
    ('OP-013','Brandon','Martinez','Haul Truck Operator','HAUL_TRUCK_OPERATOR','STANDARD','MINE-01','B','2022-02-01'),
    ('OP-014','Stephanie','Robinson','Drill Operator','DRILL_OPERATOR','SENIOR','MINE-01','A','2015-09-01'),
    ('OP-015','Timothy','Clark','Maintenance Technician','MAINTENANCE_TECH','SENIOR','MINE-01','A','2013-05-01'),
    ('OP-016','Kimberly','Lewis','Maintenance Technician','MAINTENANCE_TECH','STANDARD','MINE-01','B','2019-06-01'),
    ('OP-017','Andrew','Lee','Haul Truck Operator','HAUL_TRUCK_OPERATOR','STANDARD','MINE-01','B','2022-08-01'),
    ('OP-018','Patricia','Walker','Haul Truck Operator','HAUL_TRUCK_OPERATOR','STANDARD','MINE-01','A','2022-11-01'),
    ('OP-SUP-A','Thomas','Harris','Shift Supervisor A','SUPERVISOR','MASTER','MINE-01','A','2010-01-01'),
    ('OP-SUP-B','Angela','Moore','Shift Supervisor B','SUPERVISOR','MASTER','MINE-01','B','2011-03-01');

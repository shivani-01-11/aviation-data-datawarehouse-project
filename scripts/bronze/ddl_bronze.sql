-- ============================================================
-- Aviation Data Warehouse — Bronze Layer DDL
-- Architecture : Medallion (Bronze / Silver / Gold)
-- Target DB    : MySQL 8.x
-- Layer        : Bronze — raw ingestion, no transformations
-- Created      : 
-- ============================================================
-- Naming conventions
--   Schemas  : bronze | silver | gold
--   Tables   : <schema>.<domain>_<entity>
--              ops  = airport operations  (flights, baggage, gate events)
--              pax  = passenger data
--              ret  = retail transactions
--   Columns  : snake_case
--   DWH meta : dwh_* suffix columns appended to every table
-- ============================================================

-- ============================================================
-- 0. Database & Schemas
-- ============================================================
DROP DATABASE IF EXISTS aviation_dw;
CREATE DATABASE aviation_dw
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE aviation_dw;

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- ============================================================
-- 1. bronze.ops_flights
--    Source file : flights.csv  (32 data columns)
--    Grain       : one row per flight leg
-- ============================================================
DROP TABLE IF EXISTS bronze.ops_flights;

CREATE TABLE bronze.ops_flights (
    -- Business columns (raw, in CSV column order)
    flight_id                   VARCHAR(20),       -- e.g. UK-633
    airline_name                VARCHAR(100),
    airline_code                VARCHAR(10),       -- IATA 2-letter code
    origin_airport              CHAR(3),           -- IATA airport code
    destination_airport         CHAR(3),
    scheduled_departure_time    VARCHAR(30),       -- stored as string; cast in Silver
    actual_departure_time       VARCHAR(30),
    scheduled_arrival_time      VARCHAR(30),
    actual_arrival_time         VARCHAR(30),
    aircraft_type               VARCHAR(20),       -- e.g. A350, B737
    aircraft_registration       VARCHAR(20),       -- e.g. VT-PIU
    seat_capacity               VARCHAR(10),
    booked_passengers           VARCHAR(10),
    flight_status               VARCHAR(30),       -- Departed | Cancelled | Delayed
    departure_delay_minutes     VARCHAR(10),
    delay_reason                VARCHAR(50),       -- ATC | WX | CREW | TECH
    terminal                    VARCHAR(10),       -- T1 | T2 | T3
    gate_number                 VARCHAR(10),
    international_flight_flag   VARCHAR(10),       -- True | False
    flight_distance_km          VARCHAR(10),
    ticket_revenue              VARCHAR(20),
    boarding_start_time         VARCHAR(30),
    delayed_flight_flag         VARCHAR(10),
    delay_category              VARCHAR(30),       -- On-Time | Minor | Moderate | Severe
    load_factor_percentage      VARCHAR(25),
    flight_duration_minutes     VARCHAR(10),
    baggage_load_tons           VARCHAR(25),
    arrival_time_of_day         VARCHAR(20),       -- Morning | Afternoon | Evening | Night
    departure_day_of_week       VARCHAR(10),       -- Mon … Sun
    weekend_flight_flag         VARCHAR(10),
    season                      VARCHAR(20),       -- Spring | Summer | Autumn | Winter
    route_type                  VARCHAR(30),       -- Domestic | Short-Haul Intl | Long-Haul Intl

    -- DWH metadata
    dwh_source_system           VARCHAR(50),
    dwh_load_date               DATETIME,
    dwh_batch_id                VARCHAR(100),
    dwh_file_name               VARCHAR(255)
);


-- ============================================================
-- 2. bronze.pax_passengers
--    Source file : passengers.csv  (28 data columns)
--    Grain       : one row per passenger per flight booking
-- ============================================================
DROP TABLE IF EXISTS bronze.pax_passengers;

CREATE TABLE bronze.pax_passengers (
    passenger_id                VARCHAR(20),       -- 6-char alphanumeric, e.g. MKVIIB
    loyalty_number              VARCHAR(30),
    passenger_passport_number   VARCHAR(30),       -- masked: PP-****XXXX
    first_name                  VARCHAR(100),
    last_name                   VARCHAR(100),
    nationality                 VARCHAR(100),
    date_of_birth               VARCHAR(20),
    gender                      VARCHAR(10),
    seat_number                 VARCHAR(10),
    travel_class                VARCHAR(30),       -- Economy | Business | First
    flight_number               VARCHAR(20),
    checkin_time                VARCHAR(40),
    boarding_time               VARCHAR(40),
    gate_number                 VARCHAR(10),
    baggage_count               VARCHAR(10),
    special_meal_request        VARCHAR(100),
    wheelchair_assistance_flag  VARCHAR(10),
    unaccompanied_minor_flag    VARCHAR(10),
    email_address               VARCHAR(255),
    phone_number                VARCHAR(30),
    frequent_flyer_tier         VARCHAR(30),
    passport_expiry_date        VARCHAR(20),
    no_show_flag                VARCHAR(10),
    satisfaction_score          VARCHAR(25),
    vip_flag                    VARCHAR(10),
    booking_channel             VARCHAR(50),
    passenger_age               VARCHAR(10),
    age_group                   VARCHAR(30),       -- Youth | Adult | Senior

    -- DWH metadata
    dwh_source_system           VARCHAR(50),
    dwh_load_date               DATETIME,
    dwh_batch_id                VARCHAR(100),
    dwh_file_name               VARCHAR(255)
);


-- ============================================================
-- 3. bronze.ops_baggage
--    Source file : baggage.csv  (17 data columns + 1 trailing empty)
--    Grain       : one row per baggage tag
--    NOTE        : col 1 = passenger_id (not flight_id)
--                  col 2 = flight_id / flight_number
-- ============================================================
DROP TABLE IF EXISTS bronze.ops_baggage;

CREATE TABLE bronze.ops_baggage (
    baggage_tag_number          VARCHAR(30),       -- e.g. "4717 7156 73"
    passenger_id                VARCHAR(20),       -- FK → pax_passengers.passenger_id
    flight_id                   VARCHAR(20),       -- FK → ops_flights.flight_id
    passenger_passport_number   VARCHAR(30),
    baggage_weight_kg           VARCHAR(20),
    baggage_dimensions_cm       VARCHAR(20),       -- format: LxWxH  e.g. 55x40x23
    baggage_type                VARCHAR(30),       -- Check-in | Cabin
    checkin_counter             VARCHAR(10),
    checkin_time                VARCHAR(30),
    baggage_scan_time           VARCHAR(30),
    terminal_number             VARCHAR(10),
    baggage_status              VARCHAR(30),       -- Loaded | In-Transit | Delivered | Lost
    oversized_baggage_flag      VARCHAR(10),
    baggage_delay_minutes       VARCHAR(10),
    baggage_location            VARCHAR(50),       -- Ramp | Carousel | etc.
    baggage_loaded_time         VARCHAR(30),
    damaged_baggage_flag        VARCHAR(10),

    -- DWH metadata
    dwh_source_system           VARCHAR(50),
    dwh_load_date               DATETIME,
    dwh_batch_id                VARCHAR(100),
    dwh_file_name               VARCHAR(255)
);


-- ============================================================
-- 4. bronze.ops_gate_events
--    Source file : gate_events.csv  (14 data columns)
--    Grain       : one row per gate event (boarding start/end, gate change, etc.)
-- ============================================================
DROP TABLE IF EXISTS bronze.ops_gate_events;

CREATE TABLE bronze.ops_gate_events (
    gate_event_id               VARCHAR(50),       -- e.g. T3-R18-474592
    flight_id                   VARCHAR(20),       -- FK → ops_flights.flight_id
    gate_number                 VARCHAR(10),
    terminal                    VARCHAR(10),
    event_type                  VARCHAR(50),       -- Boarding Start | Boarding End | Gate Change
    event_timestamp             VARCHAR(30),
    staff_id                    VARCHAR(20),       -- FK → wf_staff_shifts.staff_id
    passenger_count             VARCHAR(10),
    event_category              VARCHAR(30),       -- Routine | Irregular
    gate_change_flag            VARCHAR(10),
    previous_event_timestamp    VARCHAR(30),
    gate_open_time              VARCHAR(30),
    gate_close_time             VARCHAR(30),
    boarding_completion_time    VARCHAR(30),

    -- DWH metadata
    dwh_source_system           VARCHAR(50),
    dwh_load_date               DATETIME,
    dwh_batch_id                VARCHAR(100),
    dwh_file_name               VARCHAR(255)
);


-- ============================================================
-- 5. bronze.ret_retail_transactions
--    Source file : retail_transactions.csv  (17 data columns)
--    Grain       : one row per retail transaction
-- ============================================================
DROP TABLE IF EXISTS bronze.ret_retail_transactions;

CREATE TABLE bronze.ret_retail_transactions (
    transaction_id              VARCHAR(50),       -- e.g. KSK4-1774440315797
    staff_id                    VARCHAR(20),       -- FK → wf_staff_shifts.staff_id
    store_name                  VARCHAR(100),      -- e.g. Duty Free
    store_category              VARCHAR(50),       -- Retail | F&B | Services
    passenger_passport_number   VARCHAR(30),
    flight_number               VARCHAR(20),       -- FK → ops_flights.flight_id
    transaction_timestamp       VARCHAR(30),
    product_category            VARCHAR(50),       -- Perfume | Electronics | Food | etc.
    quantity                    VARCHAR(10),
    unit_price                  VARCHAR(20),
    total_amount                VARCHAR(20),
    payment_method              VARCHAR(30),       -- Card | Cash | Wallet
    currency                    VARCHAR(10),       -- INR | USD | EUR
    loyalty_points_earned       VARCHAR(20),
    terminal                    VARCHAR(10),
    store_location              VARCHAR(50),       -- Near Gate | Landside | Airside
    duty_free_flag              VARCHAR(10),

    -- DWH metadata
    dwh_source_system           VARCHAR(50),
    dwh_load_date               DATETIME,
    dwh_batch_id                VARCHAR(100),
    dwh_file_name               VARCHAR(255)
);



/*
===============================================================================
FILE: quality_checks_silver.sql
PURPOSE:
    Validate d1`ata quality AFTER loading into Silver layer.

COVERAGE:
    - Flights
    - Passengers
    - Baggage
    - Gate Events
    - Retail Transactions

RULE TYPES:
    - Null checks
    - Duplicate checks
    - Range validation
    - Timestamp validation
    - Referential integrity
===============================================================================
*/

USE aviation_dw;

-- ============================================================================
-- 1. SILVER.FLIGHTS QUALITY CHECKS
-- ============================================================================

-- 1.1 Null or duplicate flight IDs (should NOT exist)
SELECT id, COUNT(*) AS cnt
from silver.ops_flights
GROUP BY id
HAVING COUNT(*) > 1 OR id IS NULL;


-- 1.2 Actual departure before scheduled departure (early departures)
SELECT *
FROM silver.ops_flights
WHERE actual_departure_time < scheduled_departure_time;

-- 1.3 Arrival before departure (invalid timeline)
SELECT *
FROM silver.ops_flights
WHERE actual_arrival_time < actual_departure_time;

-- 1.4 Negative delay values (invalid)
SELECT *
FROM silver.ops_flights
WHERE departure_delay_minutes < 0;

-- 1.5 Load factor > 100% (should be capped already)
SELECT *
FROM silver.ops_flights
WHERE load_factor_percentage > 100;

-- 1.6 Booked passengers > seat capacity (should not happen after LEAST fix)
SELECT *
FROM silver.ops_flights
WHERE booked_passengers > seat_capacity;

-- 1.7 Invalid terminal values
SELECT DISTINCT terminal
FROM silver.ops_flights
WHERE terminal NOT IN ('T1','T2','T3');

-- 1.8 Invalid delay category mapping
SELECT DISTINCT departure_delay_minutes, delay_category
FROM silver.ops_flights
WHERE
    (departure_delay_minutes = 0 AND delay_category <> 'On-Time')
    OR (departure_delay_minutes BETWEEN 1 AND 60 AND delay_category <> 'Moderate')
    OR (departure_delay_minutes > 120 AND delay_category <> 'High');


-- ============================================================================
-- 2. SILVER.PAX_PASSENGERS QUALITY CHECKS
-- ============================================================================

-- 2.1 Null or duplicate passenger IDs
SELECT passenger_id, COUNT(*) AS cnt
FROM silver.pax_passengers
GROUP BY passenger_id
HAVING COUNT(*) > 1 OR passenger_id IS NULL;

-- 2.2 Invalid travel class
SELECT DISTINCT travel_class
FROM silver.pax_passengers
WHERE travel_class NOT IN ('Economy','Business','First');

-- 2.3 Missing nationality
SELECT *
FROM silver.pax_passengers
WHERE nationality IS NULL OR TRIM(nationality) = '';

-- 2.4 Invalid age values
SELECT *
FROM silver.pax_passengers
WHERE passenger_age < 0 OR passenger_age > 120;

-- 2.5 Age mismatch check (validation vs DOB)
SELECT *
FROM silver.pax_passengers
WHERE passenger_age != TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE());

-- 2.6 Invalid gender values
SELECT DISTINCT gender
FROM silver.pax_passengers
WHERE gender NOT IN ('Male','Female','n/a');

-- 2.7 Boarding before check-in (invalid flow)
SELECT *
FROM silver.pax_passengers
WHERE boarding_time < checkin_time;

-- 2.8 Invalid no_show flag
SELECT DISTINCT no_show_flag
FROM silver.pax_passengers
WHERE no_show_flag NOT IN (0,1);


-- ============================================================================
-- 3. SILVER.OPS_BAGGAGE QUALITY CHECKS
-- ============================================================================

-- 3.1 Duplicate baggage tag numbers
SELECT baggage_tag_number, COUNT(*) AS cnt
FROM silver.ops_baggage
GROUP BY baggage_tag_number
HAVING COUNT(*) > 1 OR baggage_tag_number IS NULL;

-- 3.2 Negative baggage weight
SELECT *
FROM silver.ops_baggage
WHERE baggage_weight_kg < 0;

-- 3.3 Invalid baggage status
SELECT DISTINCT baggage_status
FROM silver.ops_baggage
WHERE baggage_status NOT IN ('Loaded','In-Transit','Delivered','Lost');

-- 3.4 Invalid timestamp sequence
SELECT *
FROM silver.ops_baggage
WHERE checkin_time >  baggage_scan_time
   OR baggage_scan_time > baggage_loaded_time;

-- 3.5 Negative baggage delay
SELECT *
FROM silver.ops_baggage
WHERE baggage_delay_minutes < 0;


-- ============================================================================
-- 4. SILVER.OPS_GATE_EVENTS QUALITY CHECKS
-- ============================================================================

-- 4.1 Duplicate gate event IDs
SELECT gate_event_id, COUNT(*) AS cnt
FROM silver.ops_gate_events
GROUP BY gate_event_id
HAVING COUNT(*) > 1 OR gate_event_id IS NULL;

-- 4.2 Missing gate numbers
SELECT *
FROM silver.ops_gate_events
WHERE gate_number IS NULL OR TRIM(gate_number) = '';

-- 4.3 Invalid passenger count
SELECT *
FROM silver.ops_gate_events
WHERE passenger_count < 0;

-- 4.4 Boarding completion before event timestamp
SELECT *
FROM silver.ops_gate_events
WHERE boarding_completion_time < event_timestamp;

-- 4.5 Invalid gate timing sequence
SELECT *
FROM silver.ops_gate_events
WHERE gate_open_time > boarding_completion_time
   OR boarding_completion_time > gate_close_time;

-- 4.6 Event timestamp outside gate open/close window
SELECT *
FROM silver.ops_gate_events
WHERE event_timestamp < gate_open_time
   OR event_timestamp > gate_close_time;


-- ============================================================================
-- 5. SILVER.RETAIL_TRANSACTIONS QUALITY CHECKS
-- ============================================================================

-- 5.1 Duplicate transaction IDs
SELECT transaction_id, COUNT(*) AS cnt
FROM silver.ret_retail_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1 OR transaction_id IS NULL;

-- 5.2 Negative sales values
SELECT *
FROM silver.ret_retail_transactions
WHERE total_amount < 0;

-- 5.3 Missing product categories
SELECT *
FROM silver.ret_retail_transactions
WHERE product_category IS NULL OR TRIM(product_category) = '';

-- 5.4 Invalid payment methods
SELECT DISTINCT payment_method
FROM silver.ret_retail_transactions
WHERE payment_method NOT IN ('Card','Wallet','Cash');

-- 5.5 Quantity <= 0 (invalid)
SELECT *
FROM silver.ret_retail_transactions
WHERE quantity <= 0;

-- 5.6 Unit price > total amount (should not happen after correction)
SELECT *
FROM silver.ret_retail_transactions
WHERE unit_price > total_amount;

-- 5.7 Calculated amount mismatch
SELECT *
FROM silver.ret_retail_transactions
WHERE ABS(calculated_amount - total_amount) > 1;


-- ============================================================================
-- 6. CROSS-TABLE REFERENTIAL INTEGRITY CHECKS
-- ============================================================================

-- 6.1 Passenger → Flight mapping
SELECT *
FROM silver.pax_passengers p
LEFT JOIN silver.ops_flights f
    ON p.flight_number = f.flight_id
WHERE f.flight_id IS NULL;

-- 6.2 Baggage → Passenger mapping
SELECT *
FROM silver.ops_baggage b
LEFT JOIN silver.pax_passengers p
    ON b.passenger_id = p.passenger_id
WHERE p.passenger_id IS NULL;

-- 6.3 Baggage → Flight mapping
SELECT *
FROM silver.ops_baggage b
LEFT JOIN silver.ops_flights f
    ON b.flight_id = f.flight_id
WHERE f.flight_id IS NULL;

-- 6.4 Retail → Passenger mapping
SELECT *
FROM silver.ret_retail_transactions r
LEFT JOIN silver.pax_passengers p
    ON r.passenger_passport_number = p.passenger_passport_number
WHERE p.passenger_passport_number IS NULL;

-- 6.5 Retail → Flight mapping
SELECT *
FROM silver.ret_retail_transactions r
LEFT JOIN silver.ops_flights f
    ON r.flight_number = f.flight_id
WHERE f.flight_id IS NULL;

-- 6.6 Gate Events → Flight mapping
SELECT *
FROM silver.ops_gate_events g
LEFT JOIN silver.ops_flights f
    ON g.flight_id = f.flight_id
WHERE f.flight_id IS NULL;

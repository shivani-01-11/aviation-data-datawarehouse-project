-- ============================================================
-- File Name : bronze_ret_retail_transactions_data_validation_and_profiling.sql
-- Purpose   : Validate and profile bronze.ret_retail_transactions
--             before loading into silver layer
-- ============================================================


-- ============================================================
-- Check total row count in retail transaction table
-- ============================================================
SELECT COUNT(*) AS total_record_count
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Check for duplicate or null transaction IDs
-- transaction_id is not unique in source, so surrogate key
-- will be needed in silver layer
-- ============================================================
SELECT 
    transaction_id,
    COUNT(*) AS duplicate_count
FROM bronze.ret_retail_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1
   OR transaction_id IS NULL;


-- ============================================================
-- Check transaction_id values for leading or trailing spaces
-- Expected result: 0 records
-- ============================================================
SELECT DISTINCT transaction_id
FROM bronze.ret_retail_transactions
WHERE transaction_id != TRIM(transaction_id);


-- ============================================================
-- Check staff_id values for leading or trailing spaces
-- Expected result: 0 records
-- ============================================================
SELECT DISTINCT staff_id
FROM bronze.ret_retail_transactions
WHERE staff_id != TRIM(staff_id);


-- ============================================================
-- Check store_name values for leading or trailing spaces
-- Expected result: 0 records
-- ============================================================
SELECT DISTINCT store_name
FROM bronze.ret_retail_transactions
WHERE store_name != TRIM(store_name);


-- ============================================================
-- Review distinct store names
-- Only one store exists in source data
-- ============================================================
SELECT DISTINCT store_name
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Review distinct store categories
-- Only one category exists in source data
-- ============================================================
SELECT DISTINCT store_category
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Review distinct product categories
-- Used to determine whether diversification logic is needed
-- ============================================================
SELECT DISTINCT product_category
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Review quantity values
-- Source currently contains quantity = 1 for all records
-- Quantity may need recalculation in silver layer
-- ============================================================
SELECT DISTINCT quantity
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Review payment method values
-- Source currently contains only Card
-- Payment method may be diversified in silver layer
-- ============================================================
SELECT DISTINCT payment_method
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Review currency values
-- ============================================================
SELECT DISTINCT currency
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Check if loyalty_points_earned column is empty
-- If all values are blank, silver layer can derive loyalty points
-- based on total spend
-- ============================================================
SELECT
    COUNT(*) AS blank_loyalty_points_records
FROM bronze.ret_retail_transactions
WHERE TRIM(COALESCE(loyalty_points_earned, '')) = '';


-- ============================================================
-- Identify records where unit price is greater than total amount
-- This is logically invalid and should be corrected in silver layer
-- ============================================================
SELECT
    transaction_id,
    quantity,
    unit_price,
    total_amount
FROM bronze.ret_retail_transactions
WHERE CAST(unit_price AS DECIMAL(10,2))
      > CAST(total_amount AS DECIMAL(10,2));


-- ============================================================
-- Check retail transactions linked to known passengers
-- Only passenger passport numbers existing in silver.pax_passengers
-- should be loaded into silver retail table
-- ============================================================
SELECT DISTINCT passenger_passport_number
FROM bronze.ret_retail_transactions
WHERE passenger_passport_number IN (
    SELECT DISTINCT passenger_passport_number
    FROM silver.pax_passengers
);


-- ============================================================
-- Check retail transactions linked to known flights
-- Only valid flight numbers existing in silver.ops_flights
-- should be loaded into silver retail table
-- ============================================================
SELECT DISTINCT flight_number
FROM bronze.ret_retail_transactions
WHERE flight_number IN (
    SELECT DISTINCT flight_id
    FROM silver.ops_flights
);


-- ============================================================
-- Review terminal values
-- Source currently contains same terminal value for all rows
-- ============================================================
SELECT DISTINCT terminal
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Review store location values
-- Source currently contains same location value for all rows
-- ============================================================
SELECT DISTINCT store_location
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Review duty free flag values
-- Source currently contains same value for all rows
-- ============================================================
SELECT DISTINCT duty_free_flag
FROM bronze.ret_retail_transactions;


-- ============================================================
-- Suggested transformation for quantity
-- If quantity is always 1, recalculate using total_amount / unit_price
-- ============================================================
SELECT
    transaction_id,
    quantity,
    unit_price,
    total_amount,

    CASE
        WHEN CAST(unit_price AS DECIMAL(10,2)) <= 0 THEN 1
        ELSE GREATEST(
            1,
            ROUND(
                CAST(total_amount AS DECIMAL(10,2)) /
                CAST(unit_price AS DECIMAL(10,2)),
                0
            )
        )
    END AS corrected_quantity

FROM bronze.ret_retail_transactions;


-- ============================================================
-- Suggested transformation for unit_price
-- If unit_price is greater than total_amount,
-- cap unit_price at total_amount
-- ============================================================
SELECT
    transaction_id,
    unit_price,
    total_amount,

    LEAST(
        CAST(unit_price AS DECIMAL(10,2)),
        CAST(total_amount AS DECIMAL(10,2))
    ) AS corrected_unit_price

FROM bronze.ret_retail_transactions;


-- ============================================================
-- Suggested transformation for payment method
-- Larger amounts more likely to be paid using card
-- Smaller amounts may use wallet or cash
-- ============================================================
SELECT
    transaction_id,
    total_amount,

    CASE
        WHEN CAST(total_amount AS DECIMAL(10,2)) >= 600 THEN 'Card'
        WHEN CAST(total_amount AS DECIMAL(10,2)) BETWEEN 100 AND 600 THEN 'Wallet'
        ELSE 'Cash'
    END AS corrected_payment_method

FROM bronze.ret_retail_transactions;


-- ============================================================
-- Suggested transformation for loyalty points
-- Loyalty points can be derived from total spend
-- ============================================================
SELECT
    transaction_id,
    total_amount,

    CASE
        WHEN CAST(total_amount AS DECIMAL(10,2)) >= 1000
            THEN FLOOR(CAST(total_amount AS DECIMAL(10,2)) / 10)

        WHEN CAST(total_amount AS DECIMAL(10,2)) >= 500
            THEN FLOOR(CAST(total_amount AS DECIMAL(10,2)) / 20)

        ELSE 0
    END AS derived_loyalty_points

FROM bronze.ret_retail_transactions;
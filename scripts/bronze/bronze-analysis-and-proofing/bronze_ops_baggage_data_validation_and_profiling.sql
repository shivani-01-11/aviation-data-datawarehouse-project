-- ============================================================
-- Validate baggage tag uniqueness
-- baggage_tag_number is unique and non-null in bronze layer,
-- so it can safely be retained as the business key.
-- A surrogate key is optional, but recommended for consistency
-- across all silver tables.
-- ============================================================

SELECT 
    baggage_tag_number,
    COUNT(*) AS duplicate_count
FROM bronze.ops_baggage
GROUP BY baggage_tag_number
HAVING COUNT(*) > 1
   OR baggage_tag_number IS NULL;
   
-- ============================================================
-- Identify baggage records with invalid timestamp sequence
-- Expected flow:
-- checkin_time <= baggage_scan_time <= baggage_loaded_time
-- ============================================================

SELECT
    baggage_tag_number,
    checkin_time,
    baggage_scan_time,
    baggage_loaded_time
FROM bronze.ops_baggage
WHERE CAST(checkin_time AS DATETIME) > CAST(baggage_scan_time AS DATETIME)
   OR CAST(baggage_scan_time AS DATETIME) > CAST(baggage_loaded_time AS DATETIME);
   
   
-- ============================================================
-- Generate corrected baggage process timestamps
-- Since source timestamps are inconsistent,
-- silver layer will retain original checkin_time where possible
-- and generate realistic scan/load times relative to check-in.
--
-- Logic:
-- 1. checkin_time retained from source
-- 2. baggage_scan_time = checkin_time + 5 to 30 minutes
-- 3. baggage_loaded_time = baggage_scan_time + 10 to 60 minutes
-- ============================================================

SELECT
    baggage_tag_number,

    -- Source timestamp format is MM/DD/YY HH:MM
    -- If value is null or invalid, use current timestamp
    COALESCE(
        STR_TO_DATE(checkin_time, '%m/%d/%y %H:%i'),
        NOW()
    ) AS corrected_checkin_time,

    -- Generate baggage scan time 5 to 30 minutes after check-in
    DATE_ADD(
        COALESCE(
            STR_TO_DATE(checkin_time, '%m/%d/%y %H:%i'),
            NOW()
        ),
        INTERVAL FLOOR(5 + RAND() * 25) MINUTE
    ) AS corrected_baggage_scan_time,

    -- Generate baggage loaded time 10 to 60 minutes after scan
    DATE_ADD(
        DATE_ADD(
            COALESCE(
                STR_TO_DATE(checkin_time, '%m/%d/%y %H:%i'),
                NOW()
            ),
            INTERVAL FLOOR(5 + RAND() * 25) MINUTE
        ),
        INTERVAL FLOOR(10 + RAND() * 50) MINUTE
    ) AS corrected_baggage_loaded_time

FROM bronze.ops_baggage;
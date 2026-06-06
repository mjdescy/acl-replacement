-- #############################################################################
-- Date Field Analysis Template
--
-- Computes summary statistics for date columns in the `source` table:
--   - Minimum / maximum date
--   - Count of unique days present in the data
--   - Count of missing days within the observed date range
--   - Count of null / blank / otherwise-invalid date values
--
-- Usage:
--   1. Replace the column names in the UNPIVOT ON clause below with the actual
--      date column names from your table.
--   2. Make sure the source table is loaded (see import-csv.sql or
--      import-parquet.sql).
--   3. Run this script.
-- #############################################################################

-- =============================================================================
-- Setup: Unpivot date columns into (column_name, raw_value) pairs
-- =============================================================================
-- 👇 Replace `created_date, modified_date` with your actual date column names.
--    If you have many columns, you can also use COLUMNS('regex_pattern') to
--    select columns by pattern (e.g., COLUMNS('_date$') for columns ending
--    in "_date").
WITH unpivoted AS (
    UNPIVOT source
    ON created_date, modified_date
    INTO
        NAME column_name
        VALUE raw_value
),

-- =============================================================================
-- Classify each value: null, invalid (non-castable string), or valid date
-- =============================================================================
with_validity AS (
    SELECT
        column_name,
        raw_value,
        CASE
            WHEN raw_value IS NULL                                            THEN 'null'
            WHEN try_cast(raw_value::VARCHAR AS DATE) IS NULL                 THEN 'invalid'
            ELSE                                                                   'valid'
        END AS value_status,
        try_cast(raw_value::VARCHAR AS DATE) AS date_value
    FROM unpivoted
)

-- =============================================================================
-- Analysis: Per-column summary statistics
-- =============================================================================
SELECT
    column_name,

    -- Earliest and latest dates (NULL if no valid dates exist)
    MIN(date_value)::DATE                                          AS min_date,
    MAX(date_value)::DATE                                          AS max_date,

    -- How many distinct days appear in the data
    COUNT(DISTINCT date_value::DATE)                               AS unique_days_present,

    -- Number of days in the [min, max] range that are missing from the data
    (MAX(date_value)::DATE - MIN(date_value)::DATE + 1)
        - COUNT(DISTINCT date_value::DATE)                         AS missing_days_count,

    -- Value quality metrics
    COUNT(*)                                                       AS total_rows,
    COUNT(*) FILTER (WHERE value_status = 'null')                  AS null_count,
    COUNT(*) FILTER (WHERE value_status = 'invalid')               AS invalid_count,
    COUNT(*) FILTER (WHERE value_status = 'valid')                 AS valid_count

FROM with_validity
GROUP BY column_name
ORDER BY column_name;

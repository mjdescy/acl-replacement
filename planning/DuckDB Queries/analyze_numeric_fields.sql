-- #############################################################################
-- Numeric Field Analysis Template
--
-- Computes summary statistics for numeric columns in the `source` table:
--   - Minimum / maximum value
--   - Sum, mean, median, standard deviation
--   - Count of unique numeric values
--   - Count of null / blank / otherwise-invalid values
--   - Count of zeros and negative values (data quality)
--
-- Usage:
--   1. Replace the column names in the UNPIVOT ON clause below with the actual
--      numeric column names from your table.
--   2. Make sure the source table is loaded (see import-csv.sql or
--      import-parquet.sql).
--   3. Run this script.
-- #############################################################################

-- =============================================================================
-- Setup: Unpivot numeric columns into (column_name, raw_value) pairs
-- =============================================================================
-- 👇 Replace `amount, quantity, price` with your actual numeric column names.
--    If you have many columns, you can also use COLUMNS('regex_pattern') to
--    select columns by pattern (e.g., COLUMNS('_amt$') for columns ending
--    in "_amt").
WITH unpivoted AS (
    UNPIVOT source
    ON amount, quantity, price
    INTO
        NAME column_name
        VALUE raw_value
),

-- =============================================================================
-- Classify each value: null, invalid (non-numeric string), or valid number
-- =============================================================================
with_validity AS (
    SELECT
        column_name,
        raw_value,
        CASE
            WHEN raw_value IS NULL                                           THEN 'null'
            WHEN try_cast(raw_value::VARCHAR AS DOUBLE) IS NULL              THEN 'invalid'
            ELSE                                                                  'valid'
        END AS value_status,
        try_cast(raw_value::VARCHAR AS DOUBLE) AS numeric_value
    FROM unpivoted
)

-- =============================================================================
-- Analysis: Per-column summary statistics
-- =============================================================================
SELECT
    column_name,

    -- Range and central tendency
    MIN(numeric_value)                                              AS min_value,
    MAX(numeric_value)                                              AS max_value,
    SUM(numeric_value)                                              AS total_sum,
    AVG(numeric_value)                                              AS mean,
    MEDIAN(numeric_value)                                           AS median_value,
    STDDEV_SAMP(numeric_value)                                      AS std_dev,

    -- Distribution shape
    SKEWNESS(numeric_value)                                         AS skewness,
    KURTOSIS(numeric_value)                                         AS kurtosis,

    -- Quantiles
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY numeric_value)     AS q1,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY numeric_value)     AS q3,

    -- Uniqueness
    COUNT(DISTINCT numeric_value)                                   AS unique_values_count,

    -- Data quality
    COUNT(*)                                                        AS total_rows,
    COUNT(*) FILTER (WHERE value_status = 'null')                   AS null_count,
    COUNT(*) FILTER (WHERE value_status = 'invalid')                AS invalid_count,
    COUNT(*) FILTER (WHERE value_status = 'valid')                  AS valid_count,

    -- Business-rule checks
    COUNT(*) FILTER (WHERE numeric_value = 0)                       AS zero_count,
    COUNT(*) FILTER (WHERE numeric_value < 0)                       AS negative_count,
    COUNT(*) FILTER (WHERE numeric_value > 0)                       AS positive_count

FROM with_validity
GROUP BY column_name
ORDER BY column_name;

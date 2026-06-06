-- Mapping table
CREATE OR REPLACE TABLE sample_map AS (
    SELECT 'customers' AS table_name, 50 AS sample_size
    UNION ALL
    SELECT 'orders', 30
    UNION ALL
    SELECT 'products', 20
);

-- For each table, sample and assign row number
WITH sampled AS (
    SELECT m.table_name, s.*, s_rownum.row_num
    FROM sample_map m,
    LATERAL (
        SELECT *, ROW_NUMBER() OVER (ORDER BY random()) AS row_num
        FROM query_table(m.table_name)
    ) s_rownum
    WHERE s_rownum.row_num <= m.sample_size
)
-- Interleave
SELECT * EXCLUDE (row_num)
FROM sampled
ORDER BY row_num, table_name;

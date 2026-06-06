-- Input parameters
SET VARIABLE sample_size = 109;

-- Execution
SELECT *
FROM sample_source
USING SAMPLE getvariable('sample_size');
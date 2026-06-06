-- Inputs
SET VARIABLE import_file_glob_pattern = 'dir/*.csv';

-- Execution
CREATE OR REPLACE TABLE source AS
    SELECT *
    FROM read_csv(
        getvariable('import_file_glob_pattern'), 
        union_by_name = true, 
        filename = true);
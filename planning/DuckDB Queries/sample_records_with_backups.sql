-- Input parameters
SET VARIABLE primary_sample_size = 109;
SET VARIABLE backup_sample_size = 25;
SET VARIABLE primary_sample_category_name = 'Primary';
SET VARIABLE backup_sample_category_name = 'Backup';

-- Setup
SET VARIABLE combined_sample_size = getvariable('primary_sample_size') + getvariable('backup_sample_size');
CREATE OR REPLACE SEQUENCE sample_id_sequence;

-- Execution
SELECT 
    "sample_id": nextval('serial'),
    "sample_type": CASE
        WHEN "sample_id" <= getvariable('primary_sample_size') THEN getvariable('primary_sample_category_name')
        ELSE getvariable('backup_sample_category_name')
    END
FROM sample_source
USING SAMPLE getvariable('combined_sample_size');
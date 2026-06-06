-- Randomize the order of all records in the source table.
SELECT 
    *,
    ROW_NUMBER() OVER (ORDER BY RANDOM()) AS sample_id
FROM 
    source;

-- Alternate method.
FROM source ORDER BY random();

-- Method that works with a random number seed.
SET VARIABLE random_number_seed = 49631;
FROM source ORDER BY hash(rowid + getvariable('random_number_seed'));

-- Some of these methods require another step to add a "sample_id" identity column.
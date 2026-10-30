propertyId|clientId|code              |entityType|dataType|label                     |description                                  |
----------+--------+------------------+----------+--------+--------------------------+---------------------------------------------+
     16547|    2021|minimum_investment|CLSS      |DCML    |Minimum Initial Investment|Minimum initial investment of the share class|

-- ================================================================================================================================

-- Step 2: Apply the change
UPDATE Properties
SET dataType = 'STRG'
WHERE code LIKE '%minimum_investment%'
  AND clientId = 2021
  AND dataType = 'DCML';
====================================================================================================================================
-- Step 3: Confirm the change
SELECT propertyId, clientId, code, entityType, dataType, label, description
FROM Properties
WHERE code LIKE '%minimum_investment%'
  AND clientId = 2021;
====================================================================================================================================
-- Step 4: Bust the cache
SELECT clientId, lastModified, lastFlush
FROM WarpdriveCache
WHERE clientId = 2021;
====================================================================================================================================
UPDATE WarpdriveCache
SET lastModified = NOW()
WHERE clientId = 2021;
====================================================================================================================================
SELECT clientId, lastModified, lastFlush
FROM WarpdriveCache
WHERE clientId = 2021;


-- ==================================================================================================================================
-- ROLLBACK (if needed)
-- ==================================================================================================================================

UPDATE Properties
SET dataType = 'DCML'
WHERE code LIKE '%minimum_investment%'
  AND clientId = 2021
  AND dataType = 'STRG';
=====================================================================================================================================
SELECT propertyId, clientId, code, entityType, dataType, label, description
FROM Properties
WHERE code LIKE '%minimum_investment%'
  AND clientId = 2021;
====================================================================================================================================
UPDATE WarpdriveCache
SET lastModified = NOW()
WHERE clientId = 2021;
/* ============================================================================
   *** DEV / TEST COPY - NOT FOR PRODUCTION USE ***
   Test copy of TECH-3306_revoke_ram_jeyaraman_TROWEPRICE.sql, using the
   stand-in test user kuhle.ndlela on the Utilities dev database, to
   validate the exact revoke logic (all three roles + user + login drop)
   before running it against production.

   Environment : DEV / TEST ONLY
   Database    : Utilities
   Mirrors     : TECH-3306_revoke_ram_jeyaraman_TROWEPRICE.sql
   Test grant  : db_datareader, db_StoredProcReader, db_StoredProcCreator
                 (matches the actual roles found on ram.jeyaraman in prod)

   WHAT THIS SCRIPT DOES:
   Step 1 — Pre-check: confirms the user, login type, and ALL role
            memberships (read only, safe to run)
   Step 2 — Removes kuhle.ndlela from ALL THREE roles on Utilities:
            db_datareader, db_StoredProcReader, db_StoredProcCreator
   Step 3 — Drops the kuhle.ndlela database user from Utilities
   Step 4 — Drops the kuhle.ndlela SQL login from master
   Step 5 — Post-check: confirms all 3 queries return 0 rows (green light)

   HOW TO EXECUTE:
   - Run each step individually, one GO block at a time
   - Review the PRINT output after each step before moving to the next
   - Do NOT run the entire script at once
   - Prerequisite: dev_test_setup_kuhle_ndlela.sql has already been run
     against Utilities
============================================================================ */


/* ----------------------------------------------------------------------------
   STEP 1 — PRE-REVOKE VERIFICATION (read only — safe to run first)

   Expected output:
   - First query  : 1 row - kuhle.ndlela, SQL_USER, create_date
   - Second query : 1 row - roles = "db_StoredProcReader, db_StoredProcCreator,
                    db_datareader" (order may vary)

   If either query returns 0 rows, STOP and raise with the team before
   proceeding - the user may have already been removed or never existed.
---------------------------------------------------------------------------- */
PRINT '--- STEP 1: Pre-revoke verification ---';

USE Utilities;
GO

SELECT dp.name AS database_user, dp.type_desc, dp.create_date
FROM sys.database_principals dp
WHERE dp.name = 'kuhle.ndlela';

SELECT
    DB_NAME() AS database_name,
    dp.name AS username,
    dp.type_desc AS user_type,
    STRING_AGG(r.name, ', ') AS roles
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.type IN ('S', 'U', 'G')
  AND dp.name = 'kuhle.ndlela'
GROUP BY dp.name, dp.type_desc;
GO


/* ----------------------------------------------------------------------------
   STEP 2 — REMOVE FROM ALL THREE ROLES

   Original ticket scope was db_datareader only. Pre-check confirmed
   kuhle.ndlela also holds db_StoredProcReader and db_StoredProcCreator.
   All three are removed here since the ticket calls for full removal
   of access regardless of scope.

   IF EXISTS guards mean each role is skipped safely if already absent -
   no error if one or more roles were removed already.
---------------------------------------------------------------------------- */
PRINT '--- STEP 2: Removing kuhle.ndlela from all database roles ---';

USE Utilities;
GO

IF EXISTS (
    SELECT 1 FROM sys.database_role_members drm
    JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
    JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
    WHERE dp_role.name = 'db_datareader' AND dp_user.name = 'kuhle.ndlela'
)
BEGIN
    ALTER ROLE db_datareader DROP MEMBER [kuhle.ndlela];
    PRINT 'Removed kuhle.ndlela from db_datareader.';
END
ELSE
    PRINT 'kuhle.ndlela was not in db_datareader - skipping.';

IF EXISTS (
    SELECT 1 FROM sys.database_role_members drm
    JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
    JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
    WHERE dp_role.name = 'db_StoredProcReader' AND dp_user.name = 'kuhle.ndlela'
)
BEGIN
    ALTER ROLE db_StoredProcReader DROP MEMBER [kuhle.ndlela];
    PRINT 'Removed kuhle.ndlela from db_StoredProcReader.';
END
ELSE
    PRINT 'kuhle.ndlela was not in db_StoredProcReader - skipping.';

IF EXISTS (
    SELECT 1 FROM sys.database_role_members drm
    JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
    JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
    WHERE dp_role.name = 'db_StoredProcCreator' AND dp_user.name = 'kuhle.ndlela'
)
BEGIN
    ALTER ROLE db_StoredProcCreator DROP MEMBER [kuhle.ndlela];
    PRINT 'Removed kuhle.ndlela from db_StoredProcCreator.';
END
ELSE
    PRINT 'kuhle.ndlela was not in db_StoredProcCreator - skipping.';
GO


/* ----------------------------------------------------------------------------
   STEP 3 — DROP THE DATABASE USER FROM Utilities

   Removes kuhle.ndlela as a user from the Utilities database.
   Must be done before dropping the server login in Step 4.
   The IF EXISTS guard makes this safe to re-run if needed.

   Expected output: 'Dropped database user kuhle.ndlela.'
---------------------------------------------------------------------------- */
PRINT '--- STEP 3: Dropping database user kuhle.ndlela from Utilities ---';

USE Utilities;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'kuhle.ndlela')
BEGIN
    DROP USER [kuhle.ndlela];
    PRINT 'Dropped database user kuhle.ndlela.';
END
ELSE
    PRINT 'Database user kuhle.ndlela not found - skipping.';
GO


/* ----------------------------------------------------------------------------
   STEP 4 — DROP THE SQL LOGIN FROM MASTER

   Removes the kuhle.ndlela SQL Server authentication login from the
   server entirely. This is the final removal - after this, the account
   has no footprint on this SQL Server instance at all.
   The IF EXISTS guard makes this safe to re-run if needed.

   Expected output: 'Dropped server login kuhle.ndlela.'
---------------------------------------------------------------------------- */
PRINT '--- STEP 4: Dropping SQL login kuhle.ndlela from master ---';

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'kuhle.ndlela')
BEGIN
    DROP LOGIN [kuhle.ndlela];
    PRINT 'Dropped server login kuhle.ndlela.';
END
ELSE
    PRINT 'Server login kuhle.ndlela not found - skipping.';
GO


/* ----------------------------------------------------------------------------
   STEP 5 — POST-REVOKE VERIFICATION (read only — confirms clean removal)

   ALL THREE queries must return 0 rows.
   If any query returns a row, the removal was not fully successful -
   review the output and re-run the relevant step above.

   Once confirmed, paste this output as a comment in TECH-3306 as evidence
   that the access has been fully revoked and the DoD is satisfied.
---------------------------------------------------------------------------- */
PRINT '--- STEP 5: Post-revoke verification (all queries must return 0 rows) ---';

USE Utilities;
GO

-- 1. Confirm database user is gone
SELECT dp.name AS database_user
FROM sys.database_principals dp
WHERE dp.name = 'kuhle.ndlela';

-- 2. Confirm role membership is gone (any role, not just db_datareader)
SELECT dp_role.name AS role_name, dp_user.name AS member_name
FROM sys.database_role_members drm
JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
WHERE dp_user.name = 'kuhle.ndlela';

-- 3. Confirm server login is gone
SELECT name AS server_login
FROM master.sys.server_principals
WHERE name = 'kuhle.ndlela';
GO

PRINT '--- DONE: If all 3 queries above returned 0 rows, the test PASSED. ---';

/* ============================================================================
   TEST RESULT NOTES (your own test log - not for the real ticket)
   ------------------------------------------------------------------------
   - Step 1 pre-check showed all 3 roles as expected:  [yes/no]
   - Step 2 removed all 3 roles cleanly:                [yes/no]
   - Step 3 dropped the database user:                  [yes/no]
   - Step 4 dropped the SQL login:                       [yes/no]
   - Step 5 all 3 queries returned 0 rows:                [yes/no]

   Once all of the above pass, you can be confident running
   TECH-3306_revoke_ram_jeyaraman_TROWEPRICE.sql against production
   will behave the same way. Don't forget to run
   dev_test_cleanup_kuhle_ndlela.sql afterward if you want to fully
   reset your test environment (it only needs to drop the login now,
   since this script already drops the user).
   ============================================================================ */

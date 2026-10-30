/* ============================================================================
   DEV TESTING CLEANUP - removes the test server login entirely once you're
   done testing. Run this AFTER revoke_ram_jeyaraman_TROWEPRICE.sql has
   already dropped the database user (Step 3), so only the server login
   remains.

   NOTE: The production revoke script intentionally does NOT drop the
   server login (scope = database user only). This cleanup step exists
   only for dev, to fully reset your test environment.
---------------------------------------------------------------------------- */

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'kuhle.ndlela')
BEGIN
    DROP LOGIN [kuhle.ndlela];
    PRINT 'Dropped test login kuhle.ndlela.';
END
ELSE
BEGIN
    PRINT 'Login kuhle.ndlela does not exist - nothing to clean up.';
END
GO

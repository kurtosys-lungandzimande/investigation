/* ============================================================================
   DEV TESTING SETUP - creates a stand-in user mirroring kuhle.ndlela's
   read-only access, so you can test the revoke logic before running it
   against production TROWEPRICE.

   Target dev database: Utilities
---------------------------------------------------------------------------- */

USE master;
GO

/* ----------------------------------------------------------------------------
   STEP A - Create a server login (test stand-in for kuhle.ndlela)
   Using SQL auth here for simplicity in dev. If your real user is a
   Windows/AD login, swap this for: CREATE LOGIN [DOMAIN\kuhle.ndlela]
   FROM WINDOWS;
---------------------------------------------------------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'kuhle.ndlela')
BEGIN
    CREATE LOGIN [kuhle.ndlela] WITH PASSWORD = 'Test_Only_Pa55word!', CHECK_POLICY = ON;
    PRINT 'Created test login kuhle.ndlela.';
END
ELSE
BEGIN
    PRINT 'Login kuhle.ndlela already exists - skipping.';
END
GO

/* ----------------------------------------------------------------------------
   STEP B - Create the database user and grant ALL THREE roles
   (mirrors the ACTUAL grant found on ram.jeyaraman in production:
   db_datareader, db_StoredProcReader, db_StoredProcCreator - not just
   the originally-ticketed db_datareader)
---------------------------------------------------------------------------- */

USE Utilities;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'kuhle.ndlela')
BEGIN
    CREATE USER [kuhle.ndlela] FOR LOGIN [kuhle.ndlela];
    PRINT 'Created database user kuhle.ndlela.';
END
ELSE
BEGIN
    PRINT 'Database user kuhle.ndlela already exists - skipping.';
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
    JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
    WHERE dp_role.name = 'db_datareader' AND dp_user.name = 'kuhle.ndlela'
)
BEGIN
    ALTER ROLE db_datareader ADD MEMBER [kuhle.ndlela];
    PRINT 'Added kuhle.ndlela to db_datareader.';
END
ELSE
BEGIN
    PRINT 'kuhle.ndlela already in db_datareader - skipping.';
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
    JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
    WHERE dp_role.name = 'db_StoredProcReader' AND dp_user.name = 'kuhle.ndlela'
)
BEGIN
    ALTER ROLE db_StoredProcReader ADD MEMBER [kuhle.ndlela];
    PRINT 'Added kuhle.ndlela to db_StoredProcReader.';
END
ELSE
BEGIN
    PRINT 'kuhle.ndlela already in db_StoredProcReader - skipping.';
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals dp_role ON drm.role_principal_id = dp_role.principal_id
    JOIN sys.database_principals dp_user ON drm.member_principal_id = dp_user.principal_id
    WHERE dp_role.name = 'db_StoredProcCreator' AND dp_user.name = 'kuhle.ndlela'
)
BEGIN
    ALTER ROLE db_StoredProcCreator ADD MEMBER [kuhle.ndlela];
    PRINT 'Added kuhle.ndlela to db_StoredProcCreator.';
END
ELSE
BEGIN
    PRINT 'kuhle.ndlela already in db_StoredProcCreator - skipping.';
END
GO

/* ----------------------------------------------------------------------------
   STEP C - Confirm setup worked (mirrors Step 1 of the revoke script)
---------------------------------------------------------------------------- */

PRINT '--- Verifying test setup ---';

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

/* ============================================================================
   NEXT STEP:
   Now run dev_test_revoke_kuhle_ndlela.sql against this same dev
   database, step by step, and confirm each stage behaves as expected.
   ============================================================================ */

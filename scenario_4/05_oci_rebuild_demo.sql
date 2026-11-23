-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: 4 - Reporting and Data Exchange
-- Author: Valentina Montaño Sandez
-- Date: 2026-11-21
-- Description: Drop only the scenario reporting table for the controlled reimport demonstration.
-- Environment: OCI Reporting
-- ============================================================

-- Run ONLY after the first successful import and source/import total comparison.
-- Confirm this connection points to OCI and this table contains only the project snapshot.
-- Keep the exported JSON file. Do not use PURGE: retain the normal recycle-bin recovery route.
SELECT USER AS session_user,
       SYS_CONTEXT('USERENV','DB_NAME') AS database_name,
       SYS_CONTEXT('USERENV','SERVICE_NAME') AS service_name
FROM dual;
SELECT COUNT(*) AS rows_before_drop FROM s4_hr_reporting;
DROP TABLE s4_hr_reporting;
-- Next, use SQL Developer's Import wizard to recreate S4_HR_REPORTING from
-- the same AWS JSON snapshot. Repeat 04_oci_reporting_checks.sql after import.

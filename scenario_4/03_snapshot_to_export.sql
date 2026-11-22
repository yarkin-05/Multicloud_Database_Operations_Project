-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: 4 - Reporting and Data Exchange
-- Author: Valentina Montaño Sandez
-- Date: 2026-11-21
-- Description: Select the refreshed snapshot for SQL Developer JSON export.
-- Environment: AWS Production
-- ============================================================

-- First confirm the refresh finished successfully.
SELECT mview_name, last_refresh_date, last_refresh_type, staleness
FROM user_mviews WHERE mview_name = 'S4_HR_REPORTING_MV';
-- Execute the following SELECT as a statement, then export its result as JSON
-- with SQL Developer's Export wizard, including all rows.
SELECT employee_id, first_name, last_name, job_id, department_id,
       department_name, city, salary, hire_date, department_headcount,
       department_avg_salary, department_payroll, snapshot_utc
FROM hr.s4_hr_reporting_mv
ORDER BY employee_id;

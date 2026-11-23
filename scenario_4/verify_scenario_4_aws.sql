-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: 4 - Reporting and Data Exchange
-- Author: Valentina Montaño Sandez
-- Date: 2026-11-21
-- Description: Read-only validation of the AWS snapshot, daily schedule and actual refresh log.
-- Environment: AWS Production, HR connected to ORCL PDB
-- ============================================================
SELECT SYS_CONTEXT('USERENV','CON_NAME') container_name FROM dual;
SELECT mview_name, refresh_method, refresh_mode,
last_refresh_type, last_refresh_date, staleness
FROM user_mviews WHERE mview_name='S4_HR_REPORTING_MV';
SELECT enabled, state,
TO_CHAR(next_run_date AT TIME ZONE 'America/Mexico_City','YYYY-MM-DD HH24:MI') next_mexico,
repeat_interval
FROM user_scheduler_jobs WHERE job_name='S4_NIGHTLY_MV_REFRESH';
SELECT status, error#, TO_CHAR(actual_start_date,'YYYY-MM-DD HH24:MI:SS') started,
run_duration
FROM user_scheduler_job_run_details
WHERE job_name='S4_NIGHTLY_MV_REFRESH'
ORDER BY log_date DESC;
-- Aggregate each side separately, then compare the one-row results.
SELECT m.rows_in_mv, m.employee_ids, m.mv_payroll, s.hr_payroll,
       m.snapshot_utc
FROM (SELECT COUNT(*) rows_in_mv,
             COUNT(DISTINCT employee_id) employee_ids,
             SUM(salary) mv_payroll, MIN(snapshot_utc) snapshot_utc
      FROM hr.s4_hr_reporting_mv) m
CROSS JOIN (SELECT SUM(salary) hr_payroll FROM hr.employees) s;

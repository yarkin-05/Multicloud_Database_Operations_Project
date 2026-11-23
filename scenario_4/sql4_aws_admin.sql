-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: 4 - Reporting and Data Exchange
-- Author: Valentina Montaño Sandez
-- Date: 2026-11-21
-- Description: Create HR-owned reporting objects using the existing DBA connection, with the required direct CREATE TABLE prerequisite for HR.
-- Environment: AWS Production, SYS connected to ORCL PDB
-- ============================================================
-- Initial setup only. Do not recreate objects that already exist.
-- In the SYS ORCLCDB connection, select the ORCL PDB first.
ALTER SESSION SET CONTAINER = ORCL;
-- HR already has CREATE TABLE through a role. Oracle requires a direct grant
-- for an MV created in another schema. No access to another schema is added.
GRANT CREATE TABLE TO HR;
CREATE MATERIALIZED VIEW hr.s4_hr_reporting_mv
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
DISABLE QUERY REWRITE
AS
SELECT e.employee_id, e.first_name, e.last_name, e.job_id,
       e.department_id,
       NVL(d.department_name,'Unassigned') AS department_name,
       l.city, e.salary,
       TO_CHAR(e.hire_date,'YYYY-MM-DD') AS hire_date,
       COUNT(*) OVER (PARTITION BY e.department_id) AS department_headcount,
       ROUND(AVG(e.salary) OVER (PARTITION BY e.department_id),2) AS department_avg_salary,
       SUM(e.salary) OVER (PARTITION BY e.department_id) AS department_payroll,
       TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP),
               'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS snapshot_utc
FROM hr.employees e
LEFT JOIN hr.departments d ON d.department_id = e.department_id
LEFT JOIN hr.locations l ON l.location_id = d.location_id;

DECLARE
  v_next_run TIMESTAMP WITH TIME ZONE;
BEGIN
  v_next_run := FROM_TZ(
      CAST(TRUNC(CAST(SYSTIMESTAMP AT TIME ZONE 'America/Mexico_City' AS DATE))
           AS TIMESTAMP), 'America/Mexico_City') + INTERVAL '23' HOUR;
  IF v_next_run <= SYSTIMESTAMP THEN
    v_next_run := v_next_run + INTERVAL '1' DAY;
  END IF;
  DBMS_SCHEDULER.CREATE_JOB(
    job_name => 'HR.S4_NIGHTLY_MV_REFRESH',
    job_type => 'PLSQL_BLOCK',
    job_action => 'BEGIN DBMS_MVIEW.REFRESH(''HR.S4_HR_REPORTING_MV'',''C'',atomic_refresh=>TRUE); END;',
    start_date => v_next_run,
    repeat_interval => 'FREQ=DAILY;BYHOUR=23;BYMINUTE=0;BYSECOND=0',
    enabled => TRUE,
    auto_drop => FALSE,
    comments => 'Scenario 4 daily complete refresh before the Scenario 5 HR backup.');
END;
/
-- Run the HR-owned job once through the scheduler for demonstration.
BEGIN
  DBMS_SCHEDULER.RUN_JOB('HR.S4_NIGHTLY_MV_REFRESH',use_current_session=>FALSE);
END;
/
SELECT owner, mview_name, refresh_mode, refresh_method,
last_refresh_type, last_refresh_date, staleness
FROM dba_mviews WHERE owner='HR' AND mview_name='S4_HR_REPORTING_MV';
SELECT owner, job_name, enabled, state, repeat_interval, next_run_date
FROM dba_scheduler_jobs WHERE owner='HR' AND job_name='S4_NIGHTLY_MV_REFRESH';
SELECT owner, job_name, status, error#, actual_start_date, run_duration
FROM dba_scheduler_job_run_details
WHERE owner='HR' AND job_name='S4_NIGHTLY_MV_REFRESH' ORDER BY log_date DESC;
-- Aggregate each side separately, then compare the one-row results.
SELECT m.rows_in_mv, m.employee_ids, m.mv_payroll, s.hr_payroll,
       m.snapshot_utc
FROM (SELECT COUNT(*) rows_in_mv,
             COUNT(DISTINCT employee_id) employee_ids,
             SUM(salary) mv_payroll, MIN(snapshot_utc) snapshot_utc
      FROM hr.s4_hr_reporting_mv) m
CROSS JOIN (SELECT SUM(salary) hr_payroll FROM hr.employees) s;

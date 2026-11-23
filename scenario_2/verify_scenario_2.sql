-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: 2 - Performance Crisis
-- Author: Valentina Montaño Sandez
-- Date: 2026-11-21
-- Description: Verify saved measurements and equivalent results, then regenerate plans for this session.
-- Environment: AWS Production
-- ============================================================
SET LINESIZE 220
SET PAGESIZE 200
SELECT USER session_user, SYS_CONTEXT('USERENV','CON_NAME') container_name,
(SELECT COUNT(*) FROM employees) employees,
(SELECT COUNT(*) FROM job_history) job_history,
(SELECT COUNT(*) FROM departments) departments,
(SELECT COUNT(*) FROM locations) locations FROM dual;
SELECT * FROM s2_benchmark_results ORDER BY query_name, measured_at;
SELECT b.query_name, b.elapsed_seconds before_sec, a.elapsed_seconds after_sec,
ROUND(100*(b.elapsed_seconds-a.elapsed_seconds)/NULLIF(b.elapsed_seconds,0),1) reduction_pct,
b.executions, b.fetched_rows rows_before, a.fetched_rows rows_after
FROM s2_benchmark_results b JOIN s2_benchmark_results a ON a.query_name=b.query_name
WHERE b.stage='BEFORE' AND a.stage<>'BEFORE' ORDER BY b.query_name;
SELECT index_name, status FROM user_indexes WHERE index_name='S2_EMP_UPPER_LAST_NAME_IX';
-- Both directions must return zero differences.
WITH original AS (SELECT DISTINCT
       d.department_id, d.department_name, l.city,
       (SELECT COUNT(*) FROM hr.employees x
         WHERE x.department_id = e.department_id) AS headcount,
       (SELECT ROUND(AVG(x.salary), 2) FROM hr.employees x
         WHERE x.department_id = e.department_id) AS average_salary,
       (SELECT SUM(x.salary) FROM hr.employees x
         WHERE x.department_id = e.department_id) AS total_payroll,
       (SELECT COUNT(*)
          FROM hr.job_history jh
          JOIN hr.employees x ON x.employee_id = jh.employee_id
         WHERE x.department_id = e.department_id) AS history_records
  FROM hr.employees e
  JOIN hr.departments d ON d.department_id = e.department_id
  JOIN hr.locations l ON l.location_id = d.location_id), payroll AS (
    SELECT department_id, COUNT(*) AS headcount,
           ROUND(AVG(salary), 2) AS average_salary,
           SUM(salary) AS total_payroll
      FROM hr.employees
     WHERE department_id IS NOT NULL
     GROUP BY department_id
), history AS (
    SELECT e.department_id, COUNT(*) AS history_records
      FROM hr.job_history jh
      JOIN hr.employees e ON e.employee_id = jh.employee_id
     GROUP BY e.department_id
), rewritten AS (SELECT d.department_id, d.department_name, l.city,
       p.headcount, p.average_salary, p.total_payroll,
       NVL(h.history_records, 0) AS history_records
  FROM payroll p
  JOIN hr.departments d ON d.department_id = p.department_id
  JOIN hr.locations l ON l.location_id = d.location_id
  LEFT JOIN history h ON h.department_id = p.department_id)
SELECT 'ORIGINAL_MINUS_REWRITE' comparison, COUNT(*) differences FROM
(SELECT * FROM original MINUS SELECT * FROM rewritten)
UNION ALL SELECT 'REWRITE_MINUS_ORIGINAL', COUNT(*) FROM
(SELECT * FROM rewritten MINUS SELECT * FROM original);
-- PLAN_TABLE contents can be session-specific. Regenerate current plans here.
-- The original, unhinted pre-index Q2 plan is preserved in the screenshots.
-- Q2 below shows the indexed plan in the already-configured environment.

EXPLAIN PLAN SET STATEMENT_ID = 'S2_Q1_ORIGINAL_DEMO' FOR
SELECT DISTINCT
       d.department_id, d.department_name, l.city,
       (SELECT COUNT(*) FROM hr.employees x
         WHERE x.department_id = e.department_id) AS headcount,
       (SELECT ROUND(AVG(x.salary), 2) FROM hr.employees x
         WHERE x.department_id = e.department_id) AS average_salary,
       (SELECT SUM(x.salary) FROM hr.employees x
         WHERE x.department_id = e.department_id) AS total_payroll,
       (SELECT COUNT(*)
          FROM hr.job_history jh
          JOIN hr.employees x ON x.employee_id = jh.employee_id
         WHERE x.department_id = e.department_id) AS history_records
  FROM hr.employees e
  JOIN hr.departments d ON d.department_id = e.department_id
  JOIN hr.locations l ON l.location_id = d.location_id;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','S2_Q1_ORIGINAL_DEMO','TYPICAL'));

EXPLAIN PLAN SET STATEMENT_ID = 'S2_Q1_REWRITE_DEMO' FOR
WITH payroll AS (
    SELECT department_id, COUNT(*) AS headcount,
           ROUND(AVG(salary), 2) AS average_salary,
           SUM(salary) AS total_payroll
      FROM hr.employees
     WHERE department_id IS NOT NULL
     GROUP BY department_id
), history AS (
    SELECT e.department_id, COUNT(*) AS history_records
      FROM hr.job_history jh
      JOIN hr.employees e ON e.employee_id = jh.employee_id
     GROUP BY e.department_id
)
SELECT d.department_id, d.department_name, l.city,
       p.headcount, p.average_salary, p.total_payroll,
       NVL(h.history_records, 0) AS history_records
  FROM payroll p
  JOIN hr.departments d ON d.department_id = p.department_id
  JOIN hr.locations l ON l.location_id = d.location_id
  LEFT JOIN history h ON h.department_id = p.department_id;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','S2_Q1_REWRITE_DEMO','TYPICAL'));

EXPLAIN PLAN SET STATEMENT_ID = 'S2_Q2_INDEXED_DEMO' FOR
SELECT e.employee_id, e.first_name, e.last_name,
       d.department_name, l.city, e.salary,
       COUNT(jh.start_date) AS history_records
  FROM hr.employees e
  JOIN hr.departments d ON d.department_id = e.department_id
  JOIN hr.locations l ON l.location_id = d.location_id
  LEFT JOIN hr.job_history jh ON jh.employee_id = e.employee_id
 WHERE UPPER(e.last_name) = 'KING'
 GROUP BY e.employee_id, e.first_name, e.last_name,
          d.department_name, l.city, e.salary;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','S2_Q2_INDEXED_DEMO','TYPICAL'));

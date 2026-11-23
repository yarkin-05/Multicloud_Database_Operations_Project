-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: 2 - Performance Crisis
-- Author: Valentina Montaño Sandez
-- Date: 2026-11-21
-- Description: Full before/after test, equivalent rewrite, index and measurements.
-- Environment: AWS Production - HR schema, ORCL PDB
-- ============================================================
-- Run ONCE as HR, after confirming the two S2 objects do not exist.
-- HR source rows, existing indexes and security policies are not modified.
SET LINESIZE 180
SET PAGESIZE 200
SET SERVEROUTPUT ON
SET TIMING ON
SPOOL C:\Users\Public\Documents\scenario_2_execution.log
WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE TABLE s2_benchmark_results (
  query_name VARCHAR2(30), stage VARCHAR2(30), executions NUMBER,
  fetched_rows NUMBER, elapsed_seconds NUMBER, measured_at TIMESTAMP
);

EXPLAIN PLAN SET STATEMENT_ID = 'S2_Q1_BEFORE' FOR
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
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','S2_Q1_BEFORE','TYPICAL'));
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

EXPLAIN PLAN SET STATEMENT_ID = 'S2_Q2_BEFORE' FOR
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
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','S2_Q2_BEFORE','TYPICAL'));
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

DECLARE
  c INTEGER; ignored INTEGER; col_count INTEGER; defs DBMS_SQL.DESC_TAB2;
  v_text VARCHAR2(4000); start_time PLS_INTEGER;
  fetched PLS_INTEGER := 0; elapsed NUMBER;
BEGIN
  c := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(c, q'~SELECT DISTINCT
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
  JOIN hr.locations l ON l.location_id = d.location_id~', DBMS_SQL.NATIVE);
  DBMS_SQL.DESCRIBE_COLUMNS2(c,col_count,defs);
  FOR k IN 1..col_count LOOP DBMS_SQL.DEFINE_COLUMN(c,k,v_text,4000); END LOOP;
  ignored := DBMS_SQL.EXECUTE(c);
  WHILE DBMS_SQL.FETCH_ROWS(c)>0 LOOP NULL; END LOOP;
  start_time := DBMS_UTILITY.GET_TIME;
  FOR n IN 1..1000 LOOP
    ignored := DBMS_SQL.EXECUTE(c);
    WHILE DBMS_SQL.FETCH_ROWS(c)>0 LOOP fetched := fetched + 1; END LOOP;
  END LOOP;
  elapsed := (DBMS_UTILITY.GET_TIME-start_time)/100;
  DBMS_SQL.CLOSE_CURSOR(c);
  INSERT INTO s2_benchmark_results VALUES
    ('DEPARTMENT_REPORT','BEFORE',1000,fetched,elapsed,SYSTIMESTAMP);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('DEPARTMENT_REPORT BEFORE: seconds='||elapsed||'; rows='||fetched);
EXCEPTION WHEN OTHERS THEN
  IF DBMS_SQL.IS_OPEN(c) THEN DBMS_SQL.CLOSE_CURSOR(c); END IF;
  RAISE;
END;
/

DECLARE
  c INTEGER; ignored INTEGER; col_count INTEGER; defs DBMS_SQL.DESC_TAB2;
  v_text VARCHAR2(4000); start_time PLS_INTEGER;
  fetched PLS_INTEGER := 0; elapsed NUMBER;
BEGIN
  c := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(c, q'~SELECT e.employee_id, e.first_name, e.last_name,
       d.department_name, l.city, e.salary,
       COUNT(jh.start_date) AS history_records
  FROM hr.employees e
  JOIN hr.departments d ON d.department_id = e.department_id
  JOIN hr.locations l ON l.location_id = d.location_id
  LEFT JOIN hr.job_history jh ON jh.employee_id = e.employee_id
 WHERE UPPER(e.last_name) = 'KING'
 GROUP BY e.employee_id, e.first_name, e.last_name,
          d.department_name, l.city, e.salary~', DBMS_SQL.NATIVE);
  DBMS_SQL.DESCRIBE_COLUMNS2(c,col_count,defs);
  FOR k IN 1..col_count LOOP DBMS_SQL.DEFINE_COLUMN(c,k,v_text,4000); END LOOP;
  ignored := DBMS_SQL.EXECUTE(c);
  WHILE DBMS_SQL.FETCH_ROWS(c)>0 LOOP NULL; END LOOP;
  start_time := DBMS_UTILITY.GET_TIME;
  FOR n IN 1..1000 LOOP
    ignored := DBMS_SQL.EXECUTE(c);
    WHILE DBMS_SQL.FETCH_ROWS(c)>0 LOOP fetched := fetched + 1; END LOOP;
  END LOOP;
  elapsed := (DBMS_UTILITY.GET_TIME-start_time)/100;
  DBMS_SQL.CLOSE_CURSOR(c);
  INSERT INTO s2_benchmark_results VALUES
    ('NAME_LOOKUP','BEFORE',1000,fetched,elapsed,SYSTIMESTAMP);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('NAME_LOOKUP BEFORE: seconds='||elapsed||'; rows='||fetched);
EXCEPTION WHEN OTHERS THEN
  IF DBMS_SQL.IS_OPEN(c) THEN DBMS_SQL.CLOSE_CURSOR(c); END IF;
  RAISE;
END;
/

-- Strategy 1: pre-aggregate each source once.

EXPLAIN PLAN SET STATEMENT_ID = 'S2_Q1_AFTER' FOR
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
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','S2_Q1_AFTER','TYPICAL'));
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
), rewritten AS (
SELECT d.department_id, d.department_name, l.city,
       p.headcount, p.average_salary, p.total_payroll,
       NVL(h.history_records, 0) AS history_records
  FROM payroll p
  JOIN hr.departments d ON d.department_id = p.department_id
  JOIN hr.locations l ON l.location_id = d.location_id
  LEFT JOIN history h ON h.department_id = p.department_id)
SELECT 'ORIGINAL_MINUS_REWRITE' AS direction, COUNT(*) AS differences
FROM (SELECT * FROM original MINUS SELECT * FROM rewritten)
UNION ALL
SELECT 'REWRITE_MINUS_ORIGINAL', COUNT(*)
FROM (SELECT * FROM rewritten MINUS SELECT * FROM original);

DECLARE
  c INTEGER; ignored INTEGER; col_count INTEGER; defs DBMS_SQL.DESC_TAB2;
  v_text VARCHAR2(4000); start_time PLS_INTEGER;
  fetched PLS_INTEGER := 0; elapsed NUMBER;
BEGIN
  c := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(c, q'~WITH payroll AS (
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
  LEFT JOIN history h ON h.department_id = p.department_id~', DBMS_SQL.NATIVE);
  DBMS_SQL.DESCRIBE_COLUMNS2(c,col_count,defs);
  FOR k IN 1..col_count LOOP DBMS_SQL.DEFINE_COLUMN(c,k,v_text,4000); END LOOP;
  ignored := DBMS_SQL.EXECUTE(c);
  WHILE DBMS_SQL.FETCH_ROWS(c)>0 LOOP NULL; END LOOP;
  start_time := DBMS_UTILITY.GET_TIME;
  FOR n IN 1..1000 LOOP
    ignored := DBMS_SQL.EXECUTE(c);
    WHILE DBMS_SQL.FETCH_ROWS(c)>0 LOOP fetched := fetched + 1; END LOOP;
  END LOOP;
  elapsed := (DBMS_UTILITY.GET_TIME-start_time)/100;
  DBMS_SQL.CLOSE_CURSOR(c);
  INSERT INTO s2_benchmark_results VALUES
    ('DEPARTMENT_REPORT','AFTER_REWRITE',1000,fetched,elapsed,SYSTIMESTAMP);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('DEPARTMENT_REPORT AFTER_REWRITE: seconds='||elapsed||'; rows='||fetched);
EXCEPTION WHEN OTHERS THEN
  IF DBMS_SQL.IS_OPEN(c) THEN DBMS_SQL.CLOSE_CURSOR(c); END IF;
  RAISE;
END;
/

-- Strategy 2: index the same expression used by the case-insensitive predicate.
CREATE INDEX s2_emp_upper_last_name_ix ON employees(UPPER(last_name));

EXPLAIN PLAN SET STATEMENT_ID = 'S2_Q2_AFTER' FOR
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
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','S2_Q2_AFTER','TYPICAL'));
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

DECLARE
  c INTEGER; ignored INTEGER; col_count INTEGER; defs DBMS_SQL.DESC_TAB2;
  v_text VARCHAR2(4000); start_time PLS_INTEGER;
  fetched PLS_INTEGER := 0; elapsed NUMBER;
BEGIN
  c := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(c, q'~SELECT e.employee_id, e.first_name, e.last_name,
       d.department_name, l.city, e.salary,
       COUNT(jh.start_date) AS history_records
  FROM hr.employees e
  JOIN hr.departments d ON d.department_id = e.department_id
  JOIN hr.locations l ON l.location_id = d.location_id
  LEFT JOIN hr.job_history jh ON jh.employee_id = e.employee_id
 WHERE UPPER(e.last_name) = 'KING'
 GROUP BY e.employee_id, e.first_name, e.last_name,
          d.department_name, l.city, e.salary~', DBMS_SQL.NATIVE);
  DBMS_SQL.DESCRIBE_COLUMNS2(c,col_count,defs);
  FOR k IN 1..col_count LOOP DBMS_SQL.DEFINE_COLUMN(c,k,v_text,4000); END LOOP;
  ignored := DBMS_SQL.EXECUTE(c);
  WHILE DBMS_SQL.FETCH_ROWS(c)>0 LOOP NULL; END LOOP;
  start_time := DBMS_UTILITY.GET_TIME;
  FOR n IN 1..1000 LOOP
    ignored := DBMS_SQL.EXECUTE(c);
    WHILE DBMS_SQL.FETCH_ROWS(c)>0 LOOP fetched := fetched + 1; END LOOP;
  END LOOP;
  elapsed := (DBMS_UTILITY.GET_TIME-start_time)/100;
  DBMS_SQL.CLOSE_CURSOR(c);
  INSERT INTO s2_benchmark_results VALUES
    ('NAME_LOOKUP','AFTER_INDEX',1000,fetched,elapsed,SYSTIMESTAMP);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('NAME_LOOKUP AFTER_INDEX: seconds='||elapsed||'; rows='||fetched);
EXCEPTION WHEN OTHERS THEN
  IF DBMS_SQL.IS_OPEN(c) THEN DBMS_SQL.CLOSE_CURSOR(c); END IF;
  RAISE;
END;
/

SELECT query_name, stage, executions, fetched_rows, elapsed_seconds
FROM s2_benchmark_results ORDER BY query_name, measured_at;
SELECT statement_id, cost, cardinality
FROM plan_table
WHERE statement_id IN ('S2_Q1_BEFORE','S2_Q1_AFTER','S2_Q2_BEFORE','S2_Q2_AFTER')
  AND id=0
ORDER BY statement_id;
SPOOL OFF

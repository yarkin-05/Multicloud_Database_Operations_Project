-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: 4 - Reporting and Data Exchange
-- Author: Valentina Montaño Sandez
-- Date: 2026-11-21
-- Description: Check the imported snapshot, run two management queries and create a JSON summary.
-- Environment: OCI Reporting
-- ============================================================

-- Run in the OCI reporting connection only, after wizard import.
-- The imported table must be named S4_HR_REPORTING and retain the exported columns.
SELECT USER AS session_user,
       SYS_CONTEXT('USERENV','DB_NAME') AS database_name,
       SYS_CONTEXT('USERENV','SERVICE_NAME') AS service_name
FROM dual;
SELECT COUNT(*) AS imported_rows, COUNT(DISTINCT employee_id) AS distinct_employees,
       SUM(salary) AS imported_payroll, MIN(snapshot_utc) AS snapshot_utc
FROM s4_hr_reporting;
-- Management query 1: departments with payroll above the department average.
WITH departments AS (
  SELECT department_id, department_name,
         MAX(department_headcount) AS headcount,
         MAX(department_payroll) AS total_payroll
  FROM s4_hr_reporting
  WHERE department_id IS NOT NULL
  GROUP BY department_id, department_name
)
SELECT department_name, headcount, total_payroll
FROM departments
WHERE total_payroll > (SELECT AVG(total_payroll) FROM departments)
ORDER BY total_payroll DESC;
-- Management query 2: headcount and payroll by job category.
SELECT job_id, COUNT(*) AS headcount, SUM(salary) AS total_payroll,
       ROUND(AVG(salary),2) AS average_salary
FROM s4_hr_reporting
GROUP BY job_id
ORDER BY headcount DESC, job_id;
-- JSON generation happens in OCI, using the imported snapshot only.
WITH departments AS (
  SELECT department_id, department_name,
         MAX(department_headcount) AS headcount,
         MAX(department_avg_salary) AS average_salary,
         MAX(department_payroll) AS total_payroll
  FROM s4_hr_reporting
  GROUP BY department_id, department_name
)
SELECT JSON_OBJECT(
  'source' VALUE 'OCI reporting snapshot',
  'departments' VALUE JSON_ARRAYAGG(
    JSON_OBJECT('departmentId' VALUE department_id,
                'departmentName' VALUE department_name,
                'headcount' VALUE headcount,
                'averageSalary' VALUE average_salary,
                'totalPayroll' VALUE total_payroll)
    ORDER BY department_id RETURNING CLOB)
  RETURNING CLOB) AS management_json
FROM departments;

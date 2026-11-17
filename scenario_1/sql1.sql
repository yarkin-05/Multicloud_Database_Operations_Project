-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: Scenario 1 - Security &amp; Audit
-- Author: Jacqueline Cruz Solis
-- Date: November 16th, 2026
-- Description: Oracle Unified Auditing
-- Environment: AWS Production
-- ============================================================

-- create audit policy on salary
create audit policy salary_access_pol 
actions select(salary) on hr.employees;

-- enable policy for all users (sys)
audit policy salary_access_pol;
audit policy salary_access_pol by sys;

-- create an audit policy that logs all database connections off working
create audit policy offhours_logon_pol
    actions logon
    when 'TO_NUMBER(TO_CHAR(SYSDATE, ''HH24'')) < 8 OR 
        TO_NUMBER(TO_CHAR(SYSDATE, ''HH24'')) >= 18' 
evaluate per statement; 

-- enable the policy
audit policy offhours_logon_pol;



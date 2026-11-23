-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: Scenario 1 - Security & Audit
-- Author: Jacqueline Cruz Solis
-- Date: November 16th, 2026
-- Description: Oracle Unified Auditing
-- Environment: AWS Production
-- ============================================================

-- create audit policy on salary

FGA policy: (sys)
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema => 'HR',
    object_name => 'employees',
    policy_name => 'audit_salary_access',
    audit_column => 'salary',
    enable => true,
    statement_types => 'insert, update, select, delete'
  );
END;
/



-- enable policy for all sys user
ALTER SYSTEM SET audit_sys_operations = TRUE SCOPE=SPFILE;

shutdown immediate;
startup;

Select * from UNIFIED_AUDIT_TRAIL 
where AUDIT_TYPE = FineGrainedAudit;

SELECT 
    DBUSERNAME, 
    EVENT_TIMESTAMP, 
    ACTION_NAME, 
    OBJECT_SCHEMA, 
    OBJECT_NAME, 
    SQL_TEXT,
    FGA_POLICY_NAME
FROM UNIFIED_AUDIT_TRAIL
WHERE FGA_POLICY_NAME = 'SALARY_ACCESS_POLICY'
ORDER BY EVENT_TIMESTAMP DESC;

select * from AUDSYS.AUD$UNIFIED;

-- create an audit policy that logs all database connections off working
BEGIN
  DBMS_FGA.ADD_POLICY(
   object_schema      => 'HR',
   object_name        => 'EMPLOYEES',
   policy_name        => 'chk_hr_employees',
   audit_condition   => '' TO_CHAR(SYSDATE, ''DY'', ''NLS_DATE_LANGUAGE=ENGLISH'') IN (''SAT'', ''SUN'') AND SYS_CONTEXT(''USERENV'', ''SESSION_USER'') = ''HR'',
   audit_column       => 'SALARY',
   enable             =>  TRUE,
   statement_types    => 'INSERT, UPDATE, SELECT, DELETE');
END;
/

-- enable the policy




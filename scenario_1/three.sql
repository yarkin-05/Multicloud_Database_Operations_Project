-- ============================================================
-- Project: Multicloud Database Operations
-- Scenario: Scenario 1 - Security & Audit
-- Author: Jacqueline Cruz Solis
-- Date: November 23rd, 2026
-- Description: Oracle Unified Auditing
-- Environment: AWS Production
-- ============================================================


CREATE USER audit_owner
  IDENTIFIED BY "audit"
  ACCOUNT LOCK;
  
CREATE TABLE audit_owner.login_audit (
  db_user      VARCHAR2(128),
  os_user      VARCHAR2(128),
  host         VARCHAR2(128),
  ip_address   VARCHAR2(64),
  logon_time   TIMESTAMP
);

REVOKE ALL ON audit_owner.login_audit FROM PUBLIC;
  
  
CREATE OR REPLACE PROCEDURE sys.log_after_hours_connection AS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO audit_owner.login_audit (
    db_user,
    os_user,
    host,
    ip_address,
    logon_time
  )
  VALUES (
    SYS_CONTEXT('USERENV', 'SESSION_USER'),
    SYS_CONTEXT('USERENV', 'OS_USER'),
    SYS_CONTEXT('USERENV', 'HOST'),
    SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
    SYSTIMESTAMP
  );

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
END;
/

CREATE OR REPLACE TRIGGER sys.trg_after_hours_logon
AFTER LOGON ON DATABASE
DECLARE
  v_hour NUMBER;
BEGIN
  v_hour := TO_NUMBER(TO_CHAR(SYSTIMESTAMP, 'HH24'));

  IF v_hour < 8 OR v_hour >= 18 THEN
    sys.log_after_hours_connection;
  END IF;
END;
/
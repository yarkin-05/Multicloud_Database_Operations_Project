SCENARIO 4 - REPORTING AND DATA EXCHANGE
Author: Valentina Montaño Sandez

AWS setup: sql4_aws_admin.sql, using the existing SYS connection in ORCL.
HR already held effective CREATE TABLE through a role; Oracle required a direct
grant for the materialized view owner. The job and materialized view belong to HR.
The job runs COMPLETE refresh on demand daily at 23:00 America/Mexico_City.

Repeat verification in HR: verify_scenario_4_aws.sql.
Export selection: 03_snapshot_to_export.sql. Use SQL Developer's JSON exporter.
The raw export is preserved in data/s4_hr_reporting_snapshot_raw.json.
normalise_snapshot.py extracts results[0].items as a top-level array without
changing values. The resulting data/s4_hr_reporting_snapshot.json was imported
through SQL Developer Web / Oracle Database Actions into ADMIN.S4_HR_REPORTING
in the existing OCI ATP-GBD database. Map DEPARTMENT_AVG_SALARY to NUMBER.

OCI reporting: 04_oci_reporting_checks.sql.
Reconstruction demonstration: 05_oci_rebuild_demo.sql, followed by importing the
same JSON again and rerunning the checks. This was already completed successfully.
The import history and both reconciliations are preserved in evidence/.

The refresh is scheduled; JSON export and import remain manual operations.
The OCI-generated JSON summary is preserved as raw and formatted JSON in data/.

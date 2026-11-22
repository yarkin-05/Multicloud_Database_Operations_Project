SCENARIO 2 - PERFORMANCE CRISIS
Author: Valentina Montaño Sandez

sql2.sql is the initial setup and recorded benchmark implementation.
It rewrites the department report and creates the function-based surname index.
The benchmark table and index already exist in the demonstrated HR schema.

Use verify_scenario_2.sql for a repeat demonstration in hr_con.
It reads the persisted timings, checks result equivalence and regenerates plans
for the current session. Historical pre-index Q2 evidence is in the screenshots.
All timing comparisons are cumulative totals for 1000 complete server executions.

"""Keep SQL Developer's original export and extract its rows for the OCI wizard.
Author: Valentina Montaño Sandez
Project: Multicloud Database Operations, Scenario 4
The row values, including omitted properties for SQL NULLs, are not changed.
"""
from pathlib import Path
import json

folder = Path(__file__).parent / 'data'
source = folder / 's4_hr_reporting_snapshot_raw.json'
rows = json.loads(source.read_text(encoding='utf-8'))['results'][0]['items']
target = folder / 's4_hr_reporting_snapshot.json'
target.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
assert json.loads(target.read_text(encoding='utf-8')) == rows
print(f'{len(rows)} unchanged rows saved to {target.name}')

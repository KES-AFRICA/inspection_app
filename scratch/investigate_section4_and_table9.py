import json
from collections import Counter

with open('scratch/missions/mission_m_1788898451472923_110.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("Keys in backup:", data.keys())

# Let's inspect audit installations
audit = data.get('audit_installations_electriques', {})
print("Audit keys:", audit.keys() if isinstance(audit, dict) else type(audit))

# Let's see all findings from inventory
with open('scratch/mission_inventory_raw.json', 'r', encoding='utf-8') as f:
    inv = json.load(f)

print("Inventory summary:")
instances = inv.get('instances', [])
findings = inv.get('findings', [])
print(f"Total instances: {len(instances)}, Total findings: {len(findings)}")

# Findings by tension domain
mt_findings = [f for f in findings if f.get('tensionDomain') in ['mt', 'TensionDomain.mt']]
bt_findings = [f for f in findings if f.get('tensionDomain') in ['bt', 'TensionDomain.bt']]
print(f"MT findings: {len(mt_findings)}, BT findings: {len(bt_findings)}")

# MT findings by objectType and tableName
print("\n--- MT FINDINGS BY OBJECT TYPE & TABLE ---")
mt_obj_tables = Counter((f.get('objectType'), f.get('tableName')) for f in mt_findings)
for k, v in mt_obj_tables.most_common():
    print(f"  {k}: {v}")

print("\n--- BT FINDINGS BY OBJECT TYPE & TABLE ---")
bt_obj_tables = Counter((f.get('objectType'), f.get('tableName')) for f in bt_findings)
for k, v in bt_obj_tables.most_common():
    print(f"  {k}: {v}")

# Now let's check what _isDispositionConstructiveFinding does:
def is_dispo(f):
    tbl = (f.get('tableName') or '').lower()
    if 'disposition' in tbl or 'constructive' in tbl:
        return True
    if 'exploitation' in tbl:
        return False
    if 'local' in (f.get('objectType') or '').lower():
        return True
    return False

mt_dispo = [f for f in mt_findings if is_dispo(f)]
mt_exploit = [f for f in mt_findings if not is_dispo(f)]
print(f"\nMT Dispo: {len(mt_dispo)}, MT Exploit: {len(mt_exploit)}, Sum: {len(mt_dispo) + len(mt_exploit)}")

bt_dispo = [f for f in bt_findings if is_dispo(f)]
bt_exploit = [f for f in bt_findings if not is_dispo(f)]
print(f"BT Dispo: {len(bt_dispo)}, BT Exploit: {len(bt_exploit)}, Sum: {len(bt_dispo) + len(bt_exploit)}")

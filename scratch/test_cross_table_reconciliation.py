import json

path = r'C:\Users\TeufackAndelson\.gemini\antigravity-ide\brain\408d6ca9-a8d2-4f02-9e1a-8741d90bf860\scratch\missions\mission_m_1788898451472923_110.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

audit = data.get('audit', {})

# Let's inspect all points of verification and findings in the audit
findings = []

def extract_findings_from_points(obj, obj_type, parent_local, parent_zone, tension_domain):
    points = obj.get('pointsVerification', [])
    for p in points:
        # Check if non-compliant
        conf = (p.get('conformite') or '').strip().lower()
        if conf in ['non', 'non_conforme', 'non conforme', 'false', 'nc']:
            findings.append({
                'objectType': obj_type,
                'parentLocal': parent_local,
                'parentZone': parent_zone,
                'tensionDomain': tension_domain,
                'point': p.get('pointVerification'),
                'libelle': p.get('libelle'),
                'tableName': p.get('tableName') or obj_type,
                'riskFamily': p.get('familleRisque') or p.get('riskFamily'),
                'criticality': p.get('criticite') or p.get('criticality') or 'Majeure',
            })
    # Also check observationsLibres
    obs_libres = obj.get('observationsLibres', [])
    for o in obs_libres:
        findings.append({
            'objectType': obj_type,
            'parentLocal': parent_local,
            'parentZone': parent_zone,
            'tensionDomain': tension_domain,
            'point': o.get('titre') or 'Observation libre',
            'libelle': o.get('description'),
            'tableName': 'Observation libre',
            'riskFamily': o.get('familleRisque'),
            'criticality': o.get('criticite') or 'Majeure',
        })

# 1. MT Locaux Directs
for l in audit.get('moyenneTensionLocaux', []):
    l_nom = l.get('nom')
    extract_findings_from_points(l, 'Local MT', l_nom, None, 'mt')
    for c in l.get('cellules', []):
        extract_findings_from_points(c, 'Cellule MT', l_nom, None, 'mt')
    for tr in l.get('transformateurs', []):
        extract_findings_from_points(tr, 'Transformateur MT/BT', l_nom, None, 'mt')
    for cof in l.get('coffrets', []):
        extract_findings_from_points(cof, 'Coffret MT', l_nom, None, 'mt')

# 2. MT Zones
for z in audit.get('moyenneTensionZones', []):
    z_nom = z.get('nom')
    extract_findings_from_points(z, 'Zone MT', None, z_nom, 'mt')
    for l in z.get('locaux', []):
        l_nom = l.get('nom')
        extract_findings_from_points(l, 'Local MT', l_nom, z_nom, 'mt')
        for c in l.get('cellules', []):
            extract_findings_from_points(c, 'Cellule MT', l_nom, z_nom, 'mt')
        for tr in l.get('transformateurs', []):
            extract_findings_from_points(tr, 'Transformateur MT/BT', l_nom, z_nom, 'mt')
        for cof in l.get('coffrets', []):
            extract_findings_from_points(cof, 'Coffret MT', l_nom, z_nom, 'mt')
    for cof in z.get('coffrets', []):
        extract_findings_from_points(cof, 'Coffret MT Direct', None, z_nom, 'mt')

# 3. BT Zones
for z in audit.get('basseTensionZones', []):
    z_nom = z.get('nom')
    extract_findings_from_points(z, 'Zone BT', None, z_nom, 'bt')
    for cof in z.get('coffretsDirects', []) or z.get('coffrets', []):
        c_type = cof.get('type') or 'Coffret'
        extract_findings_from_points(cof, c_type, None, z_nom, 'bt')
    for l in z.get('locaux', []):
        l_nom = l.get('nom')
        l_type = l.get('type') or 'Local BT'
        extract_findings_from_points(l, l_type, l_nom, z_nom, 'bt')
        for cof in l.get('coffrets', []):
            c_type = cof.get('type') or 'Coffret'
            extract_findings_from_points(cof, c_type, l_nom, z_nom, 'bt')

print(f"Total extracted findings: {len(findings)}")

# Now run a test on how Dart TechnicalEnrichmentEngine processes these

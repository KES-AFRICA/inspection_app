import json

json_path = r'C:\Users\TeufackAndelson\.gemini\antigravity-ide\brain\408d6ca9-a8d2-4f02-9e1a-8741d90bf860\scratch\missions\mission_m_1788898451472923_110.json'
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

audit = data.get('audit', {})
for zone in audit.get('basseTensionZones', []):
    for loc in zone.get('locaux', []):
        dc_nc = sum(1 for el in loc.get('dispositionsConstructives', []) if el.get('conforme') is False)
        ce_nc = sum(1 for el in loc.get('conditionsExploitation', []) if el.get('conforme') is False)
        print(f"{loc.get('nom')} | Type: {loc.get('type')} | DC NC: {dc_nc} | CE NC: {ce_nc} | Total NC: {dc_nc+ce_nc}")

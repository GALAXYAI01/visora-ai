import urllib.request, json

base = 'http://localhost:8000'

# 1. Seed demo audit
req = urllib.request.Request(f'{base}/demo', data=b'', method='POST')
r = urllib.request.urlopen(req)
demo = json.loads(r.read())
aid = demo['audit_id']
print(f'[1] DEMO SEEDED: {aid}')

# 2. Check /audit/{id}
r2 = urllib.request.urlopen(f'{base}/audit/{aid}')
a = json.loads(r2.read())
print(f'[2] AUDIT: DI={a["disparate_impact"]}, severity={a["bias_severity"]}')

# 3. Check /human-cost/{id}
r3 = urllib.request.urlopen(f'{base}/human-cost/{aid}')
h = json.loads(r3.read())
print(f'[3] HUMAN-COST: risk={h["legal_risk_label"]} ({h["legal_risk_score"]}), unfair/yr={h["unfair_yearly"]:,}, lawsuit=${h["lawsuit_risk_usd"]/1e6:.1f}M')
print(f'    shadow: {h["shadow_story"][:110]}...')
print(f'    regulations: {[r["law"] for r in h["regulations"]]}')

# 4. Check /scan-text
payload = json.dumps({'text': 'We need a rockstar ninja developer, young and hungry, culture fit'}).encode()
req4 = urllib.request.Request(f'{base}/scan-text', data=payload, headers={'Content-Type': 'application/json'}, method='POST')
r4 = urllib.request.urlopen(req4)
s = json.loads(r4.read())
print(f'[4] SCAN-TEXT: level={s["overall_bias_level"]}, score={s["bias_score"]}, flagged={len(s["flagged_phrases"])} phrases')
for p in s['flagged_phrases']:
    print(f'    - "{p["phrase"]}" | {p["bias_type"]} | {p["severity"]}')

# 5. Check /audits list
r5 = urllib.request.urlopen(f'{base}/audits')
audits = json.loads(r5.read())
print(f'[5] AUDITS LIST: {len(audits)} audit(s)')

# 6. Check /simulate
sim_payload = json.dumps({'age':28,'hours_per_week':45,'education':'Bachelors','race':'White','gender':'Female'}).encode()
req6 = urllib.request.Request(f'{base}/simulate', data=sim_payload, headers={'Content-Type': 'application/json'}, method='POST')
r6 = urllib.request.urlopen(req6)
sim = json.loads(r6.read())
print(f'[6] SIMULATE(Female): {sim["decision"]} ({sim["confidence"]}%), bias_detected={sim["bias_detected"]}')

print()
print('ALL BACKEND ENDPOINTS VERIFIED OK')

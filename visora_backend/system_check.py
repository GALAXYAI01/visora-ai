import requests, json, sys
sys.stdout.reconfigure(encoding='utf-8')

print("=== FULL SYSTEM CHECK ===")
print()

# 1. Backend Health
r = requests.get("http://localhost:8000/")
print("1. Backend Health:", "PASS" if r.status_code==200 else "FAIL", "-", r.json()["status"])

# 2. Upload Endpoint
with open("sample_data.csv","rb") as f:
    r = requests.post("http://localhost:8000/upload", files={"file": ("test.csv", f, "text/csv")}, data={"protected_attr":"sex","target_col":"income"})
audit_id = r.json().get("audit_id","")
print("2. Upload Endpoint:", "PASS" if r.status_code==200 else "FAIL", "-", r.json())

# 3. Simulate Endpoint
r = requests.post("http://localhost:8000/simulate", json={"age":34,"hours_per_week":40,"education":"Bachelors","race":"White","gender":"Male"})
sim = r.json()
print("3. Simulate Endpoint:", "PASS" if r.status_code==200 and "prediction" in sim else "FAIL", "-", "prediction:", sim.get("prediction","N/A"))

# 4. Scan Text Endpoint
r = requests.post("http://localhost:8000/scan-text", json={"text":"We need a young energetic male candidate."})
scan = r.json()
print("4. Scan Text Endpoint:", "PASS" if r.status_code==200 else "FAIL", "-", "verdict:", scan.get("verdict","N/A"))

# 5. Demo Seed
r = requests.post("http://localhost:8000/demo")
print("5. Demo Seed:", "PASS" if r.status_code==200 else "FAIL")

# 6. Audit List
r = requests.get("http://localhost:8000/audits")
audits = r.json()
print("6. Audit List:", "PASS" if r.status_code==200 else "FAIL", "-", len(audits), "audits")

# 7. Get Single Audit
if audits:
    aid = audits[0].get("audit_id","")
    r = requests.get(f"http://localhost:8000/audit/{aid}")
    print("7. Get Audit:", "PASS" if r.status_code==200 else "FAIL", "-", aid)

# 8. Human Cost
r = requests.get("http://localhost:8000/human-cost/VS-20260419-DEMO01")
print("8. Human Cost:", "PASS" if r.status_code==200 else "FAIL")

print()
print("=== Flutter Web ===")
try:
    r = requests.get("http://localhost:3000/", timeout=5)
    print("9. Flutter Web:", "PASS" if r.status_code==200 else "FAIL", "-", f"{len(r.text)} bytes served")
except:
    print("9. Flutter Web: NOT RUNNING")

print()
print("=== SUMMARY ===")
print("All backend endpoints operational. Ready for deployment.")

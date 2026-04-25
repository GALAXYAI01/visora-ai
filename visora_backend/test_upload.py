"""
Quick API smoke test — upload sample CSV, start audit, check /audits.
Run from visora_backend/ directory with the venv active.
"""
import requests, json, time, sys, os

BASE = "http://localhost:8000"
SAMPLE = os.path.join(os.path.dirname(__file__), "..", "sample_dataset.csv")

def check(label, resp):
    print(f"\n{'='*50}")
    print(f"  {label}  [{resp.status_code}]")
    print(f"{'='*50}")
    try:
        print(json.dumps(resp.json(), indent=2))
    except Exception:
        print(resp.text[:500])
    return resp

# 1. Health check
r = check("GET /  (health)", requests.get(f"{BASE}/"))
assert r.status_code == 200, "Backend not running!"
print("\n✅ Backend is UP")

# 2. List audits (should be empty initially)
r = check("GET /audits", requests.get(f"{BASE}/audits"))
assert r.status_code == 200

# 3. Simulate bias
r = check("POST /simulate", requests.post(f"{BASE}/simulate", json={
    "age": 34, "hours_per_week": 45,
    "education": "Bachelors", "race": "White", "gender": "Male"
}))
assert r.status_code == 200
assert "decision" in r.json(), "Simulate missing 'decision' field"
print("\n✅ /simulate endpoint working")

# 4. Upload file
if not os.path.exists(SAMPLE):
    print(f"\n⚠️  sample_dataset.csv not found at {SAMPLE}, skipping upload test")
    sys.exit(0)

with open(SAMPLE, "rb") as f:
    r = check("POST /upload", requests.post(f"{BASE}/upload", files={
        "file": ("sample_dataset.csv", f, "text/csv"),
    }, data={"protected_attr": "sex", "target_col": "income"}))

assert r.status_code == 200, f"Upload failed: {r.text}"
data = r.json()
audit_id = data["audit_id"]
print(f"\n✅ Upload successful — audit_id: {audit_id}")

# 5. Verify audit is in list
time.sleep(1)
r = check("GET /audits (after upload)", requests.get(f"{BASE}/audits"))
audits = r.json()
assert any(a["audit_id"] == audit_id for a in audits), "Audit not found in list!"
print("\n✅ Audit appears in /audits list")

print("\n" + "="*50)
print("  ALL SMOKE TESTS PASSED ✅")
print("="*50)

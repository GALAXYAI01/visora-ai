import os
import uuid
import json
import asyncio
import shutil
from pathlib import Path
from datetime import datetime

from fastapi import FastAPI, UploadFile, File, Form, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Visora Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path("uploads")
REPORT_DIR = Path("reports")
UPLOAD_DIR.mkdir(exist_ok=True)
REPORT_DIR.mkdir(exist_ok=True)

# In-memory audit store  { audit_id: state_dict }
audit_store: dict = {}


# ─── Health ──────────────────────────────────────────────────────────────────
@app.get("/")
def health():
    return {"status": "Visora backend running", "version": "1.0.0"}


# ─── Demo seed ───────────────────────────────────────────────────────────────
@app.post("/demo")
def seed_demo():
    """Seeds a realistic completed audit for UI demo without running the ML pipeline."""
    demo_id = "VS-20260419-DEMO01"
    audit_store[demo_id] = {
        "audit_id":               demo_id,
        "protected_attr":         "sex",
        "target_col":             "income",
        "status":                 "complete",
        "row_count":              48842,
        "feature_count":          14,
        "protected_values":       ["Male", "Female"],
        "disparate_impact":       0.362,
        "statistical_parity":     -0.198,
        "equalized_odds":         0.51,
        "approval_rates":         {"Male": 30.4, "Female": 11.0},
        "bias_severity":          "HIGH",
        "legal_threshold_violated": True,
        "shap_top_features": [
            {"feature": "capital-gain",   "importance": 0.1832},
            {"feature": "age",            "importance": 0.1204},
            {"feature": "hours-per-week", "importance": 0.0891},
            {"feature": "education-num",  "importance": 0.0782},
        ],
        "gemini_explanation": (
            "The model shows severe gender-based bias. Males receive income approval at a rate "
            "2.76x higher than females (30.4% vs 11.0%), violating EEOC disparate impact standards "
            "(threshold: 0.80, actual: 0.362). Capital gains and age amplify this disparity. "
            "Immediate remediation via Fairlearn reweighting is strongly recommended."
        ),
        "remediation_applied":    "Fairlearn Reweighing",
        "metrics_after":          {"disparate_impact": 0.918, "statistical_parity": -0.031, "equalized_odds": 0.89},
        "accuracy_before":        82.4,
        "accuracy_after":         80.1,
        "pdf_path":               "",
        "created_at":             datetime.now().isoformat(),
    }
    return {"audit_id": demo_id, "status": "seeded"}


# ─── Upload + trigger audit ───────────────────────────────────────────────────
@app.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    protected_attr: str = Form("sex"),
    target_col: str     = Form("income"),
):
    audit_id = f"VS-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

    file_path = UPLOAD_DIR / f"{audit_id}.csv"
    with open(file_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    audit_store[audit_id] = {
        "audit_id":       audit_id,
        "file_path":      str(file_path),
        "protected_attr": protected_attr,
        "target_col":     target_col,
        "status":         "queued",
        "completed_agents": [],
        "current_agent":  None,
        "error":          None,
        "created_at":     datetime.now().isoformat(),
    }

    return {"audit_id": audit_id, "status": "queued"}


# ─── WebSocket: real-time agent progress ──────────────────────────────────────
@app.websocket("/ws/audit/{audit_id}")
async def audit_websocket(websocket: WebSocket, audit_id: str):
    await websocket.accept()

    if audit_id not in audit_store:
        await websocket.send_json({"error": "Audit not found"})
        await websocket.close()
        return

    try:
        from pipeline import pipeline
        from models.state import AuditState

        state = audit_store[audit_id]
        state["completed_agents"] = []

        agents = ["DataProfiler", "BiasDetector", "Explainer", "Remediator", "ReportGen"]

        async def send_progress(agent: str, status: str, completed: list):
            await websocket.send_json({
                "type":          "progress",
                "current_agent": agent,
                "status":        status,
                "completed":     completed,
                "total":         len(agents),
                "pct":           int((len(completed) / len(agents)) * 100),
            })

        audit_state = AuditState(
            audit_id=audit_id,
            file_path=state["file_path"],
            protected_attr=state["protected_attr"],
            target_col=state["target_col"],
        )

        for agent_name in agents:
            await send_progress(agent_name, "running", state["completed_agents"])
            audit_state = await asyncio.get_event_loop().run_in_executor(
                None, pipeline.run_agent, agent_name, audit_state
            )
            state["completed_agents"].append(agent_name)
            state["current_agent"] = agent_name
            audit_store[audit_id].update(audit_state.dict())
            await send_progress(agent_name, "done", state["completed_agents"])

        current_state = audit_store[audit_id]
        current_state["status"] = "complete"

        await websocket.send_json({
            "type": "complete",
            "audit_id":            audit_id,
            "row_count":           current_state.get("row_count", 0),
            "feature_count":       current_state.get("feature_count", 0),
            "protected_attr":      current_state.get("protected_attr", ""),
            "target_col":          current_state.get("target_col", ""),
            "protected_values":    current_state.get("protected_values", []),
            "disparate_impact":    current_state.get("disparate_impact", 0),
            "statistical_parity":  current_state.get("statistical_parity", 0),
            "equalized_odds":      current_state.get("equalized_odds", 0),
            "approval_rates":      current_state.get("approval_rates", {}),
            "bias_severity":       current_state.get("bias_severity", "UNKNOWN"),
            "legal_threshold_violated": current_state.get("legal_threshold_violated", False),
            "shap_top_features":   current_state.get("shap_top_features", []),
            "gemini_explanation":  current_state.get("gemini_explanation", ""),
            "remediation_applied": current_state.get("remediation_applied", ""),
            "metrics_after":       current_state.get("metrics_after", {}),
            "accuracy_before":     current_state.get("accuracy_before", 0),
            "accuracy_after":      current_state.get("accuracy_after", 0),
            "pdf_path":            current_state.get("pdf_path", ""),
        })

    except WebSocketDisconnect:
        pass
    except Exception as e:
        import traceback
        try:
            await websocket.send_json({"type": "error", "message": str(e), "trace": traceback.format_exc()})
        except Exception:
            pass
    finally:
        try:
            await websocket.close()
        except Exception:
            pass


# ─── List all audits (BEFORE /audit/{id} to avoid route shadowing) ────────────
@app.get("/audits")
def list_audits():
    audits = []
    for aid, state in audit_store.items():
        audits.append({
            "audit_id":         aid,
            "status":           state.get("status", "queued"),
            "protected_attr":   state.get("protected_attr", ""),
            "target_col":       state.get("target_col", ""),
            "bias_severity":    state.get("bias_severity", "UNKNOWN"),
            "disparate_impact": state.get("disparate_impact", 0),
            "row_count":        state.get("row_count", 0),
            "created_at":       state.get("created_at", ""),
        })
    audits.sort(key=lambda x: x.get("created_at", ""), reverse=True)
    return audits


# ─── Get single audit result ───────────────────────────────────────────────────
@app.get("/audit/{audit_id}")
def get_audit(audit_id: str):
    if audit_id not in audit_store:
        return JSONResponse(status_code=404, content={"error": "Not found"})
    return audit_store[audit_id]


# ─── Download PDF ─────────────────────────────────────────────────────────────
@app.get("/report/{audit_id}")
def download_report(audit_id: str):
    if audit_id not in audit_store:
        return JSONResponse(status_code=404, content={"error": "Audit not found"})

    pdf_path = audit_store[audit_id].get("pdf_path", "")
    if not pdf_path or not Path(pdf_path).exists():
        return JSONResponse(status_code=404, content={"error": "PDF not ready yet"})

    return FileResponse(
        path=pdf_path,
        media_type="application/pdf",
        filename=f"visora_audit_{audit_id}.pdf",
        headers={"Content-Disposition": f'attachment; filename="visora_audit_{audit_id}.pdf"'},
    )


# ─── Simulate ─────────────────────────────────────────────────────────────────
@app.post("/simulate")
async def simulate_bias(body: dict):
    try:
        age    = int(body.get("age", 34))
        hours  = int(body.get("hours_per_week", 45))
        edu    = str(body.get("education", "Bachelors"))
        race   = str(body.get("race", "White"))
        gender = str(body.get("gender", "Male"))

        edu_map = {"Bachelors": 0.5, "Masters": 0.7, "PhD": 0.8,
                   "HS-grad": 0.2, "Some-college": 0.35, "Assoc": 0.38}

        base_score = (
            (age - 18) / 50 * 0.3 +
            (hours - 10) / 70 * 0.25 +
            edu_map.get(edu, 0.4) * 0.3
        )

        gender_penalty = 0.22 if gender.lower() == "female" else 0.0
        score = max(0.0, min(1.0, base_score - gender_penalty + 0.1))

        hired      = score >= 0.5
        confidence = round((score if hired else 1 - score) * 100, 1)

        flipped_gender  = "Female" if gender.lower() == "male" else "Male"
        flipped_penalty = 0.22 if flipped_gender == "Female" else 0.0
        flipped_score   = max(0.0, min(1.0, score + gender_penalty - flipped_penalty))
        flipped_hired   = flipped_score >= 0.5

        outcome_changed = hired != flipped_hired

        return {
            "decision":         "HIRED" if hired else "REJECTED",
            "confidence":       confidence,
            "gender":           gender,
            "flipped_gender":   flipped_gender,
            "flipped_decision": "HIRED" if flipped_hired else "REJECTED",
            "outcome_changed":  outcome_changed,
            "bias_detected":    outcome_changed,
            "message": (
                "Flipping gender changes the outcome — bias detected."
                if outcome_changed else
                "Gender did not change the outcome for this profile."
            ),
        }
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


# ─── Human Cost / Legal Impact ────────────────────────────────────────────────
@app.get("/human-cost/{audit_id}")
def get_human_cost(audit_id: str):
    if audit_id not in audit_store:
        return JSONResponse(status_code=404, content={"error": "Audit not found"})

    state = audit_store[audit_id]
    if state.get("status") != "complete":
        return JSONResponse(status_code=400, content={"error": "Audit not complete yet"})

    di              = float(state.get("disparate_impact", 0.8))
    row_count       = int(state.get("row_count", 10000))
    approval_rates  = state.get("approval_rates", {})
    protected_attr  = state.get("protected_attr", "sex")

    # Legal risk score (0-100): lower DI = higher risk
    legal_risk_score = max(0, min(100, int((1 - di) * 100)))
    legal_risk_label = (
        "CRITICAL" if legal_risk_score >= 80 else
        "HIGH"     if legal_risk_score >= 60 else
        "MEDIUM"   if legal_risk_score >= 40 else "LOW"
    )

    # Unfair decisions per year
    vals            = list(approval_rates.values())
    gap             = abs(vals[0] - vals[1]) / 100 if len(vals) >= 2 else 0.1
    unfair_yearly   = int(row_count * gap * 1.2)

    # Lawsuit exposure
    lawsuit_risk_usd = int(unfair_yearly * 125_000)

    # Shadow profile story
    groups = list(approval_rates.keys())
    rates  = list(approval_rates.values())
    higher, lower = (groups[0], groups[1]) if rates[0] > rates[1] else (groups[1], groups[0])
    higher_rate   = max(rates)
    lower_rate    = min(rates)
    shadow_story  = (
        f"Two candidates \u2014 {higher} and {lower} \u2014 submitted identical r\u00e9sum\u00e9s. "
        f"Same education. Same experience. Same test scores. "
        f"The {higher} candidate was approved at {higher_rate:.0f}%. "
        f"The {lower} candidate: only {lower_rate:.0f}%. "
        f"This {lower} applicant now has a \u2018shadow profile\u2019 \u2014 invisible debt, reduced credit ceiling, "
        f"compounding disadvantage \u2014 through no fault of their own."
    )

    # Regulatory map
    regulations = []
    if protected_attr in ["sex", "gender", "race", "age"]:
        regulations.append({"law": "EEOC \u2014 Uniform Guidelines", "region": "USA", "violated": di < 0.8})
    regulations.append({"law": "EU AI Act \u2014 Article 10", "region": "EU", "violated": di < 0.85})
    regulations.append({"law": "NYC Local Law 144", "region": "New York", "violated": di < 0.8})
    if protected_attr in ["sex", "gender", "race"]:
        regulations.append({"law": "California FEHA", "region": "California", "violated": di < 0.8})

    return {
        "audit_id":         audit_id,
        "legal_risk_score": legal_risk_score,
        "legal_risk_label": legal_risk_label,
        "unfair_yearly":    unfair_yearly,
        "lawsuit_risk_usd": lawsuit_risk_usd,
        "shadow_story":     shadow_story,
        "regulations":      regulations,
        "disparate_impact": di,
        "approval_rates":   approval_rates,
    }


# ─── Text Bias Scanner (Gemini + heuristic fallback) ─────────────────────────
@app.post("/scan-text")
def scan_text(body: dict):
    text = body.get("text", "").strip()
    if not text:
        return JSONResponse(status_code=400, content={"error": "No text provided"})
    if len(text) > 5000:
        return JSONResponse(status_code=400, content={"error": "Text too long (max 5000 chars)"})

    # Heuristic phrase library
    BIAS_PHRASES = [
        {"phrase": "rockstar",      "bias_type": "Gender/Culture Bias",   "severity": "HIGH",
         "suggestion": "Use 'skilled professional' or 'expert'"},
        {"phrase": "ninja",         "bias_type": "Culture Bias",          "severity": "HIGH",
         "suggestion": "Use 'specialist' or 'expert'"},
        {"phrase": "guru",          "bias_type": "Culture Bias",          "severity": "MEDIUM",
         "suggestion": "Use 'experienced professional'"},
        {"phrase": "young",         "bias_type": "Age Discrimination",    "severity": "HIGH",
         "suggestion": "Remove age references entirely"},
        {"phrase": "digital native","bias_type": "Age Discrimination",    "severity": "HIGH",
         "suggestion": "Describe the actual skill needed (e.g., 'proficient in social media')"},
        {"phrase": "recent graduate","bias_type": "Age Discrimination",   "severity": "HIGH",
         "suggestion": "Specify required skills, not graduation recency"},
        {"phrase": "hungry",        "bias_type": "Socioeconomic Bias",    "severity": "MEDIUM",
         "suggestion": "Use 'motivated' or 'driven'"},
        {"phrase": "aggressive",    "bias_type": "Gender Bias",           "severity": "HIGH",
         "suggestion": "Use 'results-oriented' or 'proactive'"},
        {"phrase": "culture fit",   "bias_type": "Cultural/Racial Bias",  "severity": "HIGH",
         "suggestion": "Use 'values alignment' with specific criteria"},
        {"phrase": "native speaker","bias_type": "National Origin Bias",  "severity": "HIGH",
         "suggestion": "State required fluency level (e.g., 'C2 English proficiency')"},
        {"phrase": "strong work ethic", "bias_type": "Racial/Class Bias", "severity": "MEDIUM",
         "suggestion": "Describe specific behaviors or outcomes"},
        {"phrase": "self-starter",  "bias_type": "Disability Bias",       "severity": "LOW",
         "suggestion": "Describe specific expected behaviors"},
        {"phrase": "manpower",      "bias_type": "Gender Bias",           "severity": "MEDIUM",
         "suggestion": "Use 'workforce' or 'personnel'"},
        {"phrase": "chairman",      "bias_type": "Gender Bias",           "severity": "MEDIUM",
         "suggestion": "Use 'chairperson' or 'chair'"},
        {"phrase": "top university","bias_type": "Socioeconomic/Class Bias","severity": "HIGH",
         "suggestion": "Remove ranking requirements; focus on skills"},
    ]

    text_lower = text.lower()
    flagged = []
    for entry in BIAS_PHRASES:
        if entry["phrase"].lower() in text_lower:
            # find the actual phrase in text (with original casing)
            idx = text_lower.find(entry["phrase"].lower())
            actual = text[idx: idx + len(entry["phrase"])]
            flagged.append({
                "phrase":     actual,
                "bias_type":  entry["bias_type"],
                "severity":   entry["severity"],
                "suggestion": entry["suggestion"],
            })

    # Try Gemini for richer analysis
    try:
        import google.generativeai as genai
        api_key = os.getenv("GEMINI_API_KEY", "")
        if api_key:
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel("gemini-1.5-flash")
            prompt = (
                "You are a bias detection expert. Analyze this job description for biased, "
                "exclusionary, or discriminatory language. Return ONLY valid JSON with this schema:\n"
                '{"flagged_phrases":[{"phrase":"...","bias_type":"...","severity":"HIGH|MEDIUM|LOW","suggestion":"..."}],'
                '"overall_bias_level":"HIGH|MEDIUM|LOW|NONE","bias_score":0-100,"summary":"..."}\n\n'
                f"Text to analyze:\n{text}"
            )
            resp = model.generate_content(prompt)
            raw  = resp.text.strip()
            # Strip markdown code fences if present
            if raw.startswith("```"):
                raw = raw.split("```")[1]
                if raw.startswith("json"):
                    raw = raw[4:]
            gemini_result = json.loads(raw.strip())
            # Keep heuristic matches + Gemini matches (deduplicated)
            existing_phrases = {f["phrase"].lower() for f in flagged}
            for gf in gemini_result.get("flagged_phrases", []):
                if gf["phrase"].lower() not in existing_phrases:
                    flagged.append(gf)
                    existing_phrases.add(gf["phrase"].lower())
            return {
                "flagged_phrases":    flagged,
                "overall_bias_level": gemini_result.get("overall_bias_level", "HIGH" if flagged else "NONE"),
                "bias_score":         gemini_result.get("bias_score", min(100, len(flagged) * 18)),
                "summary":            gemini_result.get("summary", ""),
                "source":             "gemini",
            }
    except Exception:
        pass  # fall through to heuristic result

    severity_weights = {"HIGH": 20, "MEDIUM": 12, "LOW": 6}
    bias_score = min(100, sum(severity_weights.get(f["severity"], 10) for f in flagged))
    overall    = "NONE" if not flagged else (
        "HIGH"   if bias_score >= 40 else
        "MEDIUM" if bias_score >= 20 else "LOW"
    )
    summary = (
        f"Found {len(flagged)} biased phrase(s). "
        + ("Immediate revision recommended." if overall == "HIGH" else
           "Some language may exclude qualified candidates." if overall == "MEDIUM" else
           "Minor improvements possible.")
    ) if flagged else "No significant bias detected. The text appears inclusive."

    return {
        "flagged_phrases":    flagged,
        "overall_bias_level": overall,
        "bias_score":         bias_score,
        "summary":            summary,
        "source":             "heuristic",
    }


# ─── Entry point ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

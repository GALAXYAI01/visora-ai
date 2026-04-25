"""
Standalone Visora Backend — Demo / Test Mode

Runs the full FastAPI server with mock agents that don't rely on
scipy, sklearn, shap, or aif360. This lets us test the entire
Flutter ↔ backend integration (upload, WebSocket progress, results,
simulate, PDF download) without heavy ML compilation dependencies.

Usage:  python run_demo.py
"""

import os
import uuid
import json
import asyncio
import shutil
import random
import time
from pathlib import Path
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, UploadFile, File, Form, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Visora Backend (Demo)", version="1.0.0-demo")

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
    return {"status": "Visora backend running", "version": "1.0.0-demo"}


# ─── Upload + trigger audit ───────────────────────────────────────────────────
@app.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    protected_attr: str = Form("sex"),
    target_col: str    = Form("income"),
):
    audit_id = f"VS-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

    # Save file
    file_path = UPLOAD_DIR / f"{audit_id}.csv"
    with open(file_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    # Count rows (basic profiling)
    try:
        with open(file_path, "r") as f:
            row_count = sum(1 for _ in f) - 1  # minus header
    except:
        row_count = 0

    # Store initial state
    audit_store[audit_id] = {
        "audit_id": audit_id,
        "file_path": str(file_path),
        "protected_attr": protected_attr,
        "target_col": target_col,
        "status": "queued",
        "completed_agents": [],
        "current_agent": None,
        "error": None,
        "created_at": datetime.now().isoformat(),
        "row_count": row_count,
    }

    return {"audit_id": audit_id, "status": "queued"}


# ─── Mock Agent Functions ─────────────────────────────────────────────────────
def _mock_data_profiler(state: dict) -> dict:
    """Simulates data profiling — reads file and extracts basic info."""
    try:
        with open(state["file_path"], "r") as f:
            header = f.readline().strip().split(",")
            row_count = sum(1 for _ in f)
    except:
        header = ["age", "workclass", "education", "sex", "income"]
        row_count = 32561

    return {
        **state,
        "row_count": row_count,
        "feature_count": len(header),
        "columns": header,
        "protected_values": ["Male", "Female"],
        "class_distribution": {"<=50K": int(row_count * 0.75), ">50K": int(row_count * 0.25)},
        "current_agent": "DataProfiler",
        "completed_agents": state.get("completed_agents", []) + ["DataProfiler"],
        "error": None,
    }


def _mock_bias_detector(state: dict) -> dict:
    """Simulates bias detection with realistic demo results."""
    return {
        **state,
        "disparate_impact": 0.55,
        "statistical_parity": -0.33,
        "equalized_odds": 0.41,
        "approval_rates": {"Male": 74.2, "Female": 41.0},
        "bias_severity": "HIGH",
        "legal_threshold_violated": True,
        "shap_top_features": [
            {"feature": "relationship", "importance": 0.1842},
            {"feature": "marital-status", "importance": 0.1531},
            {"feature": "education-num", "importance": 0.1207},
            {"feature": "age", "importance": 0.0983},
            {"feature": "hours-per-week", "importance": 0.0856},
        ],
        "accuracy_before": 85.4,
        "current_agent": "BiasDetector",
        "completed_agents": state.get("completed_agents", []) + ["BiasDetector"],
        "error": None,
    }


def _mock_explainer(state: dict) -> dict:
    """Simulates Gemini AI explanation."""
    return {
        **state,
        "gemini_explanation": (
            "Analysis reveals that 'marital-status' and 'relationship' features serve as "
            "strong proxies for gender, creating indirect discrimination in the model's "
            "decision boundary. The model exhibits a 33.2% gap in approval rates between "
            "male and female applicants. Removing 'relationship' and re-weighting "
            "'marital-status' coefficients by -12% could stabilize the Disparate Impact "
            "score above the 0.80 legal threshold while maintaining 83% accuracy."
        ),
        "current_agent": "Explainer",
        "completed_agents": state.get("completed_agents", []) + ["Explainer"],
        "error": None,
    }


def _mock_remediator(state: dict) -> dict:
    """Simulates bias remediation results."""
    return {
        **state,
        "remediation_applied": "Reweighing + Feature masking (relationship)",
        "metrics_after": {
            "disparate_impact": 0.83,
            "statistical_parity": -0.08,
            "equalized_odds": 0.79,
        },
        "accuracy_after": 83.3,
        "current_agent": "Remediator",
        "completed_agents": state.get("completed_agents", []) + ["Remediator"],
        "error": None,
    }


def _mock_report_gen(state: dict) -> dict:
    """Simulates PDF report generation."""
    try:
        from reportlab.lib.pagesizes import letter
        from reportlab.pdfgen import canvas

        audit_id = state.get("audit_id", "DEMO")
        pdf_path = str(REPORT_DIR / f"visora_audit_{audit_id}.pdf")

        c = canvas.Canvas(pdf_path, pagesize=letter)
        c.setFont("Helvetica-Bold", 20)
        c.drawString(72, 730, "VISORA AI — Bias Audit Report")
        c.setFont("Helvetica", 12)
        c.drawString(72, 700, f"Audit ID: {audit_id}")
        c.drawString(72, 680, f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
        c.drawString(72, 650, f"Protected Attribute: {state.get('protected_attr', 'N/A')}")
        c.drawString(72, 630, f"Rows Analyzed: {state.get('row_count', 'N/A')}")
        c.drawString(72, 600, f"Bias Severity: {state.get('bias_severity', 'N/A')}")
        c.drawString(72, 580, f"Disparate Impact: {state.get('disparate_impact', 'N/A')}")
        c.drawString(72, 560, f"Remediation: {state.get('remediation_applied', 'N/A')}")
        c.drawString(72, 530, "Full compliance documentation — Generated by Visora AI")
        c.save()
    except Exception as e:
        pdf_path = ""
        print(f"[ReportGen] PDF generation skipped: {e}")

    return {
        **state,
        "pdf_path": pdf_path,
        "current_agent": "ReportGen",
        "completed_agents": state.get("completed_agents", []) + ["ReportGen"],
        "error": None,
    }


AGENTS = [
    ("DataProfiler", _mock_data_profiler),
    ("BiasDetector", _mock_bias_detector),
    ("Explainer", _mock_explainer),
    ("Remediator", _mock_remediator),
    ("ReportGen", _mock_report_gen),
]


# ─── WebSocket: real-time agent progress ──────────────────────────────────────
@app.websocket("/ws/audit/{audit_id}")
async def audit_websocket(websocket: WebSocket, audit_id: str):
    await websocket.accept()

    if audit_id not in audit_store:
        await websocket.send_json({"error": "Audit not found"})
        await websocket.close()
        return

    try:
        state = audit_store[audit_id]
        state["completed_agents"] = []

        for agent_name, agent_fn in AGENTS:
            # Send "running" status
            await websocket.send_json({
                "type": "progress",
                "current_agent": agent_name,
                "status": "running",
                "completed": state.get("completed_agents", []),
                "total": len(AGENTS),
                "pct": int((len(state.get("completed_agents", [])) / len(AGENTS)) * 100),
            })
            await asyncio.sleep(0.1)

            # Simulate agent work (realistic delay)
            await asyncio.sleep(random.uniform(0.8, 2.0))

            # Run agent
            state = agent_fn(state)

            if state.get("error"):
                await websocket.send_json({
                    "type": "error",
                    "agent": agent_name,
                    "message": state["error"],
                })
                state["error"] = None

            # Send "complete" status
            await websocket.send_json({
                "type": "progress",
                "current_agent": agent_name,
                "status": "complete",
                "completed": state.get("completed_agents", []),
                "total": len(AGENTS),
                "pct": int((len(state.get("completed_agents", [])) / len(AGENTS)) * 100),
            })
            await asyncio.sleep(0.05)

        # Save final state
        audit_store[audit_id] = state
        audit_store[audit_id]["status"] = "complete"

        # Send final result
        await websocket.send_json({
            "type": "complete",
            "audit_id": audit_id,
            "result": {
                "row_count":           state.get("row_count", 0),
                "feature_count":       state.get("feature_count", 0),
                "protected_attr":      state.get("protected_attr", ""),
                "target_col":          state.get("target_col", ""),
                "protected_values":    state.get("protected_values", []),
                "disparate_impact":    state.get("disparate_impact", 0),
                "statistical_parity":  state.get("statistical_parity", 0),
                "equalized_odds":      state.get("equalized_odds", 0),
                "approval_rates":      state.get("approval_rates", {}),
                "bias_severity":       state.get("bias_severity", "UNKNOWN"),
                "legal_threshold_violated": state.get("legal_threshold_violated", False),
                "shap_top_features":   state.get("shap_top_features", []),
                "gemini_explanation":  state.get("gemini_explanation", ""),
                "remediation_applied": state.get("remediation_applied", ""),
                "metrics_after":       state.get("metrics_after", {}),
                "accuracy_before":     state.get("accuracy_before", 0),
                "accuracy_after":      state.get("accuracy_after", 0),
                "pdf_path":            state.get("pdf_path", ""),
            }
        })

    except WebSocketDisconnect:
        pass
    except Exception as e:
        import traceback
        try:
            await websocket.send_json({"type": "error", "message": str(e), "trace": traceback.format_exc()})
        except:
            pass
    finally:
        try:
            await websocket.close()
        except:
            pass


# ─── List all audits ──────────────────────────────────────────────────────────
@app.get("/audits")
def list_audits():
    audits = []
    for aid, state in audit_store.items():
        audits.append({
            "audit_id": aid,
            "status": state.get("status", "queued"),
            "protected_attr": state.get("protected_attr", ""),
            "target_col": state.get("target_col", ""),
            "bias_severity": state.get("bias_severity", "UNKNOWN"),
            "disparate_impact": state.get("disparate_impact", 0),
            "row_count": state.get("row_count", 0),
            "created_at": state.get("created_at", ""),
        })
    audits.sort(key=lambda x: x.get("created_at", ""), reverse=True)
    return audits


# ─── Get audit result ─────────────────────────────────────────────────────────
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


# ─── Simulate endpoint ────────────────────────────────────────────────────────
@app.post("/simulate")
async def simulate_bias(body: dict):
    """
    Takes a profile dict, runs it through a simulated model,
    returns prediction + what happens when you flip the protected attr.
    """
    try:
        age   = body.get("age", 34)
        hours = body.get("hours_per_week", 45)
        edu   = body.get("education", "Bachelors")
        race  = body.get("race", "White")
        gender = body.get("gender", "Male")

        # Simulate: base score
        base_score = (
            (age - 18) / 50 * 0.3 +
            (hours - 10) / 70 * 0.25 +
            {"Bachelors": 0.5, "Masters": 0.7, "PhD": 0.8, "HS-grad": 0.2}.get(edu, 0.4) * 0.3
        )

        # Gender bias (intentional for demo — mirrors real adult income dataset bias)
        gender_penalty = 0.0 if gender in ["Male", "male"] else 0.22
        base_score = max(0.0, min(1.0, base_score - gender_penalty + 0.1))

        hired = base_score >= 0.5
        confidence = round(base_score * 100 if hired else (1 - base_score) * 100, 1)

        # Flip gender
        flipped_gender = "Female" if gender in ["Male", "male"] else "Male"
        flipped_penalty = 0.0 if flipped_gender == "Male" else 0.22
        flipped_score = max(0.0, min(1.0, base_score + gender_penalty - flipped_penalty))
        flipped_hired = flipped_score >= 0.5

        outcome_changed = hired != flipped_hired

        return {
            "decision":         "HIRED" if hired else "REJECTED",
            "confidence":       confidence,
            "gender":           gender,
            "flipped_gender":   flipped_gender,
            "flipped_decision": "HIRED" if flipped_hired else "REJECTED",
            "outcome_changed":  outcome_changed,
            "bias_detected":    outcome_changed,
            "message":          "Flipping gender changes the outcome — bias detected." if outcome_changed else "Gender did not change the outcome for this profile.",
        }

    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


# ─── Run ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    print("\n>>> Starting Visora Backend (Demo Mode)...")
    print("   Health: http://localhost:8000/")
    print("   Docs:   http://localhost:8000/docs\n")
    uvicorn.run("run_demo:app", host="0.0.0.0", port=8000, reload=True)

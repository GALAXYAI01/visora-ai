import os
from google import genai
from google.genai import types


def human_cost_agent(state: dict) -> dict:
    di        = state.get("disparate_impact", 1.0)
    severity  = state.get("bias_severity", "LOW")
    rates     = state.get("approval_rates", {})
    protected = state.get("protected_attr", "group")
    target    = state.get("target_col", "outcome")
    row_count = state.get("row_count", 1000)

    vals     = list(rates.values())
    max_rate = max(vals) if vals else 50.0
    min_rate = min(vals) if vals else 30.0
    gap_pct  = round(max_rate - min_rate, 1)

    monthly_decisions     = max(row_count, 500)
    disadvantaged_fraction = 0.45
    expected_rate          = max_rate / 100
    actual_rate            = min_rate / 100
    unfair_monthly = int(monthly_decisions * disadvantaged_fraction * (expected_rate - actual_rate))
    unfair_yearly  = unfair_monthly * 12

    lawsuit_risk_usd = unfair_yearly * 125_000
    india_penalty_cr = 250
    eu_penalty_eur   = 30_000_000

    disadvantaged = min(rates, key=rates.get) if rates else "Female"
    advantaged    = max(rates, key=rates.get) if rates else "Male"

    names_map = {
        "sex":    ("Priya Sharma",  "Peter Sharma"),
        "gender": ("Priya Sharma",  "Peter Sharma"),
        "race":   ("Marcus Johnson","Marcus Thompson"),
        "age":    ("Sarah (52yrs)", "Sarah (28yrs)"),
    }
    disadv_name, adv_name = names_map.get(protected.lower(), ("Candidate A", "Candidate B"))

    if di < 0.6:
        legal_risk_score, legal_risk_label = 95, "CRITICAL"
    elif di < 0.8:
        legal_risk_score, legal_risk_label = 72, "HIGH"
    elif di < 0.9:
        legal_risk_score, legal_risk_label = 40, "MEDIUM"
    else:
        legal_risk_score, legal_risk_label = 12, "LOW"

    regulations = []
    if severity in ("HIGH", "MEDIUM"):
        regulations = [
            {
                "jurisdiction": "India",
                "law": "DPDP Act 2023",
                "section": "Section 4 — Lawful processing of personal data",
                "status": "VIOLATED" if di < 0.8 else "AT RISK",
                "penalty": f"Up to ₹{india_penalty_cr} crore",
                "action": "Immediate bias remediation required before deployment"
            },
            {
                "jurisdiction": "European Union",
                "law": "EU AI Act 2024",
                "section": "Article 10 — Data governance & Article 13 — Transparency",
                "status": "VIOLATED" if di < 0.8 else "AT RISK",
                "penalty": "Up to €30M or 6% of global revenue",
                "action": "Mandatory human oversight and bias documentation required"
            },
            {
                "jurisdiction": "United States",
                "law": "Title VII Civil Rights Act + EEOC Guidelines",
                "section": "4/5ths Rule — Disparate Impact doctrine",
                "status": "VIOLATED" if di < 0.8 else "PASSING",
                "penalty": "Class action + compensatory damages (no cap)",
                "action": "Disparate impact score must reach 0.80 minimum"
            },
        ]
    else:
        regulations = [{
            "jurisdiction": "Global", "law": "All major AI fairness regulations",
            "section": "—", "status": "COMPLIANT",
            "penalty": "No immediate risk", "action": "Continue monitoring; re-audit quarterly"
        }]

    # Base result — always returned even if Gemini fails
    result = {
        "unfair_monthly":      unfair_monthly,
        "unfair_yearly":       unfair_yearly,
        "gap_pct":             gap_pct,
        "lawsuit_risk_usd":    lawsuit_risk_usd,
        "india_penalty_cr":    india_penalty_cr,
        "eu_penalty_eur":      eu_penalty_eur,
        "legal_risk_score":    legal_risk_score,
        "legal_risk_label":    legal_risk_label,
        "regulations":         regulations,
        "shadow_story":        f"{disadv_name} submitted the same qualifications as {adv_name}. The model hired {adv_name} with 87% confidence and rejected {disadv_name} with 62% confidence. Nothing changed except the name.",
        "disadvantaged_group": disadvantaged,
        "advantaged_group":    advantaged,
        "disadv_name":         disadv_name,
        "adv_name":            adv_name,
        "error":               None,
    }

    # Try to get a better Gemini story — failure is safe
    try:
        client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
        shadow_prompt = f"""Write a 3-sentence human-impact story about AI bias.

Context: A {target} prediction model. Protected attribute: {protected}.
{disadvantaged} group approval rate: {min_rate:.1f}%. {advantaged} group: {max_rate:.1f}%.
Unfair decisions per year: {unfair_yearly:,}.

Format:
Sentence 1: Describe {disadv_name} — qualifications, experience, what she applied for.
Sentence 2: Model rejected her. Same profile as {adv_name} was approved.  
Sentence 3: Real-world consequence for her life.

Be specific, emotional, human. Max 80 words. No bullet points."""

        resp = client.models.generate_content(
            model="gemini-2.5-flash-preview-04-17",
            contents=shadow_prompt,
            config=types.GenerateContentConfig(temperature=0.7, max_output_tokens=150)
        )
        result["shadow_story"] = resp.text.strip()
    except Exception:
        pass  # fallback story already set above

    return result

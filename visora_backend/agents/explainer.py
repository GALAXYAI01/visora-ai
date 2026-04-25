import os
from google import genai
from google.genai import types
from models.state import AuditState


def explainer_agent(state: AuditState) -> AuditState:
    """
    Sends real bias metrics to Gemini 2.5 Flash and gets a plain-English
    explanation of why the bias exists and who is affected.
    """
    try:
        client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

        shap_str = ", ".join(
            [f"{f['feature']} ({f['importance']})" for f in state.get("shap_top_features", [])]
        )

        approval_str = ", ".join(
            [f"{g}: {v}%" for g, v in state.get("approval_rates", {}).items()]
        )

        prompt = f"""You are an AI fairness expert analyzing a machine learning model for bias.

Dataset: {state.get('row_count', 0):,} rows
Protected attribute analyzed: {state['protected_attr']}
Target variable: {state['target_col']}

Fairness metrics computed:
- Disparate Impact Score: {state.get('disparate_impact', 0):.3f} (legal minimum: 0.80)
- Statistical Parity Difference: {state.get('statistical_parity', 0):.3f}
- Equalized Odds Ratio: {state.get('equalized_odds', 0):.3f}
- Bias Severity: {state.get('bias_severity', 'UNKNOWN')}

Approval rates by {state['protected_attr']} group:
{approval_str}

Top SHAP features driving decisions (by importance):
{shap_str}

Write a 2-3 sentence plain-English explanation of:
1. What bias was found and how severe it is
2. Which feature(s) are likely acting as proxies causing this bias
3. What real-world harm this could cause

Write in first person as if explaining to a business executive who is not technical.
Be specific with the numbers. Do not use bullet points. Maximum 80 words."""

        response = client.models.generate_content(
            model="gemini-2.5-flash-preview-04-17",
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=0.4,
                max_output_tokens=200,
            )
        )

        explanation = response.text.strip()

        return {
            **state,
            "gemini_explanation": explanation,
            "current_agent": "Explainer",
            "completed_agents": state.get("completed_agents", []) + ["Explainer"],
            "error": None,
        }

    except Exception as e:
        # Fallback explanation if Gemini fails
        fallback = (
            f"The model shows a disparate impact score of {state.get('disparate_impact', 0):.2f}, "
            f"which is {'below' if state.get('legal_threshold_violated') else 'above'} the legal threshold of 0.80. "
            f"Groups based on {state['protected_attr']} receive significantly different outcomes, "
            f"with approval rates ranging from {min(state.get('approval_rates', {0:0}).values(), default=0):.1f}% "
            f"to {max(state.get('approval_rates', {0:100}).values(), default=100):.1f}%."
        )
        return {
            **state,
            "gemini_explanation": fallback,
            "current_agent": "Explainer",
            "completed_agents": state.get("completed_agents", []) + ["Explainer"],
            "error": None,
        }

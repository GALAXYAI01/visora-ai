import os
import json
from google import genai
from google.genai import types


def text_bias_scanner(text: str) -> dict:
    """
    Scans any text (job description, policy, rejection letter) for
    biased language using Gemini. Returns flagged phrases with explanations.
    """
    try:
        client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

        prompt = f"""You are an AI fairness expert specializing in detecting biased language in professional documents.

Analyze the following text for language that is statistically shown to:
- Deter women or non-binary candidates (e.g. "rockstar", "aggressive", "dominant", "ninja", "competitive")
- Discriminate by race or ethnicity (e.g. requirements that correlate with race)
- Disadvantage older workers (e.g. "digital native", "young and hungry", "recent graduate")
- Create class-based barriers (e.g. unpaid internship requirements, ivy league preferences)
- Use ableist language
- Contain any other documented bias patterns

TEXT TO ANALYZE:
{text}

Respond ONLY with a valid JSON object in this exact format, no markdown, no backticks:
{{
  "overall_bias_level": "HIGH|MEDIUM|LOW|NONE",
  "bias_score": <integer 0-100>,
  "flagged_phrases": [
    {{
      "phrase": "<exact phrase from text>",
      "bias_type": "<type of bias>",
      "affects": "<who is disadvantaged>",
      "severity": "HIGH|MEDIUM|LOW",
      "suggestion": "<better alternative phrasing>"
    }}
  ],
  "summary": "<2-sentence plain English summary of findings>",
  "rewrite_suggestion": "<one key sentence that could replace the most biased part>"
}}

If no bias is found, return flagged_phrases as empty array and overall_bias_level as NONE."""

        response = client.models.generate_content(
            model="gemini-2.5-flash-preview-04-17",
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=0.2,
                max_output_tokens=800,
            )
        )

        raw = response.text.strip()
        # Strip markdown fences if present
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        raw = raw.strip()

        result = json.loads(raw)
        result["error"] = None
        return result

    except json.JSONDecodeError:
        # Fallback: extract what we can
        return {
            "overall_bias_level": "UNKNOWN",
            "bias_score": 0,
            "flagged_phrases": [],
            "summary": "Could not parse Gemini response. Please try again.",
            "rewrite_suggestion": "",
            "error": "JSON parse error"
        }
    except Exception as e:
        return {
            "overall_bias_level": "ERROR",
            "bias_score": 0,
            "flagged_phrases": [],
            "summary": str(e),
            "rewrite_suggestion": "",
            "error": str(e)
        }

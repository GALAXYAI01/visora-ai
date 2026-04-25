from typing import TypedDict, Optional, Any
import pandas as pd

class AuditState(TypedDict):
    # Input
    file_path: str
    protected_attr: str
    target_col: str
    audit_id: str

    # DataProfiler output
    row_count: int
    feature_count: int
    columns: list[str]
    protected_values: list[str]
    class_distribution: dict

    # BiasDetector output
    disparate_impact: float
    statistical_parity: float
    equalized_odds: float
    approval_rates: dict          # {group_val: rate}
    bias_severity: str            # HIGH / MEDIUM / LOW
    legal_threshold_violated: bool
    shap_top_features: list[dict] # [{feature, importance}]

    # Explainer output
    gemini_explanation: str

    # Remediator output
    remediation_applied: str
    metrics_after: dict           # same keys as above
    accuracy_before: float
    accuracy_after: float

    # ReportGen output
    pdf_path: str

    # Progress tracking
    current_agent: str
    completed_agents: list[str]
    error: Optional[str]

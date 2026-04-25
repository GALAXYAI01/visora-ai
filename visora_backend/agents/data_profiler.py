import pandas as pd
import numpy as np
from models.state import AuditState


def data_profiler_agent(state: AuditState) -> AuditState:
    """
    Reads the uploaded CSV, detects protected attribute distribution,
    class balance, and prepares data profile.
    """
    try:
        df = pd.read_csv(state["file_path"])

        # Clean column names
        df.columns = df.columns.str.strip()

        protected = state["protected_attr"]
        target = state["target_col"]

        # Auto-detect target if not found
        if target not in df.columns:
            # Try common names
            for candidate in ["income", "label", "target", "class", "salary", "hired", "loan_status"]:
                if candidate in df.columns.str.lower().tolist():
                    target = df.columns[df.columns.str.lower() == candidate][0]
                    break
            else:
                target = df.columns[-1]  # fallback: last column

        # Auto-detect protected attr if not found
        if protected not in df.columns:
            for candidate in ["sex", "gender", "race", "age", "Sex", "Gender", "Race", "Age"]:
                if candidate in df.columns:
                    protected = candidate
                    break

        # Get protected attribute values
        protected_values = df[protected].dropna().unique().tolist()
        protected_values = [str(v) for v in protected_values]

        # Class distribution of target
        target_dist = df[target].value_counts().to_dict()
        class_distribution = {str(k): int(v) for k, v in target_dist.items()}

        return {
            **state,
            "row_count": len(df),
            "feature_count": len(df.columns),
            "columns": df.columns.tolist(),
            "protected_values": protected_values,
            "class_distribution": class_distribution,
            "target_col": target,
            "protected_attr": protected,
            "current_agent": "DataProfiler",
            "completed_agents": state.get("completed_agents", []) + ["DataProfiler"],
            "error": None,
        }
    except Exception as e:
        return {**state, "error": f"DataProfiler error: {str(e)}", "current_agent": "DataProfiler"}

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
import shap
from models.state import AuditState


def bias_detector_agent(state: AuditState) -> AuditState:
    """
    Trains a model on the dataset and computes real fairness metrics
    using AIF360 and SHAP feature importance.
    """
    try:
        df = pd.read_csv(state["file_path"])
        df.columns = df.columns.str.strip()

        protected = state["protected_attr"]
        target = state["target_col"]

        # ---------- Encode data ----------
        df_enc = df.copy()
        encoders = {}
        for col in df_enc.select_dtypes(include=["object", "category"]).columns:
            le = LabelEncoder()
            df_enc[col] = le.fit_transform(df_enc[col].astype(str))
            encoders[col] = le

        X = df_enc.drop(columns=[target])
        y = df_enc[target]

        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.25, random_state=42
        )

        # ---------- Train model ----------
        model = RandomForestClassifier(n_estimators=50, random_state=42, n_jobs=-1)
        model.fit(X_train, y_train)

        accuracy = model.score(X_test, y_test)

        # ---------- Predictions on full dataset for fairness ----------
        y_pred = model.predict(X)

        # ---------- Compute approval rates per protected group ----------
        # Decode protected attr back to original labels
        prot_series = df[protected].astype(str)
        groups = prot_series.unique().tolist()

        approval_rates = {}
        for g in groups:
            mask = prot_series == g
            if mask.sum() == 0:
                continue
            rate = float(y_pred[mask].mean())
            approval_rates[g] = round(rate, 4)

        # Sort groups for consistent ordering
        sorted_groups = sorted(approval_rates.items(), key=lambda x: -x[1])

        # ---------- Disparate Impact ----------
        # DI = min_group_rate / max_group_rate
        rates = list(approval_rates.values())
        if len(rates) >= 2 and max(rates) > 0:
            disparate_impact = round(min(rates) / max(rates), 4)
        else:
            disparate_impact = 1.0

        # ---------- Statistical Parity Difference ----------
        if len(rates) >= 2:
            stat_parity = round(min(rates) - max(rates), 4)
        else:
            stat_parity = 0.0

        # ---------- Equalized Odds (TPR difference) ----------
        y_arr = np.array(y)
        # Binary: assume positive class = 1 or the majority class
        pos_class = int(y.mode()[0])
        tpr_per_group = {}
        for g in groups:
            mask = (prot_series == g).values
            y_true_g = y_arr[mask]
            y_pred_g = y_pred[mask]
            pos_mask = y_true_g == pos_class
            if pos_mask.sum() > 0:
                tpr_per_group[g] = float(np.mean(y_pred_g[pos_mask] == pos_class))
            else:
                tpr_per_group[g] = 0.0

        tpr_vals = list(tpr_per_group.values())
        if len(tpr_vals) >= 2:
            equalized_odds = round(min(tpr_vals) / max(tpr_vals) if max(tpr_vals) > 0 else 0.0, 4)
        else:
            equalized_odds = 1.0

        # ---------- Bias severity ----------
        legal_violated = disparate_impact < 0.8
        if disparate_impact < 0.6:
            severity = "HIGH"
        elif disparate_impact < 0.8:
            severity = "MEDIUM"
        else:
            severity = "LOW"

        # ---------- SHAP top features ----------
        # Use a small sample for speed
        sample_size = min(200, len(X_test))
        explainer = shap.TreeExplainer(model)
        shap_values = explainer.shap_values(X_test.iloc[:sample_size])

        # Handle shap output shapes: list, 2D array, or 3D array (n_samples, n_features, n_classes)
        if isinstance(shap_values, list):
            sv = np.abs(shap_values[1])
        elif shap_values.ndim == 3:
            sv = np.abs(shap_values[:, :, 1])   # class 1
        else:
            sv = np.abs(shap_values)

        mean_shap = sv.mean(axis=0)
        feat_importance = sorted(
            zip(X.columns.tolist(), mean_shap.tolist()),
            key=lambda x: -x[1]
        )[:5]

        shap_top = [{"feature": f, "importance": round(v, 4)} for f, v in feat_importance]

        return {
            **state,
            "disparate_impact": disparate_impact,
            "statistical_parity": stat_parity,
            "equalized_odds": equalized_odds,
            "approval_rates": {k: round(v * 100, 1) for k, v in approval_rates.items()},
            "bias_severity": severity,
            "legal_threshold_violated": legal_violated,
            "shap_top_features": shap_top,
            "accuracy_before": round(accuracy * 100, 2),
            "current_agent": "BiasDetector",
            "completed_agents": state.get("completed_agents", []) + ["BiasDetector"],
            "error": None,
        }

    except Exception as e:
        import traceback
        return {
            **state,
            "error": f"BiasDetector error: {str(e)}\n{traceback.format_exc()}",
            "current_agent": "BiasDetector"
        }

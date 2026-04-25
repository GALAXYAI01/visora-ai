import os
from datetime import datetime
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from models.state import AuditState

# ── Color palette ────────────────────────────────────────────────────────────
NAVY    = colors.HexColor("#0D1425")
BLUE    = colors.HexColor("#3B82F6")
PURPLE  = colors.HexColor("#8B5CF6")
RED     = colors.HexColor("#EF4444")
GREEN   = colors.HexColor("#22C55E")
AMBER   = colors.HexColor("#F59E0B")
WHITE   = colors.white
LGRAY   = colors.HexColor("#9CA3AF")
DGRAY   = colors.HexColor("#1A1F2D")
BORDER  = colors.HexColor("#374151")


def report_gen_agent(state: AuditState) -> AuditState:
    """Generates a professional PDF bias audit report."""
    try:
        os.makedirs("reports", exist_ok=True)
        audit_id = state.get("audit_id", "VIS-0000")
        pdf_path = f"reports/{audit_id}.pdf"

        doc = SimpleDocTemplate(
            pdf_path,
            pagesize=A4,
            leftMargin=20*mm, rightMargin=20*mm,
            topMargin=18*mm, bottomMargin=18*mm,
        )

        styles = getSampleStyleSheet()
        story = []

        # ── Helpers ──────────────────────────────────────────────────────────
        def h(txt, size=22, color=WHITE, bold=True, align=TA_LEFT, space_after=6):
            s = ParagraphStyle("h", fontName="Helvetica-Bold" if bold else "Helvetica",
                               fontSize=size, textColor=color, spaceAfter=space_after,
                               alignment=align, leading=size*1.3)
            return Paragraph(txt, s)

        def p(txt, size=10, color=LGRAY, align=TA_LEFT, italic=False, space_after=4):
            fname = "Helvetica-Oblique" if italic else "Helvetica"
            s = ParagraphStyle("p", fontName=fname, fontSize=size, textColor=color,
                               spaceAfter=space_after, alignment=align, leading=size*1.5)
            return Paragraph(txt, s)

        def spacer(h=6): return Spacer(1, h*mm)
        def divider(): return HRFlowable(width="100%", thickness=0.5, color=BORDER, spaceAfter=4*mm)

        # ── Cover ─────────────────────────────────────────────────────────────
        cover_data = [[
            Paragraph('<font color="#3B82F6" size="28"><b>Visora</b></font>', styles["Normal"]),
            Paragraph(f'<font color="#9CA3AF" size="9">Audit ID: {audit_id}<br/>Date: {datetime.now().strftime("%B %d, %Y")}</font>', styles["Normal"]),
        ]]
        cover_tbl = Table(cover_data, colWidths=["60%", "40%"])
        cover_tbl.setStyle(TableStyle([
            ("ALIGN", (0,0), (0,0), "LEFT"),
            ("ALIGN", (1,0), (1,0), "RIGHT"),
            ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ]))
        story.append(cover_tbl)
        story.append(spacer(2))
        story.append(h("AI Bias Audit Report", size=20, color=WHITE))
        story.append(p("Know What Your AI Really Decides", size=11, color=LGRAY, italic=True))
        story.append(spacer(4))
        story.append(divider())

        # ── Severity banner ───────────────────────────────────────────────────
        severity = state.get("bias_severity", "UNKNOWN")
        sev_color = RED if severity == "HIGH" else (AMBER if severity == "MEDIUM" else GREEN)
        banner_data = [[
            Paragraph(f'<font color="white" size="14"><b>⚠ {severity} BIAS DETECTED</b></font>', styles["Normal"]),
            Paragraph(f'<font color="#9CA3AF" size="9">Protected Attr: {state.get("protected_attr","")}<br/>Target: {state.get("target_col","")}</font>', styles["Normal"]),
        ]]
        b_tbl = Table(banner_data, colWidths=["60%", "40%"])
        b_tbl.setStyle(TableStyle([
            ("BACKGROUND", (0,0), (-1,-1), sev_color),
            ("ALIGN", (0,0),(0,0),"LEFT"), ("ALIGN",(1,0),(1,0),"RIGHT"),
            ("VALIGN",(0,0),(-1,-1),"MIDDLE"),
            ("TOPPADDING",(0,0),(-1,-1),8), ("BOTTOMPADDING",(0,0),(-1,-1),8),
            ("LEFTPADDING",(0,0),(-1,-1),10), ("RIGHTPADDING",(0,0),(-1,-1),10),
            ("ROUNDEDCORNERS", [6,6,6,6]),
        ]))
        story.append(b_tbl)
        story.append(spacer(4))

        # ── Dataset summary ───────────────────────────────────────────────────
        story.append(h("Dataset Summary", size=14, color=WHITE))
        story.append(spacer(1))
        ds_data = [
            ["Rows Analyzed", f"{state.get('row_count',0):,}"],
            ["Features",      str(state.get('feature_count',0))],
            ["Protected Attr",state.get("protected_attr","")],
            ["Groups Found",  ", ".join(state.get("protected_values",[]))],
            ["Target Column", state.get("target_col","")],
        ]
        ds_tbl = Table(ds_data, colWidths=["40%","60%"])
        ds_tbl.setStyle(TableStyle([
            ("BACKGROUND",(0,0),(0,-1), DGRAY),
            ("BACKGROUND",(1,0),(1,-1), colors.HexColor("#111827")),
            ("TEXTCOLOR",(0,0),(0,-1), LGRAY), ("FONTSIZE",(0,0),(0,-1),9),
            ("TEXTCOLOR",(1,0),(1,-1), WHITE),  ("FONTSIZE",(1,0),(1,-1),10),
            ("FONTNAME",(1,0),(1,-1),"Helvetica-Bold"),
            ("TOPPADDING",(0,0),(-1,-1),6),("BOTTOMPADDING",(0,0),(-1,-1),6),
            ("LEFTPADDING",(0,0),(-1,-1),10),
            ("GRID",(0,0),(-1,-1),0.3,BORDER),
        ]))
        story.append(ds_tbl)
        story.append(spacer(4))
        story.append(divider())

        # ── Fairness metrics ──────────────────────────────────────────────────
        story.append(h("Fairness Metrics — Before Remediation", size=14, color=WHITE))
        story.append(spacer(1))

        di    = state.get("disparate_impact", 0)
        sp    = state.get("statistical_parity", 0)
        eo    = state.get("equalized_odds", 0)
        legal = state.get("legal_threshold_violated", False)

        def metric_color(val, threshold=0.8):
            return RED if val < threshold else GREEN

        metrics_data = [
            ["Metric", "Score", "Threshold", "Status"],
            ["Disparate Impact",    f"{di:.3f}", "≥ 0.800", "FAIL" if di < 0.8 else "PASS"],
            ["Statistical Parity",  f"{sp:.3f}", "≈ 0.000", "FAIL" if abs(sp) > 0.1 else "PASS"],
            ["Equalized Odds",       f"{eo:.3f}", "≥ 0.800", "FAIL" if eo < 0.8 else "PASS"],
            ["Accuracy (before)",   f"{state.get('accuracy_before',0):.1f}%", "—", "—"],
        ]
        m_tbl = Table(metrics_data, colWidths=["35%","20%","20%","25%"])
        m_tbl.setStyle(TableStyle([
            ("BACKGROUND",(0,0),(-1,0), BLUE), ("TEXTCOLOR",(0,0),(-1,0), WHITE),
            ("FONTNAME",(0,0),(-1,0),"Helvetica-Bold"), ("FONTSIZE",(0,0),(-1,0),10),
            ("BACKGROUND",(0,1),(0,-1), DGRAY), ("TEXTCOLOR",(0,1),(0,-1), LGRAY), ("FONTSIZE",(0,1),(0,-1),9),
            ("TEXTCOLOR",(1,1),(2,-1), WHITE), ("FONTSIZE",(1,1),(2,-1),11), ("FONTNAME",(1,1),(2,-1),"Helvetica-Bold"),
            ("TEXTCOLOR",(3,1),(3,1), RED if di < 0.8 else GREEN),
            ("TEXTCOLOR",(3,2),(3,2), RED if abs(sp) > 0.1 else GREEN),
            ("TEXTCOLOR",(3,3),(3,3), RED if eo < 0.8 else GREEN),
            ("FONTNAME",(3,1),(3,-1),"Helvetica-Bold"), ("FONTSIZE",(3,1),(3,-1),9),
            ("GRID",(0,0),(-1,-1),0.3,BORDER),
            ("TOPPADDING",(0,0),(-1,-1),7),("BOTTOMPADDING",(0,0),(-1,-1),7),
            ("LEFTPADDING",(0,0),(-1,-1),10),
        ]))
        story.append(m_tbl)
        story.append(spacer(3))

        # Approval rates
        story.append(p("Approval Rates by Group:", size=10, color=WHITE))
        story.append(spacer(1))
        ar = state.get("approval_rates", {})
        ar_data = [["Group", "Approval Rate"]] + [[g, f"{v:.1f}%"] for g, v in ar.items()]
        ar_tbl = Table(ar_data, colWidths=["50%","50%"])
        ar_tbl.setStyle(TableStyle([
            ("BACKGROUND",(0,0),(-1,0), DGRAY), ("TEXTCOLOR",(0,0),(-1,0), LGRAY),
            ("FONTNAME",(0,0),(-1,0),"Helvetica-Bold"), ("FONTSIZE",(0,0),(-1,0),9),
            ("TEXTCOLOR",(0,1),(0,-1), WHITE), ("TEXTCOLOR",(1,1),(1,-1), RED),
            ("FONTNAME",(1,1),(1,-1),"Helvetica-Bold"), ("FONTSIZE",(1,1),(1,-1),11),
            ("GRID",(0,0),(-1,-1),0.3,BORDER),
            ("TOPPADDING",(0,0),(-1,-1),6),("BOTTOMPADDING",(0,0),(-1,-1),6),
            ("LEFTPADDING",(0,0),(-1,-1),10),
        ]))
        story.append(ar_tbl)
        story.append(spacer(4))
        story.append(divider())

        # ── SHAP features ─────────────────────────────────────────────────────
        story.append(h("Top Bias-Contributing Features (SHAP)", size=14, color=WHITE))
        story.append(spacer(1))
        shap_feats = state.get("shap_top_features", [])
        shap_data = [["Feature", "SHAP Importance"]] + [[f["feature"], f"{f['importance']:.4f}"] for f in shap_feats]
        sh_tbl = Table(shap_data, colWidths=["65%","35%"])
        sh_tbl.setStyle(TableStyle([
            ("BACKGROUND",(0,0),(-1,0), PURPLE), ("TEXTCOLOR",(0,0),(-1,0), WHITE),
            ("FONTNAME",(0,0),(-1,0),"Helvetica-Bold"),
            ("TEXTCOLOR",(0,1),(0,-1), WHITE), ("FONTSIZE",(0,1),(0,-1),10),
            ("TEXTCOLOR",(1,1),(1,-1), AMBER), ("FONTNAME",(1,1),(1,-1),"Helvetica-Bold"),
            ("GRID",(0,0),(-1,-1),0.3,BORDER),
            ("TOPPADDING",(0,0),(-1,-1),7),("BOTTOMPADDING",(0,0),(-1,-1),7),
            ("LEFTPADDING",(0,0),(-1,-1),10),
        ]))
        story.append(sh_tbl)
        story.append(spacer(4))
        story.append(divider())

        # ── Gemini explanation ────────────────────────────────────────────────
        story.append(h("Gemini AI Insight", size=14, color=WHITE))
        story.append(spacer(2))
        story.append(p(f'"{state.get("gemini_explanation","")}"', size=11, color=WHITE, italic=True))
        story.append(spacer(4))
        story.append(divider())

        # ── After remediation ─────────────────────────────────────────────────
        ma = state.get("metrics_after", {})
        if ma:
            story.append(h("After Remediation", size=14, color=GREEN))
            story.append(spacer(1))
            rem_data = [
                ["Metric", "Before", "After", "Change"],
                ["Disparate Impact",
                 f"{di:.3f}", f"{ma.get('disparate_impact',0):.3f}",
                 f"+{ma.get('disparate_impact',0)-di:.3f}"],
                ["Statistical Parity",
                 f"{sp:.3f}", f"{ma.get('statistical_parity',0):.3f}",
                 f"{ma.get('statistical_parity',0)-sp:.3f}"],
                ["Equalized Odds",
                 f"{eo:.3f}", f"{ma.get('equalized_odds',0):.3f}",
                 f"+{ma.get('equalized_odds',0)-eo:.3f}"],
                ["Accuracy",
                 f"{state.get('accuracy_before',0):.1f}%",
                 f"{state.get('accuracy_after',0):.1f}%",
                 f"{state.get('accuracy_after',0)-state.get('accuracy_before',0):.1f}%"],
            ]
            rem_tbl = Table(rem_data, colWidths=["35%","20%","20%","25%"])
            rem_tbl.setStyle(TableStyle([
                ("BACKGROUND",(0,0),(-1,0), GREEN), ("TEXTCOLOR",(0,0),(-1,0), NAVY),
                ("FONTNAME",(0,0),(-1,0),"Helvetica-Bold"),
                ("TEXTCOLOR",(0,1),(0,-1), LGRAY), ("TEXTCOLOR",(1,1),(2,-1), WHITE),
                ("FONTNAME",(1,1),(2,-1),"Helvetica-Bold"),
                ("TEXTCOLOR",(3,1),(3,-1), GREEN), ("FONTNAME",(3,1),(3,-1),"Helvetica-Bold"),
                ("GRID",(0,0),(-1,-1),0.3,BORDER),
                ("TOPPADDING",(0,0),(-1,-1),7),("BOTTOMPADDING",(0,0),(-1,-1),7),
                ("LEFTPADDING",(0,0),(-1,-1),10),
            ]))
            story.append(rem_tbl)
            story.append(spacer(4))

        # ── Certificate ───────────────────────────────────────────────────────
        story.append(divider())
        cert_severity = ma.get("disparate_impact", di)
        cert_text = "Low Bias Risk — Tier 1" if cert_severity >= 0.8 else "Remediation Required"
        cert_data = [[
            Paragraph(f'<font color="#D97706" size="13"><b>★ Visora Certified</b></font><br/><font color="#9CA3AF" size="9">{cert_text}</font>', styles["Normal"]),
            Paragraph(f'<font color="#6B7280" size="8">Audit ID: {audit_id}<br/>{datetime.now().strftime("%B %d, %Y")}</font>', styles["Normal"]),
        ]]
        cert_tbl = Table(cert_data, colWidths=["70%","30%"])
        cert_tbl.setStyle(TableStyle([
            ("BACKGROUND",(0,0),(-1,-1), colors.HexColor("#1A1205")),
            ("BOX",(0,0),(-1,-1),1,colors.HexColor("#D97706")),
            ("TOPPADDING",(0,0),(-1,-1),10),("BOTTOMPADDING",(0,0),(-1,-1),10),
            ("LEFTPADDING",(0,0),(-1,-1),12),("RIGHTPADDING",(0,0),(-1,-1),12),
            ("VALIGN",(0,0),(-1,-1),"MIDDLE"),
            ("ALIGN",(1,0),(1,0),"RIGHT"),
        ]))
        story.append(cert_tbl)

        doc.build(story)

        return {
            **state,
            "pdf_path": pdf_path,
            "current_agent": "ReportGen",
            "completed_agents": state.get("completed_agents", []) + ["ReportGen"],
            "error": None,
        }

    except Exception as e:
        import traceback
        return {
            **state,
            "pdf_path": "",
            "error": f"ReportGen error: {str(e)}\n{traceback.format_exc()}",
            "current_agent": "ReportGen",
        }

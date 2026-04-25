# Visora — AI Bias Audit Platform

<div align="center">
  
**[Unbiased AI Decision] Ensuring Fairness and Detecting Bias in Automated Decisions**

*A comprehensive solution to inspect data sets and software models for hidden unfairness or discrimination.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)](https://dart.dev)
[![Gemini AI](https://img.shields.io/badge/Gemini-AI%20Powered-orange?logo=google)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-green)]()

</div>

---

## 🎯 Problem Statement

Computer programs now make life-changing decisions about who gets a job, a bank loan, or even medical care. If these programs learn from flawed or unfair historical data, they repeat and amplify discriminatory mistakes.

**Visora** provides organizations with an easy way to **measure, flag, and fix** harmful bias before their systems impact real people.

---

## ✨ Key Features

### 📊 Dataset Bias Audit
- Upload any CSV dataset and select protected attributes (gender, race, age, etc.)
- **Computes real fairness metrics** directly in-browser:
  - **Disparate Impact** (EEOC 4/5ths rule)
  - **Statistical Parity Difference**
  - **Equalized Odds**
- Works **fully offline** — no backend required for the core audit

### 🔍 AI Text Bias Scanner
- Paste any text — job descriptions, loan policies, HR rules, model outputs
- **Gemini AI** analyzes for hidden bias with:
  - Severity ratings (HIGH / MODERATE / LOW)
  - Bias type classification (age, gender, racial, disability, etc.)
  - Specific phrase flagging with explanations
  - AI-generated improved text suggestions
  - Legal & regulatory risk warnings

### 🧪 Bias Simulation
- Test individual profiles against the model
- See how changing protected attributes affects outcomes
- Demonstrates algorithmic fairness at the individual level

### 🛡️ Automated Remediation
- **Adversarial debiasing** applied automatically
- Before/after metric comparison
- Accuracy impact analysis (fairness-accuracy tradeoff)

### 📄 PDF Report Generation
- Professional multi-page bias audit report
- Includes: executive summary, metrics, approval rates, compliance status, human impact
- Downloads directly to your computer

### 👥 Human Impact Assessment
- Quantifies the real-world cost of bias
- Estimated unfair decisions per month
- Projected financial liability
- Legal risk scoring

### 🔐 Security
- AES-256-CBC encrypted session storage
- SHA-256 password hashing
- Admin authentication with 24-hour sessions
- API security interceptors

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│              Flutter Web App                 │
│  ┌─────────┐ ┌──────────┐ ┌──────────────┐ │
│  │  Login   │ │  Upload  │ │  Text Scanner│ │
│  │  Screen  │ │  Screen  │ │  (Gemini AI) │ │
│  └────┬─────┘ └────┬─────┘ └──────┬───────┘ │
│       │            │               │         │
│  ┌────┴────────────┴───────────────┴───────┐ │
│  │           Riverpod State Mgmt           │ │
│  └────┬──────────┬──────────┬──────────────┘ │
│       │          │          │                │
│  ┌────┴────┐ ┌───┴───┐ ┌───┴─────────────┐  │
│  │  Auth   │ │Encrypt│ │ DemoAuditEngine  │  │
│  │Provider │ │Service│ │ (Local Analysis) │  │
│  └─────────┘ └───────┘ └─────────────────┘  │
└───────────────────┬─────────────────────────┘
                    │ (optional)
         ┌──────────┴──────────┐
         │  Python Backend     │
         │  (FastAPI + ML)     │
         └─────────────────────┘
```

### Tech Stack
| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter Web (Dart 3.x) |
| **State** | Riverpod |
| **Routing** | GoRouter with auth guards |
| **AI** | Gemini 2.0 Flash (direct API) |
| **Charts** | fl_chart |
| **PDF** | pdf + printing packages |
| **Security** | AES-256-CBC (encrypt), SHA-256 (crypto) |
| **Backend** | FastAPI + scikit-learn (optional) |

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.x installed
- Chrome browser

### 1. Clone & Install
```bash
git clone <repo-url>
cd visora
flutter pub get
```

### 2. Configure Environment
```bash
# .env file (already included)
GEMINI_API_KEY=your_gemini_api_key
BACKEND_URL=http://localhost:8000
ENCRYPTION_KEY=your_secret_key
```

### 3. Run
```bash
flutter run -d chrome --web-port=8080
```

### 4. Login
- **Username:** `admin`
- **Password:** `visora2024`

### 5. Try It
1. Click **Upload** → select any CSV with demographic data
2. Set protected attribute (e.g., `gender`) and target column (e.g., `income`)
3. Click **Start Audit** → see real bias metrics computed from your data
4. Navigate to **Scanner** → paste text and get AI-powered bias analysis
5. Check **Reports** → download PDF, deploy remediated model

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry, router, auth guard
├── theme/app_theme.dart         # Luminous Professional design system
├── screens/
│   ├── login_screen.dart        # Admin authentication
│   ├── home_screen.dart         # Dashboard overview
│   ├── upload_screen.dart       # CSV upload + local audit engine
│   ├── progress_screen.dart     # Audit progress pipeline
│   ├── results_screen.dart      # Bias detection results
│   ├── simulation_screen.dart   # Individual bias simulation
│   ├── remediation_screen.dart  # Fix bias + PDF + deploy
│   ├── text_scanner_screen.dart # Gemini AI text analysis
│   └── human_cost_screen.dart   # Impact quantification
├── services/
│   ├── demo_audit_engine.dart   # Local CSV bias calculator
│   ├── gemini_service.dart      # Direct Gemini API client
│   ├── report_generator.dart    # PDF report builder
│   ├── encryption_service.dart  # AES-256-CBC encryption
│   ├── auth_provider.dart       # Session management
│   └── api_service.dart         # Backend API + interceptors
└── widgets/
    └── bottom_nav.dart          # Navigation shell
```

---

## 🧪 Sample Datasets

The app works with any CSV containing:
- A **protected attribute** column (gender, race, age_group, etc.)
- A **target/outcome** column (approved, income, hired, etc.)

Recommended test datasets:
- [Adult Census Income](https://archive.ics.uci.edu/ml/datasets/adult) — `sex` / `income`
- [COMPAS Recidivism](https://github.com/propublica/compas-analysis) — `race` / `two_year_recid`
- [German Credit](https://archive.ics.uci.edu/ml/datasets/statlog+(german+credit+data)) — `personal_status` / `class`

---

## 📜 Fairness Metrics Explained

| Metric | Formula | Threshold | Regulation |
|--------|---------|-----------|------------|
| **Disparate Impact** | P(Y=1\|unprivileged) / P(Y=1\|privileged) | ≥ 0.80 | EEOC 4/5ths Rule |
| **Statistical Parity** | P(Y=1\|unprivileged) - P(Y=1\|privileged) | ≥ -0.10 | EU AI Act |
| **Equalized Odds** | TPR ratio between groups | ≥ 0.80 | GDPR Art. 22 |

---

## 🔒 Security Architecture

```
User Input → SHA-256 Hash → Credential Check
Session Data → AES-256-CBC → SharedPreferences (encrypted)
API Requests → Security Interceptor → Stripped error details
Flutter Web → Compiled Dart/WASM → Opaque to browser DevTools
```

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">
  <b>Built for the Google Build AI Hackathon 2026</b><br>
  <i>Ensuring fairness in automated decisions, one audit at a time.</i>
</div>

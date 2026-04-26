import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Direct Gemini API service for AI-powered bias analysis.
/// Includes local fallback so features always work without errors.
class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Analyze text for bias — tries Gemini API first, falls back to local engine.
  static Future<Map<String, dynamic>> scanTextForBias(String text) async {
    // Try Gemini API
    if (_apiKey.isNotEmpty) {
      try {
        return await _geminiScan(text);
      } catch (_) {
        // Fall through to local analysis
      }
    }
    // Local fallback — always works
    return _localBiasAnalysis(text);
  }

  /// Chat with Visora AI — tries Gemini API first, falls back to local knowledge base.
  static Future<String> chat(String userMessage) async {
    if (_apiKey.isNotEmpty) {
      try {
        return await _geminiChat(userMessage);
      } catch (_) {
        // Fall through to local
      }
    }
    return _localChatResponse(userMessage);
  }

  // ──────────────────────────────────────────────────────────────
  // Gemini API calls
  // ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _geminiScan(String text) async {
    final prompt = '''
You are an expert AI bias auditor. Analyze the following text for any form of bias, discrimination, or unfairness. 

Text to analyze:
"""
$text
"""

Respond ONLY with valid JSON in this exact format (no markdown, no code fences):
{
  "overall_risk": "HIGH" or "MODERATE" or "LOW",
  "bias_score": <number 0-100>,
  "summary": "<1–2 sentence summary>",
  "flags": [
    {
      "phrase": "<exact biased phrase from text>",
      "type": "<bias type: age, gender, racial, disability, socioeconomic, religious, appearance>",
      "severity": "HIGH" or "MODERATE" or "LOW",
      "explanation": "<why this is biased>",
      "suggestion": "<neutral alternative>"
    }
  ],
  "legal_risks": ["<list of applicable regulations this might violate>"],
  "improved_text": "<rewritten version of the text with bias removed>"
}
''';

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

    final response = await _dio.post(url, data: {
      'contents': [
        {'parts': [{'text': prompt}]}
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 2048,
      },
    });

    final data = response.data as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) throw Exception('Empty');

    final content = candidates[0]['content']['parts'][0]['text'] as String;
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '').replaceFirst(RegExp(r'\n?```$'), '');
    }

    return json.decode(cleaned) as Map<String, dynamic>;
  }

  static Future<String> _geminiChat(String userMessage) async {
    final systemPrompt = '''You are Visora AI, an expert assistant for AI bias auditing and fairness.
You help users understand fairness metrics (Disparate Impact, Statistical Parity, Equalized Odds),
bias remediation techniques, legal compliance (EEOC, EU AI Act, GDPR), and best practices for
building fair ML models. Keep answers concise and actionable. Use bullet points when helpful.
If asked about something unrelated to AI fairness/bias, politely redirect to your domain.''';

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

    final response = await _dio.post(url, data: {
      'contents': [
        {'role': 'user', 'parts': [{'text': '$systemPrompt\n\nUser question: $userMessage'}]}
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 1024,
      },
    });

    final data = response.data as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) throw Exception('Empty');
    return (candidates[0]['content']['parts'][0]['text'] as String).trim();
  }

  // ──────────────────────────────────────────────────────────────
  // LOCAL FALLBACK — Smart bias detection without API
  // ──────────────────────────────────────────────────────────────

  static final _biasPatterns = <String, Map<String, String>>{
    'young': {'type': 'age', 'explanation': 'Age-specific language excludes older candidates and may violate ADEA', 'suggestion': 'motivated'},
    'energetic': {'type': 'age', 'explanation': 'Often used as a proxy for youth, creating age discrimination', 'suggestion': 'enthusiastic'},
    'digital native': {'type': 'age', 'explanation': 'Implies preference for younger workers raised with technology', 'suggestion': 'tech-proficient'},
    'fresh graduate': {'type': 'age', 'explanation': 'Excludes experienced workers and implies age preference', 'suggestion': 'entry-level candidate'},
    'recent graduate': {'type': 'age', 'explanation': 'May discriminate against older applicants or career changers', 'suggestion': 'qualified candidate'},
    'manpower': {'type': 'gender', 'explanation': 'Gender-coded language that implies male preference', 'suggestion': 'workforce'},
    'chairman': {'type': 'gender', 'explanation': 'Gendered title that assumes male leadership', 'suggestion': 'chairperson'},
    'manmade': {'type': 'gender', 'explanation': 'Unnecessarily gendered language', 'suggestion': 'artificial or synthetic'},
    'mankind': {'type': 'gender', 'explanation': 'Excludes non-male identities', 'suggestion': 'humanity or humankind'},
    'he ': {'type': 'gender', 'explanation': 'Assumes male gender as default', 'suggestion': 'they'},
    'his ': {'type': 'gender', 'explanation': 'Assumes male gender as default', 'suggestion': 'their'},
    'salesman': {'type': 'gender', 'explanation': 'Gendered job title', 'suggestion': 'salesperson'},
    'waitress': {'type': 'gender', 'explanation': 'Gendered job title', 'suggestion': 'server'},
    'fireman': {'type': 'gender', 'explanation': 'Gendered job title', 'suggestion': 'firefighter'},
    'self-starter': {'type': 'age', 'explanation': 'Often coded language that correlates with youth-oriented culture', 'suggestion': 'self-motivated professional'},
    'ninja': {'type': 'appearance', 'explanation': 'Informal language with cultural appropriation concerns', 'suggestion': 'expert'},
    'rockstar': {'type': 'appearance', 'explanation': 'Informal language that can signal exclusionary culture', 'suggestion': 'high performer'},
    'guru': {'type': 'religious', 'explanation': 'Appropriates religious terminology', 'suggestion': 'expert or specialist'},
    'native english': {'type': 'racial', 'explanation': 'Discriminates against non-native speakers and certain ethnic groups', 'suggestion': 'fluent in English'},
    'clean-shaven': {'type': 'religious', 'explanation': 'May discriminate against those with religious grooming requirements', 'suggestion': 'professional appearance'},
    'physical demands': {'type': 'disability', 'explanation': 'May exclude people with disabilities without proper justification', 'suggestion': 'role requirements'},
    'able-bodied': {'type': 'disability', 'explanation': 'Excludes people with disabilities', 'suggestion': 'capable of performing essential functions'},
    'walk': {'type': 'disability', 'explanation': 'Assumes physical mobility as a requirement', 'suggestion': 'move or navigate'},
    'stand for long': {'type': 'disability', 'explanation': 'Physical requirement that may exclude disabled candidates', 'suggestion': 'sustained work periods'},
    'culture fit': {'type': 'racial', 'explanation': 'Often used as proxy for racial or ethnic homogeneity', 'suggestion': 'values alignment'},
    'aggressive': {'type': 'gender', 'explanation': 'Masculine-coded language that discourages female applicants', 'suggestion': 'determined or proactive'},
    'dominant': {'type': 'gender', 'explanation': 'Masculine-coded language associated with power hierarchies', 'suggestion': 'leading'},
    'competitive': {'type': 'gender', 'explanation': 'Research shows masculine-coded words discourage female applicants', 'suggestion': 'achievement-oriented'},
    'robust': {'type': 'gender', 'explanation': 'Masculine-coded language implying physical strength requirements', 'suggestion': 'resilient or strong'},
    'fast-paced': {'type': 'age', 'explanation': 'Can signal preference for younger workers and exclude those with disabilities', 'suggestion': 'dynamic environment'},
  };

  static Map<String, dynamic> _localBiasAnalysis(String text) {
    final lower = text.toLowerCase();
    final flags = <Map<String, dynamic>>[];
    final legalRisks = <String>{};

    for (final entry in _biasPatterns.entries) {
      if (lower.contains(entry.key)) {
        flags.add({
          'phrase': _findOriginalPhrase(text, entry.key),
          'type': entry.value['type'],
          'severity': (entry.value['type'] == 'age' || entry.value['type'] == 'gender' || entry.value['type'] == 'racial') ? 'HIGH' : 'MODERATE',
          'explanation': entry.value['explanation'],
          'suggestion': 'Consider using "${entry.value['suggestion']}" instead',
        });

        // Map bias types to legal risks
        switch (entry.value['type']) {
          case 'age': legalRisks.add('Age Discrimination in Employment Act (ADEA)'); break;
          case 'gender': legalRisks.add('Title VII of the Civil Rights Act'); legalRisks.add('EU Gender Equality Directive'); break;
          case 'racial': legalRisks.add('Title VII of the Civil Rights Act'); legalRisks.add('EU Anti-Discrimination Directive'); break;
          case 'disability': legalRisks.add('Americans with Disabilities Act (ADA)'); legalRisks.add('EU Employment Equality Directive'); break;
          case 'religious': legalRisks.add('Title VII of the Civil Rights Act — Religious Discrimination'); break;
        }
      }
    }

    final score = flags.isEmpty ? 8 : (flags.length * 18).clamp(20, 92);
    final risk = score >= 60 ? 'HIGH' : score >= 30 ? 'MODERATE' : 'LOW';

    String summary;
    if (flags.isEmpty) {
      summary = 'No significant bias patterns detected. The text appears largely neutral and inclusive.';
    } else {
      final types = flags.map((f) => f['type']).toSet().join(', ');
      summary = 'Detected ${flags.length} potential bias indicator(s) related to $types. Review flagged phrases for inclusive alternatives.';
    }

    // Generate improved text
    var improved = text;
    for (final entry in _biasPatterns.entries) {
      if (lower.contains(entry.key)) {
        improved = improved.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value['suggestion']!);
      }
    }

    return {
      'overall_risk': risk,
      'bias_score': score,
      'summary': summary,
      'flags': flags,
      'legal_risks': legalRisks.toList(),
      'improved_text': improved,
    };
  }

  static String _findOriginalPhrase(String text, String pattern) {
    final idx = text.toLowerCase().indexOf(pattern);
    if (idx == -1) return pattern;
    // Grab surrounding context (up to 40 chars)
    final start = (idx - 10).clamp(0, text.length);
    final end = (idx + pattern.length + 10).clamp(0, text.length);
    var phrase = text.substring(start, end).trim();
    // Trim to word boundaries
    if (start > 0) phrase = '...$phrase';
    if (end < text.length) phrase = '$phrase...';
    return phrase;
  }

  // ──────────────────────────────────────────────────────────────
  // LOCAL CHAT FALLBACK — Knowledge base responses
  // ──────────────────────────────────────────────────────────────

  static final _knowledgeBase = <String, String>{
    'disparate impact': '''**Disparate Impact** (also called adverse impact) occurs when a seemingly neutral policy disproportionately affects a protected group.

• **The 4/5ths Rule**: If the selection rate for a protected group is less than 80% of the rate for the highest-scoring group, disparate impact exists.
• **Formula**: Disparate Impact Ratio = (Selection rate of protected group) ÷ (Selection rate of majority group)
• **Threshold**: A ratio below 0.80 indicates potential discrimination.
• **Legal basis**: Griggs v. Duke Power Co. (1971) established this standard.

Example: If 60% of male applicants are hired but only 40% of female applicants, the DI ratio = 0.40/0.60 = 0.67 — which is below 0.80, indicating disparate impact.''',

    'gender bias': '''**How to Fix Gender Bias in AI/ML Models:**

1. **Audit Training Data**: Check for imbalanced representation across gender groups.
2. **Remove Proxy Variables**: Features like height, name, or hobbies can encode gender.
3. **Use Debiasing Techniques**:
   • Pre-processing: Reweighting or resampling training data
   • In-processing: Adding fairness constraints to the loss function
   • Post-processing: Adjusting decision thresholds per group
4. **Inclusive Language**: Remove gendered terms from text-based models.
5. **Regular Audits**: Run Visora bias scans on every model version.
6. **Diverse Teams**: Include diverse perspectives in model design and validation.''',

    'equalized odds': '''**Equalized Odds** is a fairness metric that requires a classifier to have equal True Positive Rates (TPR) and equal False Positive Rates (FPR) across all protected groups.

• **Definition**: P(Ŷ=1|Y=1,A=a) = P(Ŷ=1|Y=1,A=b) AND P(Ŷ=1|Y=0,A=a) = P(Ŷ=1|Y=0,A=b)
• **Meaning**: The model should be equally accurate for all groups — same rates of correct approvals AND same rates of false approvals.
• **Relaxation**: "Equal Opportunity" only requires equal TPR (not FPR).
• **Trade-off**: Often conflicts with calibration — you may need to choose which fairness metric matters most for your use case.

This is the gold standard metric recommended by the EU AI Act for high-risk AI systems.''',

    'eeoc': '''**EEOC Compliance for AI Models:**

The Equal Employment Opportunity Commission (EEOC) enforces federal laws prohibiting employment discrimination. For AI/ML:

• **Title VII**: Prohibits discrimination based on race, color, religion, sex, or national origin — applies to AI hiring tools.
• **4/5ths Rule**: AI screening must not create adverse impact (selection rate < 80% of majority group).
• **EEOC Guidance (2023)**: Employers are liable for discriminatory AI tools, even if developed by third parties.
• **Key Requirements**:
  1. Validate AI tools for disparate impact before deployment
  2. Provide reasonable accommodations for disability
  3. Document bias testing and mitigation efforts
  4. Ensure transparency in automated decision-making
• **Penalties**: Compensatory damages, back pay, injunctive relief, and fines up to \$300K per violation.''',

    'statistical parity': '''**Statistical Parity** (also called Demographic Parity) requires that the positive prediction rate is the same across all protected groups.

• **Definition**: P(Ŷ=1|A=a) = P(Ŷ=1|A=b) for all groups a, b
• **Meaning**: Each group should receive positive outcomes at the same rate, regardless of the actual outcome.
• **Limitation**: Doesn't account for differences in base rates — can force inaccurate predictions.
• **When to use**: Best for scenarios where historical data may reflect systemic bias (e.g., hiring, lending).
• **Alternative**: Consider Equalized Odds when base rates genuinely differ across groups.''',

    'remediation': '''**Bias Remediation Techniques:**

**Pre-processing (Data Level):**
• Reweighting: Assign higher weights to underrepresented groups
• Resampling: Over-sample minority groups or under-sample majority
• Data augmentation: Generate synthetic fair data

**In-processing (Model Level):**
• Adversarial debiasing: Train with a fairness adversary
• Fairness constraints: Add penalties for group disparity in loss function
• Calibration: Ensure predicted probabilities match actual outcomes per group

**Post-processing (Output Level):**
• Threshold adjustment: Set different decision thresholds per group to equalize outcomes
• Reject option classification: Defer uncertain decisions for human review
• Output perturbation: Slightly adjust scores near the decision boundary''',
  };

  static String _localChatResponse(String query) {
    final lower = query.toLowerCase().trim();

    // ── Greetings ──
    if (RegExp(r'^(hi|hello|hey|howdy|greetings|good morning|good afternoon|good evening|sup|yo)\b').hasMatch(lower)) {
      return "Hello! 👋 I'm Visora AI, your bias auditing assistant. I can help you with:\n\n• Understanding fairness metrics (Disparate Impact, Equalized Odds, etc.)\n• Detecting and fixing bias in ML models\n• Legal compliance (EEOC, EU AI Act, GDPR)\n• Scanning text for biased language\n• Remediation strategies\n\nWhat would you like to know?";
    }

    // ── About Visora ──
    if (_matches(lower, ['what', 'visora']) || _matches(lower, ['tell', 'visora']) || _matches(lower, ['about', 'visora']) || _matches(lower, ['how', 'visora', 'work'])) {
      return '''**Visora** is an AI-powered bias auditing platform that helps organizations detect, measure, and remediate bias in machine learning models.

**Key Features:**
• 📊 Automated fairness metric computation (Disparate Impact, Statistical Parity, Equalized Odds)
• 🔍 Text bias scanning for job listings, policies, and AI outputs
• 🎯 What-If simulation to test model behavior across demographics
• 🛠️ One-click bias remediation with debiased dataset export
• 📋 Compliance-ready PDF audit reports
• 🤖 AI-powered insights and recommendations

Visora works by analyzing your datasets or text for patterns of bias, then providing actionable recommendations to make your AI systems fairer.''';
    }

    // ── Direct knowledge base matches ──
    for (final entry in _knowledgeBase.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // ── Expanded topic matching ──

    // Bias types
    if (_matches(lower, ['age', 'bias']) || _matches(lower, ['ageism'])) {
      return '''**Age Bias in AI:**

Age bias occurs when AI systems discriminate based on age, often favoring younger candidates.

**Common Indicators:**
• Job listings using "young," "energetic," "digital native," "fresh graduate"
• Training data skewed toward a specific age group
• Proxy variables like graduation year or years of experience used improperly

**Legal Framework:** The Age Discrimination in Employment Act (ADEA) prohibits discrimination against individuals 40+.

**How to Fix:**
1. Remove age-correlated features from models
2. Audit selection rates across age groups using the 4/5ths rule
3. Use inclusive language in all text (replace "young" with "motivated")
4. Regularly test models for disparate impact on age groups''';
    }

    if (_matches(lower, ['racial', 'bias']) || _matches(lower, ['race', 'bias']) || _matches(lower, ['racism', 'ai'])) {
      return '''**Racial Bias in AI Systems:**

Racial bias is one of the most critical and well-documented forms of AI discrimination.

**Notable Examples:**
• COMPAS recidivism algorithm showed higher false positive rates for Black defendants
• Facial recognition systems with higher error rates for darker skin tones
• Resume screening tools penalizing names associated with certain ethnicities

**Detection Methods:**
• Compare True Positive/False Positive rates across racial groups
• Test for disparate impact using the 4/5ths rule
• Audit proxy variables (zip code, name, school) that correlate with race

**Remediation:**
1. Diverse & representative training data
2. Remove proxy variables for race
3. Apply fairness constraints (Equalized Odds)
4. Regular third-party audits
5. Human oversight for high-stakes decisions''';
    }

    if (_matches(lower, ['gender', 'bias']) || _matches(lower, ['sex', 'bias']) || _matches(lower, ['gender', 'fix'])) {
      return _knowledgeBase['gender bias']!;
    }

    if (_matches(lower, ['disability', 'bias']) || _matches(lower, ['ableism'])) {
      return '''**Disability Bias in AI:**

AI systems can discriminate against people with disabilities through language, design, and data biases.

**Common Issues:**
• Job listings requiring "ability to stand," "walk," or "physically demanding tasks" without justification
• Resume screening penalizing employment gaps (common for people with chronic conditions)
• Voice/speech recognition failing for people with speech disabilities
• Inaccessible AI interfaces

**Legal Framework:** Americans with Disabilities Act (ADA) requires reasonable accommodations.

**Solutions:**
1. Use inclusive language ("navigate" instead of "walk")
2. Ensure training data includes people with disabilities
3. Test accessibility of AI interfaces
4. Remove ableist proxy variables from models''';
    }

    // Fairness metrics
    if (_matches(lower, ['fair', 'metric']) || _matches(lower, ['which', 'metric']) || _matches(lower, ['list', 'metric'])) {
      return '''**Key Fairness Metrics:**

1. **Disparate Impact Ratio** — Selection rate ratio between groups (threshold: ≥ 0.80)
2. **Statistical Parity** — Equal positive prediction rates across groups
3. **Equalized Odds** — Equal TPR and FPR across groups
4. **Equal Opportunity** — Equal TPR across groups (relaxed Equalized Odds)
5. **Calibration** — Predicted probabilities match actual outcomes per group
6. **Predictive Parity** — Equal PPV (precision) across groups
7. **Treatment Equality** — Equal ratio of false negatives to false positives

⚠️ **Important:** No single metric captures all aspects of fairness. Visora recommends using 2-3 metrics together based on your use case.''';
    }

    if (_matches(lower, ['equal', 'opportunity'])) {
      return '''**Equal Opportunity** is a fairness metric that requires equal True Positive Rates across all protected groups.

• **Definition:** P(Ŷ=1|Y=1,A=a) = P(Ŷ=1|Y=1,A=b)
• **Meaning:** Among people who *should* be selected, the selection rate must be the same regardless of group membership.
• **Difference from Equalized Odds:** Equal Opportunity only requires equal TPR, not equal FPR.
• **When to use:** When false negatives are more harmful than false positives (e.g., loan approvals, hiring).

This is often a practical compromise between full Equalized Odds and model performance.''';
    }

    if (_matches(lower, ['calibration'])) {
      return '''**Calibration (Fairness):**

A model is calibrated if predicted probabilities match actual outcomes across all groups.

• **Example:** If the model says "70% chance of loan repayment" for Group A and Group B, then 70% of both groups should actually repay.
• **Why it matters:** Ensures predictions mean the same thing for everyone.
• **Trade-off:** Perfect calibration often conflicts with Equalized Odds — you typically can't have both.
• **Testing:** Use calibration curves/plots segmented by protected group.''';
    }

    // Remediation & fixing bias
    if (_matches(lower, ['bias', 'fix']) || _matches(lower, ['remove', 'bias']) || _matches(lower, ['reduce', 'bias']) || _matches(lower, ['debias']) || _matches(lower, ['mitigat'])) {
      return _knowledgeBase['remediation']!;
    }

    if (_matches(lower, ['reweighting']) || _matches(lower, ['resampling']) || _matches(lower, ['pre-processing']) || _matches(lower, ['preprocessing'])) {
      return '''**Pre-processing Debiasing Techniques:**

These methods modify the *training data* before model training:

1. **Reweighting** — Assign higher sample weights to underrepresented groups so they have equal influence on the model.

2. **Resampling** — Over-sample minority groups or under-sample majority groups to balance the dataset.

3. **Data Augmentation** — Generate synthetic fair data points to fill representation gaps.

4. **Disparate Impact Remover** — Transform feature values to reduce correlation with protected attributes while preserving rank ordering.

5. **Label Correction** — Identify and correct historically biased labels in training data.

**When to use:** Best when you have access to training data and can retrain the model. Most transparent approach.''';
    }

    // Legal & compliance
    if (_matches(lower, ['eu ai', 'act']) || _matches(lower, ['regulation']) || _matches(lower, ['law', 'ai']) || _matches(lower, ['compliance', 'ai'])) {
      return '''**AI Regulations & Compliance:**

**🇺🇸 United States:**
• EEOC — Enforces anti-discrimination in AI hiring tools
• Title VII — Prohibits discrimination based on race, sex, religion, national origin
• ADEA — Age discrimination protection for 40+
• ADA — Disability accommodation requirements
• NYC Local Law 144 — Mandatory bias audits for automated employment tools

**🇪🇺 European Union:**
• EU AI Act — Risk-based regulation; high-risk AI requires conformity assessments
• GDPR — Right to explanation for automated decisions
• Penalties: Up to €35M or 7% of global revenue

**Best Practices:**
1. Conduct bias audits before deployment
2. Document fairness testing in technical documentation
3. Provide transparency to affected individuals
4. Maintain human oversight for high-stakes decisions''';
    }

    if (_matches(lower, ['gdpr']) || _matches(lower, ['data', 'protection'])) {
      return '''**GDPR & AI Fairness:**

The General Data Protection Regulation has several provisions relevant to AI bias:

• **Article 22:** Right not to be subject to purely automated decision-making
• **Article 13-14:** Right to meaningful information about the logic involved in automated decisions
• **Article 35:** Data Protection Impact Assessment required for profiling
• **Recital 71:** Right to obtain human intervention and challenge automated decisions

**Implications for AI:**
1. Users must be informed when AI makes decisions about them
2. You must be able to explain *why* the AI made a specific decision
3. Individuals can request human review of automated decisions
4. Bias in AI can constitute unlawful processing under GDPR''';
    }

    // ML concepts
    if (_matches(lower, ['training', 'data']) || _matches(lower, ['dataset', 'bias'])) {
      return '''**Training Data Bias:**

Biased training data is the #1 cause of biased AI models. Common issues:

**Types of Data Bias:**
• **Historical bias** — Data reflects past discrimination (e.g., fewer women in tech roles)
• **Representation bias** — Certain groups are underrepresented in the dataset
• **Measurement bias** — Data collection methods favor certain groups
• **Label bias** — Human annotators introduce their own biases
• **Selection bias** — Non-random sampling skews the data

**How to Detect:**
1. Compute demographic breakdowns of your dataset
2. Compare label distributions across protected groups
3. Check for proxy variables that correlate with protected attributes
4. Use Visora's automated profiling to identify imbalances

**How to Fix:**
1. Collect more diverse, representative data
2. Apply reweighting or resampling techniques
3. Use synthetic data augmentation
4. Audit labels for consistency across groups''';
    }

    if (_matches(lower, ['model', 'audit']) || _matches(lower, ['audit', 'process']) || _matches(lower, ['how', 'audit'])) {
      return '''**How to Conduct an AI Bias Audit:**

**Step 1: Define Scope**
• Identify the AI system and its decision-making context
• Determine protected attributes (race, gender, age, disability)
• Select appropriate fairness metrics

**Step 2: Data Analysis**
• Profile training data for demographic representation
• Check for proxy variables and label bias
• Use Visora's automated data profiler

**Step 3: Model Testing**
• Compute fairness metrics across all protected groups
• Apply the 4/5ths rule for disparate impact
• Test edge cases and intersectional groups

**Step 4: Remediation**
• Apply debiasing techniques (pre/in/post-processing)
• Re-test to confirm improvement
• Document all changes

**Step 5: Reporting**
• Generate compliance-ready audit reports
• Include methodology, findings, and remediation steps
• Visora generates these reports automatically''';
    }

    if (_matches(lower, ['explainab']) || _matches(lower, ['interpret']) || _matches(lower, ['xai'])) {
      return '''**Explainability & Interpretability in AI:**

Understanding *why* an AI makes decisions is crucial for fairness:

**Techniques:**
• **SHAP** — Shows how each feature contributes to a prediction
• **LIME** — Explains individual predictions with local approximations
• **Feature Importance** — Ranks which features most influence the model
• **Counterfactual Explanations** — "You would have been approved if X were different"
• **Decision Trees** — Inherently interpretable models

**Why it matters for fairness:**
1. Helps identify if protected attributes influence decisions
2. Required by GDPR Article 22 (right to explanation)
3. Enables affected individuals to challenge decisions
4. Builds trust in AI systems''';
    }

    if (_matches(lower, ['false positive']) || _matches(lower, ['false negative']) || _matches(lower, ['confusion matrix'])) {
      return '''**Understanding Errors in Fairness:**

• **False Positive (FP):** Model incorrectly predicts positive (e.g., flagging a qualified candidate as unfit)
• **False Negative (FN):** Model incorrectly predicts negative (e.g., missing a biased phrase)
• **True Positive Rate (TPR):** Proportion of actual positives correctly identified
• **False Positive Rate (FPR):** Proportion of actual negatives incorrectly flagged

**Fairness Connection:**
If FPR is higher for Group A than Group B, the model unfairly penalizes Group A. This is exactly what Equalized Odds aims to prevent — it requires equal TPR *and* equal FPR across groups.''';
    }

    // Practical questions
    if (_matches(lower, ['hiring']) || _matches(lower, ['recruitment']) || _matches(lower, ['resume', 'screen'])) {
      return '''**AI Bias in Hiring & Recruitment:**

AI hiring tools are among the most scrutinized for bias:

**Famous Cases:**
• Amazon scrapped a resume screening tool that penalized women (2018)
• HireVue faced backlash for video interview AI analyzing facial expressions
• NYC Local Law 144 now requires annual bias audits for automated hiring tools

**Common Biases:**
• Gender bias in resume keywords ("competitive" vs "collaborative")
• Name-based discrimination (ethnic-sounding names scored lower)
• Education bias favoring elite institutions
• Employment gap penalties (disproportionately affects women, disabled)

**Best Practices:**
1. Audit selection rates using the 4/5ths rule across all demographics
2. Remove names, photos, and demographic data from screening
3. Validate AI against diverse candidate pools
4. Combine AI screening with human review
5. Use Visora to scan job descriptions for biased language''';
    }

    if (_matches(lower, ['lending']) || _matches(lower, ['credit']) || _matches(lower, ['loan'])) {
      return '''**AI Bias in Lending & Credit:**

Lending algorithms have been shown to discriminate against minority groups:

**Key Issues:**
• Zip code as a proxy for race (redlining)
• Credit history reflecting historical discrimination
• Differential pricing based on protected characteristics

**Regulatory Framework:**
• Equal Credit Opportunity Act (ECOA)
• Fair Housing Act
• Consumer Financial Protection Bureau (CFPB) oversight

**Remediation:**
1. Test for disparate impact in approval rates
2. Remove proxy variables (zip code, school)
3. Use interpretable models for high-stakes lending decisions
4. Provide adverse action notices with clear explanations
5. Regular third-party audits of lending algorithms''';
    }

    if (_matches(lower, ['healthcare']) || _matches(lower, ['medical', 'ai'])) {
      return '''**AI Bias in Healthcare:**

Healthcare AI has shown significant disparities across demographic groups:

**Documented Issues:**
• Risk prediction algorithms underestimating illness severity for Black patients
• Dermatology AI trained mostly on light skin, failing for darker skin tones
• Clinical trial data skewed toward male participants

**Impact:** Biased healthcare AI can lead to misdiagnosis, delayed treatment, and health disparities.

**Solutions:**
1. Ensure diverse training data across demographics
2. Validate model performance separately for each group
3. Include domain experts from diverse backgrounds
4. Test for equalized odds in diagnostic accuracy
5. Maintain human oversight for critical decisions''';
    }

    // Thank you / appreciation
    if (_matches(lower, ['thank']) || _matches(lower, ['thanks']) || _matches(lower, ['appreciate'])) {
      return "You're welcome! 😊 I'm always here to help with bias auditing, fairness metrics, and compliance questions. Feel free to ask anything else!";
    }

    // Goodbye
    if (_matches(lower, ['bye']) || _matches(lower, ['goodbye']) || _matches(lower, ['see you'])) {
      return "Goodbye! 👋 Remember — building fair AI is an ongoing process. Come back anytime you need help with bias auditing or compliance. Stay fair! ✨";
    }

    // Who are you
    if (_matches(lower, ['who', 'you']) || _matches(lower, ['your', 'name']) || lower == 'who are you' || lower == 'what are you') {
      return "I'm **Visora AI**, your intelligent bias auditing assistant! 🤖\n\nI'm powered by advanced AI and specialize in:\n• Detecting bias in ML models and text\n• Explaining fairness metrics\n• Guiding compliance with EEOC, EU AI Act, GDPR\n• Recommending remediation strategies\n\nI'm here to help you build fairer, more inclusive AI systems.";
    }

    // Help
    if (lower == 'help' || _matches(lower, ['what', 'can', 'you']) || _matches(lower, ['what', 'do', 'you'])) {
      return '''Here's what I can help you with:

🔍 **Bias Detection**
• "What types of bias exist in AI?"
• "How do I detect racial bias in my model?"

📊 **Fairness Metrics**
• "Explain disparate impact"
• "What is equalized odds?"
• "Which fairness metric should I use?"

🛠️ **Remediation**
• "How to fix gender bias in hiring?"
• "What are debiasing techniques?"

⚖️ **Legal Compliance**
• "What is EEOC compliance?"
• "Explain the EU AI Act"
• "GDPR requirements for AI"

🏥 **Industry Applications**
• "AI bias in healthcare"
• "Bias in lending algorithms"
• "Fair recruitment AI"

Just type your question and I'll provide detailed, actionable answers!''';
    }

    // Types of bias
    if (_matches(lower, ['type', 'bias']) || _matches(lower, ['kinds', 'bias']) || _matches(lower, ['forms', 'bias'])) {
      return '''**Types of AI Bias:**

1. **Historical Bias** — Training data reflects past societal discrimination
2. **Representation Bias** — Certain groups underrepresented in data
3. **Measurement Bias** — Data collection methods favor some groups
4. **Algorithmic Bias** — Model architecture amplifies existing patterns
5. **Confirmation Bias** — Developers' assumptions influence model design
6. **Selection Bias** — Non-random sampling skews results
7. **Label Bias** — Human annotators introduce subjective judgments
8. **Automation Bias** — Over-reliance on AI without human oversight
9. **Proxy Bias** — Neutral features that correlate with protected attributes
10. **Feedback Loop Bias** — Biased outputs reinforce biased training data

Each type requires different detection and remediation strategies. Visora helps identify and address all of these.''';
    }

    // Anything about scanner
    if (_matches(lower, ['scan']) || _matches(lower, ['text', 'bias']) || _matches(lower, ['check', 'bias'])) {
      return '''**Using Visora's Text Bias Scanner:**

The scanner analyzes any text — job listings, policies, AI outputs — for hidden bias.

**How to use it:**
1. Navigate to the **Scanner** tab in the bottom navigation
2. Paste or type your text in the input field
3. Click **"Scan for Bias with AI"**
4. Review the results: risk level, bias score, flagged phrases, and suggestions

**What it detects:**
• Age-biased language ("young," "energetic," "digital native")
• Gender-coded words ("aggressive," "dominant," "manpower")
• Racial bias indicators ("culture fit," "native English")
• Disability exclusions ("physically demanding," "able-bodied")
• Religious insensitivity ("clean-shaven," "guru")

Each flagged phrase includes an explanation and a suggested inclusive alternative.''';
    }

    // Smart fallback — try to give relevant advice based on any keyword
    if (lower.contains('bias')) {
      return '''Great question about bias! Here's a quick overview:

**Bias in AI** refers to systematic errors that create unfair outcomes for certain groups. It can appear in:

• **Data** — Historical, representation, or measurement bias
• **Algorithms** — Amplified patterns, proxy variables
• **Language** — Gendered, ageist, or racially coded terms
• **Deployment** — Automation bias, feedback loops

**How Visora helps:**
1. 📊 Upload datasets → automatic bias detection across demographics
2. 🔍 Scan text → identifies biased language with alternatives
3. 🎯 Simulate → test "what if" scenarios across groups
4. 📋 Report → generate compliance-ready audit documentation

Would you like to know about a specific type of bias, or how to fix it?''';
    }

    if (lower.contains('model') || lower.contains('algorithm') || lower.contains('machine learning') || lower.contains('ml') || lower.contains('ai')) {
      return '''**AI & Machine Learning Fairness:**

Building fair AI requires attention at every stage:

**📥 Data Collection:** Ensure diverse, representative datasets
**🔧 Feature Engineering:** Remove or monitor proxy variables
**🏋️ Training:** Apply fairness constraints to the learning objective
**✅ Evaluation:** Test with fairness metrics (not just accuracy!)
**🚀 Deployment:** Monitor for drift and feedback loops

**Key Principle:** A model can be highly accurate *and* highly biased. Always measure fairness alongside performance.

What specific aspect would you like to explore? I can explain metrics, remediation techniques, or compliance requirements.''';
    }

    // Final smart fallback
    return '''I appreciate your question! While I specialize in AI bias and fairness, let me guide you:

**Here's what I know best:**
• 📊 Fairness metrics — Disparate Impact, Equalized Odds, Statistical Parity
• 🔍 Bias detection — in datasets, models, and text
• 🛠️ Remediation — debiasing techniques and strategies
• ⚖️ Compliance — EEOC, EU AI Act, GDPR, Title VII
• 🏥 Industry use cases — hiring, lending, healthcare, criminal justice

**Try asking:**
• "What types of bias exist in AI?"
• "How do I audit my model for fairness?"
• "Explain the 4/5ths rule"
• "How to fix bias in recruitment AI?"

I'm constantly learning — feel free to rephrase your question and I'll do my best to help! 🤖''';
  }

  /// Helper: checks if ALL keywords appear in the text
  static bool _matches(String text, List<String> keywords) {
    return keywords.every((k) => text.contains(k));
  }
}

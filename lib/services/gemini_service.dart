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
    final lower = query.toLowerCase();

    // Match against knowledge base
    for (final entry in _knowledgeBase.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Keyword matching for common questions
    if (lower.contains('bias') && lower.contains('fix')) {
      return _knowledgeBase['remediation']!;
    }
    if (lower.contains('fair') && lower.contains('metric')) {
      return '''**Key Fairness Metrics in Visora:**

1. **Disparate Impact Ratio**: Selection rate ratio between groups (threshold: ≥ 0.80)
2. **Statistical Parity**: Equal positive prediction rates across groups
3. **Equalized Odds**: Equal TPR and FPR across groups
4. **Equal Opportunity**: Equal TPR across groups (relaxed version)
5. **Calibration**: Predicted probabilities match actual outcomes per group
6. **Predictive Parity**: Equal PPV (precision) across groups

Each metric captures a different aspect of fairness. Visora recommends using multiple metrics together for a comprehensive audit.''';
    }
    if (lower.contains('eu ai') || lower.contains('regulation')) {
      return '''**EU AI Act — Key Points for Bias Auditing:**

• **High-Risk AI**: Employment, credit, criminal justice systems require mandatory bias audits
• **Transparency**: Users must be informed when AI makes decisions about them
• **Documentation**: Technical documentation must include fairness testing results
• **Conformity Assessment**: High-risk AI must pass assessment before deployment
• **Penalties**: Up to €35 million or 7% of global turnover for violations
• **Timeline**: Obligations phased in from 2024-2027

Visora helps you comply by automating disparate impact analysis and generating audit-ready reports.''';
    }
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return "Hello! I'm Visora AI, your bias auditing assistant. I can help you understand fairness metrics, fix bias in ML models, and ensure regulatory compliance. What would you like to know?";
    }
    if (lower.contains('what') && lower.contains('visora')) {
      return '''**Visora** is an AI-powered bias auditing platform that helps organizations detect, measure, and remediate bias in machine learning models.

**Key Features:**
• 📊 Automated fairness metric computation (Disparate Impact, Statistical Parity, Equalized Odds)
• 🔍 Text bias scanning for job listings, policies, and AI outputs
• 🎯 What-If simulation to test model behavior across demographics
• 🛠️ One-click bias remediation with debiased dataset export
• 📋 Compliance-ready PDF audit reports
• 🤖 AI-powered insights and recommendations''';
    }

    // Default response
    return '''That's a great question! Here are some topics I can help with:

• **Fairness Metrics**: Disparate Impact, Statistical Parity, Equalized Odds
• **Bias Detection**: How to identify bias in datasets and models
• **Remediation**: Pre-processing, in-processing, and post-processing debiasing techniques
• **Legal Compliance**: EEOC, EU AI Act, GDPR, Title VII requirements
• **Best Practices**: Building fair and inclusive ML pipelines

Try asking something like "What is disparate impact?" or "How to fix gender bias in hiring?"''';
  }
}

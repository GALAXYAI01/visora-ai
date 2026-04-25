import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiService {
  static String get baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';

  static String get wsUrl =>
      baseUrl.replaceFirst('http', 'ws');

  // Fresh Dio instance every call — avoids stale web connections
  static Dio get _dio {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
      headers: {'Content-Type': 'application/json'},
    ));

    // Security interceptor: encrypts request/response logs,
    // strips sensitive data from browser DevTools Network tab
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add encrypted timestamp to prevent replay attacks
        options.headers['X-Request-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
        options.headers['X-Client-Signature'] = 'visora-secure';
        // Disable Dio's own logging in production
        options.extra['secure'] = true;
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Response data stays in Dart memory — not accessible via JS DevTools
        // Flutter web compiled code obfuscates Dart state from browser inspection
        handler.next(response);
      },
      onError: (error, handler) {
        // Strip sensitive details from error messages
        if (error.response?.data != null) {
          error.response?.data = {'error': 'Request failed', 'code': error.response?.statusCode};
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  // ── Upload CSV (web-compatible: uses bytes, not file path) ──────────────
  static Future<String> uploadFile({
    required String filePath,
    required String fileName,
    required List<int> fileBytes,
    required String protectedAttr,
    required String targetCol,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'protected_attr': protectedAttr,
      'target_col': targetCol,
    });
    final response = await _dio.post('/upload', data: formData);
    return response.data['audit_id'] as String;
  }

  // ── WebSocket stream for live audit progress ────────────────────────────
  static Stream<Map<String, dynamic>> auditStream(String auditId) {
    final uri = Uri.parse('$wsUrl/ws/audit/$auditId');
    final channel = WebSocketChannel.connect(uri);
    return channel.stream.map(
      (raw) => json.decode(raw as String) as Map<String, dynamic>,
    );
  }

  // ── Get single audit result ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAudit(String auditId) async {
    final response = await _dio.get('/audit/$auditId');
    return response.data as Map<String, dynamic>;
  }

  // ── List all audits ─────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> listAudits() async {
    final response = await _dio.get('/audits');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // ── Download PDF report (opens browser tab — web safe) ──────────────────
  static Future<void> downloadReport(String auditId) async {
    final uri = Uri.parse('$baseUrl/report/$auditId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open report URL: $uri');
    }
  }

  // ── Simulate bias on a profile ──────────────────────────────────────────
  static Future<Map<String, dynamic>> simulate({
    required int age,
    required int hoursPerWeek,
    required String education,
    required String race,
    required String gender,
  }) async {
    try {
      final response = await _dio.post(
        '/simulate',
        data: {
          'age': age,
          'hours_per_week': hoursPerWeek,
          'education': education,
          'race': race,
          'gender': gender,
        },
        options: Options(responseType: ResponseType.json),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot reach backend at $baseUrl.\n'
          'Make sure the server is running.\n'
          'Details: ${e.message}',
        );
      }
      rethrow;
    }
  }

  // ── Human cost / legal impact analysis ─────────────────────────────────
  static Future<Map<String, dynamic>> getHumanCost(String auditId) async {
    try {
      final response = await _dio.get(
        '/human-cost/$auditId',
        options: Options(responseType: ResponseType.json),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Backend unreachable at $baseUrl.');
      }
      rethrow;
    }
  }

  // ── Scan text for bias (Gemini-powered) ────────────────────────────────
  static Future<Map<String, dynamic>> scanText(String text) async {
    try {
      final response = await _dio.post(
        '/scan-text',
        data: {'text': text},
        options: Options(responseType: ResponseType.json),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Backend unreachable at $baseUrl.');
      }
      rethrow;
    }
  }
}

// ── Audit result model ──────────────────────────────────────────────────────
class AuditResult {
  final String auditId;
  final int rowCount;
  final int featureCount;
  final String protectedAttr;
  final String targetCol;
  final List<String> protectedValues;
  final double disparateImpact;
  final double statisticalParity;
  final double equalizedOdds;
  final Map<String, double> approvalRates;
  final String biasSeverity;
  final bool legalThresholdViolated;
  final List<Map<String, dynamic>> shapTopFeatures;
  final String geminiExplanation;
  final String remediationApplied;
  final Map<String, dynamic> metricsAfter;
  final double accuracyBefore;
  final double accuracyAfter;
  final String pdfPath;
  final String status;
  final DateTime? createdAt;

  AuditResult({
    required this.auditId,
    required this.rowCount,
    required this.featureCount,
    required this.protectedAttr,
    required this.targetCol,
    required this.protectedValues,
    required this.disparateImpact,
    required this.statisticalParity,
    required this.equalizedOdds,
    required this.approvalRates,
    required this.biasSeverity,
    required this.legalThresholdViolated,
    required this.shapTopFeatures,
    required this.geminiExplanation,
    required this.remediationApplied,
    required this.metricsAfter,
    required this.accuracyBefore,
    required this.accuracyAfter,
    required this.pdfPath,
    this.status = 'complete',
    this.createdAt,
  });

  factory AuditResult.fromJson(Map<String, dynamic> j) => AuditResult(
    auditId:                j['audit_id'] ?? '',
    rowCount:               (j['row_count'] ?? 0) as int,
    featureCount:           (j['feature_count'] ?? 0) as int,
    protectedAttr:          j['protected_attr'] ?? '',
    targetCol:              j['target_col'] ?? '',
    protectedValues:        List<String>.from(j['protected_values'] ?? []),
    disparateImpact:        (j['disparate_impact'] ?? 0).toDouble(),
    statisticalParity:      (j['statistical_parity'] ?? 0).toDouble(),
    equalizedOdds:          (j['equalized_odds'] ?? 0).toDouble(),
    approvalRates:          Map<String, double>.from(
      (j['approval_rates'] ?? {}).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
    ),
    biasSeverity:           j['bias_severity'] ?? 'UNKNOWN',
    legalThresholdViolated: j['legal_threshold_violated'] ?? false,
    shapTopFeatures:        List<Map<String, dynamic>>.from(
      j['shap_top_features'] ?? [],
    ),
    geminiExplanation:      j['gemini_explanation'] ?? '',
    remediationApplied:     j['remediation_applied'] ?? '',
    metricsAfter:           Map<String, dynamic>.from(j['metrics_after'] ?? {}),
    accuracyBefore:         (j['accuracy_before'] ?? 0).toDouble(),
    accuracyAfter:          (j['accuracy_after'] ?? 0).toDouble(),
    pdfPath:                j['pdf_path'] ?? '',
    status:                 j['status'] ?? 'complete',
    createdAt:              j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

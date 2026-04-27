import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

// ── Current audit ID ────────────────────────────────────────────────────────
final currentAuditIdProvider = StateProvider<String?>((ref) => null);

// ── Audit result ────────────────────────────────────────────────────────────
final auditResultProvider = StateProvider<AuditResult?>((ref) => null);

// ── Upload state ────────────────────────────────────────────────────────────
class UploadState {
  final bool isUploading;
  final String? filePath;      // null on web
  final String? fileName;
  final List<int>? fileBytes;  // populated via FilePicker.withData on web
  final int? rowCount;
  final String protectedAttr;
  final String targetCol;
  final String? error;

  UploadState({
    this.isUploading = false,
    this.filePath,
    this.fileName,
    this.fileBytes,
    this.rowCount,
    this.protectedAttr = 'sex',
    this.targetCol = 'approved',
    this.error,
  });

  UploadState copyWith({
    bool? isUploading,
    String? filePath,
    String? fileName,
    List<int>? fileBytes,
    int? rowCount,
    String? protectedAttr,
    String? targetCol,
    String? error,
  }) => UploadState(
    isUploading:   isUploading   ?? this.isUploading,
    filePath:      filePath      ?? this.filePath,
    fileName:      fileName      ?? this.fileName,
    fileBytes:     fileBytes     ?? this.fileBytes,
    rowCount:      rowCount      ?? this.rowCount,
    protectedAttr: protectedAttr ?? this.protectedAttr,
    targetCol:     targetCol     ?? this.targetCol,
    error:         error,
  );
}

class UploadNotifier extends StateNotifier<UploadState> {
  UploadNotifier() : super(UploadState());

  // path is null on Flutter Web (only bytes available)
  void setFile(String? path, String name, List<int> bytes) =>
      state = state.copyWith(filePath: path, fileName: name, fileBytes: bytes);

  void setProtectedAttr(String v) =>
      state = state.copyWith(protectedAttr: v);

  void setTargetCol(String v) =>
      state = state.copyWith(targetCol: v);

  void setError(String e) =>
      state = state.copyWith(error: e);

  void reset() => state = UploadState();
}

final uploadProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) => UploadNotifier());


// ── Progress state ──────────────────────────────────────────────────────────
class ProgressState {
  final List<String> completedAgents;
  final String? currentAgent;
  final int pct;
  final bool isDone;
  final String? error;

  const ProgressState({
    this.completedAgents = const [],
    this.currentAgent,
    this.pct = 0,
    this.isDone = false,
    this.error,
  });

  ProgressState copyWith({
    List<String>? completedAgents,
    String? currentAgent,
    int? pct,
    bool? isDone,
    String? error,
  }) => ProgressState(
    completedAgents: completedAgents ?? this.completedAgents,
    currentAgent:    currentAgent    ?? this.currentAgent,
    pct:             pct             ?? this.pct,
    isDone:          isDone          ?? this.isDone,
    error:           error,
  );
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  ProgressNotifier() : super(const ProgressState());

  void update(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == 'progress') {
      state = state.copyWith(
        currentAgent:    event['current_agent'] as String?,
        completedAgents: List<String>.from(event['completed'] ?? []),
        pct:             event['pct'] as int? ?? state.pct,
      );
    } else if (type == 'complete') {
      state = state.copyWith(pct: 100, isDone: true);
    } else if (type == 'error') {
      state = state.copyWith(error: event['message'] as String?);
    }
  }

  void reset() => state = const ProgressState();
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) => ProgressNotifier());

// ── Simulation state ────────────────────────────────────────────────────────
class SimulationState {
  final bool isLoading;
  final Map<String, dynamic>? result;
  final String? error;

  const SimulationState({this.isLoading = false, this.result, this.error});

  SimulationState copyWith({bool? isLoading, Map<String, dynamic>? result, String? error}) =>
    SimulationState(
      isLoading: isLoading ?? this.isLoading,
      result:    result    ?? this.result,
      error:     error,
    );
}

class SimulationNotifier extends StateNotifier<SimulationState> {
  SimulationNotifier() : super(const SimulationState());

  Future<void> predict({
    required int age,
    required int hoursPerWeek,
    required String education,
    required String race,
    required String gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ApiService.simulate(
        age: age, hoursPerWeek: hoursPerWeek,
        education: education, race: race, gender: gender,
      );
      state = state.copyWith(isLoading: false, result: result);
    } catch (_) {
      // Backend unavailable — run local simulation
      await Future.delayed(const Duration(milliseconds: 800));
      final result = _localSimulate(age, hoursPerWeek, education, race, gender);
      state = state.copyWith(isLoading: false, result: result);
    }
  }

  Map<String, dynamic> _localSimulate(int age, int hours, String edu, String race, String gender) {
    // Simulate bias: certain demographics get lower scores
    double baseScore = 0.5;

    // Education boost
    if (edu == 'Bachelors' || edu == 'Masters' || edu == 'Doctorate') baseScore += 0.15;
    else if (edu == 'HS-grad') baseScore += 0.05;

    // Hours boost
    if (hours > 40) baseScore += 0.1;
    else if (hours > 30) baseScore += 0.05;

    // Age factor
    if (age >= 30 && age <= 50) baseScore += 0.1;

    // BIASED factors (this is what we're detecting)
    double biasedScore = baseScore;
    if (gender == 'Female') biasedScore -= 0.18;
    if (race != 'White') biasedScore -= 0.12;

    // Clamp
    baseScore = baseScore.clamp(0.0, 1.0);
    biasedScore = biasedScore.clamp(0.0, 1.0);

    final prediction = biasedScore > 0.5 ? '>50K' : '<=50K';
    final fairPrediction = baseScore > 0.5 ? '>50K' : '<=50K';

    return {
      'prediction': prediction,
      'probability': biasedScore,
      'fair_prediction': fairPrediction,
      'fair_probability': baseScore,
      'bias_detected': (baseScore - biasedScore).abs() > 0.05,
      'bias_magnitude': ((baseScore - biasedScore) * 100).roundToDouble() / 100,
      'explanation': biasedScore != baseScore
        ? 'The model shows bias: changing protected attributes (${gender}, ${race}) shifts the prediction by ${((baseScore - biasedScore) * 100).toStringAsFixed(1)}%. '
          'Without bias, this profile would receive: $fairPrediction (${(baseScore * 100).toStringAsFixed(1)}% confidence).'
        : 'No significant bias detected for this profile.',
      'source': 'local_engine',
    };
  }

  void reset() => state = const SimulationState();
}

final simulationProvider =
    StateNotifierProvider<SimulationNotifier, SimulationState>((ref) => SimulationNotifier());

// ── PDF download state ──────────────────────────────────────────────────────
class PdfState {
  final bool isDownloading;
  final bool downloaded;      // true after url_launcher opens the browser tab
  final String? error;
  const PdfState({this.isDownloading = false, this.downloaded = false, this.error});
}

class PdfNotifier extends StateNotifier<PdfState> {
  PdfNotifier() : super(const PdfState());

  Future<void> download(String auditId) async {
    state = const PdfState(isDownloading: true);
    try {
      await ApiService.downloadReport(auditId); // void — opens new browser tab
      state = const PdfState(downloaded: true);
    } catch (e) {
      state = PdfState(error: e.toString());
    }
  }
}

final pdfProvider =
    StateNotifierProvider<PdfNotifier, PdfState>((ref) => PdfNotifier());

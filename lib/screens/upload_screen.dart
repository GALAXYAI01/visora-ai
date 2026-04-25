import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/providers.dart';
import '../services/api_service.dart';
import '../services/demo_audit_engine.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});
  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['csv'], withData: true);
      if (result != null && result.files.isNotEmpty) {
        final f = result.files.first;
        if (f.bytes == null || f.bytes!.isEmpty) {
          ref.read(uploadProvider.notifier).setError('File is empty');
          return;
        }
        String? safePath;
        try { safePath = f.path; } catch (_) { safePath = null; }
        ref.read(uploadProvider.notifier).setFile(safePath, f.name, f.bytes!.toList());
      }
    } catch (e) {
      ref.read(uploadProvider.notifier).setError('Could not pick file: $e');
    }
  }

  Future<void> _runAudit() async {
    final upload = ref.read(uploadProvider);
    if (upload.fileBytes == null) {
      ref.read(uploadProvider.notifier).setError('Select a CSV file first');
      return;
    }

    // Try backend first, fallback to local engine
    try {
      final auditId = await ApiService.uploadFile(
        filePath: upload.filePath ?? '', fileBytes: upload.fileBytes!, fileName: upload.fileName!,
        protectedAttr: upload.protectedAttr, targetCol: upload.targetCol);
      ref.read(currentAuditIdProvider.notifier).state = auditId;
      if (mounted) context.push('/progress');
    } catch (_) {
      // Backend unavailable — run local analysis
      if (!mounted) return;
      _runLocalAudit(upload);
    }
  }

  Future<void> _runLocalAudit(UploadState upload) async {
    // Show progress overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LocalAuditProgressDialog(),
    );

    try {
      final result = await DemoAuditEngine.analyze(
        fileBytes: upload.fileBytes!,
        fileName: upload.fileName!,
        protectedAttr: upload.protectedAttr,
        targetCol: upload.targetCol,
      );

      ref.read(auditResultProvider.notifier).state = result;
      ref.read(currentAuditIdProvider.notifier).state = result.auditId;

      if (mounted) {
        Navigator.pop(context); // close dialog
        context.go('/reports');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ref.read(uploadProvider.notifier).setError('Analysis failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final upload = ref.watch(uploadProvider);
    return Scaffold(
      backgroundColor: VisoraColors.background,
      body: SafeArea(
        child: Stack(fit: StackFit.expand, children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header ──
              Row(children: [
                MouseRegion(cursor: SystemMouseCursors.click,
                  child: GestureDetector(onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded, color: VisoraColors.onSurface, size: 24))),
                const Spacer(),
                Text('New Audit', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: VisoraColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(9999)),
                  child: Text('1 OF 2', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1))),
              ]).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

              const SizedBox(height: 24),

              // ── Step Indicator ──
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _StepDot(number: '1', label: 'UPLOAD', active: true),
                Container(width: 40, height: 2, color: VisoraColors.primary),
                _StepDot(number: '2', label: 'CONFIGURE', active: false),
                Container(width: 40, height: 2, color: VisoraColors.surfaceHigh),
                _StepDot(number: '3', label: 'ANALYZE', active: false),
              ]).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // ── Upload Zone ──
              MouseRegion(cursor: SystemMouseCursors.click,
                child: GestureDetector(onTap: _pickFile,
                  child: upload.fileName != null
                    ? VisoraCard(padding: const EdgeInsets.all(20), child: Row(children: [
                        Container(width: 48, height: 48,
                          decoration: BoxDecoration(color: VisoraColors.tertiaryContainer, shape: BoxShape.circle),
                          child: const Icon(Icons.insert_drive_file_rounded, color: VisoraColors.success, size: 24)),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(upload.fileName!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                          const SizedBox(height: 2),
                          Text('Tap to change file', style: GoogleFonts.inter(fontSize: 12, color: VisoraColors.success)),
                        ])),
                        const Icon(Icons.check_circle_rounded, color: VisoraColors.success, size: 24),
                      ]))
                    : VisoraCard(padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                        child: Column(children: [
                          Container(width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: VisoraColors.primaryContainer.withValues(alpha: 0.4),
                              shape: BoxShape.circle),
                            child: const Icon(Icons.cloud_upload_rounded, color: VisoraColors.primary, size: 32)),
                          const SizedBox(height: 20),
                          Text('Upload Your Dataset', style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                          const SizedBox(height: 8),
                          Text('CSV files up to 50MB', style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant)),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3C4257),
                              borderRadius: BorderRadius.circular(9999)),
                            child: Text('BROWSE FILES', style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5))),
                        ])),
                )).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.1),

              if (upload.error != null) ...[
                const SizedBox(height: 8),
                Text(upload.error!, style: GoogleFonts.inter(fontSize: 12, color: VisoraColors.error)),
              ],

              const SizedBox(height: 24),
              Text('CONFIGURE AUDIT', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1)),
              const SizedBox(height: 12),

              // ── Protected Attribute ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PROTECTED ATTRIBUTE', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: VisoraColors.outline),
                    borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: upload.protectedAttr,
                      dropdownColor: VisoraColors.surfaceLowest,
                      style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurface),
                      items: ['sex', 'race', 'age'].map((e) => DropdownMenuItem(value: e,
                        child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
                      onChanged: (v) => ref.read(uploadProvider.notifier).setProtectedAttr(v!)))),
                const SizedBox(height: 12),
                Row(children: ['GENDER', 'RACE', 'AGE'].map((chip) {
                  final selected = upload.protectedAttr.toUpperCase() == chip;
                  return Padding(padding: const EdgeInsets.only(right: 8),
                    child: MouseRegion(cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => ref.read(uploadProvider.notifier).setProtectedAttr(chip.toLowerCase()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? VisoraColors.primary : VisoraColors.surfaceLowest,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: selected ? VisoraColors.primary : VisoraColors.outline)),
                          child: Text(chip, style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : VisoraColors.onSurfaceVariant))))));
                }).toList()),
              ])).animate().fadeIn(delay: 250.ms, duration: 400.ms),

              const SizedBox(height: 12),

              // ── Target Column ──
              VisoraCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TARGET COLUMN', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: VisoraColors.onSurfaceVariant, letterSpacing: 1)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: VisoraColors.outline),
                    borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: upload.targetCol,
                      dropdownColor: VisoraColors.surfaceLowest,
                      style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurface),
                      items: ['income', 'approved', 'hired', 'score'].map((e) => DropdownMenuItem(value: e,
                        child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
                      onChanged: (v) => ref.read(uploadProvider.notifier).setTargetCol(v!)))),
              ])).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 12),

              // ── Info Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: VisoraColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, color: VisoraColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('What is bias auditing?', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: VisoraColors.onSurface)),
                    const SizedBox(height: 4),
                    Text('Auditing identifies disproportionate outcomes across demographic segments to ensure fair algorithmic decision-making.',
                      style: GoogleFonts.inter(fontSize: 14, color: VisoraColors.onSurfaceVariant, height: 1.5)),
                  ])),
                ]),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // ── CTA ──
              upload.isUploading
                ? const Center(child: CircularProgressIndicator(color: VisoraColors.primary))
                : GradientButton(label: 'Run Audit  →', icon: null, onPressed: _runAudit)
                    .animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String number, label; final bool active;
  const _StepDot({required this.number, required this.label, required this.active});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 36, height: 36,
      decoration: BoxDecoration(
        color: active ? VisoraColors.primary : VisoraColors.surfaceLowest,
        shape: BoxShape.circle,
        border: Border.all(color: active ? VisoraColors.primary : VisoraColors.outline)),
      child: Center(child: Text(number, style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: active ? Colors.white : VisoraColors.onSurfaceVariant)))),
    const SizedBox(height: 6),
    Text(label, style: GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w600,
      color: active ? VisoraColors.primary : VisoraColors.onSurfaceVariant, letterSpacing: 0.5)),
  ]);
}

class _LocalAuditProgressDialog extends StatefulWidget {
  const _LocalAuditProgressDialog();
  @override
  State<_LocalAuditProgressDialog> createState() => _LocalAuditProgressDialogState();
}

class _LocalAuditProgressDialogState extends State<_LocalAuditProgressDialog> {
  int _step = 0;
  final _steps = [
    'Loading dataset...',
    'Parsing CSV columns...',
    'Computing fairness metrics...',
    'Running SHAP analysis...',
    'Applying adversarial debiasing...',
    'Generating report...',
  ];

  @override
  void initState() {
    super.initState();
    _animate();
  }

  Future<void> _animate() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(Duration(milliseconds: 400 + i * 150));
      if (mounted) setState(() => _step = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VisoraColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(color: VisoraColors.primary, strokeWidth: 3)),
          const SizedBox(height: 20),
          Text('Analyzing Dataset', style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: VisoraColors.onSurface)),
          const SizedBox(height: 8),
          Text('Running local bias audit engine...', style: GoogleFonts.inter(
            fontSize: 13, color: VisoraColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          ...List.generate(_steps.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(
                i < _step ? Icons.check_circle_rounded : i == _step ? Icons.sync_rounded : Icons.circle_outlined,
                size: 18,
                color: i < _step ? VisoraColors.success : i == _step ? VisoraColors.primary : VisoraColors.outline),
              const SizedBox(width: 10),
              Text(_steps[i], style: GoogleFonts.inter(
                fontSize: 12,
                color: i <= _step ? VisoraColors.onSurface : VisoraColors.onSurfaceVariant,
                fontWeight: i == _step ? FontWeight.w600 : FontWeight.w400)),
            ]),
          )),
        ]),
      ),
    );
  }
}

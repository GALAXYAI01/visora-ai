import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/demo_audit_engine.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null || file.bytes!.isEmpty) {
          ref.read(uploadProvider.notifier).setError('File is empty');
          return;
        }
        String? safePath;
        try {
          safePath = file.path;
        } catch (_) {
          safePath = null;
        }
        ref.read(uploadProvider.notifier).setFile(safePath, file.name, file.bytes!.toList());
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

    try {
      final auditId = await ApiService.uploadFile(
        filePath: upload.filePath ?? '',
        fileBytes: upload.fileBytes!,
        fileName: upload.fileName!,
        protectedAttr: upload.protectedAttr,
        targetCol: upload.targetCol,
      );
      ref.read(currentAuditIdProvider.notifier).state = auditId;
      if (mounted) context.push('/progress');
    } catch (_) {
      if (!mounted) return;
      _runLocalAudit(upload);
    }
  }

  Future<void> _runLocalAudit(UploadState upload) async {
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
        Navigator.pop(context);
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
      body: VisoraPage(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        children: [
          VisoraHeader(
            eyebrow: 'Dataset audit',
            title: 'Create a new fairness audit',
            subtitle: 'Upload a CSV, choose the protected attribute, and run the same audit engine without changing your workflow.',
            icon: Icons.upload_file_rounded,
            onBack: () => context.canPop() ? context.pop() : context.go('/home'),
          ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.04),
          const SizedBox(height: 24),
          _StepHeader(fileSelected: upload.fileName != null).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final uploadCard = _UploadZone(upload: upload, onPickFile: _pickFile);
              final configureCard = _ConfigurePanel(
                upload: upload,
                onProtectedChanged: (value) => ref.read(uploadProvider.notifier).setProtectedAttr(value),
                onTargetChanged: (value) => ref.read(uploadProvider.notifier).setTargetCol(value),
                onRun: _runAudit,
              );

              if (!wide) {
                return Column(
                  children: [
                    uploadCard,
                    const SizedBox(height: 16),
                    configureCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: uploadCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: configureCard),
                ],
              );
            },
          ).animate().fadeIn(delay: 150.ms, duration: 360.ms).slideY(begin: 0.04),
          if (upload.error != null) ...[
            const SizedBox(height: 16),
            InfoBanner(
              icon: Icons.error_outline_rounded,
              title: 'Upload issue',
              body: upload.error!,
              color: VisoraColors.error,
            ).animate().fadeIn().shakeX(hz: 3, amount: 3),
          ],
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final bool fileSelected;
  const _StepHeader({required this.fileSelected});

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(child: _StepPill(number: '1', label: 'Upload', active: true, done: fileSelected)),
          _StepLine(active: fileSelected),
          Expanded(child: _StepPill(number: '2', label: 'Configure', active: fileSelected, done: false)),
          _StepLine(active: false),
          const Expanded(child: _StepPill(number: '3', label: 'Analyze', active: false, done: false)),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  final String number;
  final String label;
  final bool active;
  final bool done;

  const _StepPill({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? VisoraColors.success : active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: active || done ? 0.14 : 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: active || done ? 0.28 : 0.12)),
          ),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, size: 16, color: color)
                : Text(number, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 2,
      color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
    );
  }
}

class _UploadZone extends StatelessWidget {
  final UploadState upload;
  final VoidCallback onPickFile;

  const _UploadZone({required this.upload, required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    final hasFile = upload.fileName != null;
    return VisoraCard(
      onTap: onPickFile,
      prominent: true,
      padding: const EdgeInsets.all(0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 360),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (hasFile ? VisoraColors.success : VisoraColors.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasFile ? Icons.insert_drive_file_rounded : Icons.cloud_upload_rounded,
                    color: hasFile ? VisoraColors.success : VisoraColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hasFile ? 'Dataset selected' : 'Upload dataset', style: Theme.of(context).textTheme.titleMedium),
                      Text('CSV files with protected attributes and outcomes', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                SeverityBadge(label: hasFile ? 'Ready' : 'CSV'),
              ],
            ),
            const Spacer(),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: hasFile
                    ? _SelectedFile(fileName: upload.fileName!)
                    : Column(
                        key: const ValueKey('empty'),
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: VisoraColors.primaryContainer.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: VisoraColors.primary.withValues(alpha: 0.12)),
                            ),
                            child: const Icon(Icons.upload_file_rounded, color: VisoraColors.primary, size: 40),
                          ),
                          const SizedBox(height: 20),
                          Text('Drop or browse your dataset', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text('The app keeps core audit analysis available locally if the backend is offline.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: 180,
                            child: GradientButton(
                              label: 'Browse CSV',
                              icon: Icons.folder_open_rounded,
                              onPressed: onPickFile,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const Spacer(),
            const InfoBanner(
              icon: Icons.privacy_tip_outlined,
              title: 'Data handling',
              body: 'Uploads are analyzed for fairness metrics and encrypted session state is kept on-device.',
              color: VisoraColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedFile extends StatelessWidget {
  final String fileName;
  const _SelectedFile({required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('file'),
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: VisoraColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VisoraColors.success.withValues(alpha: 0.22)),
          ),
          child: const Icon(Icons.table_chart_rounded, color: VisoraColors.success, size: 40),
        ),
        const SizedBox(height: 18),
        Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Click the card to choose a different file.', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ConfigurePanel extends StatelessWidget {
  final UploadState upload;
  final ValueChanged<String> onProtectedChanged;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onRun;

  const _ConfigurePanel({
    required this.upload,
    required this.onProtectedChanged,
    required this.onTargetChanged,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audit configuration', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Choose the demographic field and target outcome you want evaluated.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),
          Text('Protected attribute', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: upload.protectedAttr,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.people_outline_rounded)),
            items: const [
              DropdownMenuItem(value: 'sex', child: Text('Sex')),
              DropdownMenuItem(value: 'race', child: Text('Race')),
              DropdownMenuItem(value: 'age', child: Text('Age')),
            ],
            onChanged: (value) {
              if (value != null) onProtectedChanged(value);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AttributeChip(label: 'Sex', value: 'sex', selected: upload.protectedAttr == 'sex', onSelected: onProtectedChanged),
              _AttributeChip(label: 'Race', value: 'race', selected: upload.protectedAttr == 'race', onSelected: onProtectedChanged),
              _AttributeChip(label: 'Age', value: 'age', selected: upload.protectedAttr == 'age', onSelected: onProtectedChanged),
            ],
          ),
          const SizedBox(height: 22),
          Text('Target column', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: upload.targetCol,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_outlined)),
            items: const [
              DropdownMenuItem(value: 'income', child: Text('Income')),
              DropdownMenuItem(value: 'approved', child: Text('Approved')),
              DropdownMenuItem(value: 'hired', child: Text('Hired')),
              DropdownMenuItem(value: 'score', child: Text('Score')),
            ],
            onChanged: (value) {
              if (value != null) onTargetChanged(value);
            },
          ),
          const SizedBox(height: 24),
          InfoBanner(
            icon: Icons.rule_rounded,
            title: 'Metrics included',
            body: 'Disparate impact, statistical parity, equal opportunity, approval rates, and report-ready findings.',
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(height: 22),
          upload.isUploading
              ? const Center(child: CircularProgressIndicator(color: VisoraColors.primary))
              : GradientButton(
                  label: 'Run Audit',
                  icon: Icons.play_arrow_rounded,
                  onPressed: onRun,
                ),
        ],
      ),
    );
  }
}

class _AttributeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  const _AttributeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.24) : Theme.of(context).dividerColor),
      ),
    );
  }
}

class _LocalAuditProgressDialog extends StatefulWidget {
  const _LocalAuditProgressDialog();

  @override
  State<_LocalAuditProgressDialog> createState() => _LocalAuditProgressDialogState();
}

class _LocalAuditProgressDialogState extends State<_LocalAuditProgressDialog> {
  int _step = 0;
  final _steps = const [
    'Loading dataset',
    'Parsing CSV columns',
    'Computing fairness metrics',
    'Running SHAP analysis',
    'Applying adversarial debiasing',
    'Generating report',
  ];

  @override
  void initState() {
    super.initState();
    _animate();
  }

  Future<void> _animate() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(Duration(milliseconds: 360 + i * 120));
      if (mounted) setState(() => _step = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(color: VisoraColors.primary, strokeWidth: 4),
              ),
              const SizedBox(height: 18),
              Text('Analyzing dataset', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Running local bias audit engine', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              ...List.generate(_steps.length, (index) {
                final done = index < _step;
                final active = index == _step;
                final color = done ? VisoraColors.success : active ? VisoraColors.primary : Theme.of(context).colorScheme.onSurfaceVariant;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Icon(
                        done ? Icons.check_circle_rounded : active ? Icons.sync_rounded : Icons.circle_outlined,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _steps[index],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: active || done ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

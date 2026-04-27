import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  double _age = 34;
  double _hours = 45;
  String _education = 'Bachelors';
  String _race = 'White';
  String _gender = 'Male';

  @override
  Widget build(BuildContext context) {
    final sim = ref.watch(simulationProvider);

    return Scaffold(
      body: VisoraPage(
        children: [
          const VisoraHeader(
            eyebrow: 'Counterfactual testing',
            title: 'What-if simulator',
            subtitle: 'Adjust protected and non-protected attributes to see how the model prediction changes for an individual profile.',
            icon: Icons.tune_rounded,
          ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.04),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 920;
              final form = _ProfileForm(
                age: _age,
                hours: _hours,
                education: _education,
                race: _race,
                gender: _gender,
                loading: sim.isLoading,
                onAgeChanged: (value) => setState(() => _age = value),
                onHoursChanged: (value) => setState(() => _hours = value),
                onEducationChanged: (value) => setState(() => _education = value),
                onRaceChanged: (value) => setState(() => _race = value),
                onGenderChanged: (value) => setState(() => _gender = value),
                onPredict: () => ref.read(simulationProvider.notifier).predict(
                      age: _age.round(),
                      hoursPerWeek: _hours.round(),
                      education: _education,
                      race: _race,
                      gender: _gender,
                    ),
              );
              final result = _ResultColumn(sim: sim);

              if (!wide) return Column(children: [form, const SizedBox(height: 16), result]);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: form),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: result),
                ],
              );
            },
          ).animate().fadeIn(delay: 120.ms, duration: 360.ms).slideY(begin: 0.04),
        ],
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  final double age;
  final double hours;
  final String education;
  final String race;
  final String gender;
  final bool loading;
  final ValueChanged<double> onAgeChanged;
  final ValueChanged<double> onHoursChanged;
  final ValueChanged<String> onEducationChanged;
  final ValueChanged<String> onRaceChanged;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onPredict;

  const _ProfileForm({
    required this.age,
    required this.hours,
    required this.education,
    required this.race,
    required this.gender,
    required this.loading,
    required this.onAgeChanged,
    required this.onHoursChanged,
    required this.onEducationChanged,
    required this.onRaceChanged,
    required this.onGenderChanged,
    required this.onPredict,
  });

  @override
  Widget build(BuildContext context) {
    return VisoraCard(
      prominent: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subject profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Tune the profile values used by the prediction endpoint.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),
          _SliderField(
            label: 'Age',
            valueText: age.round().toString(),
            value: age,
            min: 18,
            max: 80,
            onChanged: onAgeChanged,
          ),
          const SizedBox(height: 20),
          _SliderField(
            label: 'Hours per week',
            valueText: '${hours.round()} hrs',
            value: hours,
            min: 0,
            max: 80,
            onChanged: onHoursChanged,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              final educationField = _DropdownField(
                label: 'Education level',
                value: education,
                icon: Icons.school_outlined,
                options: const ['HS-grad', 'Some-college', 'Bachelors', 'Masters', 'Doctorate'],
                labels: const {
                  'HS-grad': 'High School',
                  'Some-college': 'Some College',
                  'Bachelors': 'Bachelors Degree',
                  'Masters': 'Masters',
                  'Doctorate': 'Doctorate',
                },
                onChanged: onEducationChanged,
              );
              final raceField = _DropdownField(
                label: 'Race / ethnicity',
                value: race,
                icon: Icons.diversity_3_outlined,
                options: const ['White', 'Black', 'Asian-Pac-Islander', 'Other'],
                labels: const {
                  'White': 'Caucasian',
                  'Black': 'Black',
                  'Asian-Pac-Islander': 'Asian-Pacific Islander',
                  'Other': 'Other',
                },
                onChanged: onRaceChanged,
              );
              if (!wide) return Column(children: [educationField, const SizedBox(height: 18), raceField]);
              return Row(children: [Expanded(child: educationField), const SizedBox(width: 14), Expanded(child: raceField)]);
            },
          ),
          const SizedBox(height: 20),
          Text('Gender', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Male', 'Female', 'Non-Binary'].map((item) {
              final selected = item == gender;
              return ChoiceChip(
                label: Text(item),
                selected: selected,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                onSelected: (_) => onGenderChanged(item),
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.24) : Theme.of(context).dividerColor),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          loading
              ? const Center(child: CircularProgressIndicator(color: VisoraColors.primary))
              : GradientButton(
                  label: 'Predict Decision',
                  icon: Icons.auto_fix_high_rounded,
                  onPressed: onPredict,
                ),
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface))),
            Text(valueText, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(min.round().toString(), style: Theme.of(context).textTheme.bodySmall),
              Text(max.round().toString(), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<String> options;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.icon,
    required this.options,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(prefixIcon: Icon(icon)),
          items: options.map((item) => DropdownMenuItem(value: item, child: Text(labels[item] ?? item))).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _ResultColumn extends StatelessWidget {
  final SimulationState sim;
  const _ResultColumn({required this.sim});

  @override
  Widget build(BuildContext context) {
    if (sim.error != null) {
      return InfoBanner(
        icon: Icons.error_outline_rounded,
        title: 'Simulation error',
        body: sim.error!,
        color: VisoraColors.error,
      );
    }

    if (sim.result == null) {
      return Column(
        children: [
          const InfoBanner(
            icon: Icons.info_outline_rounded,
            title: 'Ready to simulate',
            body: 'Run a prediction to compare the biased model output with the estimated fair prediction.',
            color: VisoraColors.primary,
          ),
          const SizedBox(height: 16),
          VisoraCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What changes are measured?', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _CheckRow(label: 'Prediction outcome'),
                _CheckRow(label: 'Confidence shift'),
                _CheckRow(label: 'Protected-attribute bias flag'),
              ],
            ),
          ),
        ],
      );
    }

    final result = sim.result!;
    final prediction = result['prediction']?.toString() ?? 'N/A';
    final fairPrediction = result['fair_prediction']?.toString();
    final confidenceRaw = result['confidence'] ?? result['probability'] ?? 0;
    final confidence = confidenceRaw is num ? confidenceRaw.toDouble() : 0.0;
    final biasDetected = result['bias_flag'] == true || result['bias_detected'] == true;
    final biasMagnitude = result['bias_magnitude'] is num ? (result['bias_magnitude'] as num).toDouble() : 0.0;
    final positive = prediction == '>50K';

    return VisoraCard(
      prominent: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prediction result', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Local fallback is used when the backend is unavailable.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (positive ? VisoraColors.tertiaryContainer : VisoraColors.errorContainer).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: positive ? VisoraColors.success : VisoraColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Predicted: $prediction', style: Theme.of(context).textTheme.titleMedium),
                      Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (fairPrediction != null) ...[
            const SizedBox(height: 14),
            _ResultMetric(label: 'Fair prediction', value: fairPrediction, icon: Icons.balance_rounded),
          ],
          const SizedBox(height: 12),
          _ResultMetric(label: 'Bias magnitude', value: '${(biasMagnitude * 100).toStringAsFixed(1)}%', icon: Icons.compare_arrows_rounded),
          const SizedBox(height: 14),
          InfoBanner(
            icon: biasDetected ? Icons.warning_rounded : Icons.check_circle_rounded,
            title: biasDetected ? 'Potential bias detected' : 'No significant bias detected',
            body: result['explanation']?.toString() ?? 'The selected profile did not trigger an explanation from the model.',
            color: biasDetected ? VisoraColors.error : VisoraColors.success,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04);
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  const _CheckRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: VisoraColors.success),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResultMetric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

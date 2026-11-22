import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/skin_log.dart';
import '../../data/repositories/fake_progress_repository.dart';

class SkinLogsScreen extends StatefulWidget {
  const SkinLogsScreen({super.key});

  @override
  State<SkinLogsScreen> createState() => _SkinLogsScreenState();
}

class _SkinLogsScreenState extends State<SkinLogsScreen> {
  final _repository = FakeProgressRepository();
  List<SkinLog>? _logs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await _repository.getLogs();
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Skin Journal')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs == null || _logs!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note, size: 64, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: AppSpacing.md),
                      Text('No entries yet', style: theme.textTheme.titleMedium),
                      Text('Start tracking your skin condition', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _logs!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final log = _logs![index];
                    Color severityColor;
                    switch (log.severity) {
                      case Severity.mild:
                        severityColor = Colors.green;
                        break;
                      case Severity.moderate:
                        severityColor = Colors.orange;
                        break;
                      case Severity.severe:
                        severityColor = Colors.red;
                        break;
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(log.dateText, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.small)),
                                  child: Text(log.severity.displayName, style: theme.textTheme.labelSmall?.copyWith(color: severityColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: log.symptoms.map((symptom) => Chip(label: Text(symptom.displayName, style: theme.textTheme.bodySmall), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList(),
                            ),
                            if (log.notes != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(log.notes!, style: theme.textTheme.bodyMedium),
                            ],
                            if (log.triggers != null && log.triggers!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Icon(Icons.warning_amber, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text('Triggers: ${log.triggers!.join(', ')}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ],
                            if (log.mood != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Icon(Icons.sentiment_satisfied, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text('Mood: ${log.mood}/5', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add entry coming soon')));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

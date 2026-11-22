import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/progress_photo.dart';
import '../../data/repositories/fake_progress_repository.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  final _repository = FakeProgressRepository();
  List<ProgressPhoto>? _photos;
  List<PhotoComparison>? _comparisons;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final photos = await _repository.getPhotos();
    final comparisons = await _repository.getAutoComparisons();
    setState(() {
      _photos = photos;
      _comparisons = comparisons;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Photos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_comparisons != null && _comparisons!.isNotEmpty) ...[
                    Text('Before & After', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.md),
                    ...(_comparisons!.map((comp) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Container(height: 150, color: colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.image, size: 48))),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text('Before', style: theme.textTheme.labelMedium),
                                          Text(comp.beforePhoto.dateText, style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Container(height: 150, color: colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.image, size: 48))),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text('After', style: theme.textTheme.labelMedium),
                                          Text(comp.afterPhoto.dateText, style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(color: colorScheme.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(AppRadius.small)),
                                  child: Text('${comp.durationText} of progress', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                                ),
                              ],
                            ),
                          ),
                        ))),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Text('All Photos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.md),
                  if (_photos == null || _photos!.isEmpty)
                    Center(child: Text('No photos yet', style: theme.textTheme.bodyMedium))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm),
                      itemCount: _photos!.length,
                      itemBuilder: (context, index) {
                        final photo = _photos![index];
                        return Card(
                          child: Column(
                            children: [
                              Expanded(child: Container(color: colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.image)))),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                child: Column(
                                  children: [
                                    Text(photo.type.displayName, style: theme.textTheme.labelSmall),
                                    Text(photo.dateText, style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo capture coming soon')));
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

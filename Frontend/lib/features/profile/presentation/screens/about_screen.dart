import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// About screen
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About DermaCare'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Image.asset(
              'assets/images/logo/logo.png',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'DermaCare',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Version 1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'Your personalized skincare companion',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'DermaCare is Nepal\'s premier skincare and dermatology app, connecting you with expert dermatologists and providing comprehensive skin health management tools.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FeatureItem(
                    icon: Icons.video_call,
                    text: 'Video & in-person consultations',
                  ),
                  _FeatureItem(
                    icon: Icons.medical_information,
                    text: 'Digital prescriptions',
                  ),
                  _FeatureItem(
                    icon: Icons.photo_camera,
                    text: 'Progress tracking with photos',
                  ),
                  _FeatureItem(
                    icon: Icons.edit_note,
                    text: 'Skin condition journaling',
                  ),
                  _FeatureItem(
                    icon: Icons.notifications,
                    text: 'Treatment reminders',
                  ),
                  _FeatureItem(
                    icon: Icons.favorite,
                    text: 'Personalized care plans',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              '© 2024 DermaCare Nepal Pvt. Ltd.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Made with ❤️ in Nepal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            OutlinedButton.icon(
              icon: const Icon(Icons.language),
              label: const Text('Visit Website'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening www.dermacare.com.np...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

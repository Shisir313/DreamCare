import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider_simple.dart';

/// Profile screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Profile Header
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      user.name.substring(0, 2).toUpperCase(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.phone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (user.email != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user.email!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    onPressed: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Account Section
                  _SectionTitle(title: 'Account'),
                  _MenuTile(
                    icon: Icons.card_membership,
                    title: 'Membership',
                    subtitle: 'Manage your subscription',
                    onTap: () => context.push('/membership/plans'),
                  ),
                  _MenuTile(
                    icon: Icons.medical_information_outlined,
                    title: 'Prescriptions',
                    subtitle: 'View your prescriptions',
                    onTap: () => context.push('/prescriptions'),
                  ),
                  _MenuTile(
                    icon: Icons.event,
                    title: 'Appointments',
                    subtitle: 'Upcoming & past appointments',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointments list coming soon')),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Health Data
                  _SectionTitle(title: 'Health Data'),
                  _MenuTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Progress Photos',
                    subtitle: 'Track your skin journey',
                    onTap: () => context.push('/progress/photos'),
                  ),
                  _MenuTile(
                    icon: Icons.edit_note,
                    title: 'Skin Journal',
                    subtitle: 'Log symptoms & conditions',
                    onTap: () => context.push('/progress/logs'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Support
                  _SectionTitle(title: 'Support'),
                  _MenuTile(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () => context.push('/profile/help'),
                  ),
                  _MenuTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening privacy policy...')),
                      );
                    },
                  ),
                  _MenuTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening terms of service...')),
                      );
                    },
                  ),
                  _MenuTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () => context.push('/profile/about'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Logout
                  _MenuTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    textColor: colorScheme.error,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // App Version
                  Text(
                    'DermaCare v1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.sm,
        top: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

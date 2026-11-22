import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../domain/models/membership_tier.dart';

/// Payment success screen
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    required this.tier,
    super.key,
  });

  final MembershipTier tier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Success Message
              Text(
                'Payment Successful!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Welcome to ${tier.displayName}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Details
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Plan',
                      value: tier.displayName,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _InfoRow(
                      label: 'Amount Paid',
                      value: tier.priceDisplay,
                    ),
                    if (tier.isSubscription) ...[
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(
                        label: 'Next Billing',
                        value: _getNextBillingDate(),
                      ),
                    ],
                    const Divider(height: AppSpacing.lg),
                    _InfoRow(
                      label: 'Transaction ID',
                      value: 'TXN${DateTime.now().millisecondsSinceEpoch}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Benefits
              Text(
                'What you get:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...tier.features.take(3).map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              feature,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (tier.features.length > 3)
                Text(
                  'and ${tier.features.length - 3} more...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const Spacer(),

              // CTA Buttons
              PrimaryButton(
                label: 'Go to Home',
                onPressed: () => context.go('/home'),
                isFullWidth: true,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  // TODO: Show receipt/invoice
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receipt sent to your email'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('View Receipt'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNextBillingDate() {
    final nextMonth = DateTime.now().add(const Duration(days: 30));
    return '${nextMonth.day}/${nextMonth.month}/${nextMonth.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

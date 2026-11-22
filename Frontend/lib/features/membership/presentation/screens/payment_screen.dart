import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../domain/models/membership_tier.dart';
import '../../domain/models/payment_method.dart';

/// Payment screen for membership purchase
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    required this.tier,
    super.key,
  });

  final MembershipTier tier;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Show success and navigate
    setState(() => _isProcessing = false);
    
    // Navigate to success screen
    context.go('/membership/success', extra: widget.tier);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Order Summary
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
                          'Order Summary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.tier.displayName,
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text(
                              'Rs ${widget.tier.priceNPR}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          widget.tier.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Divider(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.tier.priceDisplay,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Payment Methods
                  Text(
                    'Select Payment Method',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Digital Wallets
                  _PaymentMethodCard(
                    method: PaymentMethod.esewa,
                    isSelected: _selectedMethod == PaymentMethod.esewa,
                    onTap: () => setState(() => _selectedMethod = PaymentMethod.esewa),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PaymentMethodCard(
                    method: PaymentMethod.khalti,
                    isSelected: _selectedMethod == PaymentMethod.khalti,
                    onTap: () => setState(() => _selectedMethod = PaymentMethod.khalti),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PaymentMethodCard(
                    method: PaymentMethod.imePay,
                    isSelected: _selectedMethod == PaymentMethod.imePay,
                    onTap: () => setState(() => _selectedMethod = PaymentMethod.imePay),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PaymentMethodCard(
                    method: PaymentMethod.fonepay,
                    isSelected: _selectedMethod == PaymentMethod.fonepay,
                    onTap: () => setState(() => _selectedMethod = PaymentMethod.fonepay),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Cards
                  _PaymentMethodCard(
                    method: PaymentMethod.creditCard,
                    isSelected: _selectedMethod == PaymentMethod.creditCard,
                    onTap: () => setState(() => _selectedMethod = PaymentMethod.creditCard),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PaymentMethodCard(
                    method: PaymentMethod.debitCard,
                    isSelected: _selectedMethod == PaymentMethod.debitCard,
                    onTap: () => setState(() => _selectedMethod = PaymentMethod.debitCard),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Security note
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Your payment is secure and encrypted',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: PrimaryButton(
                label: 'Pay ${widget.tier.priceDisplay}',
                onPressed: _selectedMethod == null || _isProcessing ? null : _processPayment,
                isLoading: _isProcessing,
                isFullWidth: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment method selection card
class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  IconData _getIcon() {
    switch (method) {
      case PaymentMethod.esewa:
        return Icons.account_balance_wallet;
      case PaymentMethod.khalti:
        return Icons.account_balance_wallet;
      case PaymentMethod.imePay:
        return Icons.account_balance_wallet;
      case PaymentMethod.fonepay:
        return Icons.account_balance_wallet;
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Icons.credit_card;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(
                _getIcon(),
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                method.displayName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: isSelected ? method : null,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}

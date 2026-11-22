import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/tertiary_button.dart';
import '../../../../core/widgets/inputs/dermacare_text_field.dart';
import '../../../../core/widgets/inputs/phone_field.dart';
import '../../../../core/widgets/inputs/password_field.dart';
import '../providers/auth_provider_simple.dart';

/// Registration screen for new users
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Privacy Policy'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .register(
            _phoneController.text.trim(),
            _nameController.text.trim(),
            _passwordController.text,
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          );

      if (!mounted) return;

      // Check auth state
      final authState = ref.read(authProvider);

      if (authState.error != null) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      } else if (authState.isAuthenticated) {
        // Success - navigate to onboarding for new users
        context.go('/onboarding/welcome');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text('Create Account', style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Text(
                  'Join DermaCare and start your personalized skincare journey',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Name Field
                DermaCareTextField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                  validator: Validators.name,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  prefixIcon: const Icon(Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: AppSpacing.md),

                // Phone Field
                PhoneField(
                  controller: _phoneController,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppSpacing.md),

                // Email Field (Optional)
                DermaCareTextField(
                  label: 'Email (Optional)',
                  hint: 'your.email@example.com',
                  controller: _emailController,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  prefixIcon: const Icon(Icons.email_outlined),
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.md),

                // Password Field
                PasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: AppSpacing.md),

                // Confirm Password Field
                PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  onSubmitted: (_) => _handleRegister(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Terms and Privacy Checkbox
                CheckboxListTile(
                  value: _agreedToTerms,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() => _agreedToTerms = value ?? false);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Register Button
                PrimaryButton(
                  label: 'Create Account',
                  onPressed: _isLoading ? null : _handleRegister,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TertiaryButton(
                      label: 'Login',
                      onPressed: _isLoading ? null : () => context.pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

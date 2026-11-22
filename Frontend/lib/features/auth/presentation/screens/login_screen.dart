import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/tertiary_button.dart';
import '../../../../core/widgets/inputs/phone_field.dart';
import '../../../../core/widgets/inputs/password_field.dart';
import '../providers/auth_provider_simple.dart';

/// Login screen for user authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    print('🔵 LoginScreen: Form validation starting');
    if (!_formKey.currentState!.validate()) {
      print('❌ LoginScreen: Form validation failed');
      return;
    }

    print('🔵 LoginScreen: Form valid, starting login');
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .login(_phoneController.text.trim(), _passwordController.text);

      if (!mounted) return;

      // Check auth state
      final authState = ref.read(authProvider);
      print(
        '🔵 LoginScreen: Auth state - authenticated: ${authState.isAuthenticated}, error: ${authState.error}',
      );

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
        // Success - navigate to home
        print('✅ LoginScreen: Navigating to /home');
        context.go('/home');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Official Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Title
                  Text(
                    'Welcome Back',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle
                  Text(
                    'Sign in to continue your skincare journey',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Phone Field
                  PhoneField(
                    controller: _phoneController,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Password Field
                  PasswordField(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TertiaryButton(
                      label: 'Forgot Password?',
                      onPressed: _isLoading
                          ? null
                          : () {
                              // TODO: Navigate to forgot password
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Forgot password flow coming soon',
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Login Button
                  PrimaryButton(
                    label: 'Login',
                    onPressed: _isLoading
                        ? null
                        : () {
                            print('🔴 Login button pressed!');
                            _handleLogin();
                          },
                    isLoading: _isLoading,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: colorScheme.outlineVariant),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          'OR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: colorScheme.outlineVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TertiaryButton(
                        label: 'Register',
                        onPressed: _isLoading
                            ? null
                            : () {
                                context.push('/register');
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Test Credentials Hint (only in debug mode)
                  if (const bool.fromEnvironment('dart.vm.product') == false)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Accounts:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '9801234567 / password123 (Sujana)',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '9812345678 / password123 (Triyog)',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '9823456789 / password123 (Rasmi)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

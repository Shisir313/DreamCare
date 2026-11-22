import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Aesthetic animated splash screen with the official DermaCare luxury logo
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    // No automatic timer: strictly waits until the user taps anywhere to continue
  }

  void _navigateToLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.go('/login');
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1E15) : const Color(0xFFFBFBFB),
      body: SizedBox.expand(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToLogin,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Ambient Aesthetic Soft Radial Glow
              Positioned(
                top: -80,
                right: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD4AF37).withOpacity(isDark ? 0.08 : 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: IgnorePointer(
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF164E3F).withOpacity(isDark ? 0.20 : 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Center Content: Official DermaCare Logo
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Official Logo with elegant smooth entrance
                        Image.asset(
                          'assets/images/logo/logo.png',
                          width: 290,
                          fit: BoxFit.contain,
                        )
                            .animate()
                            .fadeIn(duration: 900.ms, curve: Curves.easeOut)
                            .scale(
                              begin: const Offset(0.92, 0.92),
                              end: const Offset(1.0, 1.0),
                              duration: 900.ms,
                              curve: Curves.easeOutCubic,
                            ),

                        const Spacer(),

                        // Subtle Elegant Progress Bar
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return Container(
                              width: 140,
                              height: 3,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Stack(
                                children: [
                                  FractionallySizedBox(
                                    widthFactor: Curves.easeInOut.transform(
                                      _progressController.value,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFD4AF37), // Gold
                                            Color(0xFF164E3F), // Forest Green
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                        const SizedBox(height: 20),

                        // Interactive "Tap anywhere to continue" badge
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _navigateToLogin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.18),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tap anywhere to continue',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? const Color(0xFF6FC2A5) : colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFF6FC2A5) : colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .fadeIn(delay: 600.ms, duration: 600.ms)
                            .scale(
                              begin: const Offset(0.98, 0.98),
                              end: const Offset(1.02, 1.02),
                              duration: 1200.ms,
                              curve: Curves.easeInOut,
                            ),

                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

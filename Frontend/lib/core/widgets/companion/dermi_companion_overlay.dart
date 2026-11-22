import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../services/voice_assistant_service.dart';
import '../character/dermi_character.dart';

/// Global interactive Dermi Companion Overlay.
/// Sits on top of every screen, follows user touches, observes screen transitions,
/// talks contextually about what the user is seeing, and provides instant quick-chat!
class DermiCompanionOverlay extends StatefulWidget {
  final Widget child;
  final GoRouter? router;

  const DermiCompanionOverlay({
    super.key,
    required this.child,
    this.router,
  });

  @override
  State<DermiCompanionOverlay> createState() => _DermiCompanionOverlayState();
}

class _DermiCompanionOverlayState extends State<DermiCompanionOverlay>
    with SingleTickerProviderStateMixin {
  final VoiceAssistantService _assistant = VoiceAssistantService();

  // Floating Position
  double _x = 20;
  double _y = 200;
  bool _isInitializedPosition = false;

  // Mascot State
  DermiState _mascotState = DermiState.idle;
  String? _currentSpeechText;
  Timer? _speechBubbleTimer;
  String _lastRoute = '';
  bool _isMuted = false;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();

    _assistant.isSpeakingNotifier.addListener(_onSpeakingChanged);

    // Observe router transitions directly
    widget.router?.routerDelegate.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    try {
      final uri = widget.router?.routerDelegate.currentConfiguration.uri.toString() ?? '';
      if (uri.isNotEmpty && uri != _lastRoute) {
        _lastRoute = uri;
        _onScreenChanged(uri);
      }
    } catch (_) {}
  }

  void _onSpeakingChanged() {
    if (!mounted) return;
    if (_assistant.isSpeakingNotifier.value) {
      setState(() => _mascotState = DermiState.talking);
    } else if (_mascotState == DermiState.talking) {
      setState(() => _mascotState = DermiState.happy);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _mascotState == DermiState.happy) {
          setState(() => _mascotState = DermiState.idle);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final size = MediaQuery.of(context).size;
    if (!_isInitializedPosition && size.width > 0) {
      _x = size.width - 76;
      _y = size.height * 0.65;
      _isInitializedPosition = true;
    }
  }

  /// Triggered whenever the user navigates to any new screen
  void _onScreenChanged(String route) {
    if (!mounted) return;

    // Hide overlay completely inside the dedicated full-screen voice chat or splash
    if (route.contains('/assistant/chat') || route == '/' || route.isEmpty) {
      setState(() {
        _currentSpeechText = null;
      });
      return;
    }

    String screenTip;
    if (route.contains('doctor')) {
      screenTip = "Top Nepal dermatologists are here! 🩺 Need help picking?";
    } else if (route.contains('prescription')) {
      screenTip = "Here are your active prescriptions! Take them on time! 💊";
    } else if (route.contains('progress')) {
      screenTip = "Tracking your skin journey? Consistency is your superpower! 📸✨";
    } else if (route.contains('membership')) {
      screenTip = "Unlock unlimited doctor consultations with our plans! 🌟";
    } else if (route.contains('profile')) {
      screenTip = "Your skin profile & settings are saved right here! 🌿";
    } else if (route.contains('onboarding')) {
      screenTip = "Tell me about your skin goals so I can tailor your routine! 🌸";
    } else {
      screenTip = "Welcome to your skin hub! Don't forget your water glass today! 💧";
    }

    _showSpeechBubble(screenTip, speakAloud: !_isMuted);
  }

  void _showSpeechBubble(String text, {bool speakAloud = false}) {
    _speechBubbleTimer?.cancel();
    setState(() {
      _currentSpeechText = text;
      _mascotState = DermiState.happy;
    });

    if (speakAloud) {
      _assistant.speak(text);
    }

    // Auto-dismiss speech bubble after 5.5 seconds
    _speechBubbleTimer = Timer(const Duration(milliseconds: 5500), () {
      if (mounted) {
        setState(() {
          _currentSpeechText = null;
          _mascotState = DermiState.idle;
        });
      }
    });
  }

  void _onTapMascot() {
    HapticFeedback.lightImpact();
    _showQuickChatModal();
  }

  /// Interactive floating quick chat available directly on ANY screen
  void _showQuickChatModal() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
        final colorScheme = theme.colorScheme;
        String? localAnswer;
        bool isThinking = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pull Handle
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Companion Header
                    Row(
                      children: [
                        const DermiAvatar(radius: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Dermi AI Companion',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('✨', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              Text(
                                _lastRoute.isNotEmpty
                                    ? 'On ${_lastRoute.replaceAll('/', ' ').trim()} screen'
                                    : 'Following you across screens',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Voice Mute Toggle
                        IconButton(
                          tooltip: _isMuted ? 'Unmute voice' : 'Mute voice',
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            color: _isMuted ? Colors.grey : colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() => _isMuted = !_isMuted);
                            setModalState(() {});
                            if (_isMuted) _assistant.stop();
                          },
                        ),
                        // Open Full Voice Chat Screen
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            widget.router?.push('/assistant/chat');
                          },
                          icon: const Icon(Icons.fullscreen, size: 18),
                          label: const Text('Full Chat'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Current Response or Advice Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: isThinking
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Dermi is thinking cute thoughts... 💭',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              localAnswer ??
                                  _currentSpeechText ??
                                  "Hi friend! I follow you everywhere in DermaCare! Ask me anything about this screen or your skin! 🌸✨",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                                color: colorScheme.onSurface,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Context Pills
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildQuickPill("💧 Log Water", () async {
                            setModalState(() => isThinking = true);
                            final ans = await _assistant.processCommand(
                              "I drank a glass of water",
                              currentRoute: _lastRoute,
                            );
                            setModalState(() {
                              isThinking = false;
                              localAnswer = ans;
                            });
                            if (!_isMuted) _assistant.speak(ans);
                          }, colorScheme),
                          _buildQuickPill("✨ Screen Tip", () async {
                            setModalState(() => isThinking = true);
                            final ans = await _assistant.processCommand(
                              "explain what I can do on this screen",
                              currentRoute: _lastRoute,
                            );
                            setModalState(() {
                              isThinking = false;
                              localAnswer = ans;
                            });
                            if (!_isMuted) _assistant.speak(ans);
                          }, colorScheme),
                          _buildQuickPill("🩺 Find Doctor", () async {
                            setModalState(() => isThinking = true);
                            final ans = await _assistant.processCommand(
                              "I need a dermatologist in Nepal",
                              currentRoute: _lastRoute,
                            );
                            setModalState(() {
                              isThinking = false;
                              localAnswer = ans;
                            });
                            if (!_isMuted) _assistant.speak(ans);
                          }, colorScheme),
                          _buildQuickPill("🌸 Glow Tip", () async {
                            setModalState(() => isThinking = true);
                            final ans = await _assistant.processCommand(
                              "give me a skincare tip",
                              currentRoute: _lastRoute,
                            );
                            setModalState(() {
                              isThinking = false;
                              localAnswer = ans;
                            });
                            if (!_isMuted) _assistant.speak(ans);
                          }, colorScheme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Instant Text Input Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: TextField(
                              controller: textController,
                              decoration: const InputDecoration(
                                hintText: 'Ask Dermi right here... ✨',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (val) async {
                                final text = val.trim();
                                if (text.isEmpty) return;
                                textController.clear();
                                setModalState(() => isThinking = true);
                                final ans = await _assistant.processCommand(
                                  text,
                                  currentRoute: _lastRoute,
                                );
                                setModalState(() {
                                  isThinking = false;
                                  localAnswer = ans;
                                });
                                if (!_isMuted) _assistant.speak(ans);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.send_rounded, size: 20),
                          onPressed: () async {
                            final text = textController.text.trim();
                            if (text.isEmpty) return;
                            textController.clear();
                            setModalState(() => isThinking = true);
                            final ans = await _assistant.processCommand(
                              text,
                              currentRoute: _lastRoute,
                            );
                            setModalState(() {
                              isThinking = false;
                              localAnswer = ans;
                            });
                            if (!_isMuted) _assistant.speak(ans);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickPill(String label, VoidCallback onTap, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        backgroundColor: colorScheme.primary.withOpacity(0.08),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: onTap,
      ),
    );
  }

  @override
  void dispose() {
    widget.router?.routerDelegate.removeListener(_onRouteChanged);
    _assistant.isSpeakingNotifier.removeListener(_onSpeakingChanged);
    _speechBubbleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFullVoiceChat = _lastRoute.contains('/assistant/chat') || _lastRoute == '/';
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Main App Screen Content
        widget.child,

        // Floating Mascot & Speech Bubble
        if (!isFullVoiceChat && !_isMinimized)
          Positioned(
            left: _x,
            top: _y,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _x += details.delta.dx;
                  _y += details.delta.dy;
                  _x = _x.clamp(8.0, screenSize.width - 68.0);
                  _y = _y.clamp(60.0, screenSize.height - 110.0);
                });
              },
              onPanEnd: (details) {
                final middle = screenSize.width / 2;
                setState(() {
                  _x = _x < middle ? 16.0 : (screenSize.width - 68.0);
                });
              },
              onTap: _onTapMascot,
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Speech Bubble when mascot is on right side
                    if (_currentSpeechText != null && _x > screenSize.width / 2)
                      _buildFloatingSpeechBubble(_currentSpeechText!),

                    // Cute Floating Dermi Avatar Mascot
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8CE09D), Color(0xFF4A7C59)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A7C59).withOpacity(0.40),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: DermiCharacter(
                          size: 52,
                          state: _mascotState,
                          enableInteraction: false,
                        ),
                      ),
                    )
                        .animate(target: _mascotState == DermiState.talking ? 1 : 0)
                        .scale(
                          duration: 400.ms,
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.12, 1.12),
                        ),

                    // Speech Bubble when mascot is on left side
                    if (_currentSpeechText != null && _x <= screenSize.width / 2)
                      _buildFloatingSpeechBubble(_currentSpeechText!),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingSpeechBubble(String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3326) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A7C59).withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1A3823),
          height: 1.3,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.0, 1.0));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../../../core/widgets/character/dermi_character.dart';
import '../../../../core/services/voice_assistant_service.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  final VoiceAssistantService _assistant = VoiceAssistantService();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  DermiState _dermiState = DermiState.idle;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _voiceEnabled = true;

  @override
  void initState() {
    super.initState();

    // Listen to speaking state to animate Dermi's mouth
    _assistant.isSpeakingNotifier.addListener(_onSpeakingChanged);
    _assistant.isListeningNotifier.addListener(_onListeningChanged);

    _initialize();
  }

  void _onSpeakingChanged() {
    if (!mounted) return;
    if (_assistant.isSpeakingNotifier.value) {
      setState(() => _dermiState = DermiState.talking);
    } else if (_dermiState == DermiState.talking) {
      setState(() => _dermiState = DermiState.happy);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _dermiState == DermiState.happy) {
          setState(() => _dermiState = DermiState.idle);
        }
      });
    }
  }

  void _onListeningChanged() {
    if (!mounted) return;
    if (_assistant.isListeningNotifier.value) {
      setState(() => _dermiState = DermiState.listening);
    } else if (_dermiState == DermiState.listening) {
      setState(() => _dermiState = DermiState.idle);
    }
  }

  Future<void> _initialize() async {
    await _assistant.initialize();
    if (mounted) setState(() => _isInitialized = true);
    _greetUser();
  }

  void _greetUser() {
    const welcome =
        'Yahoo! ✨ Namaste and hello! I\'m Dermi, your cute skincare buddy! 🌸\n\n'
        'You can talk to me with the mic or type messages below!\n\n'
        'Ask me about your skin routine, hydration, acne, or finding a doctor! 💕';

    _addMessage(welcome, isUser: false);
    if (_voiceEnabled) {
      _assistant.speak(
        'Yahoo! Hi there! I\'m Dermi, your cute skincare buddy! How can I make your skin glow today?',
      );
    }
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Handle Voice Input
  Future<void> _startListening() async {
    if (!_isInitialized || _isProcessing) return;

    setState(() {
      _dermiState = DermiState.listening;
    });

    final recognizedText = await _assistant.listen();

    if (recognizedText != null && recognizedText.isNotEmpty) {
      _addMessage(recognizedText, isUser: true);
      await _processUserInput(recognizedText);
    } else {
      _addMessage(
        "Aww, I couldn't catch that! You can speak closer to the mic or type your question below! 💬✨",
        isUser: false,
      );
      setState(() => _dermiState = DermiState.idle);
    }
  }

  /// Handle Text or Voice Message Submission
  Future<void> _handleTextSubmit(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isProcessing) return;

    _textController.clear();
    _addMessage(clean, isUser: true);
    await _processUserInput(clean);
  }

  Future<void> _processUserInput(String input) async {
    setState(() {
      _isProcessing = true;
      _dermiState = DermiState.thinking;
    });

    // Simulate natural thinking duration
    await Future.delayed(const Duration(milliseconds: 550));

    final response = await _assistant.processCommand(input, currentRoute: '/assistant/chat');

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    _addMessage(response, isUser: false);

    if (_voiceEnabled) {
      await _assistant.speak(response);
    } else {
      setState(() => _dermiState = DermiState.happy);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _dermiState = DermiState.idle);
    }
  }

  void _onTappedDermi() {
    setState(() => _dermiState = DermiState.happy);
    if (_voiceEnabled) {
      _assistant.speak("Hehe! That tickles! Let's make your skin glow today! ✨");
    }
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _dermiState = DermiState.idle);
    });
  }

  @override
  void dispose() {
    _assistant.isSpeakingNotifier.removeListener(_onSpeakingChanged);
    _assistant.isListeningNotifier.removeListener(_onListeningChanged);
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const DermiAvatar(radius: 16),
            const SizedBox(width: 10),
            const Text('Chat with Dermi'),
          ],
        ),
        actions: [
          // Voice Mute / Unmute Toggle
          IconButton(
            tooltip: _voiceEnabled ? 'Mute Dermi voice' : 'Enable Dermi voice',
            icon: Icon(
              _voiceEnabled ? Icons.volume_up : Icons.volume_off,
              color: _voiceEnabled ? colorScheme.primary : Colors.grey,
            ),
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (!_voiceEnabled) {
                _assistant.stop();
              } else {
                _assistant.speak("Voice enabled! ✨");
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      const DermiAvatar(radius: 16),
                      const SizedBox(width: 8),
                      const Text('About Dermi ✨'),
                    ],
                  ),
                  content: const Text(
                    'Dermi is your responsive AI skincare companion for DermaCare!\n\n'
                    '• Speak using the mic button OR type your messages\n'
                    '• Responds instantly with verified skincare advice\n'
                    '• Guides you on acne, routines, SPF & Nepal doctors\n'
                    '• Tap on Dermi anytime to play with her! 🌸',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Awesome!'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Interactive Animated Mascot Header
          Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                  colorScheme.surface,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dermiState == DermiState.listening
                      ? AvatarGlow(
                          glowColor: colorScheme.primary,
                          animate: true,
                          glowRadiusFactor: 0.35,
                          child: DermiCharacter(
                            state: _dermiState,
                            size: 155,
                            onTap: _onTappedDermi,
                          ),
                        )
                      : DermiCharacter(
                          state: _dermiState,
                          size: 155,
                          onTap: _onTappedDermi,
                        ),
                  const SizedBox(height: 10),
                  _buildStatusText(theme),
                ],
              ),
            ),
          ),

          // 2. Quick Suggestion Prompt Chips
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildPromptChip('💧 Log Water', 'I drank a glass of water!'),
                _buildPromptChip('✨ Skincare Tip', 'Give me a skincare tip'),
                _buildPromptChip('🧼 Routine Steps', 'What order should I apply skincare?'),
                _buildPromptChip('☀️ Sunscreen Advice', 'Tell me about sunscreen in Nepal'),
                _buildPromptChip('🩺 Find Doctor', 'I need a dermatologist'),
                _buildPromptChip('💖 Cheer Me Up', 'I am having a bad skin day'),
              ],
            ),
          ),

          // 3. Chat Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _ChatBubble(
                        message: _messages[index],
                        onReplay: (text) => _assistant.speak(text),
                      )
                          .animate()
                          .fadeIn(delay: (index * 30).ms, duration: 300.ms)
                          .slideY(begin: 0.15, end: 0);
                    },
                  ),
          ),

          // 4. Responsive Chat Input Bar (Text + Voice Mic)
          _buildResponsiveInputBar(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String label, String prompt) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
        backgroundColor: colorScheme.primary.withOpacity(0.08),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _isProcessing
            ? null
            : () {
                _addMessage(prompt, isUser: true);
                _processUserInput(prompt);
              },
      ),
    );
  }

  Widget _buildStatusText(ThemeData theme) {
    String text;
    Color color;

    switch (_dermiState) {
      case DermiState.idle:
        text = '✨ Tap mic, type below, or tap me! ✨';
        color = theme.colorScheme.onSurfaceVariant;
        break;
      case DermiState.listening:
        text = 'Listening to your voice... Speak now! 🎤';
        color = theme.colorScheme.primary;
        break;
      case DermiState.thinking:
        text = 'Thinking cute skincare thoughts... 💭';
        color = theme.colorScheme.secondary;
        break;
      case DermiState.talking:
        text = 'Dermi is speaking... 💬';
        color = const Color(0xFF2E633C);
        break;
      case DermiState.happy:
        text = 'Yay! So happy to chat with you! 🥰';
        color = Colors.green;
        break;
    }

    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DermiAvatar(radius: 32)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 1800.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.08, 1.08),
              ),
          const SizedBox(height: 16),
          Text(
            'Ask me anything about your skin!',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Type below or press the mic to talk! ✨',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Full-featured chat bar allowing both Typing & Voice Mic
  Widget _buildResponsiveInputBar(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Microphone Button
            GestureDetector(
              onTap: _isProcessing ? null : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _dermiState == DermiState.listening
                        ? [const Color(0xFFFF5252), const Color(0xFFD32F2F)]
                        : [const Color(0xFF68C28E), const Color(0xFF4A7C59)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_dermiState == DermiState.listening
                              ? Colors.red
                              : const Color(0xFF4A7C59))
                          .withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _dermiState == DermiState.listening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Text Input Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type message to Dermi... ✨',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: _handleTextSubmit,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send Button
            IconButton(
              icon: Icon(Icons.send_rounded, color: colorScheme.primary),
              onPressed: () => _handleTextSubmit(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser})
      : timestamp = DateTime.now();
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String) onReplay;

  const _ChatBubble({
    required this.message,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const DermiAvatar(radius: 17),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: message.isUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      height: 1.42,
                    ),
                  ),
                  if (!message.isUser) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => onReplay(message.text),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_outlined,
                            size: 14,
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Play voice',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.primary.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 17,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: 18,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

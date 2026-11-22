import 'dart:math' as math;
import 'package:dio/dio.dart';

/// Intelligent, responsive skincare assistant service
/// Features deep offline conversational NLP + optional cloud LLM fallback
class AIAssistantService {
  static final AIAssistantService _instance = AIAssistantService._internal();
  factory AIAssistantService() => _instance;
  AIAssistantService._internal();

  final Dio _dio = Dio();
  static const String _apiKey = '';
  static const String _baseUrl = 'https://api.openai.com/v1';

  static const String _systemPrompt = '''
You are Dermi, the ultra-cute, adorable, and cheerful AI skincare mascot for DermaCare in Nepal!
Speak in a warm, sweet, animated mascot tone with emojis (✨, 💧, 🌸, 💖).
Keep answers under 40 words so voice is fast and adorable!
''';

  final List<Map<String, String>> _conversationHistory = [];

  void _initializeConversation() {
    if (_conversationHistory.isEmpty) {
      _conversationHistory.add({
        'role': 'system',
        'content': _systemPrompt,
      });
    }
  }

  /// Get AI response with intelligent local NLP first, or cloud fallback
  Future<String> getResponse(String userMessage, {String currentRoute = ''}) async {
    final cleanInput = userMessage.trim();
    if (cleanInput.isEmpty) {
      return "Hehe! I'm listening! Tell me what's on your mind! 🌸✨";
    }

    // Try intelligent local conversational engine first
    final localResponse = _matchLocalIntent(cleanInput, currentRoute);
    if (localResponse != null) {
      return localResponse;
    }

    // If no exact match and online API key is available, attempt remote LLM
    if (_apiKey.startsWith('sk-')) {
      try {
        _initializeConversation();
        _conversationHistory.add({'role': 'user', 'content': cleanInput});

        final response = await _dio.post(
          '$_baseUrl/chat/completions',
          options: Options(
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': 'gpt-3.5-turbo',
            'messages': _conversationHistory,
            'max_tokens': 120,
            'temperature': 0.75,
          },
        );

        final aiMessage = response.data['choices'][0]['message']['content'];
        _conversationHistory.add({'role': 'assistant', 'content': aiMessage});
        return aiMessage;
      } catch (e) {
        // Fall back gracefully to smart fallback
      }
    }

    return _generateSmartFallback(cleanInput);
  }

  /// Comprehensive offline Skincare & Companion NLP Engine
  String? _matchLocalIntent(String message, String currentRoute) {
    final lower = message.toLowerCase();

    // 1. Greetings & Namaste
    if (_hasAny(lower, ['hello', 'hi', 'hey', 'namaste', 'morning', 'evening', 'afternoon', 'sup'])) {
      final greetings = [
        "Yahoo! ✨ Namaste! I'm Dermi, your little skincare buddy! Ready to glow today? 💖",
        "Hello beautiful friend! 🌸 Dermi is super happy to see you! How is your skin feeling today? ✨",
        "Namaste! 🌿 May your day be as refreshing as morning dew! What can I help you with today? 💧",
      ];
      return greetings[math.Random().nextInt(greetings.length)];
    }

    // 2. Identity & Mascot Questions
    if (_hasAny(lower, ['who are you', 'what are you', 'your name', 'what can you do', 'who made you'])) {
      return "I'm Dermi! 💧 Your cute, glowing skincare mascot for DermaCare! I track your hydration, share skincare tips, and guide you to top doctors in Nepal! 🌸✨";
    }

    // 3. How are you / Status
    if (_hasAny(lower, ['how are you', 'how r u', 'feeling', 'doing today'])) {
      return "I'm feeling so bubbly and hydrated! 💧 My little leaf sprout is wiggling with joy! How about you, friend? 🥰";
    }

    // 4. Compliments & Affection
    if (_hasAny(lower, ['cute', 'love you', 'sweet', 'pretty', 'adorable', 'good bot', 'best'])) {
      return "Awww! 🥰 You're making my cheeks blush pink! You are the absolute sweetest! Keep shining bright! 🌸✨";
    }

    // 5. Emotional Support & Bad Skin Days
    if (_hasAny(lower, ['ugly', 'insecure', 'bad skin', 'hate my face', 'sad', 'crying', 'depressed', 'breakout today'])) {
      return "Aww, big warm hug! 💖 Please remember: texture and breakouts are completely normal! Your skin does not define your beauty. Treat it gently and you will glow! 🌸✨";
    }

    // 6. Acne, Pimples, Breakouts
    if (_hasAny(lower, ['acne', 'pimple', 'breakout', 'blackhead', 'whitehead', 'zit', 'blemish'])) {
      return "For pesky breakouts: 🌿 Cleanse gently with Salicylic acid, never squeeze or pop, and keep hands off! For persistent acne, consult Dr. Anjali in our Doctors tab! 🩺✨";
    }

    // 7. Dry Skin & Flakiness
    if (_hasAny(lower, ['dry', 'flaky', 'peeling', 'tight', 'winter'])) {
      return "Dry skin remedy: 💧 Apply Hyaluronic acid while your skin is still damp, and seal with a ceramide moisturizer! Also drink your 8 glasses of water today! 🌸";
    }

    // 8. Oily Skin & Greasiness
    if (_hasAny(lower, ['oily', 'greasy', 'shine', 'pores', 'sebum'])) {
      return "For oily skin: ✨ Look for Niacinamide and oil-free gel moisturizers. Don't skip moisturizing - dehydrated skin actually produces more oil! 🧴";
    }

    // 9. Sunscreen & SPF
    if (_hasAny(lower, ['sunscreen', 'sun', 'spf', 'uv', 'sunburn'])) {
      return "Sunscreen is Queen! ☀️ Even on cloudy Kathmandu days, UV rays penetrate clouds. Use SPF 50+ broad-spectrum every single morning! ✨";
    }

    // 10. Dark Spots, Scars, Pigmentation
    if (_hasAny(lower, ['dark spot', 'pigment', 'scar', 'mark', 'melasma'])) {
      return "For dark spots: 🍊 Vitamin C serum in the morning and daily sunscreen are your magic duo! Niacinamide also fades marks beautifully! ✨";
    }

    // 11. Water & Hydration Tracking
    if (_hasAny(lower, ['water', 'drink', 'hydrate', 'thirst', 'glass'])) {
      return "Glug, glug, glug! 💧 Drinking 8 glasses of water boosts skin elasticity and natural glow! Log a glass on your Home screen right now! 🌸✨";
    }

    // 12. Doctors & Appointments
    if (_hasAny(lower, ['doctor', 'appointment', 'hospital', 'clinic', 'dermatologist', 'mediciti', 'patan'])) {
      return "We have wonderful Nepal dermatologists available! 🩺 Tap 'Doctors' in the bottom navigation to view profiles, reviews, and book video or clinic visits! 👨‍⚕️✨";
    }

    // 13. Skincare Routine Steps
    if (_hasAny(lower, ['routine', 'step', 'order', 'am routine', 'pm routine'])) {
      return "Golden routine order: 🧼 1. Gentle Cleanser -> 2. Toner -> 3. Active Serum -> 4. Moisturizer -> 5. Sunscreen (Day)! Night: double cleanse and moisturize! 🌙✨";
    }

    // 14. Retinol / Anti-aging
    if (_hasAny(lower, ['retinol', 'wrinkle', 'aging', 'fine line', 'anti aging'])) {
      return "Retinol magic: 🌙 Always start slow (2 nights a week) at bedtime. Use the sandwich method (moisturizer, retinol, moisturizer) and NEVER skip SPF! ☀️";
    }

    // 15. Sensitive Skin & Redness
    if (_hasAny(lower, ['sensitive', 'redness', 'burn', 'irritat', 'eczema', 'rosacea'])) {
      return "Gentle care: 🌿 Stop all strong acids. Use soothing Centella (Cica), panthenol, and fragrance-free formulas until your skin barrier heals! 💖";
    }

    // 16. Current Screen Context
    if (_hasAny(lower, ['where am i', 'what screen', 'explain screen', 'this page'])) {
      return _getScreenContextMessage(currentRoute);
    }

    // 17. Thank you
    if (_hasAny(lower, ['thank', 'thanks', 'dhanyabad', 'danyabad'])) {
      return "You're so welcome! 💖 My little heart is beaming! I'm always here cheering for your glowing journey! 🌸✨";
    }

    return null;
  }

  /// Context-aware messages based on which screen the user is currently looking at
  String _getScreenContextMessage(String route) {
    if (route.contains('doctor')) {
      return "You are on the Doctors screen! 🩺 Filter by specialty and check verified reviews from patients across Nepal!";
    } else if (route.contains('prescription')) {
      return "You are on your Prescriptions tab! 💊 Here you can track your medication schedules, dosages, and doctor notes!";
    } else if (route.contains('progress')) {
      return "You are looking at your Progress Journal! 📸 Compare before & after photos to watch your skin barrier heal over time!";
    } else if (route.contains('membership')) {
      return "You are on the Membership plans screen! 🌟 You can subscribe via eSewa, Khalti, or FonePay in NPR for unlimited doctor consults!";
    } else if (route.contains('profile')) {
      return "You are in your Profile & Settings! 🌿 Manage your skin preferences, hydration goals, and notification reminders!";
    } else {
      return "You are on your Home Dashboard! 🏠 Tap 'Log a Glass' to keep your hydration streak going, or explore your daily routines! 💧✨";
    }
  }

  /// Smart conversational fallback for unmapped queries
  String _generateSmartFallback(String input) {
    final tips = [
      "Ooh, that's interesting! 🌸 For your skin health, remember that consistency and gentle care win every time! What is your main skin goal today? ✨",
      "I hear you! 💧 Skin health is a journey, and every small step counts! Have you remembered your sunscreen and water intake today? ☀️",
      "Hehe! I'm always learning new skincare secrets! 🌿 You can ask me about acne, dark spots, dry skin, routine steps, or booking top Nepal doctors! 🩺✨",
    ];
    return tips[DateTime.now().millisecond % tips.length];
  }

  bool _hasAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  void clearHistory() {
    _conversationHistory.clear();
  }
}

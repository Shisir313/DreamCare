import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'ai_assistant_service.dart';

/// Service responsible for Voice Input (STT), Voice Output (TTS),
/// and processing user commands with conversational skincare AI.
class VoiceAssistantService {
  static final VoiceAssistantService _instance =
      VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._internal();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AIAssistantService _aiService = AIAssistantService();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  bool _hasMicPermission = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isSpeechAvailable => _speech.isAvailable;
  bool get hasMicPermission => _hasMicPermission;

  // Listeners for UI state synchronisation
  ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Text-to-Speech (TTS) with cute mascot voice
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.52); // Cheerful cadence
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.48); // Cute anime/mascot high-pitch

      _tts.setStartHandler(() {
        _isSpeaking = true;
        isSpeakingNotifier.value = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        isSpeakingNotifier.value = false;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        isSpeakingNotifier.value = false;
      });

      // 2. Request runtime microphone permission
      final status = await Permission.microphone.request();
      _hasMicPermission = status.isGranted;

      // 3. Initialize Speech-to-Text
      if (_hasMicPermission) {
        _isInitialized = await _speech.initialize(
          onError: (error) {
            debugPrint('Speech recognition error: ${error.errorMsg}');
            _isListening = false;
            isListeningNotifier.value = false;
          },
          onStatus: (status) {
            debugPrint('Speech status: $status');
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
              isListeningNotifier.value = false;
            }
          },
        );
      } else {
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Voice assistant initialization warning: $e');
      _isInitialized = true;
    }
  }

  /// Speak text aloud in Dermi's cute voice
  Future<void> speak(String text) async {
    try {
      await initialize();
      // Clean emojis from spoken text for natural, smooth TTS pronunciation
      final cleanText = text
          .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), '')
          .replaceAll(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true), '')
          .replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), '')
          .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '')
          .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '')
          .replaceAll('✨', '')
          .replaceAll('💧', '')
          .replaceAll('🌸', '')
          .replaceAll('💖', '')
          .trim();

      if (cleanText.isNotEmpty) {
        await _tts.speak(cleanText);
      }
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  /// Stop speaking immediately
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      isSpeakingNotifier.value = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Listen for user voice and return recognized text cleanly
  Future<String?> listen({Duration timeout = const Duration(seconds: 5)}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check permission again if not granted initially
    if (!_hasMicPermission) {
      final status = await Permission.microphone.request();
      _hasMicPermission = status.isGranted;
      if (!_hasMicPermission) return null;
      await _speech.initialize();
    }

    if (!_speech.isAvailable) {
      return null;
    }

    final completer = Completer<String?>();
    String recognizedWords = '';

    _isListening = true;
    isListeningNotifier.value = true;

    Timer? safetyTimer;

    await _speech.listen(
      onResult: (result) {
        recognizedWords = result.recognizedWords;
        // If final recognized speech is received, complete immediately
        if (result.finalResult && !completer.isCompleted) {
          safetyTimer?.cancel();
          _isListening = false;
          isListeningNotifier.value = false;
          completer.complete(recognizedWords.trim());
        }
      },
      listenFor: timeout,
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      cancelOnError: true,
    );

    // Timeout safety fallback
    safetyTimer = Timer(timeout + const Duration(seconds: 1), () {
      if (!completer.isCompleted) {
        _isListening = false;
        isListeningNotifier.value = false;
        _speech.stop();
        completer.complete(recognizedWords.trim().isEmpty ? null : recognizedWords.trim());
      }
    });

    return completer.future;
  }

  /// Stop listening immediately
  void stopListening() {
    _speech.stop();
    _isListening = false;
    isListeningNotifier.value = false;
  }

  /// Process command through the conversational Skincare AI Engine
  Future<String> processCommand(String command, {String currentRoute = ''}) async {
    return _aiService.getResponse(command, currentRoute: currentRoute);
  }

  /// Clear AI conversation history
  void clearHistory() {
    _aiService.clearHistory();
  }
}

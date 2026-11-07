import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    if (kIsWeb) {
      try {
        // Pre-warm browser voice list
        web.window.speechSynthesis.getVoices();
      } catch (_) {}
    }
  }

  web.HTMLAudioElement? _currentAudio;
  bool _isPlaying = false;
  String? _currentlyPlayingId;

  bool get isPlaying => _isPlaying;
  String? get currentlyPlayingId => _currentlyPlayingId;

  bool isCurrentPlaying(String id) => _isPlaying && _currentlyPlayingId == id;

  /// Stop any currently playing audio or speech
  void stop() {
    try {
      if (kIsWeb) {
        web.window.speechSynthesis.cancel();
        if (_currentAudio != null) {
          _currentAudio!.pause();
          _currentAudio!.currentTime = 0;
          _currentAudio = null;
        }
      }
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
    _isPlaying = false;
    _currentlyPlayingId = null;
    notifyListeners();
  }

  /// Play audio for a dhikr.
  /// If [audioUrl] is provided, streams authentic human recitation (e.g. Quran recitation).
  /// Falls back to Web Speech Synthesis with natural voice selection.
  Future<void> playDhikr({
    required String id,
    required String arabicText,
    String? audioUrl,
  }) async {
    // If already playing this item, toggle stop
    if (isCurrentPlaying(id)) {
      stop();
      return;
    }

    // Stop any other playing audio
    stop();

    _isPlaying = true;
    _currentlyPlayingId = id;
    notifyListeners();

    if (!kIsWeb) {
      _isPlaying = false;
      _currentlyPlayingId = null;
      notifyListeners();
      return;
    }

    // 1. Try real audio URL if available
    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        final audio = web.HTMLAudioElement()..src = audioUrl;
        _currentAudio = audio;

        audio.onended = (web.Event _) {
          _isPlaying = false;
          _currentlyPlayingId = null;
          _currentAudio = null;
          notifyListeners();
        }.toJS;

        audio.onerror = (web.Event e) {
          debugPrint('Audio stream failed, falling back to speech synthesis');
          _playSpeechSynthesis(id, arabicText);
        }.toJS;

        audio.play();
        return;
      } catch (e) {
        debugPrint('Audio playback error: $e');
      }
    }

    // 2. Default: Web Speech API with natural Arabic voice selection
    _playSpeechSynthesis(id, arabicText);
  }

  void _playSpeechSynthesis(String id, String arabicText) {
    try {
      final synth = web.window.speechSynthesis;
      synth.cancel();

      // Clean special decorative marks, brackets, and Quranic stop marks for natural speech
      final cleanText = arabicText
          .replaceAll(RegExp(r'[﴿﴾\(\)\[\]«»\{\}—•]'), ' ')
          .replaceAll('ﷺ', 'صلى الله عليه وسلم')
          .replaceAll('ٱ', 'ا') // Normalize Alef Wasla for TTS engines
          .replaceAll(RegExp(r'[ۖ-ۭ]'), '') // Remove Quranic annotations/pause marks
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final utterance = web.SpeechSynthesisUtterance(cleanText);

      // Select best natural Arabic voice available in the browser
      try {
        final voices = synth.getVoices();
        web.SpeechSynthesisVoice? bestVoice;

        // Pass 1: Natural / Neural / Online / Google / Microsoft Arabic voices
        for (var i = 0; i < voices.length; i++) {
          final v = voices[i];
          final lang = v.lang.toLowerCase();
          final name = v.name.toLowerCase();
          if (lang.startsWith('ar')) {
            if (name.contains('natural') ||
                name.contains('neural') ||
                name.contains('online') ||
                name.contains('google') ||
                name.contains('shakir') ||
                name.contains('hamed') ||
                name.contains('fatima') ||
                name.contains('salma')) {
              bestVoice = v;
              break;
            }
          }
        }

        // Pass 2: Any Arabic voice
        if (bestVoice == null) {
          for (var i = 0; i < voices.length; i++) {
            final v = voices[i];
            if (v.lang.toLowerCase().startsWith('ar')) {
              bestVoice = v;
              break;
            }
          }
        }

        if (bestVoice != null) {
          utterance.voice = bestVoice;
          utterance.lang = bestVoice.lang;
        } else {
          utterance.lang = 'ar-SA';
        }
      } catch (_) {
        utterance.lang = 'ar-SA';
      }

      utterance.rate = 0.95; // Fluent, natural speed
      utterance.pitch = 1.0;

      utterance.onend = (web.SpeechSynthesisEvent _) {
        if (_currentlyPlayingId == id) {
          _isPlaying = false;
          _currentlyPlayingId = null;
          notifyListeners();
        }
      }.toJS;

      utterance.onerror = (web.SpeechSynthesisErrorEvent _) {
        if (_currentlyPlayingId == id) {
          _isPlaying = false;
          _currentlyPlayingId = null;
          notifyListeners();
        }
      }.toJS;

      synth.speak(utterance);
    } catch (e) {
      debugPrint('Speech synthesis error: $e');
      _isPlaying = false;
      _currentlyPlayingId = null;
      notifyListeners();
    }
  }
}

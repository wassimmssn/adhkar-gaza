import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

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
  /// If [audioUrl] is provided, attempts to stream real human audio (e.g. Quran recitation).
  /// Falls back to Web Speech Synthesis in Arabic for supplications or if audio fails.
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

    // 2. Default: Web Speech API (Native browser Arabic TTS)
    _playSpeechSynthesis(id, arabicText);
  }

  void _playSpeechSynthesis(String id, String arabicText) {
    try {
      final synth = web.window.speechSynthesis;
      synth.cancel();

      // Clean special decorative marks if any for smoother TTS pronunciation
      final cleanText = arabicText
          .replaceAll(RegExp(r'[﴿﴾\(\)\[\]]'), '')
          .replaceAll('ﷺ', 'صلى الله عليه وسلم');

      final utterance = web.SpeechSynthesisUtterance(cleanText);
      utterance.lang = 'ar-SA';
      utterance.rate = 0.85; // Slightly slower for clear pronunciation

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

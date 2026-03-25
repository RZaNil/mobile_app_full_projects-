import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef SpeechResultCallback = void Function(String text, bool isFinal);

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechInitialized = false;
  bool _ttsInitialized = false;
  bool _isListening = false;
  bool _disposed = false;
  VoidCallback? _onListeningDone;

  bool get isListening => _isListening;

  Future<bool> initialize() async {
    return _initializeTts();
  }

  Future<bool> _initializeTts() async {
    if (_disposed) {
      return false;
    }
    if (_ttsInitialized) {
      return true;
    }

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
      _ttsInitialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _prepareSpeechRecognition() async {
    if (_disposed) {
      return false;
    }

    final PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    if (_speechInitialized) {
      return true;
    }

    try {
      final bool available = await _speechToText.initialize(
        onStatus: (String statusText) {
          final String lower = statusText.toLowerCase();
          if (lower == 'done' || lower == 'notlistening') {
            _finishListening();
          }
        },
        onError: (SpeechRecognitionError _) {
          _finishListening();
        },
      );
      _speechInitialized = available;
      return available;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startListening(
    SpeechResultCallback onResult,
    VoidCallback onListeningDone,
  ) async {
    final bool ready = await _prepareSpeechRecognition();
    if (!ready) {
      _finishListening(onListeningDone);
      return false;
    }

    _onListeningDone = onListeningDone;
    _isListening = true;

    try {
      await _speechToText.listen(
        localeId: 'en_US',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
        },
      );
      return true;
    } catch (_) {
      _finishListening();
      return false;
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    _onListeningDone = null;
    if (_disposed) {
      return;
    }

    try {
      await _speechToText.stop();
    } catch (_) {
      // Ignore stop failures so the UI can recover gracefully.
    }
  }

  Future<void> speak(String text) async {
    if (_disposed || text.trim().isEmpty) {
      return;
    }

    final bool ready = await _initializeTts();
    if (!ready) {
      return;
    }

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(_expandForSpeech(text));
    } catch (_) {
      // TTS is optional. Fail silently so the rest of the app keeps working.
    }
  }

  Future<void> stopSpeaking() async {
    if (_disposed) {
      return;
    }

    try {
      await _flutterTts.stop();
    } catch (_) {
      // Ignore stop failures so the rest of the flow can continue.
    }
  }

  void dispose() {
    _disposed = true;
    _isListening = false;
    _onListeningDone = null;

    try {
      _speechToText.cancel();
    } catch (_) {
      // Ignore plugin cleanup issues during disposal.
    }

    try {
      _flutterTts.stop();
    } catch (_) {
      // Ignore plugin cleanup issues during disposal.
    }
  }

  String _expandForSpeech(String input) {
    String text = input;

    const Map<String, String> replacements = <String, String>{
      'EWU': 'E W U',
      'CSE': 'C S E',
      'ECE': 'E C E',
      'EEE': 'E E E',
      'BBA': 'B B A',
      'MBA': 'M B A',
      'BDT': 'Taka',
      'TK': 'Taka',
    };

    replacements.forEach((String key, String value) {
      text = text.replaceAllMapped(
        RegExp('\\b$key\\b', caseSensitive: false),
        (_) => value,
      );
    });

    return text;
  }

  void _finishListening([VoidCallback? fallback]) {
    _isListening = false;
    final VoidCallback? callback = _onListeningDone ?? fallback;
    _onListeningDone = null;
    callback?.call();
  }
}

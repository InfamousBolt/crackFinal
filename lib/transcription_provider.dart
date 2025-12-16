import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class TranscriptionProvider extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();

  String _transcribedText = '';
  bool _isListening = false;
  bool _isInitialized = false;
  String _errorMessage = '';
  double _confidenceLevel = 0.0;

  String get transcribedText => _transcribedText;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get errorMessage => _errorMessage;
  double get confidenceLevel => _confidenceLevel;

  Future<void> _initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          _errorMessage = 'Microphone permission required';
          notifyListeners();
          return;
        }
      }

      // Initialize speech to text
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _errorMessage = 'Speech recognition error: ${error.errorMsg}';
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
            notifyListeners();
          }
        },
      );

      if (!_isInitialized) {
        _errorMessage = 'Failed to initialize speech recognition';
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Initialization error: $e';
      notifyListeners();
    }
  }

  Future<void> startListening() async {
    // Initialize if not already done
    if (!_isInitialized) {
      await _initialize();
      if (!_isInitialized) {
        // Initialization failed, error message already set
        return;
      }
    }

    if (_isListening) {
      return; // Already listening
    }

    try {
      // Clear previous text when starting new session
      _transcribedText = '';
      _errorMessage = '';
      _confidenceLevel = 0.0;

      await _speechToText.listen(
        onResult: (result) {
          _transcribedText = result.recognizedWords;
          _confidenceLevel = result.confidence;
          notifyListeners();
        },
        listenFor: const Duration(minutes: 30), // Long duration for continuous listening
        pauseFor: const Duration(seconds: 3), // Short pause to keep listening active
        partialResults: true, // Enable partial results for real-time updates
        onSoundLevelChange: (level) {
          // Optional: can use this for visual feedback
        },
        cancelOnError: false,
        listenMode: ListenMode.confirmation, // For continuous recognition
      );

      _isListening = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start listening: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    try {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to stop listening: $e';
      notifyListeners();
    }
  }

  void clearTranscription() {
    _transcribedText = '';
    _confidenceLevel = 0.0;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.cancel();
    super.dispose();
  }
}

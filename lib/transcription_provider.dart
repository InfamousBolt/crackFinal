import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class TranscriptionProvider extends ChangeNotifier {
  String _transcribedText = '';
  bool _isListening = false;
  bool _isInitialized = true; // Google Cloud API doesn't need initialization
  String _errorMessage = '';
  double _confidenceLevel = 0.0;

  StreamSubscription? _audioStreamSubscription;
  List<int> _audioBuffer = [];
  Timer? _sendTimer;

  String get transcribedText => _transcribedText;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get errorMessage => _errorMessage;
  double get confidenceLevel => _confidenceLevel;

  /// Start listening and transcribing audio
  ///
  /// This will process audio chunks and send them to Google Cloud Speech-to-Text API
  Future<void> startListening() async {
    if (_isListening) {
      return; // Already listening
    }

    // Check if API key is configured
    if (Config.googleCloudApiKey == 'YOUR_GOOGLE_CLOUD_API_KEY_HERE') {
      _errorMessage = 'Google Cloud API key not configured. Please add your API key in lib/config.dart';
      _isInitialized = false;
      notifyListeners();
      return;
    }

    try {
      // Clear previous text when starting new session
      _transcribedText = '';
      _errorMessage = '';
      _confidenceLevel = 0.0;
      _audioBuffer.clear();

      _isListening = true;
      notifyListeners();

      // Note: Audio streaming will be handled by the recorder
      // We'll send accumulated audio periodically
      _startPeriodicTranscription();

    } catch (e) {
      _errorMessage = 'Failed to start listening: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  /// Send audio data to Google Cloud Speech-to-Text API
  void addAudioData(List<int> audioData) {
    if (_isListening) {
      _audioBuffer.addAll(audioData);
    }
  }

  /// Periodically send accumulated audio to Google Cloud for transcription
  void _startPeriodicTranscription() {
    _sendTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_audioBuffer.isNotEmpty) {
        await _transcribeAudioChunk();
      }
    });
  }

  /// Send audio chunk to Google Cloud Speech-to-Text API
  Future<void> _transcribeAudioChunk() async {
    if (_audioBuffer.isEmpty) return;

    try {
      // Convert audio buffer to base64
      final audioBytes = Uint8List.fromList(_audioBuffer);
      final audioBase64 = base64Encode(audioBytes);

      // Clear buffer after encoding
      _audioBuffer.clear();

      // Prepare request body for Google Cloud Speech-to-Text API
      final requestBody = {
        'config': {
          'encoding': Config.encoding,
          'sampleRateHertz': Config.sampleRateHertz,
          'languageCode': Config.languageCode,
          'enableAutomaticPunctuation': true,
          'model': 'latest_short', // Optimized for short utterances with low latency
        },
        'audio': {
          'content': audioBase64,
        },
      };

      // Send request to Google Cloud Speech-to-Text API
      final response = await http.post(
        Uri.parse(
          'https://speech.googleapis.com/v1/speech:recognize?key=${Config.googleCloudApiKey}',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract transcription results
        if (responseData['results'] != null && responseData['results'].isNotEmpty) {
          final result = responseData['results'][0];

          if (result['alternatives'] != null && result['alternatives'].isNotEmpty) {
            final alternative = result['alternatives'][0];
            final transcript = alternative['transcript'] ?? '';
            final confidence = alternative['confidence'] ?? 0.0;

            // Append new transcription to existing text
            if (transcript.isNotEmpty) {
              _transcribedText += ' $transcript';
              _confidenceLevel = confidence.toDouble();
              notifyListeners();
            }
          }
        }
      } else {
        // Handle API errors
        final errorData = jsonDecode(response.body);
        _errorMessage = 'API Error: ${errorData['error']['message'] ?? 'Unknown error'}';
        notifyListeners();
      }
    } catch (e) {
      if (_isListening) {
        _errorMessage = 'Transcription error: $e';
        notifyListeners();
      }
    }
  }

  /// Stop listening and transcribing
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    try {
      _isListening = false;

      // Cancel periodic timer
      _sendTimer?.cancel();
      _sendTimer = null;

      // Cancel audio stream subscription
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // Send any remaining audio data
      if (_audioBuffer.isNotEmpty) {
        await _transcribeAudioChunk();
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to stop listening: $e';
      notifyListeners();
    }
  }

  /// Clear transcription text
  void clearTranscription() {
    _transcribedText = '';
    _confidenceLevel = 0.0;
    _errorMessage = '';
    _audioBuffer.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _audioStreamSubscription?.cancel();
    super.dispose();
  }
}

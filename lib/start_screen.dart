import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'transcription_provider.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  bool _recorderInitialized = false;
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _audioRecorder = FlutterSoundRecorder();

    try {
      await _audioRecorder!.openRecorder();
      setState(() {
        _recorderInitialized = true;
      });
    } catch (e) {
      _showSnackbar('Failed to initialize recorder: $e');
    }
  }

  @override
  void dispose() {
    _audioRecorder?.closeRecorder();
    _audioRecorder = null;
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (!_recorderInitialized || _audioRecorder == null) {
      _showSnackbar('Recorder not initialized');
      return;
    }

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check microphone permission
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          _showSnackbar('Microphone permission required');
          return;
        }
      }

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/start_recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _currentRecordingPath = filePath;
      });

      // Start transcription
      if (mounted) {
        final transcriptionProvider = Provider.of<TranscriptionProvider>(
          context,
          listen: false,
        );
        await transcriptionProvider.startListening();
      }

      _showSnackbar('Recording and transcription started');
    } catch (e) {
      _showSnackbar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder!.stopRecorder();

      setState(() {
        _isRecording = false;
      });

      // Stop transcription
      if (mounted) {
        final transcriptionProvider = Provider.of<TranscriptionProvider>(
          context,
          listen: false,
        );
        await transcriptionProvider.stopListening();
      }

      _showSnackbar('Recording saved! Check Audio and Transcription tabs');

      // Clear the path after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentRecordingPath = null;
          });
        }
      });
    } catch (e) {
      _showSnackbar('Failed to stop recording: $e');
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status text
              Text(
                _isRecording ? 'Recording...' : 'Ready',
                style: TextStyle(
                  color: _isRecording ? Colors.yellow : Colors.white70,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 60),

              // Big toggle button
              GestureDetector(
                onTap: _recorderInitialized ? _toggleRecording : null,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.yellow : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.yellow : Colors.red)
                            .withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isRecording ? 'Press to\nStop' : 'Start',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Instruction text
              if (!_isRecording && _recorderInitialized)
                Text(
                  'Tap the button to start recording',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),

              if (_isRecording)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tap to stop and save',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

              if (!_recorderInitialized) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

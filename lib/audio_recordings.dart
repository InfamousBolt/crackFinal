import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordings extends StatefulWidget {
  const AudioRecordings({super.key});

  @override
  State<AudioRecordings> createState() => _AudioRecordingsState();
}

class _AudioRecordingsState extends State<AudioRecordings>
    with WidgetsBindingObserver {
  FlutterSoundRecorder? _audioRecorder;
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();

  RecordingState _recordingState = RecordingState.idle;
  String? _recordingPath;
  String? _savedPath;
  bool _isPlaying = false;
  bool _recorderInitialized = false;
  String? _currentPlayingPath;

  List<File> _startScreenRecordings = [];
  List<File> _audioScreenRecordings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initRecorder();
    _loadSavedRecordings();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == ap.PlayerState.playing;
          if (state == ap.PlayerState.completed) {
            _currentPlayingPath = null;
            _isPlaying = false;
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload recordings when app comes back to foreground
      _loadSavedRecordings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioRecorder?.closeRecorder();
    _audioRecorder = null;
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSavedRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.aac'))
          .toList();

      files.sort((a, b) => b.path.compareTo(a.path)); // Newest first

      setState(() {
        _startScreenRecordings = files
            .where((file) => file.path.contains('start_recording_'))
            .toList();
        _audioScreenRecordings = files
            .where((file) =>
                file.path.contains('recording_') &&
                !file.path.contains('start_recording_'))
            .toList();
      });
    } catch (e) {
      _showSnackbar('Failed to load recordings: $e');
    }
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

  Future<void> _startRecording() async {
    if (!_recorderInitialized || _audioRecorder == null) {
      _showSnackbar('Recorder not initialized');
      return;
    }

    try {
      // Check microphone permission
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        _showSnackbar('Microphone permission not granted');
        return;
      }

      // Get temporary directory for recording
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/temp_recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _recordingState = RecordingState.recording;
        _recordingPath = filePath;
      });

      _showSnackbar('Recording started');
    } catch (e) {
      _showSnackbar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_audioRecorder == null) return;

    try {
      await _audioRecorder!.stopRecorder();

      setState(() {
        _recordingState = RecordingState.stopped;
      });

      _showSnackbar('Recording stopped');

      // Auto-save the recording
      await _saveRecording();

      // Reload the list of recordings
      await _loadSavedRecordings();
    } catch (e) {
      _showSnackbar('Failed to stop recording: $e');
    }
  }

  Future<void> _saveRecording() async {
    if (_recordingPath == null) {
      _showSnackbar('No recording to save');
      return;
    }

    try {
      // Get app documents directory for permanent storage
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      final savePath = '${directory.path}/$fileName';

      // Copy the temp recording to permanent storage
      final recordingFile = File(_recordingPath!);
      await recordingFile.copy(savePath);

      setState(() {
        _savedPath = savePath;
        _recordingState = RecordingState.saved;
      });

      print(
          'Recording saved. State: $_recordingState, Path: $_savedPath'); // Debug
      _showSnackbar('Recording saved: $fileName');
    } catch (e) {
      _showSnackbar('Failed to save recording: $e');
    }
  }

  void _newRecording() {
    setState(() {
      _recordingState = RecordingState.idle;
      _recordingPath = null;
      // Keep _savedPath so they can still access the last recording if needed
    });
    _showSnackbar('Ready for new recording');
  }

  Future<void> _playRecording() async {
    if (_savedPath == null) {
      _showSnackbar('No saved recording to play');
      return;
    }

    await _playFile(_savedPath!);
  }

  Future<void> _playFile(String filePath) async {
    try {
      if (_isPlaying && _currentPlayingPath == filePath) {
        await _audioPlayer.pause();
        _showSnackbar('Playback paused');
      } else {
        await _audioPlayer.play(ap.DeviceFileSource(filePath));
        setState(() {
          _currentPlayingPath = filePath;
        });
        _showSnackbar('Playing: ${filePath.split('/').last}');
      }
    } catch (e) {
      _showSnackbar('Failed to play recording: $e');
    }
  }

  Future<void> _deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      await file.delete();
      _showSnackbar('Recording deleted');
      await _loadSavedRecordings();
    } catch (e) {
      _showSnackbar('Failed to delete: $e');
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
      appBar: AppBar(
        title: const Text('Audio Recordings'),
        backgroundColor: Colors.grey[850],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedRecordings,
            tooltip: 'Refresh list',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recording controls section
                _buildRecordingControls(),

                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),

                // Start Screen Recordings section
                if (_startScreenRecordings.isNotEmpty) ...[
                  Text(
                    'Came from Start Screen',
                    style: TextStyle(
                      color: Colors.yellow[700],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._startScreenRecordings
                      .map((file) => _buildRecordingTile(file)),
                  const SizedBox(height: 24),
                ],

                // Audio Screen Recordings section
                if (_audioScreenRecordings.isNotEmpty) ...[
                  const Text(
                    'Audio Screen Recordings',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._audioScreenRecordings
                      .map((file) => _buildRecordingTile(file)),
                ],

                // Empty state
                if (_startScreenRecordings.isEmpty &&
                    _audioScreenRecordings.isEmpty) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.music_note,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recordings yet',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Record audio from Start screen or here',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Column(
      children: [
        // Status indicator
        _buildStatusIndicator(),
        const SizedBox(height: 24),

        // Recording controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Record button
            _buildActionButton(
              icon: Icons.fiber_manual_record,
              label: 'Record',
              color: Colors.red,
              onPressed: (_recorderInitialized &&
                      _recordingState == RecordingState.idle)
                  ? _startRecording
                  : null,
            ),
            const SizedBox(width: 16),

            // Stop button
            _buildActionButton(
              icon: Icons.stop,
              label: 'Stop',
              color: Colors.orange,
              onPressed: _recordingState == RecordingState.recording
                  ? _stopRecording
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // New Recording button
            _buildActionButton(
              icon: Icons.refresh,
              label: 'New',
              color: Colors.purple,
              onPressed: _recordingState == RecordingState.saved
                  ? _newRecording
                  : null,
            ),
            const SizedBox(width: 16),

            // Listen button (for most recent recording)
            _buildActionButton(
              icon: _isPlaying && _currentPlayingPath == _savedPath
                  ? Icons.pause
                  : Icons.play_arrow,
              label: _isPlaying && _currentPlayingPath == _savedPath
                  ? 'Pause'
                  : 'Listen',
              color: Colors.blue,
              onPressed: _recordingState == RecordingState.saved
                  ? _playRecording
                  : null,
            ),
          ],
        ),

        // Current recording info
        if (_savedPath != null && _recordingState == RecordingState.saved) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last: ${_savedPath!.split('/').last}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecordingTile(File file) {
    final fileName = file.path.split('/').last;
    final isPlaying = _isPlaying && _currentPlayingPath == file.path;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: isPlaying ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: ListTile(
        leading: Icon(
          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          color: isPlaying ? Colors.blue : Colors.green,
          size: 36,
        ),
        title: Text(
          fileName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatFileSize(file),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(file.path),
        ),
        onTap: () => _playFile(file.path),
      ),
    );
  }

  String _formatFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  void _showDeleteConfirmation(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecording(filePath);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_recordingState) {
      case RecordingState.recording:
        statusText = 'Recording...';
        statusColor = Colors.red;
        statusIcon = Icons.fiber_manual_record;
        break;
      case RecordingState.stopped:
        statusText = 'Saving...';
        statusColor = Colors.orange;
        statusIcon = Icons.save;
        break;
      case RecordingState.saved:
        statusText = 'Recording Saved';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusText =
            _recorderInitialized ? 'Ready to Record' : 'Initializing...';
        statusColor = _recorderInitialized ? Colors.grey : Colors.orange;
        statusIcon = Icons.mic;
    }

    return Column(
      children: [
        Icon(
          statusIcon,
          size: 64,
          color: statusColor,
        ),
        const SizedBox(height: 16),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? color : Colors.grey[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(20),
            shape: const CircleBorder(),
            elevation: isEnabled ? 6 : 0,
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.grey[600],
            fontSize: 13,
            fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

enum RecordingState {
  idle,
  recording,
  stopped,
  saved,
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transcription_provider.dart';

class TranscribedScreen extends StatefulWidget {
  const TranscribedScreen({super.key});

  @override
  State<TranscribedScreen> createState() => _TranscribedScreenState();
}

class _TranscribedScreenState extends State<TranscribedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Live Transcription',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Consumer<TranscriptionProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    if (provider.isListening)
                      const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.red,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      provider.isListening ? 'Listening...' : 'Not Active',
                      style: TextStyle(
                        color: provider.isListening ? Colors.red : Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TranscriptionProvider>(
        builder: (context, provider, child) {
          // Auto-scroll when text changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.transcribedText.isNotEmpty) {
              _scrollToBottom();
            }
          });

          return SafeArea(
            child: Column(
              children: [
                // Status and info panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            provider.isInitialized
                                ? Icons.check_circle
                                : Icons.error,
                            color: provider.isInitialized
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.isInitialized
                                ? 'Speech Recognition Ready'
                                : 'Not Initialized',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (provider.confidenceLevel > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.analytics_outlined,
                              color: Colors.blue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Confidence: ${(provider.confidenceLevel * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (provider.errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.errorMessage,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Transcription text area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child: provider.transcribedText.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mic_none,
                                  size: 80,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Start recording in the "Start" tab\nto see live transcription here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 18,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Minimal latency mode enabled',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            child: SelectableText(
                              provider.transcribedText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 1.6,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                  ),
                ),

                // Action buttons
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Clear button
                      ElevatedButton.icon(
                        onPressed: provider.transcribedText.isNotEmpty
                            ? () {
                                provider.clearTranscription();
                              }
                            : null,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),

                      // Copy button
                      ElevatedButton.icon(
                        onPressed: provider.transcribedText.isNotEmpty
                            ? () {
                                // Copy to clipboard functionality can be added here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copy functionality - coming soon!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

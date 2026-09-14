import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/app_colors.dart';

class VoiceSearchBottomSheet extends StatefulWidget {
  const VoiceSearchBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceSearchBottomSheet(),
    );
  }

  @override
  State<VoiceSearchBottomSheet> createState() => _VoiceSearchBottomSheetState();
}

class _VoiceSearchBottomSheetState extends State<VoiceSearchBottomSheet>
    with SingleTickerProviderStateMixin {
  late final stt.SpeechToText _speech;
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _statusMessage = 'Initializing microphone...';
  late AnimationController _pulseController;

  final List<String> _quickSuggestions = [
    'Hikvision 4K Camera',
    'CP Plus 8CH DVR',
    'Dome Camera',
    'Bullet Camera',
    'WiFi IP Camera',
    'Night Vision CCTV',
    'Hard Disk 2TB',
    'CCTV Power Supply',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initSpeechAndListen();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initSpeechAndListen() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (mounted) {
        setState(() {
          _isSpeechInitialized = available;
        });

        if (available) {
          _startListening();
        } else {
          setState(() {
            _statusMessage = 'Speech recognition unavailable on this device.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpeechInitialized = false;
          _statusMessage = 'Could not access microphone: $e';
        });
      }
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      setState(() {
        _isListening = true;
        _statusMessage = 'Listening... Speak now';
      });
    } else if (status == 'notListening' || status == 'done') {
      setState(() {
        _isListening = false;
        if (_recognizedText.trim().isEmpty) {
          _statusMessage = 'Tap mic to try again';
        }
      });
      // Auto-submit if words were recognized
      if (_recognizedText.trim().isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && _recognizedText.trim().isNotEmpty) {
            Navigator.pop(context, _recognizedText.trim());
          }
        });
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _statusMessage = 'Tap mic to speak or choose a keyword';
    });
  }

  Future<void> _startListening() async {
    if (!_isSpeechInitialized) {
      await _initSpeechAndListen();
      return;
    }

    setState(() {
      _recognizedText = '';
      _statusMessage = 'Listening... Speak now';
      _isListening = true;
    });

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (mounted) {
            setState(() {
              _recognizedText = result.recognizedWords;
              if (result.finalResult && _recognizedText.trim().isNotEmpty) {
                _statusMessage = 'Searching for "$_recognizedText"...';
              }
            });

            if (result.finalResult && _recognizedText.trim().isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.pop(context, _recognizedText.trim());
                }
              });
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.search,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = 'Error listening: $e';
        });
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.mic, color: AppColors.primaryRed, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Voice Search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Pulsing Mic Button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _isListening ? 1.0 + (_pulseController.value * 0.15) : 1.0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening)
                    Container(
                      width: 100 * scale,
                      height: 100 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryRed.withValues(alpha: 0.18),
                      ),
                    ),
                  if (_isListening)
                    Container(
                      width: 84 * scale,
                      height: 84 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryRed.withValues(alpha: 0.30),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isListening
                              ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                              : [const Color(0xFF475569), const Color(0xFF334155)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? AppColors.primaryRed : Colors.grey)
                                .withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Status & Recognized text
          Text(
            _isListening ? 'Listening...' : _statusMessage,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isListening ? AppColors.primaryRed : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(minHeight: 50),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _recognizedText.isNotEmpty
                    ? AppColors.primaryRed.withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _recognizedText.isEmpty ? 'Say camera brand, model, or category...' : '"$_recognizedText"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: _recognizedText.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                color: _recognizedText.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                fontStyle: _recognizedText.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),

          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, _recognizedText.trim()),
                icon: const Icon(Icons.search, color: Colors.white, size: 18),
                label: Text(
                  'Search "$_recognizedText"',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Quick Suggestion Chips
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Popular Searches:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((suggestion) {
              return InkWell(
                onTap: () => Navigator.pop(context, suggestion),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up, size: 14, color: AppColors.primaryRed),
                      const SizedBox(width: 6),
                      Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

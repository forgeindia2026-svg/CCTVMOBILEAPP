import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class AudioHelper {
  static final _audioRecorder = AudioRecorder();
  static final _audioPlayer = AudioPlayer();
  static String? _recordedFilePath;
  static String? _recordedBase64;

  static Future<void> startMicRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        Directory tempDir = await getTemporaryDirectory();
        String path = '${tempDir.path}/audio_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        debugPrint('✅ Mic recording started: $path');
      } else {
        debugPrint('❌ Mic permission denied');
      }
    } catch (e) {
      debugPrint('AudioHelper startMicRecording error: $e');
    }
  }

  static Future<String?> stopMicRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        _recordedFilePath = path;
        final file = File(path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        _recordedBase64 = 'data:audio/m4a;base64,$base64String';
        debugPrint('✅ Mic recording stopped. Base64 length: ${_recordedBase64?.length}');
        return _recordedBase64;
      }
    } catch (e) {
      debugPrint('AudioHelper stopMicRecording error: $e');
    }
    return null;
  }

  static Future<String?> getRecordedAudioBase64() async {
    return _recordedBase64;
  }

  static void playVoicePlaybackSound(String text) async {
    if (_recordedFilePath != null) {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    } else if (_recordedBase64 != null) {
       playAudioData(_recordedBase64!);
    }
  }

  static String resolveAudioUrl(String rawAudio) {
    if (rawAudio.trim().isEmpty) return '';
    final str = rawAudio.trim();
    if (str.startsWith('data:audio')) {
      return str;
    }
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return ApiService.resolveImageUrl(str);
    }
    if (str.startsWith('/') || str.startsWith('uploads/')) {
      return ApiService.resolveImageUrl(str);
    }
    if (str.length > 100 && !str.contains(':')) {
      return 'data:audio/webm;base64,$str'; // Fallback
    }
    return str;
  }

  static void playAudioData(String audioUrlOrBase64) async {
    try {
      final resolved = resolveAudioUrl(audioUrlOrBase64);
      if (resolved.startsWith('data:audio')) {
        final parts = resolved.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          await _audioPlayer.play(BytesSource(bytes));
        }
      } else {
        await _audioPlayer.play(UrlSource(resolved));
      }
    } catch (e) {
      debugPrint('AudioHelper playAudioData error: $e');
    }
  }

  static void stopAudioData() async {
    await _audioPlayer.stop();
  }

  static void stopVoicePlaybackSound() async {
    await _audioPlayer.stop();
  }

  static void deleteMicRecording() {
    _recordedBase64 = null;
    if (_recordedFilePath != null) {
      try {
        final file = File(_recordedFilePath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
      _recordedFilePath = null;
    }
    _audioPlayer.stop();
  }
}

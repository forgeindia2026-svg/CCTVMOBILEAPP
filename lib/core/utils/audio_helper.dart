// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import 'dart:js_interop';
import '../services/api_service.dart';

@JS('eval')
external void _evalJS(String script);

class AudioHelper {
  static void startMicRecording() {
    if (!kIsWeb) return;
    try {
      try {
        html.window.sessionStorage.remove('sk_recorded_voice_base64');
        html.window.localStorage.remove('sk_recorded_voice_base64');
        html.window.localStorage.remove('flutter.sk_recorded_voice_base64');
        final currentWinName = html.window.name ?? '';
        if (currentWinName.startsWith('AUDIO_B64:')) {
          html.window.name = '';
        }
      } catch (_) {}

      const script = '''
        (function() {
          try {
            window._audioChunks = [];
            window._recordedAudioUrl = null;
            window._recordedAudioBase64 = null;
            window._isAudioProcessingComplete = false;

            if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
              navigator.mediaDevices.getUserMedia({ audio: true }).then(function(stream) {
                window._micStream = stream;
                var mimeType = 'audio/webm';
                if (typeof MediaRecorder !== 'undefined') {
                  if (MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
                    mimeType = 'audio/webm;codecs=opus';
                  } else if (MediaRecorder.isTypeSupported('audio/webm')) {
                    mimeType = 'audio/webm';
                  } else if (MediaRecorder.isTypeSupported('audio/mp4')) {
                    mimeType = 'audio/mp4';
                  } else if (MediaRecorder.isTypeSupported('audio/ogg')) {
                    mimeType = 'audio/ogg';
                  }
                }
                try {
                  window._mediaRecorder = new MediaRecorder(stream, { mimeType: mimeType });
                } catch(e) {
                  window._mediaRecorder = new MediaRecorder(stream);
                }
                window._mediaRecorder.ondataavailable = function(e) {
                  if (e.data && e.data.size > 0) {
                    window._audioChunks.push(e.data);
                  }
                };
                window._mediaRecorder.start(100);
                console.log('✅ Mic recording started successfully with mimeType:', window._mediaRecorder.mimeType);
              }).catch(function(err) {
                console.error('Mic permission/access error:', err);
              });
            }
          } catch(e) { console.error('startMicRecording error:', e); }
        })();
      ''';
      _evalJS(script);
    } catch (e) {
      debugPrint('AudioHelper startMicRecording error: $e');
    }
  }

  static Future<String?> stopMicRecording() async {
    if (!kIsWeb) return null;
    try {
      const script = '''
        (function() {
          try {
            window._isAudioProcessingComplete = false;
            if (window._mediaRecorder && window._mediaRecorder.state !== 'inactive') {
              window._mediaRecorder.onstop = function() {
                try {
                  if (window._audioChunks && window._audioChunks.length > 0) {
                    var mimeType = (window._mediaRecorder && window._mediaRecorder.mimeType) ? window._mediaRecorder.mimeType : 'audio/webm';
                    var blob = new Blob(window._audioChunks, { type: mimeType });
                    if (window._recordedAudioUrl) {
                      URL.revokeObjectURL(window._recordedAudioUrl);
                    }
                    window._recordedAudioUrl = URL.createObjectURL(blob);
                    
                    var reader = new FileReader();
                    reader.readAsDataURL(blob);
                    reader.onloadend = function() {
                      var base64Data = reader.result;
                      window._recordedAudioBase64 = base64Data;
                      window._isAudioProcessingComplete = true;

                      try {
                        var elem = document.getElementById('sk_voice_b64_elem');
                        if (!elem) {
                          elem = document.createElement('input');
                          elem.id = 'sk_voice_b64_elem';
                          elem.type = 'hidden';
                          document.body.appendChild(elem);
                        }
                        elem.value = base64Data;
                      } catch(e){}

                      try {
                        window.name = 'AUDIO_B64:' + base64Data;
                      } catch(e){}
                      try {
                        sessionStorage.setItem('sk_recorded_voice_base64', base64Data);
                      } catch(e){}
                      try {
                        localStorage.setItem('sk_recorded_voice_base64', base64Data);
                      } catch(e){}
                      console.log('✅ Customer Voice Note Base64 ready! MIME:', mimeType, 'Length:', (base64Data || '').length);
                    };
                  } else {
                    window._isAudioProcessingComplete = true;
                  }
                } catch(err) {
                  console.error('Error creating audio blob:', err);
                  window._isAudioProcessingComplete = true;
                }
                if (window._micStream) {
                  window._micStream.getTracks().forEach(function(track) { track.stop(); });
                  window._micStream = null;
                }
              };
              window._mediaRecorder.stop();
            } else if (window._micStream) {
              window._micStream.getTracks().forEach(function(track) { track.stop(); });
              window._micStream = null;
              window._isAudioProcessingComplete = true;
            } else {
              window._isAudioProcessingComplete = true;
            }
          } catch(e) { 
            console.error('stopMicRecording error:', e);
            window._isAudioProcessingComplete = true;
          }
        })();
      ''';
      _evalJS(script);

      return await getRecordedAudioBase64();
    } catch (e) {
      debugPrint('AudioHelper stopMicRecording error: $e');
      return null;
    }
  }

  static Future<String?> getRecordedAudioBase64() async {
    if (!kIsWeb) return null;
    try {
      for (int i = 0; i < 60; i++) {
        // 0. Check DOM hidden element (100% reliable synchronous Web DOM access)
        try {
          final elem = html.document.getElementById('sk_voice_b64_elem') as html.InputElement?;
          final domVal = elem?.value;
          if (domVal != null && domVal.length > 300 && domVal.startsWith('data:audio')) {
            return domVal;
          }
        } catch (_) {}

        // 1. Check window.name memory backup safely
        try {
          final winName = html.window.name ?? '';
          if (winName.startsWith('AUDIO_B64:')) {
            final str = winName.substring('AUDIO_B64:'.length);
            if (str.length > 300 && str.startsWith('data:audio')) {
              return str;
            }
          }
        } catch (_) {}

        // 2. Check sessionStorage / localStorage
        try {
          final sessionStr = html.window.sessionStorage['sk_recorded_voice_base64'];
          if (sessionStr != null && sessionStr.length > 300 && sessionStr.startsWith('data:audio')) {
            return sessionStr;
          }
          final localStr = html.window.localStorage['sk_recorded_voice_base64'] ?? html.window.localStorage['flutter.sk_recorded_voice_base64'];
          if (localStr != null && localStr.length > 300 && localStr.startsWith('data:audio')) {
            return localStr;
          }
        } catch (_) {}

        // 3. Check SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          final stored = prefs.getString('sk_recorded_voice_base64');
          if (stored != null && stored.isNotEmpty && stored.length > 300 && stored.startsWith('data:audio')) {
            return stored;
          }
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      debugPrint('AudioHelper getRecordedAudioBase64 error: $e');
    }
    return null;
  }

  static void playVoicePlaybackSound(String text) {
    if (!kIsWeb) return;
    try {
      const script = '''
        (function() {
          try {
            if (window._playingAudioElem) {
              try { window._playingAudioElem.pause(); } catch(e){}
            }
            if (window._recordedAudioUrl) {
              var audio = new Audio(window._recordedAudioUrl);
              window._playingAudioElem = audio;
              audio.volume = 1.0;
              audio.play().then(function() {
                console.log('Playing recorded audio in mobile app!');
              }).catch(function(err) {
                console.warn('Audio play failed:', err);
              });
            }
          } catch(e) { console.error('Audio playback error:', e); }
        })();
      ''';
      _evalJS(script);
    } catch (e) {
      debugPrint('AudioHelper play error: $e');
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
      return 'data:audio/webm;base64,$str';
    }
    return str;
  }

  static void playAudioData(String audioUrlOrBase64) {
    if (!kIsWeb) return;
    try {
      final resolved = resolveAudioUrl(audioUrlOrBase64);
      final safeUrl = resolved.replaceAll("'", "\\'").replaceAll("\r", "").replaceAll("\n", "");
      final script = '''
        (function() {
          try {
            if (window._playingAudioElem) {
              try { window._playingAudioElem.pause(); } catch(e){}
            }
            var audio = new Audio('$safeUrl');
            window._playingAudioElem = audio;
            audio.volume = 1.0;
            audio.play().then(function() {
              console.log('Playing audio note from server/database');
            }).catch(function(err) {
              console.warn('Audio play failed:', err);
            });
          } catch(e) { console.error('Audio playback error:', e); }
        })();
      ''';
      _evalJS(script);
    } catch (e) {
      debugPrint('AudioHelper playAudioData error: $e');
    }
  }

  static void stopAudioData() {
    if (!kIsWeb) return;
    try {
      const script = '''
        (function() {
          try {
            if (window._playingAudioElem) {
              try { window._playingAudioElem.pause(); window._playingAudioElem.currentTime = 0; } catch(e){}
              window._playingAudioElem = null;
            }
          } catch(e) {}
        })();
      ''';
      _evalJS(script);
    } catch (e) {
      debugPrint('AudioHelper stopAudioData error: $e');
    }
  }

  static void stopVoicePlaybackSound() {
    if (!kIsWeb) return;
    try {
      const script = '''
        (function() {
          try {
            if (window._playingAudioElem) {
              try { window._playingAudioElem.pause(); window._playingAudioElem.currentTime = 0; } catch(e){}
              window._playingAudioElem = null;
            }
          } catch(e) {}
        })();
      ''';
      _evalJS(script);
    } catch (e) {
      debugPrint('AudioHelper stop error: $e');
    }
  }

  static void deleteMicRecording() {
    if (!kIsWeb) return;
    try {
      try {
        final elem = html.document.getElementById('sk_voice_b64_elem') as html.InputElement?;
        if (elem != null) elem.value = '';
        html.window.sessionStorage.remove('sk_recorded_voice_base64');
        html.window.localStorage.remove('sk_recorded_voice_base64');
        html.window.localStorage.remove('flutter.sk_recorded_voice_base64');
        final currentWinName = html.window.name ?? '';
        if (currentWinName.startsWith('AUDIO_B64:')) {
          html.window.name = '';
        }
      } catch (_) {}

      const script = '''
        (function() {
          try {
            if (window._playingAudioElem) {
              try { window._playingAudioElem.pause(); } catch(e){}
              window._playingAudioElem = null;
            }
            if (window._recordedAudioUrl) {
              URL.revokeObjectURL(window._recordedAudioUrl);
              window._recordedAudioUrl = null;
            }
            window._recordedAudioBase64 = null;
            window._audioChunks = [];
            window._isAudioProcessingComplete = false;
            console.log('Voice recording cleared');
          } catch(e) {}
        })();
      ''';
      _evalJS(script);
    } catch (e) {
      debugPrint('AudioHelper deleteMicRecording error: $e');
    }
  }
}

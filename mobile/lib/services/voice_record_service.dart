import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'api_service.dart';

class VoiceRecordResult {
  final Uint8List bytes;
  final int durationSeconds;
  final String extension;
  final String? uploadedUrl;

  VoiceRecordResult({
    required this.bytes,
    required this.durationSeconds,
    required this.extension,
    this.uploadedUrl,
  });
}

class VoiceRecordService {
  static final VoiceRecordService _instance = VoiceRecordService._internal();
  factory VoiceRecordService() => _instance;
  VoiceRecordService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _startTime;

  bool get isRecording => _isRecording;

  /// Check whether the app has microphone recording permission
  Future<bool> hasPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('[VoiceRecord] Permission check error: $e');
      return false;
    }
  }

  /// Start recording voice
  Future<bool> startRecording() async {
    try {
      final perm = await hasPermission();
      if (!perm) {
        debugPrint('[VoiceRecord] Microphone permission not granted');
        return false;
      }

      _startTime = DateTime.now();

      if (kIsWeb) {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '',
        );
      } else {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: '',
        );
      }

      _isRecording = true;
      debugPrint('[VoiceRecord] Recording started successfully');
      return true;
    } catch (e) {
      debugPrint('[VoiceRecord] Failed to start recording: $e');
      _isRecording = false;
      _startTime = null;
      return false;
    }
  }

  /// Get current recording duration in seconds
  int getCurrentDuration() {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }

  /// Cancel current recording and discard the buffer
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    try {
      _isRecording = false;
      _startTime = null;
      await _audioRecorder.cancel();
      debugPrint('[VoiceRecord] Recording cancelled');
    } catch (e) {
      debugPrint('[VoiceRecord] Error cancelling recording: $e');
    }
  }

  /// Stop recording, fetch audio bytes, upload to Supabase Storage, and return result
  Future<VoiceRecordResult?> stopAndUpload() async {
    if (!_isRecording) return null;

    try {
      final elapsedSeconds = getCurrentDuration();
      _isRecording = false;
      _startTime = null;

      final path = await _audioRecorder.stop();
      if (path == null || path.isEmpty) {
        debugPrint('[VoiceRecord] Stop returned empty path');
        return null;
      }

      Uint8List? audioBytes;
      final ext = kIsWeb ? 'webm' : 'm4a';

      if (kIsWeb) {
        // On web, path is a blob URL e.g. blob:http://localhost:3000/uuid
        final response = await http.get(Uri.parse(path));
        if (response.statusCode == 200) {
          audioBytes = response.bodyBytes;
        }
      } else {
        // Native platforms
        try {
          final response = await http.get(Uri.parse(path));
          if (response.statusCode == 200) {
            audioBytes = response.bodyBytes;
          }
        } catch (_) {}
      }

      if (audioBytes == null || audioBytes.isEmpty) {
        debugPrint('[VoiceRecord] Failed to load audio bytes');
        return null;
      }

      debugPrint('[VoiceRecord] Audio recorded: ${audioBytes.length} bytes, duration: ${elapsedSeconds}s');

      // Upload to Supabase Storage via backend API
      final filename = 'voice_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final publicUrl = await ApiService.uploadMedia(
        bytes: audioBytes,
        filename: filename,
        ext: ext,
      );

      debugPrint('[VoiceRecord] Audio uploaded to Supabase Storage: $publicUrl');

      return VoiceRecordResult(
        bytes: audioBytes,
        durationSeconds: elapsedSeconds > 0 ? elapsedSeconds : 1,
        extension: ext,
        uploadedUrl: publicUrl,
      );
    } catch (e) {
      debugPrint('[VoiceRecord] Error in stopAndUpload: $e');
      return null;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}

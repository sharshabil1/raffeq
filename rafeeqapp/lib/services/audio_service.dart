import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingData {
  final String path;
  final List<int> bytes;
  final String filename;

  AudioRecordingData({
    required this.path,
    required this.bytes,
    required this.filename,
  });
}

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _startTime;
  Timer? _timer;
  int _secondsRecorded = 0;

  bool get isRecording => _isRecording;
  int get secondsRecorded => _secondsRecorded;

  Future<bool> hasPermission() async {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      return true;
    }
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return true;
    }
  }

  Future<void> startRecording({required Function(int seconds) onTick}) async {
    if (_isRecording) return;

    if (!kIsWeb && !(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      try {
        final hasPerm = await hasPermission();
        if (!hasPerm) {
          throw Exception('Microphone permission not granted.');
        }
      } catch (_) {}
    }

    String path = '';
    AudioEncoder encoder = AudioEncoder.aacLc;

    if (!kIsWeb) {
      final tempDir = await getTemporaryDirectory();
      if (Platform.isLinux || Platform.isWindows) {
        encoder = AudioEncoder.wav;
        path =
            '${tempDir.path}/entry_${DateTime.now().millisecondsSinceEpoch}.wav';
      } else {
        path =
            '${tempDir.path}/entry_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
    }

    await _recorder.start(
      RecordConfig(encoder: encoder),
      path: path,
    );

    _isRecording = true;
    _startTime = DateTime.now();
    _secondsRecorded = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (_startTime != null) {
        _secondsRecorded = DateTime.now().difference(_startTime!).inSeconds;
        onTick(_secondsRecorded);
      }
    });
  }

  Future<AudioRecordingData?> stopRecording() async {
    if (!_isRecording) return null;
    _timer?.cancel();
    _isRecording = false;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }

    if (path == null) return null;

    List<int> bytes = [];
    String filename = 'entry.wav';

    if (kIsWeb) {
      // handled via blob
    } else {
      final file = File(path);
      if (await file.exists()) {
        bytes = await file.readAsBytes();
        filename = path.split('/').last;
      }
    }

    return AudioRecordingData(
      path: path,
      bytes: bytes,
      filename: filename,
    );
  }

  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
  }
}

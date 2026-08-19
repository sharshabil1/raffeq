import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_orb.dart';

enum JournalMode { text, voice }

class JournalScreen extends StatefulWidget {
  final Function(String message) showBanner;

  const JournalScreen({super.key, required this.showBanner});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  JournalMode _mode = JournalMode.text;
  final TextEditingController _textController = TextEditingController();
  final AudioService _audioService = AudioService();

  bool _isRecording = false;
  int _recSeconds = 0;

  bool _isReflecting = false;
  String _reflectingText = 'Rafeeq is reflecting on this…';

  bool _showResult = false;
  JobResultModel? _resultData;

  @override
  void dispose() {
    _textController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  void _resetScreen() {
    setState(() {
      _showResult = false;
      _isReflecting = false;
      _resultData = null;
      _textController.clear();
      _mode = JournalMode.text;
    });
  }

  Future<void> _submitTextJournal() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isReflecting = true;
      _reflectingText = AppState.instance.t('reflecting');
    });

    final res = await ApiService.instance.submitTextJob(text);
    if (res.ok && res.data is Map) {
      final jobId = (res.data['job_id'] ?? res.data['id'])?.toString();
      if (jobId != null) {
        _pollJob(jobId);
      } else {
        _showError('Job created, but no job_id was returned.');
      }
    } else {
      _showError(res.errorMsg ?? 'Failed submitting text entry.');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await _audioService.startRecording(onTick: (secs) {
        if (mounted) {
          setState(() {
            _isRecording = true;
            _recSeconds = secs;
          });
        }
      });
      if (mounted) {
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      widget.showBanner(
        AppState.instance.isArabic
            ? 'تعذر بدء التسجيل. يمكنك استخدام زر "رفع ملف صوتي".'
            : 'Could not start recording. You can use the "Upload audio file" button.',
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    setState(() => _isRecording = false);

    final recData = await _audioService.stopRecording();
    if (recData == null || recData.bytes.isEmpty) {
      widget.showBanner(
        AppState.instance.isArabic
            ? 'التسجيل قصير جداً، يرجى التحدث والتسجيل مجدداً.'
            : 'Recording was too short. Please try again.',
      );
      return;
    }

    setState(() {
      _isReflecting = true;
      _reflectingText = AppState.instance.t('processing_voice');
    });

    final res = await ApiService.instance.uploadAudio(
      path: '/api/v1/jobs/upload',
      filePath: recData.path,
      bytes: recData.bytes,
      filename: recData.filename,
    );

    if (res.ok && res.data is Map) {
      final jobId = (res.data['job_id'] ?? res.data['id'])?.toString();
      if (jobId != null) {
        _pollJob(jobId);
      } else {
        _showError('Voice uploaded, but no job_id returned.');
      }
    } else {
      _showError(res.errorMsg ?? 'Failed uploading voice entry.');
    }
  }

  Future<void> _pickAndUploadAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'm4a',
          'mp3',
          'wav',
          'aac',
          'ogg',
          'flac',
          'opus',
          'mp4',
          'm4r'
        ],
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      List<int>? bytes = file.bytes;
      if ((bytes == null || bytes.isEmpty) && file.path != null) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          bytes = await ioFile.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        widget.showBanner(AppState.instance.isArabic
            ? 'تعذر قراءة ملف الصوت.'
            : 'Could not read audio file bytes.');
        return;
      }

      setState(() {
        _isReflecting = true;
        _reflectingText = AppState.instance.t('processing_voice');
      });

      final res = await ApiService.instance.uploadAudio(
        path: '/api/v1/jobs/upload',
        filePath: file.path ?? file.name,
        bytes: bytes,
        filename: file.name,
      );

      if (res.ok && res.data is Map) {
        final jobId = (res.data['job_id'] ?? res.data['id'])?.toString();
        if (jobId != null) {
          _pollJob(jobId);
        } else {
          _showError('Audio uploaded, but no job_id was returned.');
        }
      } else {
        _showError(res.errorMsg ?? 'Failed uploading audio file.');
      }
    } catch (e) {
      widget.showBanner('Error picking audio file: $e');
    }
  }

  Future<void> _pollJob(String jobId, [int attempt = 0]) async {
    if (attempt > 40) {
      if (mounted) {
        setState(() {
          _reflectingText = AppState.instance.isArabic
              ? 'يستغرق هذا وقتاً أطول من المتوقع — عد لاحقاً.'
              : 'This is taking longer than expected — check back in a bit.';
        });
      }
      return;
    }

    final res = await ApiService.instance.getJobStatus(jobId);
    if (!mounted) return;

    if (res.ok && res.data is Map) {
      final statusVal = (res.data['status'] ?? res.data['state'] ?? '')
          .toString()
          .toLowerCase();

      if (['completed', 'done', 'success', 'finished', 'complete']
          .contains(statusVal)) {
        final resultRes = await ApiService.instance.getJobResults(jobId);
        if (mounted) {
          setState(() {
            _isReflecting = false;
            _showResult = true;
            if (resultRes.ok && resultRes.data != null) {
              _resultData = JobResultModel.fromJson(resultRes.data);
            } else {
              _resultData = JobResultModel(
                id: jobId,
                jobType: 'text',
                status: 'completed',
                summary: 'Rafeeq processed your entry.',
                sentiment: 'neutral',
                keywords: [],
                createdAt: DateTime.now().toIso8601String(),
              );
            }
          });
        }
      } else if (['failed', 'error'].contains(statusVal)) {
        setState(() {
          _reflectingText = AppState.instance.isArabic
              ? 'حدثت مشكلة أثناء معالجة التدوينة. يمكنك المحاولة مجدداً.'
              : 'Rafeeq had trouble processing that entry. You can try again.';
        });
        Timer(const Duration(seconds: 3), _resetScreen);
      } else {
        Timer(const Duration(milliseconds: 2500),
            () => _pollJob(jobId, attempt + 1));
      }
    } else {
      Timer(const Duration(milliseconds: 2500),
          () => _pollJob(jobId, attempt + 1));
    }
  }

  void _showError(String msg) {
    widget.showBanner(msg);
    setState(() {
      _isReflecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: SingleChildScrollView(
            key: ValueKey('$_isReflecting-$_showResult-$_mode-$isDark'),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  appState.t('todays_entry'),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.ink(isDark),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  appState.t('journal_subtitle'),
                  style: TextStyle(
                    color: AppColors.muted(isDark),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                if (!_isReflecting && !_showResult) ...[
                  // Mode Switcher
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft(isDark),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line(isDark)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _mode = JournalMode.text),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _mode == JournalMode.text
                                    ? AppColors.ink(isDark)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                appState.t('type_mode'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _mode == JournalMode.text
                                      ? AppColors.surface(isDark)
                                      : AppColors.muted(isDark),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _mode = JournalMode.voice),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _mode == JournalMode.voice
                                    ? AppColors.ink(isDark)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                appState.t('talk_mode'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _mode == JournalMode.voice
                                      ? AppColors.surface(isDark)
                                      : AppColors.muted(isDark),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_mode == JournalMode.text) ...[
                    TextField(
                      controller: _textController,
                      maxLines: 8,
                      style: TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          color: AppColors.ink(isDark)),
                      decoration: InputDecoration(
                        hintText: appState.t('type_hint'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink(isDark),
                        foregroundColor: AppColors.surface(isDark),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: _submitTextJournal,
                      child: Text(
                        appState.t('save_entry'),
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: _toggleRecording,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isRecording ? 108 : 96,
                          height: _isRecording ? 108 : 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _isRecording
                                  ? const [
                                      Color(0xFFF0C6C2),
                                      AppColors.rose,
                                      Color(0xFF9B4A4D)
                                    ]
                                  : const [
                                      Color(0xFFDCB7D0),
                                      AppColors.plum,
                                      AppColors.plumDeep
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording
                                        ? AppColors.rose
                                        : AppColors.plum)
                                    .withValues(alpha: 0.4),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        _isRecording
                            ? '${appState.t('recording')} ${_recSeconds}s (${appState.t('tap_to_stop')})'
                            : appState.t('tap_to_record'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isRecording
                              ? AppColors.rose
                              : AppColors.muted(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: AppColors.line(isDark)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            appState.isArabic ? 'أو' : 'OR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.faint(isDark),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: AppColors.line(isDark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Upload Audio File button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                            color: AppColors.plum.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(Icons.upload_file,
                          size: 18, color: AppColors.plum),
                      label: Text(
                        appState.t('upload_audio'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.plum,
                        ),
                      ),
                      onPressed: _pickAndUploadAudioFile,
                    ),
                    const SizedBox(height: 20),
                  ],
                ],

                if (_isReflecting) ...[
                  const SizedBox(height: 50),
                  const Center(
                      child: BreathingOrb(size: 64, isListening: true)),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      _reflectingText,
                      style: TextStyle(
                        color: AppColors.muted(isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                if (_showResult && _resultData != null) ...[
                  _buildResultCard(context, isDark, _resultData!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(
      BuildContext context, bool isDark, JobResultModel result) {
    final appState = AppState.instance;

    Color sentimentBg = AppColors.plum.withValues(alpha: 0.1);
    Color sentimentFg = AppColors.plum;
    if (result.sentiment == 'positive') {
      sentimentBg = AppColors.sage.withValues(alpha: 0.15);
      sentimentFg = const Color(0xFF2E5C43);
    } else if (result.sentiment == 'negative') {
      sentimentBg = AppColors.rose.withValues(alpha: 0.15);
      sentimentFg = const Color(0xFF8A3034);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.sage,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appState.t('noticed_title'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink(isDark),
                    ),
                  ),
                ],
              ),
              if (result.sentiment.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sentimentBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    result.sentiment.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: sentimentFg,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            result.summary,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: AppColors.ink(isDark),
            ),
          ),
          if (result.keywords.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.keywords.map((kw) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface(isDark),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.line(isDark)),
                  ),
                  child: Text(
                    '#$kw',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.plum,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppColors.line(isDark)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: _resetScreen,
            child: Center(
              child: Text(
                appState.t('write_another'),
                style: TextStyle(
                  color: AppColors.muted(isDark),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

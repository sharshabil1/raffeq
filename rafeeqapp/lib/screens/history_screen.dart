import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final Function(String message) showBanner;

  const HistoryScreen({super.key, required this.showBanner});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<JournalEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final res = await ApiService.instance.getJournals();

    if (!res.ok) {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.showBanner(AppState.instance.isArabic
            ? 'تعذر تحميل اليوميات.'
            : 'Could not load your journals.');
      }
      return;
    }

    List items = [];
    if (res.data is List) {
      items = res.data;
    } else if (res.data is Map) {
      items = (res.data['items'] ?? res.data['entries']) as List? ?? [];
    }

    _entries = items.map((e) => JournalEntry.fromJson(e)).toList();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _openJournalDetail(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JournalDetailModal(
        entrySummary: entry,
        showBanner: widget.showBanner,
        onDeleted: () {
          _loadHistory();
        },
      ),
    );
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          appState.isArabic ? 'حذف التدوينة' : 'Delete Journal',
          style: TextStyle(color: AppColors.ink(isDark)),
        ),
        content: Text(
          appState.isArabic
              ? 'هل أنت تأكد من رغبتك في حذف هذه التدوينة؟'
              : 'Are you sure you want to delete this journal entry?',
          style: TextStyle(color: AppColors.muted(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appState.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rose),
            child: Text(appState.isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiService.instance.deleteJournal(entry.id);
    if (res.ok) {
      widget.showBanner(
          appState.isArabic ? 'تم حذف التدوينة.' : 'Journal entry deleted.');
      _loadHistory();
    } else {
      widget.showBanner(res.errorMsg ?? 'Failed deleting entry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                appState.t('reflections_title'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.ink(isDark),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                appState.t('reflections_sub'),
                style: TextStyle(color: AppColors.muted(isDark), fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: AppColors.plum),
                  ),
                )
              else if (_entries.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft(isDark),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line(isDark)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.menu_book_outlined,
                          color: AppColors.faint(isDark), size: 36),
                      const SizedBox(height: 10),
                      Text(
                        appState.t('no_reflections'),
                        style: TextStyle(
                            color: AppColors.muted(isDark), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final item = _entries[index];
                    String dateStr = 'Entry';
                    if (item.date.isNotEmpty) {
                      try {
                        final dt = DateTime.parse(item.date);
                        dateStr = DateFormat('MMM d, yyyy', appState.language)
                            .format(dt);
                      } catch (_) {}
                    }

                    Color sentimentColor = AppColors.faint(isDark);
                    if (item.sentiment == 'positive') {
                      sentimentColor = AppColors.sage;
                    } else if (item.sentiment == 'negative') {
                      sentimentColor = AppColors.rose;
                    }

                    final isAudio = item.jobType == 'audio';

                    return InkWell(
                      onTap: () => _openJournalDetail(item),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft(isDark),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line(isDark)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.plum.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAudio ? Icons.mic : Icons.edit_note,
                                size: 18,
                                color: AppColors.plum,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        dateStr.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.faint(isDark),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '• ${isAudio ? appState.t('voice_entry') : appState.t('text_entry')}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.faint(isDark),
                                        ),
                                      ),
                                      if (item.sentiment != null &&
                                          item.sentiment!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: sentimentColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.summary,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.8,
                                      color: AppColors.ink(isDark),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        appState.t('read_journal'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.plum,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 10,
                                        color: AppColors.plum,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.faint(isDark),
                              ),
                              onPressed: () => _deleteEntry(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      );
    },
  );
}
}

class JournalDetailModal extends StatefulWidget {
  final JournalEntry entrySummary;
  final Function(String message) showBanner;
  final VoidCallback onDeleted;

  const JournalDetailModal({
    super.key,
    required this.entrySummary,
    required this.showBanner,
    required this.onDeleted,
  });

  @override
  State<JournalDetailModal> createState() => _JournalDetailModalState();
}

class _JournalDetailModalState extends State<JournalDetailModal> {
  JobResultModel? _fullResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    setState(() => _isLoading = true);
    final res =
        await ApiService.instance.getJobResults(widget.entrySummary.id);

    if (res.ok && res.data != null) {
      _fullResult = JobResultModel.fromJson(res.data);
    } else {
      // Fallback to summary item data
      _fullResult = JobResultModel(
        id: widget.entrySummary.id,
        jobType: widget.entrySummary.jobType,
        status: widget.entrySummary.status,
        summary: widget.entrySummary.summary,
        sentiment: widget.entrySummary.sentiment ?? 'neutral',
        keywords: [],
        createdAt: widget.entrySummary.date,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteThisEntry() async {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          appState.isArabic ? 'حذف التدوينة' : 'Delete Journal',
          style: TextStyle(color: AppColors.ink(isDark)),
        ),
        content: Text(
          appState.isArabic
              ? 'هل أنت تأكد من رغبتك في حذف هذه التدوينة؟'
              : 'Are you sure you want to delete this journal entry?',
          style: TextStyle(color: AppColors.muted(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appState.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rose),
            child: Text(appState.isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiService.instance.deleteJournal(widget.entrySummary.id);
    if (res.ok) {
      if (mounted) Navigator.pop(context);
      widget.showBanner(
          appState.isArabic ? 'تم حذف التدوينة.' : 'Journal entry deleted.');
      widget.onDeleted();
    } else {
      widget.showBanner(res.errorMsg ?? 'Failed deleting entry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;

    String dateStr = 'Journal Entry';
    if (widget.entrySummary.date.isNotEmpty) {
      try {
        final dt = DateTime.parse(widget.entrySummary.date);
        dateStr =
            DateFormat('EEEE, MMMM d, yyyy', appState.language).format(dt);
      } catch (_) {}
    }

    final isAudio = widget.entrySummary.jobType == 'audio';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.plum.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAudio ? Icons.mic : Icons.edit_note,
                      color: AppColors.plum,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAudio
                            ? appState.t('voice_entry')
                            : appState.t('text_entry'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink(isDark),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.muted(isDark)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.plum),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Original Content Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft(isDark),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.line(isDark)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.format_quote,
                                    size: 18,
                                    color: AppColors.plum,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    appState.t('original_text'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.faint(isDark),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SelectableText(
                                (_fullResult?.textPrompt ??
                                            _fullResult?.transcription ??
                                            _fullResult?.summary ??
                                            '')
                                        .isNotEmpty
                                    ? (_fullResult?.textPrompt ??
                                        _fullResult?.transcription ??
                                        _fullResult?.summary ??
                                        '')
                                    : 'No text recorded.',
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: AppColors.ink(isDark),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // AI Insights & Reflection Card
                        if (_fullResult != null) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft(isDark),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.line(isDark)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: AppColors.sage,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          appState.t('ai_insights'),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.ink(isDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_fullResult!.sentiment.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.plum
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          _fullResult!.sentiment.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.plum,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SelectableText(
                                  _fullResult!.summary,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: AppColors.ink(isDark),
                                  ),
                                ),
                                if (_fullResult!.keywords.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children:
                                        _fullResult!.keywords.map((kw) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface(isDark),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                              color: AppColors.line(isDark)),
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
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: AppColors.rose),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.rose),
            label: Text(
              appState.isArabic ? 'حذف هذه التدوينة' : 'Delete this journal',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.rose,
              ),
            ),
            onPressed: _deleteThisEntry,
          ),
        ],
      ),
    );
  }
}

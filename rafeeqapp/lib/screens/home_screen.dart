import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/modals.dart';
import '../widgets/mood_chart.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  final Function(String screenName) onNavigate;
  final Function(String message) showBanner;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onNavigate,
    required this.showBanner,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  List<MoodPoint> _moodPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);

    final profRes = await ApiService.instance.getProfile();
    if (profRes.ok && profRes.data is Map<String, dynamic>) {
      _profile = UserProfile.fromJson(profRes.data);
    }

    final histRes = await ApiService.instance.getProfileHistory();
    if (histRes.ok) {
      List items = [];
      if (histRes.data is List) {
        items = histRes.data;
      } else if (histRes.data is Map) {
        final m = histRes.data as Map;
        items = (m['history'] ?? m['items'] ?? m['entries']) as List? ?? [];
      }

      _moodPoints = items.map((it) {
        double score = 5.0;
        if (it is Map) {
          final val =
              it['mood_score'] ?? it['score'] ?? it['value'] ?? it['mood'];
          if (val is num) score = val.toDouble();
          final rawDate =
              it['date'] ?? it['created_at'] ?? it['timestamp'] ?? '';
          String label = '';
          if (rawDate.toString().isNotEmpty) {
            try {
              final dt = DateTime.parse(rawDate.toString());
              label = DateFormat('MMM d', AppState.instance.language)
                  .format(dt);
            } catch (_) {}
          }
          return MoodPoint(label: label, score: score);
        }
        return MoodPoint(label: '', score: score);
      }).toList();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _openCheckinModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckinModal(
        onSubmit: (reflection) async {
          final res = await ApiService.instance.recalibrateProfile(reflection);
          if (res.ok) {
            widget.showBanner(AppState.instance.isArabic
                ? 'شكراً لك — رفيق دون ذلك.'
                : 'Thanks — Rafeeq noted that.');
            _loadHomeData();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;
    final name = widget.user?.email.split('@').first ?? 'there';
    final dateStr = DateFormat('EEEE, MMMM d', appState.language)
        .format(DateTime.now());
    final tags = _profile?.focusTags ?? [];

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                appState.t('hi', {'name': name}),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.ink(isDark),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: TextStyle(color: AppColors.muted(isDark), fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Focus Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft(isDark),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.line(isDark)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.sage,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          appState.t('focus_title'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.ink(isDark),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isLoading)
                      Text(
                        'Loading…',
                        style: TextStyle(
                          color: AppColors.faint(isDark),
                          fontSize: 12.5,
                        ),
                      )
                    else if (tags.isNotEmpty)
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: tags.take(8).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface(isDark),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.line(isDark)),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.plum,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        appState.t('focus_empty'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.faint(isDark),
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mood Chart Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft(isDark),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.line(isDark)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.sage,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          appState.t('trending_title'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.ink(isDark),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    MoodChart(points: _moodPoints),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onNavigate('journal'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft(isDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line(isDark)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.edit_note,
                                color: AppColors.plum, size: 22),
                            const SizedBox(height: 6),
                            Text(
                              appState.t('write_today'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onNavigate('chat'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft(isDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line(isDark)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                color: AppColors.plum, size: 22),
                            const SizedBox(height: 6),
                            Text(
                              appState.t('talk_rafeeq'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Checkin Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft(isDark),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.line(isDark)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.sage,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          appState.t('checkin_title'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.ink(isDark),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appState.t('checkin_desc'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted(isDark),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        side: BorderSide(color: AppColors.line(isDark)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: _openCheckinModal,
                      child: Text(
                        appState.t('checkin_btn'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink(isDark),
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
    );
  }
}

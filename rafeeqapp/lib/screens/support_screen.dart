import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  final Function(String message) showBanner;

  const SupportScreen({super.key, required this.showBanner});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  SupportResource? _supportResource;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupportResources();
  }

  Future<void> _loadSupportResources() async {
    setState(() => _isLoading = true);
    final res = await ApiService.instance.getSupportResources();

    if (res.ok && res.data is Map<String, dynamic>) {
      _supportResource = SupportResource.fromJson(res.data);
    } else {
      widget.showBanner(res.errorMsg ?? 'Failed loading support resources.');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;
    final contacts = _supportResource?.contacts ?? [];
    final strategies = _supportResource?.copingStrategies ?? [];
    final disclaimer = _supportResource?.disclaimer ?? '';

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                appState.t('support_title'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.ink(isDark),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                appState.t('support_sub'),
                style: TextStyle(color: AppColors.muted(isDark), fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.plum),
                  ),
                )
              else ...[
                if (disclaimer.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      disclaimer,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.ink(isDark),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  appState.t('crisis_title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.ink(isDark),
                      ),
                ),
                const SizedBox(height: 10),
                ...contacts.map((contact) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft(isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line(isDark)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                contact.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink(isDark),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.plum.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                contact.phone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.plum,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          contact.description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted(isDark),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),
                Text(
                  appState.t('coping_title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.ink(isDark),
                      ),
                ),
                const SizedBox(height: 10),
                ...strategies.map((strat) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft(isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line(isDark)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strat.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink(isDark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strat.description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted(isDark),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_orb.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStepIndex = 0;
  final Map<String, dynamic> _answers = {};
  bool _isLoading = false;

  List<OnboardingQuestion> get _questions {
    final isAr = AppState.instance.isArabic;
    return [
      OnboardingQuestion(
        key: 'motivation',
        question: isAr ? 'ما الذي يجلبك إلى رفيق؟' : 'What brings you to Rafeeq?',
        isMulti: false,
        options: isAr
            ? ['التوتر والقلق', 'تعكر المزاج', 'تحسين النوم', 'فهم نفسي أكثر', 'مجرد استكشاف']
            : ['Stress & anxiety', 'Low mood', 'Better sleep', 'Understanding myself', 'Just exploring'],
      ),
      OnboardingQuestion(
        key: 'main_goal',
        question: isAr ? 'ما هو هدفك الرئيسي حالياً؟' : "What's your main goal right now?",
        isMulti: false,
        options: isAr
            ? ['الشعور بالهدوء يومياً', 'فهم أنماط مشاعري', 'بناء عادة التدوين', 'الدعم في اللحظات الصعبة']
            : ['Feel calmer day-to-day', 'Understand my patterns', 'Build a journaling habit', 'Support in hard moments'],
      ),
      OnboardingQuestion(
        key: 'triggers',
        question: isAr ? 'ما هي أكبر محفزات التوتر لديك؟' : 'What are your biggest triggers?',
        isMulti: true,
        options: isAr
            ? ['العمل', 'المواقف الاجتماعية', 'العائلة', 'النوم', 'الصحة', 'المالية']
            : ['Work', 'Social situations', 'Family', 'Sleep', 'Health', 'Finances'],
      ),
      OnboardingQuestion(
        key: 'starting_feeling',
        question: isAr ? 'كيف تشعر تجاه البدء بهذه الرحلة؟' : 'How are you feeling about starting this?',
        isMulti: false,
        options: isAr
            ? ['متفائل', 'قلق قليلاً', 'فضولي', 'لست متأكداً بعد']
            : ['Hopeful', 'Nervous', 'Curious', 'Not sure yet'],
      ),
    ];
  }

  void _toggleOption(OnboardingQuestion step, String option) {
    setState(() {
      if (step.isMulti) {
        final currentList = (_answers[step.key] as List<String>?) ?? [];
        if (currentList.contains(option)) {
          currentList.remove(option);
        } else {
          currentList.add(option);
        }
        _answers[step.key] = currentList;
      } else {
        _answers[step.key] = option;
      }
    });
  }

  bool _hasAnswer(OnboardingQuestion step) {
    final ans = _answers[step.key];
    if (step.isMulti) {
      return ans is List && ans.isNotEmpty;
    }
    return ans != null && ans.toString().isNotEmpty;
  }

  Future<void> _nextStep() async {
    if (_currentStepIndex < _questions.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      setState(() => _isLoading = true);
      final payload = {
        'what_brings_you': _answers['motivation']?.toString() ??
            _answers['what_brings_you']?.toString(),
        'main_goals': _answers['main_goal']?.toString() ??
            _answers['main_goals']?.toString(),
        'biggest_triggers': _answers['triggers'] is List
            ? List<String>.from(_answers['triggers'])
            : [],
        'additional_answers': _answers,
      };
      await ApiService.instance.submitOnboarding(payload);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      setState(() => _isLoading = false);
      widget.onFinished();
    }
  }

  Future<void> _skipOnboarding() async {
    final defaultPayload = {
      'what_brings_you': 'Skipped onboarding',
      'main_goals': 'General wellness',
      'biggest_triggers': [],
      'additional_answers': {'skipped': true},
    };
    await ApiService.instance.submitOnboarding(defaultPayload);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    widget.onFinished();
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;
    final step = _questions[_currentStepIndex];

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.surface(isDark),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_questions.length, (index) {
                      final isDone = index < _currentStepIndex;
                      final isNow = index == _currentStepIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppColors.sage
                              : (isNow
                                  ? AppColors.plum
                                  : AppColors.line(isDark)),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const BreathingOrb(size: 38),
                          const SizedBox(height: 20),
                          Text(
                            step.question,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  color: AppColors.ink(isDark),
                                ),
                          ),
                          const SizedBox(height: 24),
                          Column(
                            children: step.options.map((opt) {
                              final ans = _answers[step.key];
                              final isSelected = step.isMulti
                                  ? (ans is List && ans.contains(opt))
                                  : (ans == opt);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  onTap: () => _toggleOption(step, opt),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.plum
                                              .withValues(alpha: 0.08)
                                          : AppColors.surfaceSoft(isDark),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.plum
                                            : AppColors.line(isDark),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      opt,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.plum
                                            : AppColors.ink(isDark),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (_currentStepIndex > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: AppColors.line(isDark)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            onPressed: _prevStep,
                            child: Text(
                              appState.t('back'),
                              style: TextStyle(color: AppColors.muted(isDark)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ink(isDark),
                            foregroundColor: AppColors.surface(isDark),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: (!_hasAnswer(step) || _isLoading)
                              ? null
                              : _nextStep,
                          child: _isLoading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: AppColors.surface(isDark),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentStepIndex == _questions.length - 1
                                      ? appState.t('finish')
                                      : appState.t('next'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      appState.t('skip_for_now'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.faint(isDark),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

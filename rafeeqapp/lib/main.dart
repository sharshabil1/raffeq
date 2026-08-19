import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/support_screen.dart';
import 'services/api_service.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/banner_toast.dart';
import 'widgets/modals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  await AppState.instance.init();
  runApp(const RafeeqApp());
}

class RafeeqApp extends StatelessWidget {
  const RafeeqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final isDark = appState.isDarkMode;
        final isArabic = appState.isArabic;

        return MaterialApp(
          title: appState.t('app_name'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(isArabic),
          darkTheme: AppTheme.darkTheme(isArabic),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          locale: appState.locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('ar', ''),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: appState.textDirection,
              child: child!,
            );
          },
          home: const MainShell(),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _activeScreen =
      'auth'; // 'auth', 'onboarding', 'home', 'journal', 'history', 'chat', 'support'
  User? _user;
  UserProfile? _profile;

  String _bannerMessage = '';

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  void _showBanner(String message) {
    setState(() => _bannerMessage = message);
  }

  void _hideBanner() {
    setState(() => _bannerMessage = '');
  }

  Future<void> _checkInitialState() async {
    if (!ApiService.instance.isAuthenticated) {
      setState(() => _activeScreen = 'auth');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final localOnboarded = prefs.getBool('onboarding_completed') ?? false;

    final meRes = await ApiService.instance.getMe();
    if (meRes.ok && meRes.data is Map<String, dynamic>) {
      _user = User.fromJson(meRes.data);
    }

    if (localOnboarded) {
      setState(() => _activeScreen = 'home');
      return;
    }

    final profRes = await ApiService.instance.getProfile();
    if (profRes.ok && profRes.data is Map<String, dynamic>) {
      _profile = UserProfile.fromJson(profRes.data);
      if (_profile != null && _profile!.hasCompletedOnboarding) {
        await prefs.setBool('onboarding_completed', true);
        setState(() => _activeScreen = 'home');
      } else {
        setState(() => _activeScreen = 'onboarding');
      }
    } else {
      setState(() => _activeScreen = 'onboarding');
    }
  }

  void _handleAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final localOnboarded = prefs.getBool('onboarding_completed') ?? false;

    final meRes = await ApiService.instance.getMe();
    if (meRes.ok && meRes.data is Map<String, dynamic>) {
      _user = User.fromJson(meRes.data);
    }

    if (localOnboarded) {
      setState(() => _activeScreen = 'home');
      return;
    }

    final profRes = await ApiService.instance.getProfile();
    if (profRes.ok && profRes.data is Map<String, dynamic>) {
      _profile = UserProfile.fromJson(profRes.data);
      if (_profile != null && _profile!.hasCompletedOnboarding) {
        await prefs.setBool('onboarding_completed', true);
        setState(() => _activeScreen = 'home');
      } else {
        setState(() => _activeScreen = 'onboarding');
      }
    } else {
      setState(() => _activeScreen = 'onboarding');
    }
  }

  void _logOut() async {
    await ApiService.instance.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    setState(() {
      _user = null;
      _profile = null;
      _activeScreen = 'auth';
    });
  }

  void _openServerSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServerSetupModal(
        showBanner: _showBanner,
        onConnected: () => _checkInitialState(),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsModal(
        onLogout: _logOut,
        showBanner: _showBanner,
        onOpenServerSetup: _openServerSetup,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;

    if (_activeScreen == 'auth') {
      return Stack(
        children: [
          AuthScreen(
            onAuthenticated: _handleAuthenticated,
            showBanner: _showBanner,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: BannerToast(
              message: _bannerMessage,
              onClose: _hideBanner,
            ),
          ),
        ],
      );
    }

    if (_activeScreen == 'onboarding') {
      return Stack(
        children: [
          OnboardingScreen(
            onFinished: () => setState(() => _activeScreen = 'home'),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: BannerToast(
              message: _bannerMessage,
              onClose: _hideBanner,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // App Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.surface(isDark),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment(-0.36, -0.44),
                            colors: [
                              Color(0xFFC79AB9),
                              AppColors.plum,
                              AppColors.plumDeep
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        appState.t('app_name'),
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: AppColors.ink(isDark),
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Server IP button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceSoft(isDark),
                          side: BorderSide(color: AppColors.line(isDark)),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(
                          Icons.dns,
                          size: 18,
                          color: AppColors.plum,
                        ),
                        onPressed: _openServerSetup,
                      ),
                      const SizedBox(width: 4),
                      // Quick Language Switch Button
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          appState.setLanguage(appState.isArabic ? 'en' : 'ar');
                        },
                        child: Text(
                          appState.isArabic ? 'EN' : 'عربي',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.plum,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceSoft(isDark),
                          side: BorderSide(color: AppColors.line(isDark)),
                          shape: const CircleBorder(),
                        ),
                        icon: Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: AppColors.muted(isDark),
                        ),
                        onPressed: _openSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(
                          '$_activeScreen-$isDark-${appState.language}'),
                      child: _buildActiveScreen(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: BannerToast(
                      message: _bannerMessage,
                      onClose: _hideBanner,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(isDark),
          border: Border(top: BorderSide(color: AppColors.line(isDark))),
        ),
        child: BottomNavigationBar(
          currentIndex: _getTabIndex(_activeScreen),
          onTap: (idx) {
            final tabs = ['home', 'journal', 'history', 'chat', 'support'];
            setState(() => _activeScreen = tabs[idx]);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface(isDark),
          selectedItemColor: AppColors.plum,
          unselectedItemColor: AppColors.faint(isDark),
          selectedLabelStyle: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: appState.t('nav_home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.edit_note_outlined),
              activeIcon: const Icon(Icons.edit_note),
              label: appState.t('nav_journal'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined),
              activeIcon: const Icon(Icons.history),
              label: appState.t('nav_history'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: appState.t('nav_chat'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.health_and_safety_outlined),
              activeIcon: const Icon(Icons.health_and_safety),
              label: appState.t('nav_support'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScreen() {
    switch (_activeScreen) {
      case 'home':
        return HomeScreen(
          user: _user,
          onNavigate: (s) => setState(() => _activeScreen = s),
          showBanner: _showBanner,
        );
      case 'journal':
        return JournalScreen(showBanner: _showBanner);
      case 'history':
        return HistoryScreen(showBanner: _showBanner);
      case 'chat':
        return ChatScreen(showBanner: _showBanner);
      case 'support':
        return SupportScreen(showBanner: _showBanner);
      default:
        return HomeScreen(
          user: _user,
          onNavigate: (s) => setState(() => _activeScreen = s),
          showBanner: _showBanner,
        );
    }
  }

  int _getTabIndex(String screen) {
    switch (screen) {
      case 'home':
        return 0;
      case 'journal':
        return 1;
      case 'history':
        return 2;
      case 'chat':
        return 3;
      case 'support':
        return 4;
      default:
        return 0;
    }
  }
}

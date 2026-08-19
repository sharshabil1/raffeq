import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/modals.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final Function(String text) showBanner;

  const AuthScreen({
    super.key,
    required this.onAuthenticated,
    required this.showBanner,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _hintText = '';

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    final isReachable = await ApiService.instance.testConnection();
    if (!isReachable && mounted) {
      _openServerSetup();
    }
  }

  void _openServerSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServerSetupModal(
        showBanner: widget.showBanner,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final appState = AppState.instance;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _hintText = appState.t('enter_email_pass'));
      return;
    }

    setState(() {
      _isLoading = true;
      _hintText = _isLoginMode
          ? appState.t('logging_in')
          : appState.t('creating_acc');
    });

    if (!_isLoginMode) {
      final signupRes = await ApiService.instance.signup(email, password);
      if (!signupRes.ok) {
        setState(() {
          _isLoading = false;
          _hintText = appState.t('signup_failed');
        });
        if (signupRes.errorMsg != null) {
          widget.showBanner(signupRes.errorMsg!);
        }
        return;
      }
    }

    final loginRes = await ApiService.instance.login(email, password);
    setState(() => _isLoading = false);

    if (!loginRes.ok) {
      setState(() => _hintText = appState.t('login_failed'));
      if (loginRes.errorMsg != null) {
        widget.showBanner(loginRes.errorMsg!);
      }
      return;
    }

    final data = loginRes.data;
    String? token;
    if (data is Map<String, dynamic>) {
      token = data['access_token'] ??
          data['token'] ??
          (data['data'] is Map ? data['data']['access_token'] : null);
    }

    if (token == null || token.isEmpty) {
      setState(() => _hintText = appState.t('no_token'));
      return;
    }

    await ApiService.instance.setToken(token);
    setState(() => _hintText = '');
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.surface(isDark),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Server IP button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          backgroundColor: AppColors.surfaceSoft(isDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(color: AppColors.line(isDark)),
                          ),
                        ),
                        icon: const Icon(Icons.dns,
                            size: 15, color: AppColors.plum),
                        label: Text(
                          ApiService.instance.baseUrl.replaceAll('http://', ''),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink(isDark),
                          ),
                        ),
                        onPressed: _openServerSetup,
                      ),
                      Row(
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              appState
                                  .setLanguage(appState.isArabic ? 'en' : 'ar');
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
                            icon: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              size: 20,
                              color: AppColors.plum,
                            ),
                            onPressed: () => appState.toggleDarkMode(!isDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Center(child: BreathingOrb(size: 78)),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      appState.t('app_name'),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.ink(isDark),
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        appState.t('app_tagline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted(isDark),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Segmented Tab
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
                            onTap: () => setState(() => _isLoginMode = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLoginMode
                                    ? AppColors.ink(isDark)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                appState.t('login'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _isLoginMode
                                      ? AppColors.surface(isDark)
                                      : AppColors.muted(isDark),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isLoginMode = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isLoginMode
                                    ? AppColors.ink(isDark)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                appState.t('signup'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: !_isLoginMode
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
                  const SizedBox(height: 20),
                  Text(
                    appState.t('email'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted(isDark),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppColors.ink(isDark)),
                    decoration: const InputDecoration(
                      hintText: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    appState.t('password'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted(isDark),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: AppColors.ink(isDark)),
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink(isDark),
                      foregroundColor: AppColors.surface(isDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitAuth,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.surface(isDark),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isLoginMode
                                ? appState.t('login')
                                : appState.t('create_account'),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  if (_hintText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _hintText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.faint(isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

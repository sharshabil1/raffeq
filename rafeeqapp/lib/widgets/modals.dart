import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class SettingsModal extends StatefulWidget {
  final VoidCallback onLogout;
  final Function(String message) showBanner;
  final VoidCallback? onOpenServerSetup;

  const SettingsModal({
    super.key,
    required this.onLogout,
    required this.showBanner,
    this.onOpenServerSetup,
  });

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  late TextEditingController _urlController;
  bool _showDebugLog = false;
  bool _isTesting = false;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiService.instance.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final target = _urlController.text.trim();
    if (target.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testSuccess = null;
    });

    final ok = await ApiService.instance.testConnection(target);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = ok;
      });
      widget.showBanner(ok
          ? AppState.instance.t('connection_ok')
          : AppState.instance.t('connection_failed'));
    }
  }

  void _saveUrl() async {
    await ApiService.instance.setBaseUrl(_urlController.text.trim());
    widget.showBanner(AppState.instance.isArabic
        ? 'تم تحديث رابط API'
        : 'API Base URL updated.');
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final logs = ApiService.instance.debugLogs;
    final isDark = appState.isDarkMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appState.t('settings'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.ink(isDark),
                        ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.muted(isDark)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dark mode switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line(isDark)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: AppColors.plum,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          appState.t('dark_mode'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink(isDark),
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isDark,
                      activeColor: AppColors.plum,
                      onChanged: (val) => appState.toggleDarkMode(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Language Selector
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line(isDark)),
                ),
                child: Row(
                  children: [
                    Text(
                      appState.t('language'),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink(isDark),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => appState.setLanguage('en'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !appState.isArabic
                              ? AppColors.ink(isDark)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'English',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !appState.isArabic
                                ? AppColors.surface(isDark)
                                : AppColors.muted(isDark),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => appState.setLanguage('ar'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: appState.isArabic
                              ? AppColors.ink(isDark)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'العربية',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: appState.isArabic
                                ? AppColors.surface(isDark)
                                : AppColors.muted(isDark),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Server Setup button shortcut
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.line(isDark)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.dns, size: 18, color: AppColors.plum),
                label: Text(
                  appState.t('server_setup_title'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink(isDark),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.onOpenServerSetup != null) {
                    widget.onOpenServerSetup!();
                  }
                },
              ),

              const SizedBox(height: 14),

              Text(
                appState.t('api_base_url'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted(isDark),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: TextStyle(color: AppColors.ink(isDark)),
                      decoration: const InputDecoration(
                        hintText: 'http://localhost:8000',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 14),
                      side: BorderSide(color: AppColors.line(isDark)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.plum,
                            ),
                          )
                        : Icon(
                            _testSuccess == true
                                ? Icons.check_circle
                                : (_testSuccess == false
                                    ? Icons.error
                                    : Icons.network_check),
                            size: 18,
                            color: _testSuccess == true
                                ? AppColors.sage
                                : (_testSuccess == false
                                    ? AppColors.rose
                                    : AppColors.plum),
                          ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink(isDark),
                      foregroundColor: AppColors.surface(isDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saveUrl,
                    child: Text(appState.t('save')),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.line(isDark)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showDebugLog = !_showDebugLog;
                  });
                },
                child: Text(
                  _showDebugLog
                      ? appState.t('hide_debug')
                      : appState.t('show_debug'),
                  style: TextStyle(color: AppColors.muted(isDark)),
                ),
              ),
              if (_showDebugLog) ...[
                const SizedBox(height: 12),
                Container(
                  height: 160,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line(isDark)),
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.surfaceSoft(isDark),
                  ),
                  child: logs.isEmpty
                      ? const Text(
                          'No requests yet.',
                          style: TextStyle(fontSize: 11, color: AppColors.plum),
                        )
                      : ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final e = logs[index];
                            final color = e.ok ? AppColors.sage : AppColors.rose;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${e.method} ${e.status} ${e.path} (${e.time})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink(isDark),
                  foregroundColor: AppColors.surface(isDark),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onLogout();
                },
                child: Text(
                  appState.t('logout'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
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

class ServerSetupModal extends StatefulWidget {
  final Function(String message) showBanner;
  final VoidCallback? onConnected;

  const ServerSetupModal({
    super.key,
    required this.showBanner,
    this.onConnected,
  });

  @override
  State<ServerSetupModal> createState() => _ServerSetupModalState();
}

class _ServerSetupModalState extends State<ServerSetupModal> {
  late TextEditingController _ipController;
  bool _isTesting = false;
  bool? _testSuccess;
  String _testMessage = '';

  final List<String> _presets = [
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'http://10.0.2.2:8000',
    'http://192.168.1.100:8000',
  ];

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: ApiService.instance.baseUrl);
    _testCurrentUrl();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _testCurrentUrl([String? customUrl]) async {
    final target = (customUrl ?? _ipController.text).trim();
    if (target.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testMessage = '';
    });

    final ok = await ApiService.instance.testConnection(target);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = ok;
        _testMessage = ok
            ? AppState.instance.t('connection_ok')
            : AppState.instance.t('connection_failed');
      });
    }
  }

  Future<void> _saveAndConnect() async {
    final target = _ipController.text.trim();
    if (target.isEmpty) return;

    await ApiService.instance.setBaseUrl(target);
    widget.showBanner(AppState.instance.isArabic
        ? 'تم حفظ الاتصال بالخادم: $target'
        : 'Connected to server: $target');

    if (mounted) {
      Navigator.pop(context);
      if (widget.onConnected != null) {
        widget.onConnected!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.dns, color: AppColors.plum, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    appState.t('server_setup_title'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.ink(isDark),
                          fontSize: 17,
                        ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.muted(isDark)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            appState.t('server_setup_desc'),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted(isDark),
            ),
          ),
          const SizedBox(height: 16),

          // Preset Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _presets.map((preset) {
              final isSelected = _ipController.text.trim() == preset;
              return ChoiceChip(
                label: Text(
                  preset.replaceAll('http://', ''),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.surface(isDark)
                        : AppColors.ink(isDark),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.plum,
                backgroundColor: AppColors.surfaceSoft(isDark),
                onSelected: (selected) {
                  if (selected) {
                    _ipController.text = preset;
                    _testCurrentUrl(preset);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ipController,
                  style: TextStyle(color: AppColors.ink(isDark)),
                  decoration: const InputDecoration(
                    hintText: 'http://192.168.1.100:8000',
                  ),
                  onChanged: (val) {
                    setState(() {
                      _testSuccess = null;
                      _testMessage = '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  side: BorderSide(color: AppColors.line(isDark)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isTesting ? null : () => _testCurrentUrl(),
                child: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.plum,
                        ),
                      )
                    : Text(
                        appState.t('test_connection'),
                        style: const TextStyle(fontSize: 12),
                      ),
              ),
            ],
          ),

          if (_testMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _testSuccess == true
                      ? Icons.check_circle
                      : Icons.error_outline,
                  color:
                      _testSuccess == true ? AppColors.sage : AppColors.rose,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _testMessage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _testSuccess == true
                          ? AppColors.sage
                          : AppColors.rose,
                    ),
                  ),
                ),
              ],
            ),
          ],

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
            onPressed: _saveAndConnect,
            child: Text(
              appState.t('connect_save'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class CheckinModal extends StatelessWidget {
  final Function(String reflection) onSubmit;

  const CheckinModal({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appState.t('checkin_title'),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.ink(isDark),
                    ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.muted(isDark)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            appState.t('checkin_desc'),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted(isDark),
            ),
          ),
          const SizedBox(height: 18),
          _buildPillButton(
              context, isDark, appState.t('checkin_better'), 'better'),
          const SizedBox(height: 10),
          _buildPillButton(context, isDark, appState.t('checkin_same'), 'same'),
          const SizedBox(height: 10),
          _buildPillButton(
              context, isDark, appState.t('checkin_worse'), 'worse'),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildPillButton(
    BuildContext context,
    bool isDark,
    String label,
    String value,
  ) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        side: BorderSide(color: AppColors.line(isDark), width: 1.5),
        backgroundColor: AppColors.surfaceSoft(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () {
        Navigator.pop(context);
        onSubmit(value);
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink(isDark),
        ),
      ),
    );
  }
}

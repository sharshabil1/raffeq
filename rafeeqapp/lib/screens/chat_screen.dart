import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final Function(String message) showBanner;

  const ChatScreen({super.key, required this.showBanner});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    final res = await ApiService.instance.getChatHistory();

    _messages.clear();

    if (res.ok && res.data != null) {
      List items = [];
      if (res.data is List) {
        items = res.data;
      } else if (res.data is Map) {
        final map = res.data as Map;
        items = (map['messages'] ?? map['items'] ?? map['history'])
                as List? ??
            [];
      }

      for (final item in items) {
        _messages.add(ChatMessage.fromJson(item));
      }
    }

    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content: AppState.instance.t('coach_welcome'),
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final msgText = _inputController.text.trim();
    if (msgText.isEmpty || _isSending) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: msgText));
      _isSending = true;
    });
    _scrollToBottom();

    final res = await ApiService.instance.sendChatMessage(msgText);
    if (!mounted) return;

    setState(() => _isSending = false);

    if (res.ok && res.data != null) {
      final assistantMsg = ChatMessage.fromJson(res.data);
      setState(() {
        _messages.add(assistantMsg);
      });
    } else {
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: AppState.instance.isArabic
                ? 'تعذر الوصول إلى الخادم حالياً — يرجى المحاولة بعد لحظات.'
                : "I couldn't quite reach the server for that one — try again in a moment.",
          ),
        );
      });
      widget.showBanner(res.errorMsg ?? 'Failed sending message.');
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    final isDark = appState.isDarkMode;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    appState.t('coach_title'),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.ink(isDark),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appState.t('coach_sub'),
                    style:
                        TextStyle(color: AppColors.muted(isDark), fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.plum),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: _messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isSending) {
                          return _buildTypingIndicator(isDark);
                        }

                        final msg = _messages[index];
                        final isUser = msg.role == 'user';

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.78,
                                ),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppColors.ink(isDark)
                                      : AppColors.surfaceSoft(isDark),
                                  border: isUser
                                      ? null
                                      : Border.all(color: AppColors.line(isDark)),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isUser
                                        ? const Radius.circular(16)
                                        : const Radius.circular(4),
                                    bottomRight: isUser
                                        ? const Radius.circular(4)
                                        : const Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: isUser
                                        ? AppColors.surface(isDark)
                                        : AppColors.ink(isDark),
                                  ),
                                ),
                              ),
                              if (msg.isCrisis ||
                                  msg.emergencyResources != null) ...[
                                _buildCrisisCard(
                                    context, isDark, msg.emergencyResources),
                              ],
                              const SizedBox(height: 4),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            // Chat Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface(isDark),
                border: Border(top: BorderSide(color: AppColors.line(isDark))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(fontSize: 14, color: AppColors.ink(isDark)),
                      decoration: InputDecoration(
                        hintText: appState.t('chat_hint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.ink(isDark),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send,
                          color: AppColors.surface(isDark), size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCrisisCard(
    BuildContext context,
    bool isDark,
    Map<String, dynamic>? resources,
  ) {
    final saudi937 = resources?['saudi_health_center'] ?? '937';
    final us988 = resources?['us_crisis_lifeline'] ?? '988';

    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 4),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      decoration: BoxDecoration(
        color: AppColors.rose.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.health_and_safety, color: AppColors.rose, size: 16),
              SizedBox(width: 6),
              Text(
                'Crisis Support Available 24/7',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.rose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'If you need immediate help, reach out to free 24/7 hotlines:',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.ink(isDark).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              Chip(
                backgroundColor: AppColors.surface(isDark),
                avatar: const Icon(Icons.phone, size: 12, color: AppColors.rose),
                label: Text('SA Mental Health: $saudi937',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Chip(
                backgroundColor: AppColors.surface(isDark),
                avatar: const Icon(Icons.phone, size: 12, color: AppColors.rose),
                label: Text('US Lifeline: $us988',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft(isDark),
          border: Border.all(color: AppColors.line(isDark)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.plum,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppState.instance.isArabic
                  ? 'رفيق يكتب الان…'
                  : 'Rafeeq is typing…',
              style: TextStyle(fontSize: 12, color: AppColors.muted(isDark)),
            ),
          ],
        ),
      ),
    );
  }
}

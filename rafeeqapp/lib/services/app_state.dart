import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  AppState._internal();

  bool _isDarkMode = false;
  String _language = 'en'; // 'en' or 'ar'

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get isArabic => _language == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;
  Locale get locale => Locale(_language);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _language = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }

  Future<void> setLanguage(String lang) async {
    if (lang != 'en' && lang != 'ar') return;
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
  }

  String t(String key, [Map<String, String>? args]) {
    String text = _translations[_language]?[key] ??
        _translations['en']?[key] ??
        key;
    if (args != null) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'Rafeeq',
      'app_tagline':
          'A quiet companion for the days that are loud. Journal a little, and it starts to know you.',
      'login': 'Log in',
      'signup': 'Sign up',
      'create_account': 'Create account',
      'email': 'Email',
      'password': 'Password',
      'hi': 'Hi, {name}',
      'focus_title': 'Your focus right now',
      'focus_empty':
          "Once you've journaled a bit, Rafeeq will start noticing patterns here.",
      'trending_title': "How you've been trending",
      'chart_empty':
          'Keep journaling — your trend line will start to appear after a few entries.',
      'write_today': "Write today's entry",
      'talk_rafeeq': 'Talk to Rafeeq',
      'checkin_title': 'Check in with yourself',
      'checkin_desc': 'Compared to when you started, how does things feel lately?',
      'checkin_btn': 'Do a quick check-in',
      'checkin_better': 'Better than before',
      'checkin_same': 'About the same',
      'checkin_worse': 'Harder than before',
      'todays_entry': "Today's entry",
      'journal_subtitle': 'Type it out, or just talk — whichever feels easier.',
      'type_mode': 'Type',
      'talk_mode': 'Talk',
      'type_hint': "What's on your mind today?",
      'save_entry': 'Save entry',
      'hold_to_record': 'Hold to record',
      'tap_to_record': 'Tap to record',
      'tap_to_stop': 'Tap to stop recording',
      'upload_audio': 'Upload audio file',
      'recording': 'Recording…',
      'reflecting': 'Rafeeq is reflecting on this…',
      'processing_voice': 'Rafeeq is processing your voice entry…',
      'noticed_title': 'What Rafeeq noticed',
      'write_another': 'Write another',
      'reflections_title': 'My Journals & Reflections',
      'reflections_sub': "Read your past journals and AI insights in full.",
      'read_journal': 'Read journal',
      'original_text': 'Original Journal Text',
      'ai_insights': 'AI Insights & Analysis',
      'voice_entry': 'Voice Journal',
      'text_entry': 'Text Journal',
      'no_reflections':
          'No reflections yet — your first entry will show up here.',
      'coach_title': 'Rafeeq',
      'coach_sub': "Your coach, remembering what you've shared.",
      'coach_welcome': "Hi, I'm Rafeeq. I'm here whenever you want to talk.",
      'chat_hint': "Say what's on your mind…",
      'support_title': 'Support & Resources',
      'support_sub': 'Immediate helplines and guided tools for grounding.',
      'crisis_title': 'Emergency & Crisis Hotlines',
      'coping_title': 'Grounding & Coping Tools',
      'settings': 'Settings',
      'api_base_url': 'API Base URL',
      'save': 'Save',
      'show_debug': 'Show debug log',
      'hide_debug': 'Hide debug log',
      'logout': 'Log out',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'english': 'English',
      'arabic': 'العربية',
      'nav_home': 'Home',
      'nav_journal': 'Journal',
      'nav_history': 'History',
      'nav_chat': 'Chat',
      'nav_support': 'Support',
      'skip_for_now': 'Skip for now',
      'next': 'Next',
      'finish': 'Finish',
      'back': 'Back',
      'enter_email_pass': 'Enter an email and password.',
      'logging_in': 'Logging in…',
      'creating_acc': 'Creating your account…',
      'signup_failed': 'Signup failed — see the message above.',
      'login_failed': 'Login failed — see the message above.',
      'no_token': 'Logged in, but no token was returned by the API.',
      'server_setup_title': 'Server Connection & IP',
      'server_setup_desc': 'Select or type the IP / URL of your Rafeeq API server.',
      'test_connection': 'Test Connection',
      'connection_ok': 'Connected to server successfully!',
      'connection_failed': 'Could not reach server. Check IP & port.',
      'connect_save': 'Save & Connect',
    },
    'ar': {
      'app_name': 'رفيق',
      'app_tagline':
          'رفيق هادئ للأيام المزدحمة بالضجيج. دوّن القليل، ويبدأ بمعرفتك.',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'create_account': 'إنشاء حساب جديد',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'hi': 'مرحباً، {name}',
      'focus_title': 'تركيزك الحالي',
      'focus_empty': 'عندما تدوّن قليلاً، سيبدأ رفيق بملاحظة الأنماط هنا.',
      'trending_title': 'تطور المزاج والأنماط',
      'chart_empty':
          'واصل التدوين — سيبدأ خط الاتجاه بالظهور بعد عدة مدونات.',
      'write_today': 'اكتب يوميات اليوم',
      'talk_rafeeq': 'تحدث مع رفيق',
      'checkin_title': 'اطمئن على نفسك',
      'checkin_desc': 'مقارنة بالبداية، كيف تشعر مؤخراً؟',
      'checkin_btn': 'قم بتقييم سريع',
      'checkin_better': 'أفضل من ذي قبل',
      'checkin_same': 'تقريباً كما هو',
      'checkin_worse': 'أصعب من ذي قبل',
      'todays_entry': 'يوميات اليوم',
      'journal_subtitle': 'اكتب ما تود، أو تحدث بصوتك — أيهما أسهل عليك.',
      'type_mode': 'كتابة',
      'talk_mode': 'صوت',
      'type_hint': 'ما الذي يشغل بالك اليوم؟',
      'save_entry': 'حفظ التدوينة',
      'hold_to_record': 'اضغط باستمرار للتسجيل',
      'tap_to_record': 'اضغط لبدء التسجيل',
      'tap_to_stop': 'اضغط لإيقاف التسجيل',
      'upload_audio': 'رفع ملف صوتي',
      'recording': 'جاري التسجيل…',
      'reflecting': 'رفيق يتأمل في كلامك…',
      'processing_voice': 'رفيق يعالج تسجيلك الصوتي…',
      'noticed_title': 'ما لاحظه رفيق',
      'write_another': 'كتابة تدوينة أخرى',
      'reflections_title': 'يومياتي وتأملاتي',
      'reflections_sub': 'اقرأ تدويناتك السابقة وتأملات رفيق الكاملة.',
      'read_journal': 'قراءة التدوينة',
      'original_text': 'نص التدوينة الأصلي',
      'ai_insights': 'تحليلات وتأملات رفيق',
      'voice_entry': 'تدوينة صوتية',
      'text_entry': 'تدوينة نصية',
      'no_reflections': 'لا توجد تأملات بعد — ستظهر مدونتك الأولى هنا.',
      'coach_title': 'رفيق',
      'coach_sub': 'مستشارك الشخصي، يتذكر ما شاركته معه.',
      'coach_welcome': 'أهلاً بك، أنا رفيق. أنا هنا متى ما أردت التحدث.',
      'chat_hint': 'قل ما في خاطرك…',
      'support_title': 'الدعم والموارد',
      'support_sub': 'خطوط المساعدة المباشرة وأدوات التهدئة والإرساء.',
      'crisis_title': 'خطوط الطوارئ والأزمات',
      'coping_title': 'أدوات التهدئة والتمكين',
      'settings': 'الإعدادات',
      'api_base_url': 'رابط API الرئيسي',
      'save': 'حفظ',
      'show_debug': 'عرض سجل التطوير',
      'hide_debug': 'إخفاء سجل التطوير',
      'logout': 'تسجيل الخروج',
      'dark_mode': 'الوضع الداكن',
      'language': 'اللغة',
      'english': 'English',
      'arabic': 'العربية',
      'nav_home': 'الرئيسية',
      'nav_journal': 'اليوميات',
      'nav_history': 'السجل',
      'nav_chat': 'المحادثة',
      'nav_support': 'الدعم',
      'skip_for_now': 'تخطي الآن',
      'next': 'التالي',
      'finish': 'إنهاء',
      'back': 'رجوع',
      'enter_email_pass': 'يرجى إدخال البريد الإلكتروني وكلمة المرور.',
      'logging_in': 'جاري تسجيل الدخول…',
      'creating_acc': 'جاري إنشاء حسابك…',
      'signup_failed': 'فشل إنشاء الحساب — راجع الرسالة أعلاه.',
      'login_failed': 'فشل تسجيل الدخول — راجع الرسالة أعلاه.',
      'no_token': 'تم تسجيل الدخول لكن لم يتم إرجاع رمز الموثوقية.',
      'server_setup_title': 'عنوان الاتصال بالخادم (IP)',
      'server_setup_desc': 'اختر أو ادخل عنوان IP / الرابط لخادم API الخاص برفيق.',
      'test_connection': 'فحص الاتصال',
      'connection_ok': 'تم الاتصال بالخادم بنجاح!',
      'connection_failed': 'تعذر الوصول للخادم. تأكد من الـ IP والمنفذ.',
      'connect_save': 'حفظ واكتشاف',
    }
  };
}

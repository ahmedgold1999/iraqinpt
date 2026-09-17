import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class DailyQuestionItem {
  final int id;
  final String title;
  final String motivationalQuote;
  final String questionText;
  final String subject;
  final String correctAnswer;
  final List<String> options;
  final String explanation;

  const DailyQuestionItem({
    required this.id,
    required this.title,
    required this.motivationalQuote,
    required this.questionText,
    required this.subject,
    required this.correctAnswer,
    required this.options,
    required this.explanation,
  });
}

class DailyReminderService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _prefEnabledKey = 'daily_reminder_enabled_v1';
  static const String _prefHourKey = 'daily_reminder_hour_v1';
  static const String _prefMinuteKey = 'daily_reminder_minute_v1';
  static const String _prefLastIndexKey = 'daily_reminder_last_index_v1';
  static const String _prefLastShownDateKey =
      'daily_reminder_last_shown_date_v1';

  static const List<DailyQuestionItem> dailyQuestionsBank = [
    DailyQuestionItem(
      id: 1,
      title: '🎯 سؤال التحدي المسائي (اللغة العربية) 💡',
      motivationalQuote:
      '🎓 مستقبلك في الدراسات العليا يستحق دقيقة واحدة الآن! اختبر معلوماتك:',
      questionText: 'ما إعراب كلمة (كتاباً) في جملة: "اشتريتُ عشرينَ كتاباً"؟',
      subject: 'اللغة العربية',
      correctAnswer: 'تمييز منصوب وعلامة نصبه الفتحة',
      options: [
        'تمييز منصوب وعلامة نصبه الفتحة',
        'مفعول به ثانٍ منصوب',
        'حال منصوب بالفتحة',
        'مضاف إليه مجرور',
      ],
      explanation:
      'الاسم النكرة المنصوب الواقع بعد ألفاظ العقود (من 20 إلى 90) يُعرب دائماً تمييزاً مفرداً منصوباً.',
    ),
    DailyQuestionItem(
      id: 2,
      title: '⚡ جرعة تحفيز مسائية + سؤال حاسوب 🏆',
      motivationalQuote:
      '🚀 كل خطوة اليوم تقربك من القبول التنافسي.. أجب على سؤال اليوم:',
      questionText:
      'ما هو البروتوكول المسؤول عن تعيين عناوين IP للأجهزة في الشبكة تلقائياً؟',
      subject: 'علوم الحاسوب',
      correctAnswer: 'DHCP',
      options: ['DHCP', 'DNS', 'HTTP', 'FTP'],
      explanation:
      'بروتوكول DHCP (Dynamic Host Configuration Protocol) هو المسؤول عن توزيع عناوين الـ IP والإعدادات تلقائياً.',
    ),
    DailyQuestionItem(
      id: 3,
      title: '🌟 Evening English Challenge 🇬🇧',
      motivationalQuote:
      '✨ Small daily efforts lead to monumental success! Solve this:',
      questionText:
      'By the time the professor arrived, the students ______ the test.',
      subject: 'اللغة الإنجليزية',
      correctAnswer: 'had finished',
      options: ['had finished', 'have finished', 'finish', 'are finishing'],
      explanation:
      'نستخدم الماضي التام (Past Perfect: had + V3) للحدث الذي وقع واكتمل قبل حدث آخر في الماضي.',
    ),
    DailyQuestionItem(
      id: 4,
      title: '💡 تحدي الثقافة والذكاء التنافسي 🧠',
      motivationalQuote: '🔥 تنشيط عقلك يومياً هو سر التفوق والدرجة الكاملة:',
      questionText:
      'أكمل المتتالية العددية التالية: [ 3 ، 7 ، 15 ، 31 ، ... ]؟',
      subject: 'الثقافة العامة والتنافسي',
      correctAnswer: '63',
      options: ['63', '48', '56', '62'],
      explanation:
      'النمط هو ضرب العدد السابق في 2 ثم إضافة 1: (31 * 2) + 1 = 63.',
    ),
    DailyQuestionItem(
      id: 5,
      title: '🎯 سؤال المساء الذكي (اللغة العربية) 📚',
      motivationalQuote: '👑 لا تؤجل خطوتك.. العلم يُنال بالمثابرة اليومية:',
      questionText: 'ما نوع الهمزة في كلمة (استغفار) مع التعليل؟',
      subject: 'اللغة العربية',
      correctAnswer: 'همزة وصل لأنها مصدر لفعل سداسي',
      options: [
        'همزة وصل لأنها مصدر لفعل سداسي',
        'همزة قطع لأنها اسم علم',
        'همزة وصل لأنها ماضي خماسي',
        'همزة قطع لمصدر رباعي',
      ],
      explanation:
      'الفعل (استغفر) سداسي، ومصادر وأفعال الماضي والأمر من السداسي والخماسي همزتها همزة وصل دائماً.',
    ),
    DailyQuestionItem(
      id: 6,
      title: '⚡ سؤال التقنية والشبكات 💻',
      motivationalQuote: '🌟 تميز في مادة الحاسوب واكسب علامتها كاملة:',
      questionText: 'كم عدد البتات (Bits) التي يتكون منها عنوان IPv6 الحديث؟',
      subject: 'علوم الحاسوب',
      correctAnswer: '128 بت (Bits)',
      options: [
        '128 بت (Bits)',
        '32 بت (Bits)',
        '64 بت (Bits)',
        '256 بت (Bits)',
      ],
      explanation:
      'يتكون IPv4 من 32 بت بينما يتكون IPv6 من 128 بت ليوفر مليارات العناوين المتاحة.',
    ),
    DailyQuestionItem(
      id: 7,
      title: '🇬🇧 English Grammar Booster 🎯',
      motivationalQuote:
      '💪 Keep pushing forward! Here is your quick English question:',
      questionText:
      'If she studied harder, she ______ the competitive entrance exam.',
      subject: 'اللغة الإنجليزية',
      correctAnswer: 'would pass',
      options: ['would pass', 'will pass', 'passed', 'had passed'],
      explanation:
      'الجملة الشرطية من النوع الثاني (Second Conditional): فعل الشرط ماضي بسيط (studied) وجواب الشرط (would + verb).',
    ),
    DailyQuestionItem(
      id: 8,
      title: '🏆 تحدي النحو الوزاري العراقي 📖',
      motivationalQuote:
      '💎 من يزرع المذاكرة اليوم يحصد التفوق في يوم الامتحان:',
      questionText: 'في جملة "لا طالبَ علمٍ ممقوتٌ"، ما حكم إعراب اسم (لا)؟',
      subject: 'اللغة العربية',
      correctAnswer: 'معرب منصوب بالفتحة لأنه مضاف',
      options: [
        'معرب منصوب بالفتحة لأنه مضاف',
        'مبني على الفتح في محل نصب',
        'مرفوع بالضمة الظاهرة',
        'مجرور بالإضافة',
      ],
      explanation:
      'اسم لا النافية للجنس إذا كان مضافاً أو شبيهاً بالمضاف يكون معرباً منصوباً وليس مبنياً.',
    ),
    DailyQuestionItem(
      id: 9,
      title: '💻 سؤال أمن ومعمارية الحاسوب 🔒',
      motivationalQuote: '🚀 معلوماتك التقنية تصنع الفارق.. اختبر ذاكرتك:',
      questionText:
      'ما المنفذ (Port) الافتراضي المستخدم لنقل البيانات المشفرة عبر HTTPS؟',
      subject: 'علوم الحاسوب',
      correctAnswer: 'Port 443',
      options: ['Port 443', 'Port 80', 'Port 21', 'Port 25'],
      explanation:
      'منفذ HTTP العادي هو 80 بينما منفذ HTTPS المشفر والآمن هو 443.',
    ),
    DailyQuestionItem(
      id: 10,
      title: '🧠 ذكاء وتفكير منطقي تنافسي 💡',
      motivationalQuote:
      '🌟 دقيقة تدريب يومية تزيد سرعة بديهتك في قاعة الاختبار:',
      questionText:
      'إذا كان عقرب الساعات يشير إلى 3 وعقرب الدقائق إلى 12، فما مقدار الزاوية بينهما؟',
      subject: 'الثقافة العامة والتنافسي',
      correctAnswer: '90 درجة',
      options: ['90 درجة', '60 درجة', '120 درجة', '45 درجة'],
      explanation:
      'كل ساعة تمثل 30 درجة على قرص الساعة، 3 ساعات * 30 = 90 درجة (زاوية قائمة).',
    ),
    DailyQuestionItem(
      id: 11,
      title: '📚 تحدي اللغة والأدب 🎯',
      motivationalQuote: '👑 طريق الماجستير والدكتوراه يبدأ بالالتزام اليومي:',
      questionText:
      'ما نوع المشتق في كلمة (مُسْتَخْرَج) عندما نقول: "النفطُ مُسْتَخْرَجٌ من الأرض"؟',
      subject: 'اللغة العربية',
      correctAnswer: 'اسم مفعول',
      options: ['اسم مفعول', 'اسم فاعل', 'اسم مكان', 'مصدر ميمي'],
      explanation:
      'مضموم الأول ومفتوح ما قبل الآخر ودلّ على من وقع عليه الفعل، فهو اسم مفعول.',
    ),
    DailyQuestionItem(
      id: 12,
      title: '⚡ اختصارات الحاسوب الوزارية 🖥️',
      motivationalQuote: '🏆 لا تفوت أي نقطة في التنافسي.. تذكر هذه المعلومة:',
      questionText: 'ماذا يرمز الاختصار العلمي الشهير (BIOS) في اللوحة الأم؟',
      subject: 'علوم الحاسوب',
      correctAnswer: 'Basic Input / Output System',
      options: [
        'Basic Input / Output System',
        'Binary Integrated Operating System',
        'Base Internal Object Standard',
        'Boot Initial Order Setup',
      ],
      explanation:
      'BIOS هو البرنامج الثابت المدمج في اللوحة الأم لإقلاع وفحص عتاد الحاسوب الأساسي.',
    ),
    DailyQuestionItem(
      id: 13,
      title: '🇬🇧 Quick English Vocabulary 🌟',
      motivationalQuote: '🎯 Step by step, you are mastering the syllabus:',
      questionText: 'Which word is the closest synonym to "Comprehensive"?',
      subject: 'اللغة الإنجليزية',
      correctAnswer: 'Thorough',
      options: ['Thorough', 'Narrow', 'Simple', 'Temporary'],
      explanation:
      '"Comprehensive" تعني شامل وكامل، وأقرب مرادف لها هو "Thorough".',
    ),
    DailyQuestionItem(
      id: 14,
      title: '💡 التنافسي العام والمنهجية 📖',
      motivationalQuote: '✨ ثقتك بنفسك تصنع نجاحك.. استمر في المحاولة دائماً:',
      questionText:
      'ما هو المقياس الإحصائي الأكثر تأثراً بالقيم المتطرفة (Outliers)؟',
      subject: 'الثقافة العامة والتنافسي',
      correctAnswer: 'الوسط الحسابي (Mean)',
      options: [
        'الوسط الحسابي (Mean)',
        'الوسيط (Median)',
        'المنوال (Mode)',
        'المدى الربيعي',
      ],
      explanation:
      'الوسط الحسابي يتأثر مباشرة بجميع القيم لأنه يعتمد على جمعها، بينما الوسيط لا يتأثر بالقيم الشاذة.',
    ),
    DailyQuestionItem(
      id: 15,
      title: '🎯 سؤال الختام الذهبي (اللغة العربية) 👑',
      motivationalQuote:
      '🔥 أحسنت بالوصول إلى هنا! ثبت هذه القاعدة النحوية المهمة:',
      questionText:
      'في جملة (إنما المؤمنون إخوة)، لماذا رُفعت كلمة (المؤمنون) بعد (إنّ)؟',
      subject: 'اللغة العربية',
      correctAnswer: 'لاتصال (ما) الكافة التي كفت (إنّ) عن العمل',
      options: [
        'لاتصال (ما) الكافة التي كفت (إنّ) عن العمل',
        'لأنها فاعل مرفوع',
        'لأنها خبر إنّ مقدم',
        'لأنها بدل مرفوع',
      ],
      explanation:
      'عند دخول (ما) الزائدة الكافة على (إنّ) تكفها عن العمل ويُعرب ما بعدها مبتدأ مرفوعاً.',
    ),
  ];

  /// ===================== INITIALIZE =====================

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      tz.initializeTimeZones();

      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;

      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing timezone: $e');
      }
    }

    if (!prefs.containsKey(_prefEnabledKey)) {
      await prefs.setBool(_prefEnabledKey, true);
    }

    if (!prefs.containsKey(_prefHourKey)) {
      await prefs.setInt(_prefHourKey, 20);
    }

    if (!prefs.containsKey(_prefMinuteKey)) {
      await prefs.setInt(_prefMinuteKey, 0);
    }

    final isEnabled = prefs.getBool(_prefEnabledKey) ?? true;

    if (isEnabled) {
      await scheduleDailyReminder();
      await checkAndDispatchTodayNotification();
    }
  }

  /// ===================== SCHEDULE =====================

  static Future<void> scheduleDailyReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isEnabled = prefs.getBool(_prefEnabledKey) ?? true;

      if (!isEnabled) {
        await _localNotifications.cancel(id: 998877);
        return;
      }

      final int hour = prefs.getInt(_prefHourKey) ?? 20;
      final int minute = prefs.getInt(_prefMinuteKey) ?? 0;

      int currentIndex = prefs.getInt(_prefLastIndexKey) ?? 0;

      if (currentIndex < 0 || currentIndex >= dailyQuestionsBank.length) {
        currentIndex = 0;
      }

      final item = dailyQuestionsBank[currentIndex];

      const androidDetails = AndroidNotificationDetails(
        'daily_study_reminder_channel',
        'منبه وتحدي المذاكرة اليومي ⏰',
        channelDescription:
        'إشعارات يومية مسائية تحفيزية مع أسئلة تنافسية لاختبار معلوماتك.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final fullBody = '${item.motivationalQuote}\n\n'
          '❓ ${item.questionText}\n'
          '👉 اضغط لفتح التطبيق ومعرفة الإجابة الصحيحة والشرح!';

      final now = tz.TZDateTime.now(tz.local);

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _localNotifications.cancel(id: 998877);

      await _localNotifications.zonedSchedule(
        id: 998877,
        title: item.title,
        body: fullBody,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode:
        AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
        DateTimeComponents.time,
        payload: jsonEncode({
          'type': 'daily_question',
          'questionId': item.id,
        }),
      );

      if (kDebugMode) {
        print(
          '📅 Scheduled daily reminder for $scheduledDate',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling daily reminder: $e');
      }
    }
  }

  /// ===================== CHECK TODAY =====================

  static Future<void> checkAndDispatchTodayNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isEnabled = prefs.getBool(_prefEnabledKey) ?? true;

      if (!isEnabled) {
        return;
      }

      final int targetHour = prefs.getInt(_prefHourKey) ?? 20;
      final int targetMinute = prefs.getInt(_prefMinuteKey) ?? 0;

      final now = DateTime.now();

      final todayStr = '${now.year}-${now.month}-${now.day}';

      final lastShownDate = prefs.getString(_prefLastShownDateKey);

      if (lastShownDate != todayStr) {
        if (now.hour > targetHour ||
            (now.hour == targetHour && now.minute >= targetMinute)) {
          await triggerDailyNotificationNow();

          await prefs.setString(
            _prefLastShownDateKey,
            todayStr,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ Error checking daily reminder: $e',
        );
      }
    }
  }

  /// ===================== SHOW NOW =====================

  static Future<DailyQuestionItem> triggerDailyNotificationNow({
    int? specificIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    int currentIndex = specificIndex ?? (prefs.getInt(_prefLastIndexKey) ?? 0);

    if (currentIndex < 0 || currentIndex >= dailyQuestionsBank.length) {
      currentIndex = 0;
    }

    final item = dailyQuestionsBank[currentIndex];

    await prefs.setInt(
      _prefLastIndexKey,
      (currentIndex + 1) % dailyQuestionsBank.length,
    );

    const androidDetails = AndroidNotificationDetails(
      'daily_study_reminder_channel',
      'منبه وتحدي المذاكرة اليومي ⏰',
      channelDescription:
      'إشعارات يومية مسائية تحفيزية مع أسئلة تنافسية لاختبار معلوماتك.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final fullBody = '${item.motivationalQuote}\n\n'
        '❓ ${item.questionText}\n'
        '👉 اضغط لفتح التطبيق ومعرفة الإجابة الصحيحة والشرح!';

    await _localNotifications.show(
      id: 99000 + item.id,
      title: item.title,
      body: fullBody,
      notificationDetails: notificationDetails,
      payload: 'daily_question_${item.id}',
    );

    return item;
  }

  /// ===================== GETTERS =====================

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_prefEnabledKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _prefEnabledKey,
      enabled,
    );

    await scheduleDailyReminder();
  }

  static Future<TimeOfDay> getScheduledTime() async {
    final prefs = await SharedPreferences.getInstance();

    final hour = prefs.getInt(_prefHourKey) ?? 20;

    final minute = prefs.getInt(_prefMinuteKey) ?? 0;

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  static Future<void> setScheduledTime(
      int hour,
      int minute,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _prefHourKey,
      hour,
    );

    await prefs.setInt(
      _prefMinuteKey,
      minute,
    );

    await scheduleDailyReminder();
  }

  static DailyQuestionItem getCurrentPreviewQuestion() {
    return dailyQuestionsBank[0];
  }
}

# 📘 وثيقة تسليم المشروع ودليل المطور الشامل
## مشروع: تطبيق الامتحان الوطني الموحد (INPT - Iraqi National Proficiency Test)

---

> **موجز للمطور المستلم:**
> هذا الدليل الشامل يوضح كل تفاصيل المشروع المعمارية، البرمجية، والأمنية، بالإضافة إلى بنية قواعد البيانات وخطوات البناء والتشغيل، لتتمكن من استلام وتطوير وصيانة التطبيق بسلاسة واحترافية كاملة.

---

## 📑 فهرس المحتويات
1. [نظرة عامة على التطبيق والرؤية التقنية](#1-نظرة-عامة-على-التطبيق)
2. [المكدس التقني والمكتبات (Tech Stack)](#2-المكدس-التقني-والمكتبات)
3. [الهيكل المعماري للمشروع (Directory Structure)](#3-الهيكل-المعماري-للمشروع)
4. [بنية ونموذج بيانات Firebase (Firestore Schema)](#4-بنية-ونموذج-بيانات-firebase)
5. [منظومة الحماية والأمان (Security & Anti-Piracy)](#5-منظومة-الحماية-والأمان)
6. [نظام الإشعارات السحابية (Firebase Cloud Messaging - FCM)](#6-نظام-الإشعارات-السحابية)
7. [لوحة تحكم الإدارة الشاملة (Admin Dashboard)](#7-لوحة-تحكم-الإدارة-الشاملة)
8. [شاشات ووحدات تجربة الطالب (Student Features)](#8-شاشات-ووحدات-تجربة-الطالب)
9. [محرك الاختبارات والعمل دون إنترنت (Offline-First Engine)](#9-محرك-الاختبارات-والعمل-دون-إنترنت)
10. [إدارة الحالة والثيمات (State Management & Theming)](#10-إدارة-الحالة-والثيمات)
11. [دليل بناء الحزم والتصدير (Build & Deployment Guide)](#11-دليل-بناء-الحزم-والتصدير)
12. [ملاحظات هامة وإرشادات الصيانة والتطوير](#12-ملاحظات-هامة-وإرشادات-الصيانة)

---

## 1. نظرة عامة على التطبيق

تطبيق **الامتحان الوطني العراقي (INPT)** هو منصة تعليمية واختبارية متعددة المنصات (Android, iOS, Web) موجهة لطلبة الدراسات العليا في العراق لاجتياز الامتحان الوطني الموحد في (اللغة العربية، الحاسوب، اللغة الإنجليزية).

### ✨ أهم الإمكانيات:
- **محاكاة مطابقة للامتحان الوزاري** مع عداد تنازلي، حفظ تقدم فوري، وقراءة صوتية للأسئلة (TTS).
- **نظام اشتراكات هجين** (حسابات مجانية / باقات مميزة Premium مفعلة بأكواد رقمية فريدة أو عبر لوحة المدير).
- **قفل الحساب الصارم على جهاز واحد (Single Device Binding)** لمنع بيع أو مشاركة الحسابات.
- **تحديثات ديناميكية فورية** للأسعار، موعد الامتحان، وإعلانات النظام دون الحاجة لإعادة نشر التطبيق.
- **دعم كامل للعمل دون إنترنت (Offline-First)** مع حفظ محلي لبنوك الأسئلة والنتائج.
- **منظومة إشعارات سحابية Push Notifications** عبر قنوات FCM التلقائية.

---

## 2. المكدس التقني والمكتبات

- **Flutter SDK**: `>=3.0.0 <4.0.0` (Dart 3)
- **Backend & Cloud**:
  - **Firebase Core & Auth**: التوثيق والجلسات (Email/Password, Guest, Google, Apple ID).
  - **Cloud Firestore**: قاعدة البيانات المباشرة للطلاب، الإعدادات، والاشتراكات.
  - **Firebase Cloud Messaging (FCM)**: الإشعارات السحابية الفورية.
  - **Firebase Crashlytics**: رصد الأخطاء والانهيارات في الإنتاج.
  - **Firebase Hosting**: استضافة نسخة الويب المباشرة (`https://inptiq.web.app`).
- **حزم الصوت والوسائط والـ Web**:
  - `flutter_tts`: محرك قراءة الأسئلة بالذكاء الصوتي.
  - `flutter_inappwebview` & `webview_flutter`: تصفح الأدلة الوزارية وفحص الشهادات.
  - `flutter_local_notifications`: إدارة قنوات التنبيه في الخلفية ونوافذ الإشعار المنبثقة.
- **حزم التصميم والواجهة**:
  - `google_fonts`: خطوط عربية فاخرة (Cairo, Tajawal, Noto Kufi Arabic).
  - `lottie` & `flutter_spinkit`: الرسوم المتحركة وشاشات التحميل الفاخرة (Luxury Loaders).
  - `font_awesome_flutter`: مكتبة الأيقونات المتقدمة.
- **حزم النظام والعتاد**:
  - `device_info_plus`: استخراج بصمة الجهاز الرقمية (Android ID / iOS Vendor UUID).
  - `permission_handler`: إدارة أذونات الكاميرا والإشعارات.
  - `connectivity_plus`: مراقبة اتصال الشبكة وكشف انقطاع الإنترنت.
  - `shared_preferences`: التخزين المحلي الآمن للأسئلة والإعدادات.

---

## 3. الهيكل المعماري للمشروع

```text
lib/
├── firebase_options.dart      # إعدادات تهيئة Firebase لكل منصة (Android, iOS, Web, macOS)
├── main.dart                  # نقطة الانطلاق، الفحص الأمني (VPN/Device/Maintenance)، والتهيئة
├── routes.dart                # جدول التوجيه وإدارة مسارات الشاشات (AppRoutes)
│
├── models/                    # نماذج البيانات (Data Models)
│   ├── app_models.dart        # UserModel, UserRole
│   ├── notification_model.dart# NotificationModel
│   └── question_model.dart    # Question (نص السؤال، الخيارات، الإجابة، الشرح التوضيحي)
│
├── providers/                 # مزودات الحالة (State Management)
│   └── settings_provider.dart # الثيم (Dark/Light)، حجم الخط (Font Scale)، والتفضيلات
│
├── services/                  # طبقة الخدمات والمنطق البرمجي (Business Logic Layer)
│   ├── auth_service.dart          # إدارة الدخول، التسجيل، واسترجاع الحسابات
│   ├── config_service.dart        # جلب إعدادات الصيانة، التحديث الإجباري، والأسعار
│   ├── device_service.dart        # استخراج معرّف الجهاز وقفل الحساب على جهاز واحد
│   ├── notification_service.dart  # استقبال وبث إشعارات FCM ومعالجة الخلفية ومنع التكرار
│   ├── question_service.dart      # تحميل وتخزين ومزامنة بنوك الأسئلة (Online/Offline)
│   ├── leaderboard_service.dart   # نقاط التقييم ولوحة الصدارة وتصنيف الطلبة
│   ├── mistake_vault_service.dart # خزانة الأخطاء الذكية لحفظ ومراجعة إجابات الطالب الخاطئة
│   ├── subscription_service.dart  # التحقق من صلاحية الاشتراك وتفعيل الأكواد
│   ├── ai_explainer_service.dart  # توليد الشروحات الإرشادية الذكية لكل سؤال
│   ├── daily_reminder_service.dart# الجدولة المحلية للتنبيهات اليومية لدراسة المواد
│   ├── sound_effects_service.dart # المؤثرات الصوتية للإجابات الصحيحة والخاطئة
│   └── tts_service.dart           # النطق الصوتي للأسئلة والخيارات بالإنجليزية والعربية
│
├── screens/                   # واجهات المستخدم (UI Screens)
│   ├── admin/                 # شاشات لوحة تحكم الإدارة
│   │   ├── admin_dashboard.dart           # اللوحة الرئيسية (5 تبويبات تفاعلية)
│   │   ├── activation_management_screen.dart # إدارة الأكواد
│   │   ├── system_settings_screen.dart       # إعدادات النظام
│   │   └── admin_home.dart                   # غلاف الإدارة
│   │
│   ├── auth/                  # شاشات المصادقة
│   │   └── login_screen.dart  # تسجيل الدخول وإنشاء الحساب بأسلوب فخم
│   │
│   ├── common/                # الشاشات المشتركة وحالات النظام
│   │   ├── device_limit_screen.dart # شاشة الحظر عند فتح الحساب من هاتف ثانٍ
│   │   ├── maintenance_screen.dart  # شاشة وضع الصيانة والتحديث
│   │   └── vpn_block_screen.dart    # شاشة حظر الاتصال في حال تشغيل VPN
│   │
│   └── student/               # شاشات الطالب والامتحانات
│       ├── student_main_shell.dart          # الغلاف السفلي الرئيسي مع Luxury Bottom Nav
│       ├── home_screen.dart                 # الرئيسية (بنوك المواد، التمرن السريع، العداد)
│       ├── quiz_screen.dart                 # شاشة الامتحان الكامل ومحاكاة الوقت
│       ├── speed_quiz_screen.dart           # اختبار السرعة التفاعلي
│       ├── true_false_quiz_screen.dart      # اختبارات صح / خطأ
│       ├── mistakes_screen.dart             # خزانة ومراجعة الأخطاء السابقة
│       ├── leaderboard_screen.dart          # قائمة الشرف والمتصدرين
│       ├── smart_vault_screen.dart          # بنك الأسئلة المميزة والمحفوظة
│       ├── qualification_score_screen.dart  # حاسبة درجات المفاضلة للمتقدمين
│       ├── certificate_verification_screen.dart # فحص وتدقيق الشهادات عبر QR مع إذن الكاميرا
│       ├── exams_schedule_screen.dart       # مواعيد الامتحانات والعداد التنازلي الفاخر
│       ├── exam_instructions_screen.dart   # دليل التعليمات والضوابط الامتحانية الرسمية
│       ├── exam_centers_screen.dart         # دليل ومراكز الاختبارات المعتمدة
│       ├── study_materials_screen.dart      # الحقائب التدريبية والملازم الدراسية
│       ├── subscription_screen.dart         # شاشة باقات الاشتراك والأسعار الديناميكية
│       ├── notifications_screen.dart        # صندوق الإشعارات والتنبيهات المباشرة
│       └── profile_screen.dart              # البروفايل، الإعدادات، ومظهر التطبيق
│
├── theme/                     # منظومة الألوان والسمات البصرية
│   ├── app_colors.dart        # لوحة الألوان الملكية (Gold, Sapphire, Emerald, Slate)
│   └── app_theme.dart         # ثيمات Light و Dark ومواصفات Typography
│
├── utils/                     # الأدوات المساعدة
│   ├── web_helper.dart        # أدوات خاصة بتوافق متصفحات الويب وإزالة الـ Loader
│   └── vpn_detector.dart      # فحص واجهات الشبكة للكشف عن الـ VPN
│
└── widgets/                   # العناصر التفاعلية المشتركة (Custom Widgets)
    ├── luxury_bottom_nav.dart         # شريط التنقل السفلي الفاخر
    ├── luxury_exam_countdown_card.dart# بطاقة العداد التنازلي الحية لموعد الامتحان
    ├── luxury_loading.dart            # مؤشرات التحميل والسبلاش التفاعلي
    ├── luxury_score_certificate.dart  # شهادة النتيجة الرقمية بعد إنهاء الاختبار
    ├── luxury_card.dart               # بطاقات المحتوى ذات الإطارات المضيئة
    ├── app_app_bar.dart               # شريط التطبيق العلوي الموحد
    ├── app_button.dart                # الأزرار المتدرجة الفاخرة
    └── app_dialogs.dart               # نوافذ التأكيد والتنبيه المخصصة
```

---

## 4. بنية ونموذج بيانات Firebase

يستخدم التطبيق **Cloud Firestore** كقاعدة بيانات رئيسية. إليك المجموعات (`Collections`) والحقول بالتفصيل:

### 1. مجموعة الإعدادات: `system_settings/maintenance_and_updates`
تحتوي على وثيقة إعدادات مركزية تضبط سلوك التطبيقات في كل الأجهزة دون الحاجة لتحديث الكود:
```json
{
  "is_maintenance_on": false,          // تفعيل أو إيقاف وضع الصيانة الشامل
  "is_force_update": false,            // إجبار المستخدمين على التحديث لإصدار جديد
  "current_version": "1.2.1",          // رقم الإصدار الأحدث المنشور
  "update_url": "https://...",         // رابط تحميل التحديث (APK أو المتجر)
  "change_log": "تفاصيل التحديث...",  // سجل التغييرات الذي يظهر للمستخدم
  "price_1m": "10,000",                // سعر باقة الشهر (دينار عراقي)
  "price_2m": "15,000",                // سعر باقة الشهرين
  "price_3m": "20,000",                // سعر باقة 3 أشهر
  "price_1y": "30,000",                // سعر باقة السنة
  "exam_end_date": "2026-06-15",       // موعد انتهاء الامتحان الوطني الموحد للعداد التنازلي
  "fcm_server_key": "AIzaSy..."        // مفتاح إرسال إشعارات الـ FCM السحابية
}
```

### 2. مجموعة المستخدمين: `users/{userId}`
تمثل وثيقة كل طالب أو مدير:
```json
{
  "uid": "USER_FIREBASE_UID",
  "name": "اسم الطالب",
  "email": "student@inpt.iq",
  "role": "student",                   // "student" أو "admin"
  "isPremium": true,                   // حالة الاشتراك المميز
  "premiumUntil": "2026-12-31T00:00:00Z", // تاريخ انتهاء الصلاحية
  "activationCode": "INPT-XXXX-XXXX",  // الكود المستخدم للتفعيل
  "deviceId": "d14b988f012c45ab",      // معرّف الجهاز المقيد عليه الحساب
  "deviceIds": ["d14b988f012c45ab"],   // مصفوفة الأجهزة الموثوقة (جهاز واحد فقط)
  "deviceBoundAt": "2026-08-16T12:00:00Z",
  "stats": {
    "totalExams": 14,
    "passedExams": 12,
    "points": 1450,
    "accuracy": 87.5
  },
  "createdAt": "ServerTimestamp"
}
```

#### المجموعات الفرعية داخل المستخدم (`users/{userId}/...`):
- `users/{userId}/mistakes/{mistakeId}`: الأسئلة التي أخطأ بها الطالب في الاختبارات لمراجعتها.
- `users/{userId}/notifications/{notifId}`: الإشعارات الخاصة بالطالب وتتبع حالة القراءة (`isRead`).
- `users/{userId}/fcm_tokens/{token}`: مفاتيح أجهزة الطالب لاستقبال الإشعارات السحابية.

### 3. مجموعة الإشعارات العامة: `all_notifications/{notifId}`
المجموعة المعتمدة لبث الإشعارات لجميع الطلاب:
```json
{
  "title": "تحديث هام بخصوص مواعيد الامتحان",
  "body": "تم تمديد فترة التسجيل للامتحان الوطني...",
  "targetSegment": "all",              // "all" أو "premium" أو "free"
  "type": "broadcast",
  "createdAt": "ServerTimestamp",
  "readBy": ["uid1", "uid2"]          // مصفوفة بمعرفات الطلاب الذين قرأوا الإشعار
}
```

### 4. مجموعة أكواد التفعيل: `activation_codes/{code}`
```json
{
  "code": "INPT-9482-1084-5921",
  "isUsed": false,
  "usedBy": null,
  "usedByName": null,
  "usedAt": null,
  "durationDays": 365,
  "planType": "1_year",
  "createdAt": "ServerTimestamp",
  "createdBy": "admin_uid"
}
```

---

## 5. منظومة الحماية والأمان

### 🛡️ 1. قفل الحساب على جهاز واحد (Single Device Binding)
- **الملف المسئول**: [`lib/services/device_service.dart`](file:///e:/apps/iraqinpt/lib/services/device_service.dart)
- **طريقة العمل**:
  1. عند تسجيل الدخول لأول مرة، يقرأ التطبيق البصمة العتادية للجهاز (`androidInfo.id` في أندرويد أو `identifierForVendor` في iOS).
  2. إذا كان حساب الطالب غير مرتبط بأي جهاز، يتم ربطه وتخزين `deviceId` و `deviceIds: [deviceId]` في وثيقة الطالب بـ Firestore.
  3. إذا حاول طالب فتح الحساب من هاتف ثانٍ مختلف، يرفض التطبيق دخوله فوراً ويحوله إلى [`DeviceLimitScreen`](file:///e:/apps/iraqinpt/lib/screens/common/device_limit_screen.dart).
  4. **إعادة التعيين وفك القيد**: يمكن للمدير من شاشة **إدارة الطلبة** داخل لوحة التحكم فك قيد جهاز الطالب بضغطة زر (`resetDeviceBinding`) ليتسنى له الدخول من هاتفه الجديد.

### 🛡️ 2. منع اتصالات الـ VPN والبروكسي
- **الملف المسئول**: [`lib/utils/vpn_detector.dart`](file:///e:/apps/iraqinpt/lib/utils/vpn_detector.dart)
- **طريقة العمل**: فحص الواجهات الشبكية النشطة في نظام التشغيل (مثل `tun0`, `ppp`, `tap`, `p2p`)، وفي حال رصد اتصال VPN مشبوه يتم تحويل المستخدم لشاشة [`VpnBlockScreen`](file:///e:/apps/iraqinpt/lib/screens/common/vpn_block_screen.dart) لحماية بنوك الأسئلة وخدمات البث من محاولات التلاعب.

### 🛡️ 3. وضع الصيانة والتحديث الإجباري السحابي
- يتم فحص حالة النظام في [`main.dart`](file:///e:/apps/iraqinpt/lib/main.dart) عند فتح التطبيق مباشرة من وثيقة `maintenance_and_updates`.
- في حال تفعيل `is_maintenance_on: true`، يتحول التطبيق تلقائياً لشاشة الصيانة الفاخرة لمنع أي استخدام أثناء التعديلات.

---

## 6. نظام الإشعارات السحابية (FCM)

- **الملف المسئول**: [`lib/services/notification_service.dart`](file:///e:/apps/iraqinpt/lib/services/notification_service.dart)

### 🔄 آلية عمل واستلام الإشعارات:
1. **الاشتراك التلقائي في القنوات (Topics Subscription)**:
   - بمجرد تشغيل التطبيق، يشترك جهاز الطالب في القنوات: `all` و `students` و `global`.
2. **معالج الخلفية المعزول (`@pragma('vm:entry-point') firebaseBackgroundHandler`)**:
   - يستقبل الإشعارات السحابية حتى لو كان التطبيق مغلقاً تماماً (Terminated) أو في الخلفية (Background) ويعرضها مع صوت واهتزاز بقناة `high_importance_channel`.
3. **منع التكرار (Signature De-duplication)**:
   - تم بناء فلتر ذكي يعتمد على التوقيع الرقمي (`docId` و `title|body`) لضمان عدم ظهور أي إشعار مكرر داخل واجهة صندوق الإشعارات.
4. **البث المباشر من لوحة المدير (`sendBroadcastPush`)**:
   - يرسل طلبات HTTP موثقة إلى Google FCM (`https://fcm.googleapis.com/fcm/send`) مع أولوية قصوى `priority: "high"` و `content_available: true`.

---

## 7. لوحة تحكم الإدارة الشاملة (Admin Dashboard)

- **الملف المسئول**: [`lib/screens/admin/admin_dashboard.dart`](file:///e:/apps/iraqinpt/lib/screens/admin/admin_dashboard.dart)
- يتم الوصول إليها تلقائياً إذا كان دور المستخدم المسجل `role: "admin"`.

### 🎛️ التبويبات الخمسة الرئيسية:
1. **التبويب الأول: نظرة عامة وإحصائيات مباشرة**:
   - إجمالي عدد الطلاب، المشتركين الفعالين، الاشتراكات المنتهية، وإجمالي الإيرادات المقدرة.
2. **التبويب الثاني: إدارة الطلاب وفك قيد الأجهزة**:
   - البحث بالاسم، البريد، أو رقم الهاتف.
   - تعديل بيانات الطالب، ترقيته لاشتراك مميز، وتحديد مدة الصلاحية.
   - **زر إعادة تعيين الجهاز (Reset Device)** لفك قيد الجهاز القديم بضغطة زر.
3. **التبويب الثالث: إدارة وتوليد أكواد التفعيل**:
   - توليد فردي أو دفعات جماعية (Bulk Generation) لأكواد الاشتراك (شهر، شهرين، 3 أشهر، سنة).
   - تتبع الأكواد المستخدمة ومن قام بتفعيلها وتاريخ الاستخدام.
4. **التبويب الرابع: بث وإرسال الإشعارات**:
   - إرسال إشعار فوري لجميع الأجهزة (أو تحديد فئة الطلاب: الكل، المشتركون، المجانيون).
   - حفظ الإشعار في الأرشيف السحابي وإرسال Push Notification فوري للمغلقين.
5. **التبويب الخامس: إعدادات النظام والصيانة والأسعار**:
   - تفعيل/إلغاء وضع الصيانة والتحديث الإجباري ورابط التحديث.
   - تعديل أسعار باقات الاشتراك (1m, 2m, 3m, 1y).
   - تعديل تاريخ نهاية الامتحان للعداد التنازلي (`exam_end_date`).
   - مفتاح خادم الإشعارات السحابية (`fcm_server_key`).

---

## 8. شاشات ووحدات تجربة الطالب

1. **الرئيسية ([`home_screen.dart`](file:///e:/apps/iraqinpt/lib/screens/student/home_screen.dart))**:
   - بطاقات المواد الثلاث (اللغة العربية، الحاسوب، اللغة الإنجليزية).
   - العداد التنازلي الملكي لموعد الامتحان الموحد مع تدريجات الثواني الحية.
   - الوصول السريع لاختبار السرعة، صح/خطأ، وحاسبة المفاضلة.
2. **شاشة الامتحان التفاعلية ([`quiz_screen.dart`](file:///e:/apps/iraqinpt/lib/screens/student/quiz_screen.dart))**:
   - شريط تقدم ذكي مع مؤقت زمني دقيق لكل اختبار.
   - قراءة صوتية للسؤال والخيارات (`TTS`).
   - خيارات ملونة تفاعلية مع تبيان الإجابة الصحيحة وشرح الذكاء الاصطناعي الفوري.
   - حفظ تلقائي للأسئلة الخاطئة في خزانة الأخطاء.
   - إصدار شهادة تقييم فاخرة قابلة للمشاركة والحفظ في نهاية الاختبار ([`luxury_score_certificate.dart`](file:///e:/apps/iraqinpt/lib/widgets/luxury_score_certificate.dart)).
3. **فحص وتدقيق الشهادات ([`certificate_verification_screen.dart`](file:///e:/apps/iraqinpt/lib/screens/student/certificate_verification_screen.dart))**:
   - ربط مباشر مع بوابة جامعة بغداد الرسمية للتحقق من الوثائق (`https://qr.uob.edu.iq/`).
   - طلب إذن الكاميرا التلقائي لمسح الـ QR مع دعم الفيديو المباشر في الـ WebView.
4. **خزانة الأخطاء الذكية ([`mistakes_screen.dart`](file:///e:/apps/iraqinpt/lib/screens/student/mistakes_screen.dart))**:
   - تجميع تلقائي لجميع الأسئلة التي أخفق فيها الطالب لإعادة التمرن عليها وتصفير الأخطاء.
5. **لوحة الصدارة وقائمة الشرف ([`leaderboard_screen.dart`](file:///e:/apps/iraqinpt/lib/screens/student/leaderboard_screen.dart))**:
   - تصنيف أسبوعي وعام للطلاب الأكثر تفوقاً وحصداً للنقاط في الامتحانات.
6. **باقات الاشتراك ([`subscription_screen.dart`](file:///e:/apps/iraqinpt/lib/screens/student/subscription_screen.dart))**:
   - عرض أسعار الباقات المستخرجة مباشرة وحياً من Firestore (`price_1m`, `price_2m`, `price_3m`, `price_1y`).
   - نافذة إدخال كود التفعيل الرقمي للترقية الفورية.

---

## 9. محرك الاختبارات والعمل دون إنترنت (Offline-First)

- **الملف المسئول**: [`lib/services/question_service.dart`](file:///e:/apps/iraqinpt/lib/services/question_service.dart)

### 💡 الآلية المعمارية لتحميل الأسئلة:
1. يتم استضافة ملفات الـ JSON الخاصة ببنوك الأسئلة على مستودع GitHub موثوق لتقليل كلفة قراءات الفايربيس إلى 0%:
   - **العربية**: `questionsinpt/main/arabic`
   - **الحاسوب**: `questionsinpt/main/computer_ar`
   - **الإنجليزية**: `questionsinpt/main/english`
2. **الكاش المحلي الذكي**:
   - عند تحميل أي بنك أسئلة، يتم حفظه محلياً في `SharedPreferences` مع بصمة تجزئة (`hashKey`).
   - عند فتح الامتحان دون اتصال بالإنترنت، يقرأ التطبيق الأسئلة من الكاش المحلي فوراً دون أي انقطاع.
   - يتوفر زر **"مزامنة وتحميل جميع الأسئلة للعمل دون إنترنت"** في شاشات الطالب.

---

## 10. إدارة الحالة والثيمات

- **إدارة الحالة (State Management)**: مزيج فعال ومدروس من `Provider` مع `StatefulBuilder` و `Streams` الخاصة بـ Firestore لضمان خفة الأداء وعدم استهلاك موارد الهاتف.
- **مزود الإعدادات ([`settings_provider.dart`](file:///e:/apps/iraqinpt/lib/providers/settings_provider.dart))**:
  - تبديل الثيم بين **Dark Luxury Mode** (كحلي ملكي داكن `0xFF0F172A`) و **Light Mode**.
  - ضبط مقياس حجم الخط في التطبيق بالكامل (`fontScale`).
  - حفظ التفضيلات محلياً بـ `SharedPreferences`.

---

## 11. دليل بناء الحزم والتصدير

### 📦 1. تصدير ملف APK (Release):
```bash
flutter build apk --release
```
- **مسار الملف الناتج**: `build/app/outputs/flutter-apk/app-release.apk`

### 📦 2. تصدير حزمة Google Play Bundle (AAB):
```bash
flutter build appbundle --release
```
- **مسار الملف الناتج**: `build/app/outputs/bundle/release/app-release.aab`

### 🌐 3. نشر وتحديث موقع الويب المباشر:
```bash
flutter build web --release
npx -y firebase-tools@latest deploy --only hosting
```
- **الرابط المنشور**: [https://inptiq.web.app](https://inptiq.web.app)

---

## 12. ملاحظات هامة وإرشادات الصيانة

1. **قواعد حماية Proguard للأندرويد**:
   - ملف [`android/app/proguard-rules.pro`](file:///e:/apps/iraqinpt/android/app/proguard-rules.pro) يحتوي على قواعد `-keep` لحماية كلاسات `firebase_messaging` و `flutter_local_notifications` من الحذف عند الـ Shrinking في الـ Release.
2. **إذن الكاميرا والإشعارات في AndroidManifest**:
   - ملف [`android/app/src/main/AndroidManifest.xml`](file:///e:/apps/iraqinpt/android/app/src/main/AndroidManifest.xml) يحتوي على أذونات `POST_NOTIFICATIONS`, `CAMERA`, `VIBRATE`, `WAKE_LOCK`, و `RECEIVE_BOOT_COMPLETED`.
3. **مفتاح خادم FCM**:
   - المفتاح الرسمي للمشروع مدمج افتراضياً ومخزن في قاعدة البيانات تحت `system_settings/maintenance_and_updates -> fcm_server_key`.

---
> ✍️ **تم إعداد وتوثيق هذا الدليل ليكون مرجعاً تقنياً وهندسياً متكاملاً لأي مهندس برمجي يستلم المشروع.**

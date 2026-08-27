# 🇮🇶 تطبيق الامتحان الوطني الموحد (INPT - Iraqi National Proficiency Test)

منصة تعليمية متكاملة لطلبة الدراسات العليا في العراق لمحاكاة واجتياز الامتحان الوطني الموحد في (اللغة العربية، الحاسوب، واللغة الإنجليزية) عبر الهواتف والويب.

---

## 📖 الدليل الشامل لتسليم المشروع (Developer Handover & Documentation)

تم إعداد وثيقة توثيق وتسليم تقنية كاملة ومفصلة للمشروع تشرح كل ملف، خدمة، نموذج بيانات، ومنظومات الأمان والإشعارات:

👉 **[اضغط هنا لقراءة ملف تسليم المشروع الكامل: PROJECT_HANDOVER.md](./PROJECT_HANDOVER.md)**

---

## 🚀 ملخص الأوامر السريعة (Quick Commands)

### 1. تشغيل التطبيق في بيئة التطوير (Development):
```bash
flutter run
```

### 2. تصدير تطبيق الأندرويد (Release APK):
```bash
flutter build apk --release
```

### 3. تصدير حزمة متجر جوجل بلاي (AAB):
```bash
flutter build appbundle --release
```

### 4. بناء ونشر تطبيق الويب على Firebase Hosting:
```bash
flutter build web --release
npx -y firebase-tools@latest deploy --only hosting
```
- **رابط الويب المباشر**: [https://inptiq.web.app](https://inptiq.web.app)

---

## 🛠️ أهم التقنيات المستخدمة:
- **Framework**: Flutter 3 (Dart)
- **Backend & Cloud**: Firebase (Auth, Firestore, Cloud Messaging, Crashlytics, Hosting)
- **Security**: Single Device Hardware Locking, VPN Detection, Maintenance Mode
- **Features**: Real-time Exam Simulation, AI Question Explanations, TTS Audio, Offline Caching, Leaderboard, Smart Mistake Vault.

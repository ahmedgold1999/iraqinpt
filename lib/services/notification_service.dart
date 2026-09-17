import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:permission_handler/permission_handler.dart';

/// ✅ معالج الإشعارات والتطبيق مغلق تماماً (Background & Terminated)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  } catch (_) {}

  debugPrint('📬 Background message received: ${message.messageId}');
  
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
  
  await localNotifications.initialize(settings);

  final title = message.notification?.title ?? message.data['title']?.toString() ?? 'إشعار جديد من المنصة 📢';
  final body = message.notification?.body ?? message.data['body']?.toString() ?? message.data['message']?.toString() ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'قناة الإشعارات الفورية العامة والخاصة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: message.data.toString(),
    );
  }
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static bool _isListenersSetup = false;
  static final Set<String> _shownNotificationSignatures = {};

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String defaultServiceAccountJson = r'''{
  "type": "service_account",
  "project_id": "inpt-app-20260108022659",
  "private_key_id": "e806c0bdea8b85cd2d7dc42d809a4652c6ee4ceb",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDSQLC/fSHEJhfM\nEZpazjdJqfZLQHhXM4QGJNNuYxtlwJHnjH9ak7yn8YszRqgiH+q7Oiy3T6TyrWVQ\n7srIez7EI4MEQR1aXpgl8trzzM0pQbLOZxAoABeNwwfhE9HDw1VC8XKZ/krczzOz\nJ6IUhbwa5z5d+E/yOzVpwDzbrHNoyEkIUkDXYWjVFIUfmyh+4L3MZoACTJeRIKjC\n2WVQWuutHU2pYVkkT+j5o31VTDKpcK5NevMZi7P5Ke5cAI2lOQE/0ppb7vBqMU2r\n6YWHP97Tw+6Zs6G86l5bMKltfq2uN+1PKAKLSMUGrMDEE+R6CUsLn+wNM2V/FF2D\nQSa7nqtZAgMBAAECggEAAyCuI1PTBds7NfB6MBHNnRwByHwRCGavyHS0g2JprNUY\nJ//RmBWG5aXDTLVtGK8KUWsNNzzgbjGPl+lYX/4D5nfFIhTi+0KfKMuKPNQHd9Gl\npjLtMvbEqL+RP4eJZu8E8PMV0ED+VY4ybZjtVcR0nhNKjjerDSZVDuVNjhh4F8Ok\nxggcxkAMLw8JQ9utiN4SmCwY0/0FXR35k5biRHufZrhE3crEsgg3bq5oTWFi8VWb\nsK9hIDXC0xsN/MD25Uhrjwg/KkdD9r8b6BZ1/z3hno3TVvG3JqIwI6jcX13Br0sj\nnXR3pRxvBrLJAVFpTT2rcvvuURTL77GScKb449DEMQKBgQD64/9fe3gycgv9xtKV\nJRmVVOrCZNHzdNqARk2IZwDJ2ghhMzw0AAmlK1HxUCzZBzCmTex8AxOHzY1uPZgc\ni0mQxi+O99WJP9evQUq/uXAYcCG/6tBSybZQDCfJ+61cOztrpCfP8cs7J9gWdMP9\n/Lb/RAfL4F6VC0g0apVQbBqO6wKBgQDWiNRjLG3fcS3f3e5PIByRrTQ+sNrSuC/G\nfP+VLSD3Sm5ob12wPyc6pGTpRVLUAHJGUmWZSMv6GUMHYNsFwcorZBuj44I7ST6p\nzKLnchSuZzeA+0loER79NXfR690S0hDYZ6k09EcTN6Kc0a92jQ93DfCWN6nE3Xy6\naoO1r55FywKBgHsmeQ68Q3a3hm1OL8WnzVQAt68t3+SZ4jr+x0YCEWADVwOnK5D2\nx8U8a1+BFFJ/dgDb1Q3WULrjSd3n/Ade04Bt16BcxIM3RD6xVOihNIW6XMagkxtg\nCc5m+QzrLeBM7tDaZfRrYm+qEiaLsDy21HieQxlvC94rCIk6HAq61Zp7AoGAEa/I\nKsDv8frnuEwYqIdSM6Re6Ug1UigDME7/1zGYRSrqvUtpIu2h81C4TQ79DCNZSHjk\njWWWA3FvuD0A8ZGPdFJVgQZxpyebte38BC7Ai7xQtB6DZ8P5lRCCZ1kVqcaNwvmQ\n1p/I+Eme62TSHWj1vG/2xLukEGneLZQ4dZMb7k8CgYEAzXiaJctEBpo4uWE5QlmA\n5ST2ee8yf7yRUrC73Gv84XG9+hQ7yzKPgDtZZJb7/V2NQCFt9/STgprDM1t2ult4\n3dyJaw8pYQpctEAxhJuS1YVl2WT6dKRzJin+ZKIHvm6LZxeQiwZC11yQWmI0oT6n\n8r4Eb8JMfHICH/luVhSXJvM=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@inpt-app-20260108022659.iam.gserviceaccount.com",
  "client_id": "116175816972335544475",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40inpt-app-20260108022659.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}''';

  /// ===================== INIT =====================
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('👆 Local notification clicked: ${details.payload}');
      },
    );

    // ✅ إنشاء قناة الإشعارات للأندرويد لظهور الإشعارات كـ Heads-up مع الصوت
    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'قناة الإشعارات الفورية العامة والخاصة',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // ربط معالج الخلفية
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    }
  }

  /// ===================== ENABLE NOTIFICATIONS =====================
  static Future<void> enableNotifications() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            await Permission.notification.request();
          }
        } catch (e) {
          debugPrint('⚠️ Permission request error: $e');
        }
      }

      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // ✅ الاشتراك التلقائي في كافة المواضيع لضمان وصول الإشعارات والتطبيق مغلق
        if (!kIsWeb) {
          try {
            await _fcm.subscribeToTopic('all');
            await _fcm.subscribeToTopic('global');
            await _fcm.subscribeToTopic('students');
            debugPrint('✅ Subscribed to FCM topics: all, global, students');
          } catch (e) {
            debugPrint('⚠️ Topic subscription error: $e');
          }
        }

        String? token = await _fcm.getToken();
        debugPrint('📱 FCM Token: $token');

        await _saveTokenToFirestore(token);

        _fcm.onTokenRefresh.listen((newToken) async {
          await _saveTokenToFirestore(newToken);
          if (!kIsWeb) {
            try {
              await _fcm.subscribeToTopic('all');
              await _fcm.subscribeToTopic('global');
              await _fcm.subscribeToTopic('students');
            } catch (_) {}
          }
        });

        setupListeners();
      } else {
        debugPrint('❌ User refused notifications permission');
      }
    } catch (e) {
      debugPrint('❌ Error in enableNotifications: $e');
    }
  }

  /// ===================== SAVE TOKEN =====================
  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null || token.isEmpty) return;

    try {
      // 1. ✅ حفظ التوكن في المجموعة العامة للأجهزة لإرسال الإشعارات المباشرة حتى بدون تسجيل دخول
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
      }, SetOptions(merge: true));

      // 2. ✅ حفظ التوكن في سجل المستخدم إذا كان مسجلاً الدخول
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': kIsWeb ? 'web' : 'mobile',
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  /// ===================== LISTENERS =====================
  static void setupListeners() {
    if (_isListenersSetup) return;
    _isListenersSetup = true;

    // استلام الإشعارات والتطبيق مفتوح (Foreground FCM)
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📬 Foreground FCM: ${message.notification?.title}');
      final title = message.notification?.title ?? message.data['title']?.toString() ?? 'إشعار جديد 🔔';
      final body = message.notification?.body ?? message.data['body']?.toString() ?? message.data['message']?.toString() ?? '';
      final signature = '$title|$body';

      if (!_shownNotificationSignatures.contains(signature)) {
        _shownNotificationSignatures.add(signature);
        showLocalNotification(message);
      }
    });

    // عند الضغط على الإشعار والتطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('👆 Notification clicked (Background)');
      _handleNavigation(message);
    });

    // عند الضغط على الإشعار والتطبيق مغلق تماماً (Terminated)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('👆 Notification clicked (Terminated)');
        _handleNavigation(message);
      }
    });

    // الاستماع للإشعارات من Firestore لمنع التكرار
    final DateTime appStartTime = DateTime.now().subtract(const Duration(seconds: 3));
    FirebaseFirestore.instance
        .collection('all_notifications')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(appStartTime))
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final title = data['title']?.toString() ?? 'إشعار جديد من الإدارة 📢';
            final body = (data['body'] ?? data['message'] ?? '').toString();
            final signature = '$title|$body';
            
            // عدم تكرار العرض إذا تم عرضه مسبقاً عبر FCM
            if (!_shownNotificationSignatures.contains(signature)) {
              _shownNotificationSignatures.add(signature);
              showLocalNotificationDirect(title: title, body: body);
            }
          }
        }
      }
    }, onError: (e) => debugPrint('⚠️ Error in firestore notif stream: $e'));
  }

  /// ===================== LOCAL NOTIFICATION =====================
  static Future<void> showLocalNotification(RemoteMessage message) async {
    await showLocalNotificationDirect(
      title: message.notification?.title ?? message.data['title']?.toString() ?? 'إشعار جديد 🔔',
      body: message.notification?.body ?? message.data['body']?.toString() ?? message.data['message']?.toString() ?? '',
      payload: message.data.toString(),
    );
  }

  static Future<void> showLocalNotificationDirect({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'قناة الإشعارات الفورية العامة والخاصة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// ===================== NAVIGATION =====================
  static void _handleNavigation(RemoteMessage message) {
    final screen = message.data['screen'];
    debugPrint('🔗 Navigate to: $screen');
  }

  /// ===================== FIRESTORE STREAM (MANAGES DE-DUPLICATION) =====================
  // جلب الإشعارات الخاصة والعامة مع منع التكرار بنسبة 100%
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    final userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(35)
        .snapshots();

    final globalStream = FirebaseFirestore.instance
        .collection('all_notifications')
        .orderBy('createdAt', descending: true)
        .limit(35)
        .snapshots();

    late StreamController<List<NotificationModel>> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    QuerySnapshot? lastUserSnap;
    QuerySnapshot? lastGlobalSnap;

    void updateList() {
      Map<String, NotificationModel> map = {};
      Set<String> seenSignatures = {};

      // 1. معالجة الإشعارات الخاصة بالمستخدم أولاً
      if (lastUserSnap != null) {
        for (var doc in lastUserSnap!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().trim();
          final body = (data['body'] ?? data['message'] ?? '').toString().trim();
          final sig = '$title|$body';

          map[doc.id] = NotificationModel(
            id: doc.id,
            title: title,
            body: body,
            dateTime: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isRead: data['isRead'] ?? false,
            type: data['type'],
            isGlobal: false,
          );
          seenSignatures.add(sig);
        }
      }

      // 2. معالجة الإشعارات العامة مع فلترة التكرار
      if (lastGlobalSnap != null) {
        for (var doc in lastGlobalSnap!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().trim();
          final body = (data['body'] ?? data['message'] ?? '').toString().trim();
          final sig = '$title|$body';

          // تجنب إظهار نفس الإشعار مرتين
          if (map.containsKey(doc.id) || seenSignatures.contains(sig)) continue;

          final List readBy = data['readBy'] ?? [];

          map[doc.id] = NotificationModel(
            id: doc.id,
            title: title,
            body: body,
            dateTime: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isRead: readBy.contains(userId),
            type: data['type'],
            isGlobal: true,
          );
          seenSignatures.add(sig);
        }
      }

      List<NotificationModel> combined = map.values.toList();
      combined.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      if (!controller.isClosed) {
        controller.add(combined);
      }
    }

    controller = StreamController<List<NotificationModel>>(
      onListen: () {
        sub1 = userStream.listen((snap) {
          lastUserSnap = snap;
          updateList();
        });

        sub2 = globalStream.listen((snap) {
          lastGlobalSnap = snap;
          updateList();
        });
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  static Stream<int> getUnreadCount(String userId) {
    return getUserNotifications(userId).map((list) => list.where((n) => !n.isRead).length);
  }

  static Future<void> markAsRead(String userId, String notificationId, {bool isGlobal = false}) async {
    if (isGlobal) {
      await FirebaseFirestore.instance
          .collection('all_notifications')
          .doc(notificationId)
          .update({
        'readBy': FieldValue.arrayUnion([userId])
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    final globalDocs = await FirebaseFirestore.instance
        .collection('all_notifications')
        .orderBy('createdAt', descending: true)
        .limit(15)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    
    for (var doc in globalDocs.docs) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([userId])
      });
    }

    final privateDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in privateDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  static Future<void> deleteNotification(
      String userId, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// ===================== SEND BROADCAST VIA FCM =====================
  static Future<FcmPushResponse> sendBroadcastPush({
    required String title,
    required String body,
    String targetSegment = 'all',
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('maintenance_and_updates')
          .get();

      String serverKey = doc.data()?['fcm_server_key']?.toString().trim() ?? '';
      if (serverKey.isEmpty) {
        serverKey = 'AIzaSyDy8Av3HcsiX-ZY5suKmpbyuZOX8q4HDC0';
      }

      List<String> topics = [];
      if (targetSegment == 'all') {
        topics = ['all', 'global', 'students'];
      } else if (targetSegment == 'premium') {
        topics = ['premium'];
      } else if (targetSegment == 'free') {
        topics = ['free'];
      } else {
        topics = ['all'];
      }

      int lastStatusCode = 0;
      String lastResponseBody = '';
      bool anySuccess = false;

      // 1. ✅ فحص إذا كان مفتاح حساب خدمة فايربيس (FCM V1) متوفراً
      String serviceAccountRaw = doc.data()?['service_account_json']?.toString().trim() ?? '';
      if (serviceAccountRaw.isEmpty || !serviceAccountRaw.startsWith('{')) {
        serviceAccountRaw = defaultServiceAccountJson;
      }
      if (serviceAccountRaw.isNotEmpty && serviceAccountRaw.startsWith('{')) {
        try {
          final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountRaw);
          final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
          final authClient = await clientViaServiceAccount(accountCredentials, scopes);
          final projectId = accountCredentials.projectId;

          for (var topic in topics) {
            final v1Payload = {
              'message': {
                'topic': topic,
                'notification': {
                  'title': title,
                  'body': body,
                },
                'data': {
                  'title': title,
                  'body': body,
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'screen': 'notifications',
                  'isGlobal': 'true',
                },
                'android': {
                  'priority': 'HIGH',
                  'direct_boot_ok': true,
                  'notification': {
                    'channel_id': 'high_importance_channel',
                    'sound': 'default',
                    'default_sound': true,
                    'notification_priority': 'PRIORITY_HIGH',
                    'visibility': 'PUBLIC',
                  }
                },
                'apns': {
                  'payload': {
                    'aps': {
                      'sound': 'default',
                      'badge': 1,
                      'content-available': 1,
                    }
                  }
                }
              }
            };

            final v1Response = await authClient.post(
              Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(v1Payload),
            );

            lastStatusCode = v1Response.statusCode;
            lastResponseBody = v1Response.body;
            debugPrint('📬 FCM V1 Topic ($topic) Response: ${v1Response.statusCode} -> ${v1Response.body}');
            if (v1Response.statusCode == 200) {
              anySuccess = true;
            }
          }

          // 2. ✅ إرسال مباشر لكل الأجهزة المسجلة عبر التوكن لضمان التوصيل الفوري 100%
          try {
            final tokensSnap = await FirebaseFirestore.instance
                .collection('fcm_tokens')
                .limit(500)
                .get();

            debugPrint('📱 Sending direct FCM V1 push to ${tokensSnap.docs.length} registered devices...');
            for (var doc in tokensSnap.docs) {
              final deviceToken = doc.data()['token']?.toString();
              if (deviceToken != null && deviceToken.isNotEmpty) {
                final directPayload = {
                  'message': {
                    'token': deviceToken,
                    'notification': {
                      'title': title,
                      'body': body,
                    },
                    'data': {
                      'title': title,
                      'body': body,
                      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                      'screen': 'notifications',
                      'isGlobal': 'true',
                    },
                    'android': {
                      'priority': 'HIGH',
                      'direct_boot_ok': true,
                      'notification': {
                        'channel_id': 'high_importance_channel',
                        'sound': 'default',
                        'default_sound': true,
                        'notification_priority': 'PRIORITY_HIGH',
                        'visibility': 'PUBLIC',
                      }
                    },
                    'apns': {
                      'payload': {
                        'aps': {
                          'sound': 'default',
                          'badge': 1,
                          'content-available': 1,
                        }
                      }
                    }
                  }
                };

                authClient.post(
                  Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode(directPayload),
                );
                anySuccess = true;
              }
            }
          } catch (e) {
            debugPrint('⚠️ Direct tokens push warning: $e');
          }

          authClient.close();

          if (anySuccess) {
            return FcmPushResponse(
              success: true,
              statusCode: 200,
              message: 'تم إرسال وتعميم الإشعار السحابي بنجاح عبر FCM HTTP V1 إلى جميع الأجهزة!',
              rawResponse: lastResponseBody,
            );
          } else {
            return FcmPushResponse(
              success: false,
              statusCode: lastStatusCode,
              message: 'تعذر إرسال الإشعار عبر FCM V1 (كود: $lastStatusCode): $lastResponseBody',
              rawResponse: lastResponseBody,
            );
          }
        } catch (e) {
          debugPrint('⚠️ FCM V1 execution error: $e');
        }
      }

      for (var topic in topics) {
        final payload = {
          'to': '/topics/$topic',
          'priority': 'high',
          'content_available': true,
          'direct_boot_ok': true,
          'time_to_live': 2419200,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'android_channel_id': 'high_importance_channel',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'data': {
            'title': title,
            'body': body,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'screen': 'notifications',
            'isGlobal': 'true',
          },
        };

        try {
          final response = await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$serverKey',
            },
            body: json.encode(payload),
          );

          lastStatusCode = response.statusCode;
          lastResponseBody = response.body;

          debugPrint('📬 FCM Topic ($topic) Response: ${response.statusCode} -> ${response.body}');
          if (response.statusCode == 200) {
            anySuccess = true;
          }
        } catch (e) {
          debugPrint('⚠️ Error sending to topic $topic: $e');
          lastResponseBody = e.toString();
        }
      }

      if (anySuccess) {
        return FcmPushResponse(
          success: true,
          statusCode: 200,
          message: 'تم إرسال وتعميم الإشعار السحابي بنجاح إلى جميع الأجهزة!',
          rawResponse: lastResponseBody,
        );
      } else if (lastStatusCode == 401) {
        return FcmPushResponse(
          success: false,
          statusCode: 401,
          message: 'مفتاح خادم FCM غير صالح أو لم يتم تفعيله من Firebase Console (خطأ 401).',
          rawResponse: lastResponseBody,
        );
      } else {
        return FcmPushResponse(
          success: false,
          statusCode: lastStatusCode,
          message: 'تعذر إرسال الإشعار السحابي (كود: $lastStatusCode): $lastResponseBody',
          rawResponse: lastResponseBody,
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM broadcast push: $e');
      return FcmPushResponse(
        success: false,
        statusCode: 500,
        message: 'خطأ غير متوقع: $e',
      );
    }
  }
}

class FcmPushResponse {
  final bool success;
  final int statusCode;
  final String message;
  final String? rawResponse;

  FcmPushResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.rawResponse,
  });
}

/// ===================== MODEL =====================
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime dateTime;
  final bool isRead;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isGlobal;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.dateTime,
    this.isRead = false,
    this.type,
    this.data,
    this.isGlobal = false,
  });
}

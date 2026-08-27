import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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
    if (token == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
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
  static Future<bool> sendBroadcastPush({
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

      bool anySuccess = false;

      for (var topic in topics) {
        final payload = {
          'to': '/topics/$topic',
          'priority': 'high',
          'content_available': true,
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

          debugPrint('📬 FCM Topic ($topic) Response: ${response.statusCode} -> ${response.body}');
          if (response.statusCode == 200) {
            anySuccess = true;
          }
        } catch (e) {
          debugPrint('⚠️ Error sending to topic $topic: $e');
        }
      }

      return anySuccess;
    } catch (e) {
      debugPrint('❌ Error sending FCM broadcast push: $e');
      return false;
    }
  }
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

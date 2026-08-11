import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ✅ مهم جداً: لازم تكون خارج الكلاس
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  print('📬 Background message received: ${message.messageId}');
  
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
  
  await localNotifications.initialize(settings);

  if (message.notification != null) {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()),
    );
  }
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static bool _isListenersSetup = false;

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static final CollectionReference _notificationsCollection =
  FirebaseFirestore.instance.collection('notifications');

  /// ===================== INIT =====================
  static Future<void> initialize() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // ✅ إنشاء قناة الإشعارات للأندرويد (مهم جداً لظهور الإشعارات كـ Heads-up)
    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // إعداد الـ background (فقط غير Web)
    if (!kIsWeb) {
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
        
        // ✅ الاشتراك التلقائي في المواضيع العامة فقط على الأجهزة (غير الويب)
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
        print('❌ User refused notifications');
      }
    } catch (e) {
      print('❌ Error in enableNotifications: $e');
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
      });
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  /// ===================== LISTENERS =====================
  static void setupListeners() {
    if (_isListenersSetup) return;
    _isListenersSetup = true;

    // استلام الإشعارات والتطبيق مفتوح
    FirebaseMessaging.onMessage.listen((message) {
      print('📬 Foreground: ${message.notification?.title}');
      showLocalNotification(message);
    });

    // عند الضغط على الإشعار والتطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('👆 Notification clicked (Background)');
      _handleNavigation(message);
    });

    // عند الضغط على الإشعار والتطبيق مغلق تماماً (Terminated)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('👆 Notification clicked (Terminated)');
        _handleNavigation(message);
      }
    });
  }

  /// ===================== LOCAL NOTIFICATION =====================
  static Future<void> showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'App notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'إشعار جديد',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  /// ===================== NAVIGATION =====================
  static void _handleNavigation(RemoteMessage message) {
    final screen = message.data['screen'];
    print('🔗 Navigate to: $screen');
  }

  /// ===================== FIRESTORE STREAM =====================
  // جلب الإشعارات الخاصة والعامة مع الدمج الحي (Real-time updates)
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    final userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();

    final globalStream = FirebaseFirestore.instance
        .collection('all_notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();

    late StreamController<List<NotificationModel>> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    QuerySnapshot? lastUserSnap;
    QuerySnapshot? lastGlobalSnap;

    void updateList() {
      List<NotificationModel> combined = [];

      if (lastUserSnap != null) {
        for (var doc in lastUserSnap!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          combined.add(NotificationModel(
            id: doc.id,
            title: data['title'] ?? '',
            body: data['body'] ?? '',
            dateTime: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isRead: data['isRead'] ?? false,
            type: data['type'],
            isGlobal: false,
          ));
        }
      }

      if (lastGlobalSnap != null) {
        for (var doc in lastGlobalSnap!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final List readBy = data['readBy'] ?? [];

          combined.add(NotificationModel(
            id: doc.id,
            title: data['title'] ?? '',
            body: data['body'] ?? '',
            dateTime: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isRead: readBy.contains(userId),
            type: data['type'],
            isGlobal: true,
          ));
        }
      }

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
      // تحديث في المجموعة العامة (إضافة المستخدم لقائمة القراء)
      await FirebaseFirestore.instance
          .collection('all_notifications')
          .doc(notificationId)
          .update({
        'readBy': FieldValue.arrayUnion([userId])
      });
    } else {
      // تحديث في مجموعة المستخدم الخاصة
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    // هذه العملية قد تكون مكلفة، لذا سنقوم بوضع علامة على الإشعارات العامة الأخيرة فقط
    final globalDocs = await FirebaseFirestore.instance
        .collection('all_notifications')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    
    for (var doc in globalDocs.docs) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([userId])
      });
    }

    // الإشعارات الخاصة
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

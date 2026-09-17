import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

/// ===============================================================
/// Firebase Background & Terminated Handler
/// ===============================================================

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(
    RemoteMessage message,
    ) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();
  } catch (_) {}

  try {
    debugPrint(
      '📬 Background message received: ${message.messageId}',
    );

    final FlutterLocalNotificationsPlugin
    localNotifications =
    FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings
    androidSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings
    iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(
      settings: settings,
    );

    final String title =
        message.notification?.title ??
            message.data['title']?.toString() ??
            'إشعار جديد من المنصة 📢';

    final String body =
        message.notification?.body ??
            message.data['body']?.toString() ??
            message.data['message']?.toString() ??
            '';

    if (title.isNotEmpty || body.isNotEmpty) {
      const AndroidNotificationDetails
      androidDetails =
      AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
        'قناة الإشعارات الفورية العامة والخاصة',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails
      iosDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details =
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await localNotifications.show(
        id: message.messageId?.hashCode ??
            DateTime.now()
                .millisecondsSinceEpoch
                .remainder(1000000),
        title: title,
        body: body,
        notificationDetails: details,
        payload: jsonEncode(message.data),
      );
    }
  } catch (e, stackTrace) {
    debugPrint(
      '❌ Background notification error: $e',
    );
    debugPrint('$stackTrace');
  }
}

/// ===============================================================
/// Notification Service
/// ===============================================================

class NotificationService {
  static final FirebaseMessaging _fcm =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
  _localNotifications =
  FlutterLocalNotificationsPlugin();

  static bool _isListenersSetup = false;

  static final Set<String>
  _shownNotificationSignatures =
  <String>{};

  /// =============================================================
  /// IMPORTANT:
  /// لا تضع Service Account Private Key داخل تطبيق Flutter.
  /// =============================================================

  static const String defaultServiceAccountJson = '';

  /// =============================================================
  /// INIT
  /// =============================================================

  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings
      androidSettings =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const DarwinInitializationSettings
      iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings settings =
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: settings,
        onDidReceiveNotificationResponse:
            (NotificationResponse details) {
          debugPrint(
            '👆 Local notification clicked: '
                '${details.payload}',
          );
        },
      );

      if (!kIsWeb && Platform.isAndroid) {
        const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description:
          'قناة الإشعارات الفورية العامة والخاصة',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseBackgroundHandler,
        );
      }

      debugPrint(
        '✅ NotificationService initialized',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ NotificationService initialize error: $e',
      );
      debugPrint('$stackTrace');
    }
  }

  /// =============================================================
  /// ENABLE NOTIFICATIONS
  /// =============================================================

  static Future<void> enableNotifications() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final PermissionStatus status =
          await Permission.notification.status;

          if (!status.isGranted) {
            await Permission.notification.request();
          }
        } catch (e) {
          debugPrint(
            '⚠️ Permission request error: $e',
          );
        }
      }

      final NotificationSettings settings =
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus ==
          AuthorizationStatus.authorized ||
          settings.authorizationStatus ==
              AuthorizationStatus.provisional) {
        if (!kIsWeb) {
          try {
            await _fcm.subscribeToTopic('all');
            await _fcm.subscribeToTopic('global');
            await _fcm.subscribeToTopic('students');

            debugPrint(
              '✅ Subscribed to FCM topics: '
                  'all, global, students',
            );
          } catch (e) {
            debugPrint(
              '⚠️ Topic subscription error: $e',
            );
          }
        }

        final String? token =
        await _fcm.getToken();

        debugPrint(
          '📱 FCM Token: $token',
        );

        await _saveTokenToFirestore(token);

        _fcm.onTokenRefresh.listen(
              (String newToken) async {
            await _saveTokenToFirestore(
              newToken,
            );

            if (!kIsWeb) {
              try {
                await _fcm.subscribeToTopic('all');
                await _fcm.subscribeToTopic('global');
                await _fcm.subscribeToTopic('students');
              } catch (_) {}
            }
          },
        );

        setupListeners();
      } else {
        debugPrint(
          '❌ User refused notifications permission',
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Error in enableNotifications: $e',
      );
      debugPrint('$stackTrace');
    }
  }

  /// =============================================================
  /// SAVE TOKEN
  /// =============================================================

  static Future<void> _saveTokenToFirestore(
      String? token,
      ) async {
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(token)
          .set(
        {
          'token': token,
          'userId':
          FirebaseAuth.instance.currentUser?.uid,
          'updatedAt':
          FieldValue.serverTimestamp(),
          'platform': kIsWeb
              ? 'web'
              : Platform.isAndroid
              ? 'android'
              : 'ios',
        },
        SetOptions(merge: true),
      );

      final String? userId =
          FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .set(
          {
            'token': token,
            'createdAt':
            FieldValue.serverTimestamp(),
            'platform': kIsWeb
                ? 'web'
                : 'mobile',
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Error saving FCM token: $e',
      );
    }
  }

  /// =============================================================
  /// LISTENERS
  /// =============================================================

  static void setupListeners() {
    if (_isListenersSetup) {
      return;
    }

    _isListenersSetup = true;

    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) {
        debugPrint(
          '📬 Foreground FCM: '
              '${message.notification?.title}',
        );

        final String title =
            message.notification?.title ??
                message.data['title']?.toString() ??
                'إشعار جديد 🔔';

        final String body =
            message.notification?.body ??
                message.data['body']?.toString() ??
                message.data['message']?.toString() ??
                '';

        final String signature =
            '$title|$body';

        if (!_shownNotificationSignatures
            .contains(signature)) {
          _shownNotificationSignatures
              .add(signature);

          showLocalNotification(message);
        }
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        debugPrint(
          '👆 Notification clicked (Background)',
        );

        _handleNavigation(message);
      },
    );

    FirebaseMessaging.instance
        .getInitialMessage()
        .then(
          (RemoteMessage? message) {
        if (message != null) {
          debugPrint(
            '👆 Notification clicked (Terminated)',
          );

          _handleNavigation(message);
        }
      },
    );

    final DateTime appStartTime =
    DateTime.now().subtract(
      const Duration(seconds: 3),
    );

    FirebaseFirestore.instance
        .collection('all_notifications')
        .where(
      'createdAt',
      isGreaterThan:
      Timestamp.fromDate(appStartTime),
    )
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>>
      snapshot) {
        for (final DocumentChange<
            Map<String, dynamic>> change
        in snapshot.docChanges) {
          if (change.type !=
              DocumentChangeType.added) {
            continue;
          }

          final Map<String, dynamic>? data =
          change.doc.data();

          if (data == null) {
            continue;
          }

          final String title =
              data['title']?.toString() ??
                  'إشعار جديد من الإدارة 📢';

          final String body =
          (data['body'] ??
              data['message'] ??
              '')
              .toString();

          final String signature =
              '$title|$body';

          if (!_shownNotificationSignatures
              .contains(signature)) {
            _shownNotificationSignatures
                .add(signature);

            showLocalNotificationDirect(
              title: title,
              body: body,
              payload: jsonEncode(data),
            );
          }
        }
      },
      onError: (Object error) {
        debugPrint(
          '⚠️ Error in Firestore notification stream: '
              '$error',
        );
      },
    );
  }

  /// =============================================================
  /// LOCAL NOTIFICATION FROM FCM
  /// =============================================================

  static Future<void> showLocalNotification(
      RemoteMessage message,
      ) async {
    await showLocalNotificationDirect(
      title: message.notification?.title ??
          message.data['title']?.toString() ??
          'إشعار جديد 🔔',
      body: message.notification?.body ??
          message.data['body']?.toString() ??
          message.data['message']?.toString() ??
          '',
      payload: jsonEncode(message.data),
    );
  }

  /// =============================================================
  /// LOCAL NOTIFICATION DIRECT
  /// =============================================================

  static Future<void> showLocalNotificationDirect({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      return;
    }

    try {
      const AndroidNotificationDetails
      androidDetails =
      AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
        'قناة الإشعارات الفورية العامة والخاصة',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility:
        NotificationVisibility.public,
      );

      const DarwinNotificationDetails
      iosDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details =
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .remainder(1000000),
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Local notification error: $e',
      );
      debugPrint('$stackTrace');
    }
  }

  /// =============================================================
  /// NAVIGATION
  /// =============================================================

  static void _handleNavigation(
      RemoteMessage message,
      ) {
    final dynamic screen =
    message.data['screen'];

    debugPrint(
      '🔗 Navigate to: $screen',
    );
  }

  /// =============================================================
  /// GET USER NOTIFICATIONS
  /// =============================================================

  static Stream<List<NotificationModel>>
  getUserNotifications(
      String userId,
      ) {
    final Stream<
        QuerySnapshot<Map<String, dynamic>>>
    userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy(
      'createdAt',
      descending: true,
    )
        .limit(35)
        .snapshots();

    final Stream<
        QuerySnapshot<Map<String, dynamic>>>
    globalStream = FirebaseFirestore.instance
        .collection('all_notifications')
        .orderBy(
      'createdAt',
      descending: true,
    )
        .limit(35)
        .snapshots();

    late StreamController<
        List<NotificationModel>> controller;

    StreamSubscription? sub1;
    StreamSubscription? sub2;

    QuerySnapshot<Map<String, dynamic>>?
    lastUserSnap;

    QuerySnapshot<Map<String, dynamic>>?
    lastGlobalSnap;

    void updateList() {
      final Map<String, NotificationModel>
      map =
      <String, NotificationModel>{};

      final Set<String> seenSignatures =
      <String>{};

      if (lastUserSnap != null) {
        for (final QueryDocumentSnapshot<
            Map<String, dynamic>> doc
        in lastUserSnap!.docs) {
          final Map<String, dynamic> data =
          doc.data();

          final String title =
          (data['title'] ?? '')
              .toString()
              .trim();

          final String body =
          (data['body'] ??
              data['message'] ??
              '')
              .toString()
              .trim();

          final String signature =
              '$title|$body';

          map[doc.id] =
              NotificationModel(
                id: doc.id,
                title: title,
                body: body,
                dateTime:
                (data['createdAt']
                as Timestamp?)
                    ?.toDate() ??
                    DateTime.now(),
                isRead:
                data['isRead'] == true,
                type:
                data['type']?.toString(),
                data: data,
                isGlobal: false,
              );

          seenSignatures.add(signature);
        }
      }

      if (lastGlobalSnap != null) {
        for (final QueryDocumentSnapshot<
            Map<String, dynamic>> doc
        in lastGlobalSnap!.docs) {
          final Map<String, dynamic> data =
          doc.data();

          final String title =
          (data['title'] ?? '')
              .toString()
              .trim();

          final String body =
          (data['body'] ??
              data['message'] ??
              '')
              .toString()
              .trim();

          final String signature =
              '$title|$body';

          if (map.containsKey(doc.id) ||
              seenSignatures
                  .contains(signature)) {
            continue;
          }

          final List<dynamic> readBy =
          data['readBy'] is List
              ? List<dynamic>.from(
            data['readBy'] as List,
          )
              : <dynamic>[];

          map[doc.id] =
              NotificationModel(
                id: doc.id,
                title: title,
                body: body,
                dateTime:
                (data['createdAt']
                as Timestamp?)
                    ?.toDate() ??
                    DateTime.now(),
                isRead: readBy.contains(userId),
                type:
                data['type']?.toString(),
                data: data,
                isGlobal: true,
              );

          seenSignatures.add(signature);
        }
      }

      final List<NotificationModel>
      combined =
      map.values.toList();

      combined.sort(
            (NotificationModel a,
            NotificationModel b) {
          return b.dateTime
              .compareTo(a.dateTime);
        },
      );

      if (!controller.isClosed) {
        controller.add(combined);
      }
    }

    controller =
        StreamController<List<NotificationModel>>(
          onListen: () {
            sub1 = userStream.listen(
                  (
                  QuerySnapshot<
                      Map<String, dynamic>> snap,
                  ) {
                lastUserSnap = snap;
                updateList();
              },
            );

            sub2 = globalStream.listen(
                  (
                  QuerySnapshot<
                      Map<String, dynamic>> snap,
                  ) {
                lastGlobalSnap = snap;
                updateList();
              },
            );
          },
          onCancel: () async {
            await sub1?.cancel();
            await sub2?.cancel();

            if (!controller.isClosed) {
              await controller.close();
            }
          },
        );

    return controller.stream;
  }

  /// =============================================================
  /// UNREAD COUNT
  /// =============================================================

  static Stream<int> getUnreadCount(
      String userId,
      ) {
    return getUserNotifications(userId).map(
          (List<NotificationModel> list) {
        return list
            .where(
              (NotificationModel n) =>
          !n.isRead,
        )
            .length;
      },
    );
  }

  /// =============================================================
  /// MARK AS READ
  /// =============================================================

  static Future<void> markAsRead(
      String userId,
      String notificationId, {
        bool isGlobal = false,
      }) async {
    if (isGlobal) {
      await FirebaseFirestore.instance
          .collection('all_notifications')
          .doc(notificationId)
          .update(
        {
          'readBy':
          FieldValue.arrayUnion(
            [userId],
          ),
        },
      );
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update(
        {
          'isRead': true,
        },
      );
    }
  }

  /// =============================================================
  /// MARK ALL AS READ
  /// =============================================================

  static Future<void> markAllAsRead(
      String userId,
      ) async {
    final QuerySnapshot<
        Map<String, dynamic>> globalDocs =
    await FirebaseFirestore.instance
        .collection('all_notifications')
        .orderBy(
      'createdAt',
      descending: true,
    )
        .limit(15)
        .get();

    final WriteBatch batch =
    FirebaseFirestore.instance.batch();

    for (final QueryDocumentSnapshot<
        Map<String, dynamic>> doc
    in globalDocs.docs) {
      batch.update(
        doc.reference,
        {
          'readBy':
          FieldValue.arrayUnion(
            [userId],
          ),
        },
      );
    }

    final QuerySnapshot<
        Map<String, dynamic>> privateDocs =
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where(
      'isRead',
      isEqualTo: false,
    )
        .get();

    for (final QueryDocumentSnapshot<
        Map<String, dynamic>> doc
    in privateDocs.docs) {
      batch.update(
        doc.reference,
        {
          'isRead': true,
        },
      );
    }

    await batch.commit();
  }

  /// =============================================================
  /// DELETE NOTIFICATION
  /// =============================================================

  static Future<void> deleteNotification(
      String userId,
      String notificationId,
      ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// =============================================================
  /// SEND BROADCAST PUSH
  ///
  /// ملاحظة أمنية:
  /// إرسال FCM HTTP V1 باستخدام Service Account يجب أن يكون
  /// من Backend / Cloud Function وليس من تطبيق Flutter.
  /// =============================================================

  static Future<FcmPushResponse>
  sendBroadcastPush({
    required String title,
    required String body,
    String targetSegment = 'all',
  }) async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> doc =
      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('maintenance_and_updates')
          .get();

      final Map<String, dynamic>? data =
      doc.data();

      String serviceAccountRaw =
          data?['service_account_json']
              ?.toString()
              .trim() ??
              '';

      final String fcmServerKey =
          data?['fcm_server_key']
              ?.toString()
              .trim() ??
              '';

      final List<String> topics;

      if (targetSegment == 'all') {
        topics = <String>[
          'all',
          'global',
          'students',
        ];
      } else if (targetSegment ==
          'premium') {
        topics = <String>['premium'];
      } else if (targetSegment == 'free') {
        topics = <String>['free'];
      } else {
        topics = <String>['all'];
      }

      int lastStatusCode = 0;
      String lastResponseBody = '';
      bool anySuccess = false;

      /// =========================================================
      /// FCM HTTP V1
      /// =========================================================

      if (serviceAccountRaw.isEmpty ||
          !serviceAccountRaw.startsWith('{')) {
        serviceAccountRaw =
            defaultServiceAccountJson;
      }

      if (serviceAccountRaw.isNotEmpty &&
          serviceAccountRaw.startsWith('{')) {
        try {
          final ServiceAccountCredentials
          accountCredentials =
          ServiceAccountCredentials.fromJson(
            serviceAccountRaw,
          );

          final List<String> scopes =
          <String>[
            'https://www.googleapis.com/auth/firebase.messaging',
          ];

          final AutoRefreshingAuthClient
          authClient =
          await clientViaServiceAccount(
            accountCredentials,
            scopes,
          );

          final String projectId = accountCredentials.projectId ?? '';

          for (final String topic in topics) {
            final Map<String, dynamic>
            v1Payload = {
              'message': {
                'topic': topic,
                'notification': {
                  'title': title,
                  'body': body,
                },
                'data': {
                  'title': title,
                  'body': body,
                  'click_action':
                  'FLUTTER_NOTIFICATION_CLICK',
                  'screen': 'notifications',
                  'isGlobal': 'true',
                },
                'android': {
                  'priority': 'HIGH',
                  'direct_boot_ok': true,
                  'notification': {
                    'channel_id':
                    'high_importance_channel',
                    'sound': 'default',
                    'notification_priority':
                    'PRIORITY_HIGH',
                    'visibility': 'PUBLIC',
                  },
                },
                'apns': {
                  'payload': {
                    'aps': {
                      'sound': 'default',
                      'badge': 1,
                      'content-available': 1,
                    },
                  },
                },
              },
            };

            final Uri endpoint = Uri.parse(
              'https://fcm.googleapis.com/v1/'
                  'projects/$projectId/messages:send',
            );

            final http.Response response =
            await authClient.post(
              endpoint,
              headers: {
                'Content-Type':
                'application/json',
              },
              body: jsonEncode(
                v1Payload,
              ),
            );

            lastStatusCode =
                response.statusCode;
            lastResponseBody =
                response.body;

            debugPrint(
              '📬 FCM V1 Topic ($topic): '
                  '${response.statusCode} -> '
                  '${response.body}',
            );

            if (response.statusCode == 200) {
              anySuccess = true;
            }
          }

          authClient.close();

          if (anySuccess) {
            return FcmPushResponse(
              success: true,
              statusCode: 200,
              message:
              'تم إرسال الإشعار بنجاح عبر FCM HTTP V1.',
              rawResponse:
              lastResponseBody,
            );
          }

          return FcmPushResponse(
            success: false,
            statusCode: lastStatusCode,
            message:
            'تعذر إرسال الإشعار عبر FCM V1 '
                '(كود: $lastStatusCode): '
                '$lastResponseBody',
            rawResponse:
            lastResponseBody,
          );
        } catch (e) {
          debugPrint(
            '⚠️ FCM V1 execution error: $e',
          );
        }
      }

      /// =========================================================
      /// Legacy FCM fallback
      ///
      /// لا يوجد مفتاح افتراضي داخل التطبيق.
      /// إذا لم يوجد fcm_server_key في Firestore
      /// لن يتم إرسال Legacy FCM.
      /// =========================================================

      if (fcmServerKey.isEmpty) {
        return FcmPushResponse(
          success: false,
          statusCode: 0,
          message:
          'لم يتم إعداد FCM HTTP V1 أو مفتاح FCM للخادم. '
              'يجب تنفيذ الإرسال من Backend/Cloud Functions.',
          rawResponse: lastResponseBody,
        );
      }

      for (final String topic in topics) {
        final Map<String, dynamic> payload = {
          'to': '/topics/$topic',
          'priority': 'high',
          'content_available': true,
          'direct_boot_ok': true,
          'time_to_live': 2419200,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'android_channel_id':
            'high_importance_channel',
            'click_action':
            'FLUTTER_NOTIFICATION_CLICK',
          },
          'data': {
            'title': title,
            'body': body,
            'click_action':
            'FLUTTER_NOTIFICATION_CLICK',
            'screen': 'notifications',
            'isGlobal': 'true',
          },
        };

        try {
          final http.Response response =
          await http.post(
            Uri.parse(
              'https://fcm.googleapis.com/fcm/send',
            ),
            headers: {
              'Content-Type':
              'application/json',
              'Authorization':
              'key=$fcmServerKey',
            },
            body: jsonEncode(payload),
          );

          lastStatusCode =
              response.statusCode;
          lastResponseBody =
              response.body;

          debugPrint(
            '📬 FCM Topic ($topic): '
                '${response.statusCode} -> '
                '${response.body}',
          );

          if (response.statusCode == 200) {
            anySuccess = true;
          }
        } catch (e) {
          debugPrint(
            '⚠️ Error sending to topic $topic: $e',
          );

          lastResponseBody =
              e.toString();
        }
      }

      if (anySuccess) {
        return FcmPushResponse(
          success: true,
          statusCode: 200,
          message:
          'تم إرسال الإشعار السحابي بنجاح.',
          rawResponse:
          lastResponseBody,
        );
      }

      if (lastStatusCode == 401) {
        return FcmPushResponse(
          success: false,
          statusCode: 401,
          message:
          'مفتاح FCM غير صالح أو غير مفعّل.',
          rawResponse:
          lastResponseBody,
        );
      }

      return FcmPushResponse(
        success: false,
        statusCode: lastStatusCode,
        message:
        'تعذر إرسال الإشعار السحابي '
            '(كود: $lastStatusCode): '
            '$lastResponseBody',
        rawResponse:
        lastResponseBody,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Error sending FCM broadcast push: $e',
      );
      debugPrint('$stackTrace');

      return FcmPushResponse(
        success: false,
        statusCode: 500,
        message:
        'خطأ غير متوقع: $e',
      );
    }
  }
}

/// ===============================================================
/// FCM PUSH RESPONSE
/// ===============================================================

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

/// ===============================================================
/// NOTIFICATION MODEL
/// ===============================================================

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
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

/// ============================================================
/// Firebase Background Message Handler
/// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
try {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
} catch (_) {}

debugPrint(
'📬 Background message received: ${message.messageId}',
);

final FlutterLocalNotificationsPlugin localNotifications =
FlutterLocalNotificationsPlugin();

const androidSettings =
AndroidInitializationSettings('@mipmap/ic_launcher');

const iosSettings = DarwinInitializationSettings(
requestAlertPermission: false,
requestBadgePermission: false,
requestSoundPermission: false,
);

const settings = InitializationSettings(
android: androidSettings,
iOS: iosSettings,
);

try {
await localNotifications.initialize(
initializationSettings: settings,
);
} catch (e) {
debugPrint(
'⚠️ Background notification initialization error: $e',
);
}

final title =
message.notification?.title ??
message.data['title']?.toString() ??
'إشعار جديد من المنصة 📢';

final body =
message.notification?.body ??
message.data['body']?.toString() ??
message.data['message']?.toString() ??
'';

if (title.isEmpty && body.isEmpty) {
return;
}

const androidDetails = AndroidNotificationDetails(
'high_importance_channel',
'High Importance Notifications',
channelDescription:
'قناة الإشعارات الفورية العامة والخاصة',
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

try {
await localNotifications.show(
id: message.messageId?.hashCode ??
DateTime.now().millisecondsSinceEpoch ~/ 1000,
title: title,
body: body,
notificationDetails: const NotificationDetails(
android: androidDetails,
iOS: iosDetails,
),
payload: message.data.toString(),
);
} catch (e) {
debugPrint(
'⚠️ Background local notification error: $e',
);
}
}

/// ============================================================
/// Notification Service
/// ============================================================

class NotificationService {
static final FirebaseMessaging _fcm =
FirebaseMessaging.instance;

static bool _isListenersSetup = false;

static final Set<String> _shownNotificationSignatures = {};

static final FlutterLocalNotificationsPlugin
_localNotifications =
FlutterLocalNotificationsPlugin();

/// ==========================================================
/// IMPORTANT SECURITY NOTE
///
/// NEVER put a Firebase Service Account private key inside
/// a Flutter application.
///
/// Sending FCM HTTP v1 messages should be done from a secure
/// backend / Cloud Function / Cloud Run.
///
/// This value is intentionally empty.
/// ==========================================================

static const String defaultServiceAccountJson = '';

/// ==========================================================
/// INIT
/// ==========================================================

static Future<void> initialize() async {
const androidSettings =
AndroidInitializationSettings('@mipmap/ic_launcher');

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
initializationSettings: settings,
onDidReceiveNotificationResponse: (details) {
debugPrint(
'👆 Local notification clicked: ${details.payload}',
);
},
);

if (!kIsWeb) {
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

FirebaseMessaging.onBackgroundMessage(
firebaseBackgroundHandler,
);
}
}

/// ==========================================================
/// ENABLE NOTIFICATIONS
/// ==========================================================

static Future<void> enableNotifications() async {
try {
if (!kIsWeb && Platform.isAndroid) {
try {
final status =
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

final String? token = await _fcm.getToken();

debugPrint(
'📱 FCM Token: $token',
);

await _saveTokenToFirestore(token);

_fcm.onTokenRefresh.listen(
(newToken) async {
await _saveTokenToFirestore(newToken);

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
} catch (e) {
debugPrint(
'❌ Error in enableNotifications: $e',
);
}
}

/// ==========================================================
/// SAVE TOKEN
/// ==========================================================

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
    : (Platform.isAndroid
? 'android'
    : 'ios'),
},
SetOptions(merge: true),
);

final userId =
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
'platform':
kIsWeb ? 'web' : 'mobile',
},
SetOptions(merge: true),
);
}
} catch (e) {
debugPrint(
'Error saving token: $e',
);
}
}

/// ==========================================================
/// LISTENERS
/// ==========================================================

static void setupListeners() {
if (_isListenersSetup) {
return;
}

_isListenersSetup = true;

FirebaseMessaging.onMessage.listen(
(message) {
debugPrint(
'📬 Foreground FCM: '
'${message.notification?.title}',
);

final title =
message.notification?.title ??
message.data['title']?.toString() ??
'إشعار جديد 🔔';

final body =
message.notification?.body ??
message.data['body']?.toString() ??
message.data['message']?.toString() ??
'';

final signature = '$title|$body';

if (!_shownNotificationSignatures
    .contains(signature)) {
_shownNotificationSignatures.add(
signature,
);

showLocalNotification(message);
}
},
);

FirebaseMessaging.onMessageOpenedApp.listen(
(message) {
debugPrint(
'👆 Notification clicked (Background)',
);

_handleNavigation(message);
},
);

FirebaseMessaging.instance
    .getInitialMessage()
    .then(
(message) {
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
(snapshot) {
for (final change in snapshot.docChanges) {
if (change.type ==
DocumentChangeType.added) {
final data = change.doc.data();

if (data == null) {
continue;
}

final title =
data['title']?.toString() ??
'إشعار جديد من الإدارة 📢';

final body =
(data['body'] ??
data['message'] ??
'')
    .toString();

final signature =
'$title|$body';

if (!_shownNotificationSignatures
    .contains(signature)) {
_shownNotificationSignatures.add(
signature,
);

showLocalNotificationDirect(
title: title,
body: body,
);
}
}
}
},
onError: (e) {
debugPrint(
'⚠️ Error in firestore notif stream: $e',
);
},
);
}

/// ==========================================================
/// LOCAL NOTIFICATION
/// ==========================================================

static Future<void> showLocalNotification(
RemoteMessage message,
) async {
await showLocalNotificationDirect(
title:
message.notification?.title ??
message.data['title']?.toString() ??
'إشعار جديد 🔔',
body:
message.notification?.body ??
message.data['body']?.toString() ??
message.data['message']?.toString() ??
'',
payload: message.data.toString(),
);
}

static Future<void> showLocalNotificationDirect({
required String title,
required String body,
String? payload,
}) async {
const androidDetails =
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

const iosDetails =
DarwinNotificationDetails(
presentAlert: true,
presentBadge: true,
presentSound: true,
);

const details = NotificationDetails(
android: androidDetails,
iOS: iosDetails,
);

await _localNotifications.show(
id:
DateTime.now().millisecondsSinceEpoch ~/
1000,
title: title,
body: body,
notificationDetails: details,
payload: payload,
);
}

/// ==========================================================
/// NAVIGATION
/// ==========================================================

static void _handleNavigation(
RemoteMessage message,
) {
final screen = message.data['screen'];

debugPrint(
'🔗 Navigate to: $screen',
);
}

/// ==========================================================
/// FIRESTORE NOTIFICATIONS
/// ==========================================================

static Stream<List<NotificationModel>>
getUserNotifications(
String userId,
) {
final userStream = FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .orderBy(
'createdAt',
descending: true,
)
    .limit(35)
    .snapshots();

final globalStream =
FirebaseFirestore.instance
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

QuerySnapshot? lastUserSnap;
QuerySnapshot? lastGlobalSnap;

void updateList() {
final Map<String, NotificationModel> map =
{};

final Set<String> seenSignatures =
{};

if (lastUserSnap != null) {
for (final doc
in lastUserSnap!.docs) {
final data =
doc.data()
as Map<String, dynamic>;

final title =
(data['title'] ?? '')
    .toString()
    .trim();

final body =
(data['body'] ??
data['message'] ??
'')
    .toString()
    .trim();

final sig = '$title|$body';

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
data['isRead'] ?? false,
type: data['type'],
isGlobal: false,
);

seenSignatures.add(sig);
}
}

if (lastGlobalSnap != null) {
for (final doc
in lastGlobalSnap!.docs) {
final data =
doc.data()
as Map<String, dynamic>;

final title =
(data['title'] ?? '')
    .toString()
    .trim();

final body =
(data['body'] ??
data['message'] ??
'')
    .toString()
    .trim();

final sig = '$title|$body';

if (map.containsKey(doc.id) ||
seenSignatures.contains(sig)) {
continue;
}

final List readBy =
data['readBy'] ?? [];

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
readBy.contains(userId),
type: data['type'],
isGlobal: true,
);

seenSignatures.add(sig);
}
}

final List<NotificationModel>
combined = map.values.toList();

combined.sort(
(a, b) =>
b.dateTime.compareTo(a.dateTime),
);

if (!controller.isClosed) {
controller.add(combined);
}
}

controller =
StreamController<List<NotificationModel>>(
onListen: () {
sub1 = userStream.listen(
(snap) {
lastUserSnap = snap;
updateList();
},
);

sub2 = globalStream.listen(
(snap) {
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

static Stream<int> getUnreadCount(
String userId,
) {
return getUserNotifications(userId).map(
(list) => list
    .where((n) => !n.isRead)
    .length,
);
}

/// ==========================================================
/// MARK AS READ
/// ==========================================================

static Future<void> markAsRead(
String userId,
String notificationId, {
bool isGlobal = false,
}) async {
if (isGlobal) {
await FirebaseFirestore.instance
    .collection('all_notifications')
    .doc(notificationId)
    .update({
'readBy':
FieldValue.arrayUnion([userId]),
});
} else {
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .doc(notificationId)
    .update({
'isRead': true,
});
}
}

/// ==========================================================
/// MARK ALL AS READ
/// ==========================================================

static Future<void> markAllAsRead(
String userId,
) async {
final globalDocs =
await FirebaseFirestore.instance
    .collection('all_notifications')
    .orderBy(
'createdAt',
descending: true,
)
    .limit(15)
    .get();

final batch =
FirebaseFirestore.instance.batch();

for (final doc in globalDocs.docs) {
batch.update(
doc.reference,
{
'readBy':
FieldValue.arrayUnion([userId]),
},
);
}

final privateDocs =
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .where(
'isRead',
isEqualTo: false,
)
    .get();

for (final doc in privateDocs.docs) {
batch.update(
doc.reference,
{
'isRead': true,
},
);
}

await batch.commit();
}

/// ==========================================================
/// DELETE NOTIFICATION
/// ==========================================================

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

/// ==========================================================
/// SEND BROADCAST VIA FCM HTTP V1
///
/// NOTE:
/// This function requires a service account.
/// Do NOT hard-code the private key inside the app.
///
/// For production, move this operation to Firebase
/// Cloud Functions / Cloud Run.
/// ==========================================================

static Future<FcmPushResponse>
sendBroadcastPush({
required String title,
required String body,
String targetSegment = 'all',
}) async {
try {
final settingsDoc =
await FirebaseFirestore.instance
    .collection('system_settings')
    .doc('maintenance_and_updates')
    .get();

final data = settingsDoc.data();

String serviceAccountRaw =
data?['service_account_json']
    ?.toString()
    .trim() ??
'';

if (serviceAccountRaw.isEmpty ||
!serviceAccountRaw.startsWith('{')) {
serviceAccountRaw =
defaultServiceAccountJson;
}

if (serviceAccountRaw.isEmpty ||
!serviceAccountRaw.startsWith('{')) {
return FcmPushResponse(
success: false,
statusCode: 500,
message:
'لم يتم إعداد حساب خدمة FCM. '
'يجب تنفيذ إرسال FCM من Backend آمن.',
);
}

List<String> topics;

if (targetSegment == 'all') {
topics = [
'all',
'global',
'students',
];
} else if (targetSegment == 'premium') {
topics = ['premium'];
} else if (targetSegment == 'free') {
topics = ['free'];
} else {
topics = ['all'];
}

final accountCredentials =
ServiceAccountCredentials.fromJson(
serviceAccountRaw,
);

final scopes = <String>[
'https://www.googleapis.com/auth/firebase.messaging',
];

final authClient =
await clientViaServiceAccount(
accountCredentials,
scopes,
);

final projectId =
accountCredentials.projectId;

int lastStatusCode = 0;
String lastResponseBody = '';
bool anySuccess = false;

for (final topic in topics) {
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

final response = await authClient.post(
Uri.parse(
'https://fcm.googleapis.com/v1/'
'projects/$projectId/messages:send',
),
headers: {
'Content-Type':
'application/json',
},
body: json.encode(v1Payload),
);

lastStatusCode = response.statusCode;
lastResponseBody = response.body;

debugPrint(
'📬 FCM V1 Topic ($topic) Response: '
'${response.statusCode} -> ${response.body}',
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
rawResponse: lastResponseBody,
);
}

return FcmPushResponse(
success: false,
statusCode: lastStatusCode,
message:
'تعذر إرسال الإشعار عبر FCM V1 '
'(كود: $lastStatusCode): '
'$lastResponseBody',
rawResponse: lastResponseBody,
);
} catch (e) {
debugPrint(
'❌ Error sending FCM broadcast push: $e',
);

return FcmPushResponse(
success: false,
statusCode: 500,
message: 'خطأ غير متوقع: $e',
);
}
}
}

/// ============================================================
/// FCM PUSH RESPONSE
/// ============================================================

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

/// ============================================================
/// NOTIFICATION MODEL
/// ============================================================

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


import 'package:cloud_firestore/cloud_firestore.dart';

class AppAnnouncement {
  final bool isEnabled;
  final String text;
  final String? link;
  final String type; // 'info', 'warning', 'success'

  AppAnnouncement({
    required this.isEnabled,
    required this.text,
    this.link,
    this.type = 'info',
  });

  factory AppAnnouncement.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return AppAnnouncement(isEnabled: false, text: '');
    }
    return AppAnnouncement(
      isEnabled: data['isEnabled'] ?? false,
      text: data['text'] ?? '',
      link: data['link'],
      type: data['type'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'text': text,
      'link': link,
      'type': type,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class AnnouncementService {
  static final _firestore = FirebaseFirestore.instance;
  static final _docRef = _firestore.collection('system_settings').doc('announcement');

  /// Stream to listen to live announcement changes
  static Stream<AppAnnouncement> getAnnouncementStream() {
    return _docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return AppAnnouncement(isEnabled: false, text: '');
      return AppAnnouncement.fromMap(snapshot.data());
    });
  }

  /// Update announcement
  static Future<void> updateAnnouncement(AppAnnouncement announcement) async {
    await _docRef.set(announcement.toMap(), SetOptions(merge: true));
  }
}

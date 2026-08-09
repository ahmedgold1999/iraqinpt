class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime dateTime;
  final bool isRead;
  final String? type;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.dateTime,
    this.isRead = false,
    this.type,
    this.data,
  });
}
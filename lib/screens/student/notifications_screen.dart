import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/luxury_loading.dart';
import '../../services/notification_service.dart';
import '../../services/daily_reminder_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ألوان نمط أبل iOS الأبيض الهادئ
  static const _bgLight = Color(0xFFF8F9FA);
  static const _navyDark = Color(0xFF0F172A);
  static const _textDark = Color(0xFF1C1C1E);
  static const _textMuted = Color(0xFF8E8E93);
  static const _borderLight = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        backgroundColor: _bgLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 48, color: _navyDark),
              ),
              const SizedBox(height: 20),
              const Text(
                'الرجاء تسجيل الدخول أولاً لمشاهدة إشعاراتك',
                style: TextStyle(
                  fontSize: 16,
                  color: _textDark,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: _buildLuxuryAppBar(),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService.getUserNotifications(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationCard(
                id: notif.id,
                title: notif.title,
                body: notif.body,
                type: notif.type,
                isRead: notif.isRead,
                isGlobal: notif.isGlobal,
                createdAt: notif.dateTime,
              );
            },
          );
        },
      ),
    );
  }

  AppBar _buildLuxuryAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _navyDark,
      foregroundColor: Colors.white,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'مركز الإشعارات والتنبيهات',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Tajawal',
        ),
      ),
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('users')
              .doc(_userId)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data?.docs.length ?? 0;
            if (unreadCount == 0) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () async {
                  await _markAllAsRead();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('تم تحديد جميع الإشعارات كمقروءة', style: TextStyle(fontFamily: 'Tajawal')),
                        backgroundColor: const Color(0xFF00C853),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.done_all_rounded, color: Color(0xFFFACC15), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'قراءة الكل ($unreadCount)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.alarm_on_rounded, color: Color(0xFFFACC15), size: 22),
          tooltip: 'إعدادات المنبه والتحدي اليومي',
          onPressed: _showDailyReminderSettingsDialog,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _showDailyReminderSettingsDialog() async {
    bool isEnabled = await DailyReminderService.isEnabled();
    TimeOfDay scheduledTime = await DailyReminderService.getScheduledTime();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedTime = '${scheduledTime.hourOfPeriod}:${scheduledTime.minute.toString().padLeft(2, '0')} ${scheduledTime.period == DayPeriod.pm ? 'مساءً' : 'صباحاً'}';
            return Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.alarm_rounded, color: Color(0xFFFACC15), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'منبه وسؤال التحدي اليومي ⏰',
                              style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              'تنبيه يومي بأسئلة وزارية نموذجية وتحفيز دراسي',
                              style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفعيل الإشعار اليومي',
                              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            ),
                            Text(
                              'يصلك إشعار بسؤال مسائي جديد',
                              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                        Switch(
                          value: isEnabled,
                          activeColor: const Color(0xFF00C853),
                          onChanged: (val) async {
                            await DailyReminderService.setEnabled(val);
                            setModalState(() => isEnabled = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isEnabled) ...[
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: scheduledTime,
                        );
                        if (picked != null) {
                          await DailyReminderService.setScheduledTime(picked.hour, picked.minute);
                          setModalState(() => scheduledTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.schedule_rounded, color: Color(0xFF38BDF8), size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'وقت التنبيه اليومي:',
                                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                formattedTime,
                                style: const TextStyle(fontFamily: 'Tajawal', color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  // Send Test Notification Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await DailyReminderService.triggerDailyNotificationNow();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔔 تم إرسال إشعار التحدي بنجاح إلى شريط الإشعارات!'),
                              backgroundColor: Color(0xFF00C853),
                            ),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.send_rounded, color: Color(0xFFFACC15), size: 18),
                      label: const Text(
                        'إرسال إشعار تجريبي الآن 🚀',
                        style: TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFACC15)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markAllAsRead() async {
    if (_userId != null) {
      await NotificationService.markAllAsRead(_userId!);
    }
  }

  Future<void> _deleteNotification(String id) async {
    if (_userId != null) {
      await NotificationService.deleteNotification(_userId!, id);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildLoadingState() {
    return const LuxuryLoading(message: 'جاري جلب إشعاراتك...');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد إشعارات حالياً',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ستظهر الإشعارات والتنبيهات الجديدة هنا فور وصولها',
            style: TextStyle(
              fontSize: 13,
              color: _textMuted,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String id,
    required String title,
    required String body,
    String? type,
    String? imageUrl,
    String? buttonText,
    String? buttonUrl,
    Map<String, dynamic>? customData,
    required bool isRead,
    required bool isGlobal,
    required DateTime createdAt,
  }) {
    final isUnread = !isRead;

    return Dismissible(
      key: Key(id),
      direction: isGlobal ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      onDismissed: (_) async {
        if (!isGlobal) await _deleteNotification(id);
      },
      child: GestureDetector(
        onTap: () async {
          if (isUnread) {
            await NotificationService.markAsRead(_userId!, id, isGlobal: isGlobal);
            setState(() {});
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFFFFBEB) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnread ? const Color(0xFFF59E0B) : _borderLight,
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(type).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getNotificationIcon(type),
                        color: _getNotificationColor(type),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                    color: _textDark,
                                    fontFamily: 'Tajawal',
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            body,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF475569),
                              fontFamily: 'Tajawal',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: _textMuted),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _textMuted,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const Spacer(),
                    if (type != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTypeLabel(type),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getNotificationColor(type),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                  ],
                ),
                if (buttonText != null && buttonText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        if (buttonUrl != null && buttonUrl.isNotEmpty) {
                          _launchUrl(buttonUrl);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navyDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'exam':
        return 'امتحان';
      case 'update':
        return 'تحديث';
      case 'achievement':
        return 'إنجاز';
      case 'tip':
        return 'نصيحة';
      default:
        return 'عام';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'exam':
        return Icons.quiz_rounded;
      case 'update':
        return Icons.update_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'tip':
        return Icons.lightbulb_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'exam':
        return const Color(0xFFEF4444);
      case 'update':
        return const Color(0xFF2563EB);
      case 'achievement':
        return const Color(0xFFF59E0B);
      case 'tip':
        return const Color(0xFF00C853);
      default:
        return const Color(0xFF8B5CF6);
    }
  }
}
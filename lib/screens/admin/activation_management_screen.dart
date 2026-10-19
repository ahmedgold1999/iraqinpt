import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/subscription_service.dart';
import 'package:intl/intl.dart';

class ActivationManagementScreen extends StatefulWidget {
  const ActivationManagementScreen({super.key});

  @override
  State<ActivationManagementScreen> createState() => _ActivationManagementScreenState();
}

class _ActivationManagementScreenState extends State<ActivationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SubscriptionService _subService = SubscriptionService();
  
  List<DocumentSnapshot> _users = [];
  bool _isLoading = false;

  String _normalizeSearchText(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  String _resolveUserEmail(Map<String, dynamic> data) {
    final email = (data['email'] ?? '').toString().trim();
    if (email.isNotEmpty && email != 'null' && email != 'بدون بريد') {
      return email;
    }
    final username = (data['username'] ?? '').toString().trim();
    if (username.isNotEmpty && username != 'null') {
      return '$username@ahmeed.inpt';
    }
    return 'بدون بريد';
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _users = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final snapshot = await _db.collection('users').get();
      final normalizedQuery = _normalizeSearchText(query);
      final rawQuery = query.toLowerCase();

      final matched = snapshot.docs.where((doc) {
        final data = doc.data();
        final rawName = (data['name'] ?? data['displayName'] ?? '').toString();
        final normalizedName = _normalizeSearchText(rawName);
        final email = _resolveUserEmail(data).toLowerCase();
        final username = (data['username'] ?? '').toString().toLowerCase();
        final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString().toLowerCase();
        final uid = doc.id.toLowerCase();
        final code = (data['activationCode'] ?? data['code'] ?? '').toString().toLowerCase();
        final password = (data['password'] ?? data['pass'] ?? data['plainPassword'] ?? '').toString().toLowerCase();

        return normalizedName.contains(normalizedQuery) ||
            rawName.toLowerCase().contains(rawQuery) ||
            username.contains(rawQuery) ||
            email.contains(rawQuery) ||
            phone.contains(rawQuery) ||
            uid.contains(rawQuery) ||
            code.contains(rawQuery) ||
            password.contains(rawQuery);
      }).toList();
      
      setState(() {
        _users = matched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في البحث: $e')));
    }
  }

  void _showActivationDialog(DocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>;
    final userId = userDoc.id;
    final bool isPremium = userData['isPremium'] ?? false;
    DateTime? expiryDate;
    final dynamic rawExp = userData['expiryDate'] ?? userData['premiumUntil'];
    if (rawExp is Timestamp) expiryDate = rawExp.toDate();
    else if (rawExp is String) expiryDate = DateTime.tryParse(rawExp);

    String currentStatus = 'حساب غير مفعّل';
    if (isPremium) {
      if (expiryDate != null) {
        if (expiryDate.isBefore(DateTime.now())) {
          currentStatus = 'منتهي الصلاحية (${DateFormat('yyyy/MM/dd').format(expiryDate)})';
        } else {
          final days = expiryDate.difference(DateTime.now()).inDays;
          if (days > 365) {
            currentStatus = 'تفعيل دائمي';
          } else {
            currentStatus = 'مُفعّل ينتهي في ${DateFormat('yyyy/MM/dd').format(expiryDate)}';
          }
        }
      } else {
        currentStatus = 'تفعيل ممتاز';
      }
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعديل تفعيل: ${userData['name'] ?? 'طالب'}',
                style: const TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Text(
                  'الحالة الحالية: $currentStatus',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildDurationBtn('تفعيل 30 يوماً (شهر)', 30, userId, const Color(0xFF2563EB)),
              const SizedBox(height: 10),
              _buildDurationBtn('تفعيل 60 يوماً (شهرين)', 60, userId, const Color(0xFF8B5CF6)),
              const SizedBox(height: 10),
              _buildDurationBtn('تفعيل دائمي (مدى الحياة)', -1, userId, const Color(0xFF00C853)),
              const Divider(color: Color(0xFFE5E5EA), height: 26),
              _buildDurationBtn('إلغاء التفعيل', 0, userId, const Color(0xFFEF4444), isDeactivate: true),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        title: const Text('حذف الحساب نهائياً', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
                        content: Text('هل أنت متأكد من حذف حساب الطالب "${userData['name']}" نهائياً من النظام؟', style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white60))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _db.collection('users').doc(userId).delete();
                      _searchUsers(_searchController.text);
                    }
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text('حذف الحساب نهائياً 🗑️', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationBtn(String label, int days, String userId, Color color, {bool isDeactivate = false}) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withOpacity(0.3), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () async {
          Navigator.pop(context);
          try {
            if (isDeactivate) {
              await _subService.deactivateSubscription(userId);
            } else {
              await _subService.manualActivate(userId, days);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم تحديث التفعيل بنجاح ✅', style: TextStyle(fontFamily: 'Tajawal')),
                  backgroundColor: const Color(0xFF00C853),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              _searchUsers(_searchController.text);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            }
          }
        },
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('إدارة تفعيل حسابات الطلاب', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal'),
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الطالب للتفعيل...',
                hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Tajawal', fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F172A)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A)),
                  onPressed: () => _searchUsers(_searchController.text),
                ),
              ),
              onSubmitted: _searchUsers,
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty ? 'اكتب اسم الطالب واضغط بحث' : 'لم يتم العثور على أية نتائج',
                          style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Tajawal', fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final data = user.data() as Map<String, dynamic>;
                          final bool isPremium = data['isPremium'] ?? false;
                          DateTime? expiryDate;
                          final dynamic rawExp = data['expiryDate'] ?? data['premiumUntil'];
                          if (rawExp is Timestamp) expiryDate = rawExp.toDate();
                          else if (rawExp is String) expiryDate = DateTime.tryParse(rawExp);

                          final bool isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
                          final bool isActuallyActive = isPremium && !isExpired;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isActuallyActive
                                    ? const Color(0xFF00C853)
                                    : (isExpired ? Colors.redAccent.withOpacity(0.5) : const Color(0xFFE5E5EA)),
                                width: isActuallyActive || isExpired ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isActuallyActive
                                      ? const Color(0xFF00C853)
                                      : (isExpired ? Colors.redAccent : const Color(0xFFF2F2F7)),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  data['name']?[0]?.toUpperCase() ?? '?',
                                  style: TextStyle(
                                    color: (isActuallyActive || isExpired) ? Colors.white : const Color(0xFF1C1C1E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              title: Text(
                                data['name'] ?? 'بدون اسم',
                                style: const TextStyle(
                                  color: Color(0xFF1C1C1E),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _resolveUserEmail(data),
                                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontFamily: 'Tajawal'),
                                  ),
                                  if (isActuallyActive && expiryDate != null)
                                    Text(
                                      'مُفعّل لغاية: ${DateFormat('yyyy/MM/dd').format(expiryDate)}',
                                      style: const TextStyle(color: Color(0xFF00C853), fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                                    )
                                  else if (isExpired && expiryDate != null)
                                    Text(
                                      'منتهي الصلاحية: ${DateFormat('yyyy/MM/dd').format(expiryDate)} ⚠️',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                                    ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPremium ? const Color(0xFFF0FDF4) : const Color(0xFF0F172A),
                                  foregroundColor: isPremium ? const Color(0xFF00C853) : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                ),
                                onPressed: () => _showActivationDialog(user),
                                child: Text(
                                  isPremium ? 'تعديل' : 'تفعيل الحساب',
                                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12.5),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      ),
          ),
        ],
      ),
    );
  }
}

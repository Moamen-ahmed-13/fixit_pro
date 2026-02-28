import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: AppColors.bgCard,
            child: Row(
              children: [
                const Text(
                  '🔔 الإشعارات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                const Spacer(),
                // Mark all read
                GestureDetector(
                  onTap: () => _markAllRead(uid),
                  child: const Text(
                    'قراءة الكل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _EmptyNotifications();

                // Group by date
                final grouped = _groupByDate(docs);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: grouped.length,
                  itemBuilder: (context, i) {
                    final entry = grouped[i];
                    if (entry['type'] == 'header') {
                      return _DateHeader(label: entry['label'] as String);
                    }
                    final data = entry['data'] as Map<String, dynamic>;
                    final docId = entry['id'] as String;
                    return _NotifCard(
                      docId: docId,
                      data: data,
                      onTap: () => _handleTap(context, data, docId, uid),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _groupByDate(List<QueryDocumentSnapshot> docs) {
    final result = <Map<String, dynamic>>[];
    String? lastDate;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) continue;

      final d = ts.toDate();
      final dateStr = _dateLabel(d);

      if (dateStr != lastDate) {
        result.add({'type': 'header', 'label': dateStr});
        lastDate = dateStr;
      }
      result.add({'type': 'item', 'data': data, 'id': doc.id});
    }
    return result;
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _markAllRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  void _handleTap(BuildContext context, Map<String, dynamic> data,
      String docId, String uid) {
    // Mark as read
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});

    // Navigate based on type
    final type = data['type'] as String?;
    final orderId = data['orderId'] as String?;
    if (orderId != null && type != 'chat') {
      Navigator.pushNamed(context, '/customer/tracking', arguments: orderId);
    }
  }
}

class _NotifCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotifCard(
      {required this.docId, required this.data, required this.onTap});

  String get _emoji {
    switch (data['type']) {
      case 'order_assigned':  return '👨‍🔧';
      case 'order_onTheWay':  return '🚗';
      case 'order_completed': return '✅';
      case 'order_cancelled': return '❌';
      case 'chat':            return '💬';
      case 'promo':           return '🎉';
      default:                return '🔔';
    }
  }

  Color get _color {
    switch (data['type']) {
      case 'order_assigned':  return AppColors.accent;
      case 'order_onTheWay':  return AppColors.primary;
      case 'order_completed': return AppColors.accent;
      case 'order_cancelled': return AppColors.danger;
      case 'chat':            return const Color(0xFF9B59B6);
      case 'promo':           return AppColors.warning;
      default:                return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = data['isRead'] as bool? ?? false;
    final ts = data['createdAt'] as Timestamp?;
    final time = ts != null
        ? '${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.bgCard : _color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppColors.border : _color.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(_emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),

            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] as String? ?? '',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data['body'] as String? ?? '',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Time + unread dot
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      );
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔔', style: TextStyle(fontSize: 52)),
            SizedBox(height: 16),
            Text(
              'مفيش إشعارات لحد دلوقتي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
}

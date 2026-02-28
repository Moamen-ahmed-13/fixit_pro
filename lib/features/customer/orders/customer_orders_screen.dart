import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // ── AppBar ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            color: AppColors.bgCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'طلباتي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'جارية'),
                    Tab(text: 'مكتملة'),
                    Tab(text: 'ملغية'),
                  ],
                ),
              ],
            ),
          ),

          // ── Tabs ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _OrdersList(
                  uid: uid,
                  statuses: const [
                    'pending', 'assigned', 'onTheWay', 'inProgress'
                  ],
                ),
                _OrdersList(
                  uid: uid,
                  statuses: const ['completed'],
                ),
                _OrdersList(
                  uid: uid,
                  statuses: const ['cancelled'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final String uid;
  final List<String> statuses;

  const _OrdersList({required this.uid, required this.statuses});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: uid)
          .where('status', whereIn: statuses)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _EmptyState(statuses: statuses);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final order = OrderModel.fromFirestore(docs[i]);
            return _OrderCard(order: order);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:    return AppColors.warning;
      case OrderStatus.assigned:   return AppColors.accent;
      case OrderStatus.onTheWay:   return AppColors.primary;
      case OrderStatus.inProgress: return AppColors.primary;
      case OrderStatus.completed:  return AppColors.accent;
      case OrderStatus.cancelled:  return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (order.status != OrderStatus.completed &&
            order.status != OrderStatus.cancelled) {
          Navigator.pushNamed(context, '/customer/tracking',
              arguments: order.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Row 1
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(order.deviceEmoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.deviceType} — ${order.brand}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        order.issue,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),

            // Row 2
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.address,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            if (order.finalPrice != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ المدفوع',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      )),
                  Text(
                    '${order.finalPrice!.toInt()} ج',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],

            if (order.rating != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < order.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final List<String> statuses;
  const _EmptyState({required this.statuses});

  @override
  Widget build(BuildContext context) {
    String emoji = '📋';
    String msg = 'مفيش طلبات';
    if (statuses.contains('completed')) {
      emoji = '✅';
      msg = 'مفيش طلبات مكتملة لحد دلوقتي';
    } else if (statuses.contains('cancelled')) {
      emoji = '🚫';
      msg = 'مفيش طلبات ملغية';
    } else {
      msg = 'مفيش طلبات جارية دلوقتي';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                color: AppColors.textMuted,
              )),
          const SizedBox(height: 12),
          if (statuses.contains('pending'))
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/customer/new-request'),
              child: const Text('اطلب دلوقتي',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
        ],
      ),
    );
  }
}

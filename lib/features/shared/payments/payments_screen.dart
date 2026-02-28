import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        foregroundColor: AppColors.textMain,
        title: const Text('المدفوعات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'طرق الدفع'),
            Tab(text: 'السجل'),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _PaymentMethodsTab(),
            _PaymentHistoryTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: طرق الدفع ─────────────────────────────────────────────────────────
class _PaymentMethodsTab extends StatelessWidget {
  final _methods = const [
    _PaymentMethod(
      icon: '💵',
      name: 'كاش',
      description: 'ادفع كاش للفني بعد الخدمة',
      color: AppColors.accent,
      isAvailable: true,
    ),
    _PaymentMethod(
      icon: '💳',
      name: 'بطاقة بنكية',
      description: 'Visa / Mastercard / Meeza',
      color: AppColors.primary,
      isAvailable: true,
    ),
    _PaymentMethod(
      icon: '📱',
      name: 'Fawry',
      description: 'ادفع عن طريق Fawry',
      color: Color(0xFFE67E22),
      isAvailable: true,
    ),
    _PaymentMethod(
      icon: '🔵',
      name: 'Vodafone Cash',
      description: 'محفظة فودافون كاش',
      color: Color(0xFFE53935),
      isAvailable: false,
    ),
    _PaymentMethod(
      icon: '🟣',
      name: 'Instapay',
      description: 'انستاباي',
      color: Color(0xFF9B59B6),
      isAvailable: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary Card ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF8C42)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'طريقة الدفع الافتراضية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('💵', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Text(
                      'كاش',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'تقدر تغير طريقة الدفع عند كل طلب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'طرق الدفع المتاحة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),

          const SizedBox(height: 12),

          ..._methods.map((m) => _MethodCard(method: m)),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Text('🔒', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'كل المدفوعات محمية بتشفير SSL — بياناتك في أمان',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  final String icon;
  final String name;
  final String description;
  final Color color;
  final bool isAvailable;

  const _PaymentMethod({
    required this.icon,
    required this.name,
    required this.description,
    required this.color,
    required this.isAvailable,
  });
}

class _MethodCard extends StatelessWidget {
  final _PaymentMethod method;
  const _MethodCard({required this.method});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: method.isAvailable
                ? AppColors.border
                : AppColors.border.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: method.color.withOpacity(
                    method.isAvailable ? 0.12 : 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(method.icon,
                    style: TextStyle(
                      fontSize: 22,
                      color: method.isAvailable ? null : Colors.grey,
                    )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: method.isAvailable
                          ? AppColors.textMain
                          : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    method.description,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!method.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'قريباً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✅ متاح',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
      );
}

// ─── Tab 2: سجل المدفوعات ─────────────────────────────────────────────────────
class _PaymentHistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💰', style: TextStyle(fontSize: 52)),
                SizedBox(height: 16),
                Text(
                  'مفيش مدفوعات لحد دلوقتي',
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

        double total = 0;
        for (final d in docs) {
          final price = (d.data() as Map)['finalPrice'] as num?;
          if (price != null) total += price;
        }

        return Column(
          children: [
            // Total
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إجمالي ما دفعته',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${total.toInt()} ج',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final price = (data['finalPrice'] as num?)?.toInt() ?? 0;
                  final method = data['paymentMethod'] as String? ?? 'cash';
                  final ts = data['completedAt'] as Timestamp?;
                  final date = ts != null
                      ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                      : '—';
                  final methodEmoji = {
                    'cash': '💵',
                    'card': '💳',
                    'fawry': '📱',
                  }[method] ?? '💰';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(methodEmoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data['deviceType'] ?? ''} — ${data['brand'] ?? ''}',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              Text(
                                date,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$price ج',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '✅ مدفوع',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 9,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

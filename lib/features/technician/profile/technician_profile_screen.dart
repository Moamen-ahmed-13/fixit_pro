import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('technicians')
        .doc(uid)
        .get();
    if (!mounted) return;
    setState(() {
      _data = doc.data();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final name = _data?['name'] ?? 'الفني';
    final rating = (_data?['rating'] as num?)?.toDouble() ?? 0.0;
    final level = _data?['level'] ?? 'Junior';
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final completedOrders = (_data?['completedOrders'] as int?) ?? 0;
    final todayEarnings = (_data?['todayEarnings'] as num?)?.toDouble() ?? 0;
    final isOnline = (_data?['isOnline'] as bool?) ?? false;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1a2a3a), AppColors.bgDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, Color(0xFF00B894)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('👨‍🔧', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.accent
                              : AppColors.textMuted,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.bgDark, width: 2.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      )),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          level,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded,
                          color: AppColors.warning, size: 16),
                      Text(
                        ' ${rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(phone,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AppColors.textMuted,
                      )),
                ],
              ),
            ),

            // ── Stats ─────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _StatBox(
                    value: '$completedOrders',
                    label: 'طلب مكتمل',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    value: rating.toStringAsFixed(1),
                    label: 'تقييم الفنيين',
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    value: '${todayEarnings.toInt()} ج',
                    label: 'أرباح اليوم',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── KPI Bars ──────────────────────────────────────────────
            _KpiSection(data: _data),

            const SizedBox(height: 12),

            // ── Menu ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'أرباحي',
                      color: AppColors.accent,
                      onTap: () => Navigator.pushNamed(
                          context, '/technician/earnings'),
                    ),
                    _MenuItem(
                      icon: Icons.assignment_rounded,
                      label: 'سجل الطلبات',
                      color: AppColors.primary,
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.swap_horiz_rounded,
                      label: 'تغيير الدور',
                      color: const Color(0xFF9B59B6),
                      onTap: () =>
                          Navigator.pushNamed(context, '/role-selector'),
                    ),
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'تسجيل الخروج',
                      color: AppColors.danger,
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  )),
              const SizedBox(height: 3),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    color: AppColors.textMuted,
                  )),
            ],
          ),
        ),
      );
}

class _KpiSection extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _KpiSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final onTimeRate = (data?['onTimeRate'] as num?)?.toDouble() ?? 0.92;
    final firstFixRate = (data?['firstFixRate'] as num?)?.toDouble() ?? 0.85;
    final cancelRate = (data?['cancelRate'] as num?)?.toDouble() ?? 0.05;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 مؤشرات أدائك',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 14),
            _KpiBar(
              label: 'الالتزام بالمواعيد',
              value: onTimeRate,
              color: AppColors.accent,
            ),
            _KpiBar(
              label: 'First Time Fix',
              value: firstFixRate,
              color: AppColors.primary,
            ),
            _KpiBar(
              label: 'نسبة الإلغاء',
              value: cancelRate,
              color: AppColors.danger,
              invert: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool invert;

  const _KpiBar({
    required this.label,
    required this.value,
    required this.color,
    this.invert = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    )),
                Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ],
        ),
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    )),
              ),
              const Icon(Icons.arrow_back_ios_rounded,
                  color: AppColors.textMuted, size: 14),
            ],
          ),
        ),
      );
}

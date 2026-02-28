import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;
    setState(() {
      _userData = doc.data();
      _nameCtrl.text = _userData?['name'] ?? '';
      _loading = false;
    });
  }

  Future<void> _saveName() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': _nameCtrl.text.trim(),
    });
    setState(() {
      _userData?['name'] = _nameCtrl.text.trim();
      _isSaving = false;
      _isEditing = false;
    });
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('تسجيل الخروج',
              style: TextStyle(
                  fontFamily: 'Cairo', color: AppColors.textMain)),
          content: const Text('هل أنت متأكد؟',
              style: TextStyle(
                  fontFamily: 'Cairo', color: AppColors.textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لأ',
                  style: TextStyle(
                      fontFamily: 'Cairo', color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نعم',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final name = _userData?['name'] ?? 'بدون اسم';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), AppColors.bgDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '؟',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (_isEditing)
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _nameCtrl,
                        textAlign: TextAlign.center,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.bgCard2,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),

                  const SizedBox(height: 6),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Edit / Save buttons
                  if (_isEditing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SmallBtn(
                          label: 'إلغاء',
                          color: AppColors.textMuted,
                          onTap: () =>
                              setState(() => _isEditing = false),
                        ),
                        const SizedBox(width: 10),
                        _SmallBtn(
                          label: _isSaving ? '...' : 'حفظ',
                          color: AppColors.accent,
                          onTap: _isSaving ? null : _saveName,
                        ),
                      ],
                    )
                  else
                    _SmallBtn(
                      label: '✏️ تعديل الاسم',
                      color: AppColors.primary,
                      onTap: () => setState(() => _isEditing = true),
                    ),
                ],
              ),
            ),

            // ── Stats ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: _StatsRow(uid: FirebaseAuth.instance.currentUser!.uid),
            ),

            const SizedBox(height: 8),

            // ── Menu ──────────────────────────────────────────────────
            _MenuSection(
              title: 'حسابي',
              items: [
                _MenuItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'كل طلباتي',
                  color: AppColors.primary,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.location_on_rounded,
                  label: 'عناويني',
                  color: AppColors.accent,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.payment_rounded,
                  label: 'طرق الدفع',
                  color: AppColors.warning,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 12),

            _MenuSection(
              title: 'الدعم',
              items: [
                _MenuItem(
                  icon: Icons.headset_mic_rounded,
                  label: 'تواصل معنا',
                  color: AppColors.accent,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.star_rounded,
                  label: 'قيّم التطبيق',
                  color: AppColors.warning,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.swap_horiz_rounded,
                  label: 'تغيير الدور',
                  color: const Color(0xFF9B59B6),
                  onTap: () =>
                      Navigator.pushNamed(context, '/role-selector'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Sign out ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _signOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.danger.withOpacity(0.4)),
                  ),
                  child: const Center(
                    child: Text(
                      '🚪 تسجيل الخروج',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
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

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final String uid;
  const _StatsRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: uid)
          .get(),
      builder: (context, snap) {
        final orders = snap.data?.docs ?? [];
        final completed =
            orders.where((d) => (d.data() as Map)['status'] == 'completed').length;
        final total = orders.length;
        final ratings = orders
            .map((d) => (d.data() as Map)['rating'] as num?)
            .where((r) => r != null)
            .toList();
        final avgRating = ratings.isEmpty
            ? 0.0
            : ratings.fold<double>(
                    0, (s, r) => s + r!.toDouble()) /
                ratings.length;

        return Row(
          children: [
            _StatCard(value: '$total', label: 'إجمالي الطلبات',
                color: AppColors.primary),
            const SizedBox(width: 10),
            _StatCard(value: '$completed', label: 'مكتملة',
                color: AppColors.accent),
            const SizedBox(width: 10),
            _StatCard(
              value: ratings.isEmpty
                  ? '—'
                  : avgRating.toStringAsFixed(1),
              label: 'متوسط تقييمي',
              color: AppColors.warning,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  )),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textMuted,
                  )),
            ],
          ),
        ),
      );
}

// ─── Menu Section ─────────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, right: 4),
              child: Text(title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  )),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: items),
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

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _SmallBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ),
      );
}

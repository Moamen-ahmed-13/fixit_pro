import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});
  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen>
    with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  void _pick(String role) {
    setState(() => _selected = role);
    context.read<AuthBloc>().add(AuthRoleSelected(role));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthAuthenticated) {
              switch (state.role) {
                case 'customer':   Navigator.pushReplacementNamed(ctx, '/customer/home');
                case 'technician': Navigator.pushReplacementNamed(ctx, '/technician/home');
                case 'admin':      Navigator.pushReplacementNamed(ctx, '/admin/dashboard');
              }
            }
          },
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(),
                      // Logo
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
                        ),
                        child: const Center(child: Text('🔧', style: TextStyle(fontSize: 34))),
                      ),
                      const SizedBox(height: 20),
                      const Text('FixIt Pro', style: TextStyle(fontFamily: 'Cairo', fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textMain)),
                      const SizedBox(height: 8),
                      const Text('هتستخدم التطبيق إزاي؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      const Text('اختار دورك — مرة واحدة فقط عند التسجيل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 40),
                      // Cards
                      _Card(emoji: '👤', title: 'عميل', subtitle: 'اطلب خدمة صيانة لبيتك', color: AppColors.primary, gradient: const [Color(0xFFFF6B2B), Color(0xFFFF8C42)], selected: _selected == 'customer', onTap: () => _pick('customer')),
                      const SizedBox(height: 14),
                      _Card(emoji: '🔧', title: 'فني صيانة', subtitle: 'استقبل طلبات واشتغل وكسب', color: AppColors.accent, gradient: const [Color(0xFF00D4AA), Color(0xFF00B894)], selected: _selected == 'technician', onTap: () => _pick('technician')),
                      const SizedBox(height: 14),
                      _Card(emoji: '🛡️', title: 'مشرف / إدارة', subtitle: 'تحكم كامل في العمليات', color: const Color(0xFF9B59B6), gradient: const [Color(0xFF9B59B6), Color(0xFF8E44AD)], selected: _selected == 'admin', onTap: () => _pick('admin')),
                      const Spacer(),
                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: const Row(
                          children: [
                            Text('ℹ️', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 10),
                            Expanded(child: Text('الاختيار ده بيحدد صلاحياتك. لو محتاج تغيّره تواصل مع الدعم.', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted, height: 1.5))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatefulWidget {
  final String emoji, title, subtitle;
  final Color color;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;
  const _Card({required this.emoji, required this.title, required this.subtitle, required this.color, required this.gradient, required this.selected, required this.onTap});
  @override State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.95, upperBound: 1.0)..value = 1.0; }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapUp: (_) { _c.forward(); widget.onTap(); },
      onTapCancel: () => _c.forward(),
      child: ScaleTransition(
        scale: _c,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.selected ? widget.color.withOpacity(0.08) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.selected ? widget.color : widget.color.withOpacity(0.2), width: widget.selected ? 2 : 1),
            boxShadow: widget.selected ? [BoxShadow(color: widget.color.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))] : [],
          ),
          child: Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(gradient: LinearGradient(colors: widget.gradient), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]),
                child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w900, color: widget.selected ? widget.color : AppColors.textMain)),
                  const SizedBox(height: 3),
                  Text(widget.subtitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
                ]),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26, height: 26,
                decoration: BoxDecoration(color: widget.selected ? widget.color : AppColors.bgCard2, shape: BoxShape.circle, border: Border.all(color: widget.selected ? widget.color : AppColors.border, width: 2)),
                child: widget.selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
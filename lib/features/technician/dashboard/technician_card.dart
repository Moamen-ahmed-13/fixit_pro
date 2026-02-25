import 'package:fixit_pro/features/technician/dashboard/tracking_bloc.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TechnicianCard extends StatelessWidget {
  final TechnicianLocation tech;
  final int? etaMinutes;

  const TechnicianCard({
    super.key,
    required this.tech,
    this.etaMinutes,
  });

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: tech.phone);
    if (await canLaunchUrl(uri)) launchUrlu(uri);
  }

  Future<void> _whatsapp() async {
    final num = tech.phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/2$num');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ─ الصورة ─────────────────────────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text('👨‍🔧', style: TextStyle(fontSize: 24)),
                ),
              ),

              const SizedBox(width: 12),

              // ─ البيانات ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tech.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          tech.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tech.level,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─ الـ ETA ────────────────────────────────────────────────
              if (etaMinutes != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('⏱️',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        '$etaMinutes د',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // ─ أزرار التواصل ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.call_rounded,
                  label: 'اتصال',
                  color: AppColors.accent,
                  onTap: _call,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactButton(
                  icon: Icons.chat_rounded,
                  label: 'واتساب',
                  color: const Color(0xFF25D366),
                  onTap: _whatsapp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
}

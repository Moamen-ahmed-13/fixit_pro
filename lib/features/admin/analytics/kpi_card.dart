import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class KpiCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final String? change;
  final bool changeUp;

  const KpiCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    this.change,
    this.changeUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const Spacer(),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  changeUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: changeUp ? AppColors.accent : AppColors.danger,
                ),
                const SizedBox(width: 3),
                Text(
                  change!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: changeUp ? AppColors.accent : AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

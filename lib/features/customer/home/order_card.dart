import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ActiveOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const ActiveOrderCard({super.key, required this.order, required this.onTap});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.onTheWay:   return AppColors.primary;
      case OrderStatus.inProgress: return AppColors.accent;
      case OrderStatus.assigned:   return AppColors.warning;
      default:                     return AppColors.textMuted;
    }
  }

  double get _progressValue {
    switch (order.status) {
      case OrderStatus.pending:    return 0.1;
      case OrderStatus.assigned:   return 0.3;
      case OrderStatus.onTheWay:   return 0.6;
      case OrderStatus.inProgress: return 0.8;
      default:                     return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ الصف العلوي ──────────────────────────────────────────────
            Row(
              children: [
                Text(
                  '#${order.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

            const SizedBox(height: 10),

            // ─ الجهاز ──────────────────────────────────────────────────
            Row(
              children: [
                Text(order.deviceEmoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '${order.deviceEmoji == '❄️' ? 'تكييف' : order.deviceType} ${order.brand}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              order.issue,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 12),

            // ─ شريط التقدم ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressValue,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                minHeight: 4,
              ),
            ),

            if (order.status == OrderStatus.onTheWay) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions_car_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  const Text(
                    'الفني في الطريق — اضغط لتتبعه',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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

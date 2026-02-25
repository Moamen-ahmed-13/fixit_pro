import 'dart:async';
import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:fixit_pro/features/technician/dashboard/technician_home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class IncomingRequestCard extends StatefulWidget {
  final OrderModel order;
  final bool isProcessing;

  const IncomingRequestCard({
    super.key,
    required this.order,
    required this.isProcessing,
  });

  @override
  State<IncomingRequestCard> createState() => _IncomingRequestCardState();
}

class _IncomingRequestCardState extends State<IncomingRequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  int _secondsLeft = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Pulse animation على البادج
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // عداد تنازلي 45 ثانية
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        // انتهى الوقت — ارفض تلقائياً
        if (mounted) {
          context.read<TechnicianHomeBloc>().add(
                OrderRejected(widget.order.id),
              );
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Color get _timerColor {
    if (_secondsLeft > 20) return AppColors.accent;
    if (_secondsLeft > 10) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Badge العنوان ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                FadeTransition(
                  opacity: _pulseCtrl,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '🔔 طلب جديد!',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // عداد تنازلي
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⏱️',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$_secondsLeft ث',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _timerColor == AppColors.accent
                              ? Colors.white
                              : _timerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── تفاصيل الطلب ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.order.deviceEmoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.order.deviceType} — ${widget.order.brand}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          Text(
                            widget.order.issue,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // التاقات
                Row(
                  children: [
                    _Tag(
                      label: widget.order.address.split('،').first,
                      emoji: '📍',
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    _Tag(
                      label: widget.order.slaType == 'emergency'
                          ? 'طارئ'
                          : 'عادي',
                      emoji: widget.order.slaType == 'emergency' ? '⚡' : '🕐',
                      color: widget.order.slaType == 'emergency'
                          ? AppColors.danger
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    _Tag(
                      label: widget.order.estimatedPriceMin != null
                          ? '${widget.order.estimatedPriceMin!.toInt()}–${widget.order.estimatedPriceMax!.toInt()} ج'
                          : '؟ ج',
                      emoji: '💰',
                      color: AppColors.warning,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // أزرار القبول والرفض
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: widget.isProcessing
                            ? null
                            : () => context
                                .read<TechnicianHomeBloc>()
                                .add(OrderAccepted(widget.order.id)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: widget.isProcessing
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                '✅ قبول الطلب',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.isProcessing
                            ? null
                            : () => context
                                .read<TechnicianHomeBloc>()
                                .add(OrderRejected(widget.order.id)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'رفض',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  const _Tag({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ],
        ),
      );
}

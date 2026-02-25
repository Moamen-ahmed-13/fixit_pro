import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StatusTimeline extends StatelessWidget {
  final OrderStatus currentStatus;
  const StatusTimeline({super.key, required this.currentStatus});

  static const _steps = [
    (status: OrderStatus.pending,    label: 'تم استلام الطلب',    icon: '📋'),
    (status: OrderStatus.assigned,   label: 'تم تعيين الفني',     icon: '👨‍🔧'),
    (status: OrderStatus.onTheWay,   label: 'الفني في الطريق',    icon: '🚗'),
    (status: OrderStatus.inProgress, label: 'جاري تنفيذ الخدمة', icon: '🔧'),
    (status: OrderStatus.completed,  label: 'تمت الخدمة بنجاح',  icon: '✅'),
  ];

  int get _currentIndex =>
      _steps.indexWhere((s) => s.status == currentStatus);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_steps.length, (i) {
        final step    = _steps[i];
        final done    = i < _currentIndex;
        final current = i == _currentIndex;
        final isLast  = i == _steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ العمود الرأسي (خط + نقطة) ──────────────────────────
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    // الخط اللي فوق
                    if (i > 0)
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Container(
                            width: 2,
                            color: done || current
                                ? AppColors.accent
                                : AppColors.border,
                          ),
                        ),
                      ),
                    // الدائرة
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.accent
                            : current
                                ? AppColors.primary
                                : AppColors.bgCard2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done
                              ? AppColors.accent
                              : current
                                  ? AppColors.primary
                                  : AppColors.border,
                          width: 2,
                        ),
                        boxShadow: current
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : Text(step.icon,
                                style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                    // الخط اللي تحت
                    if (!isLast)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Container(
                            width: 2,
                            color: done
                                ? AppColors.accent
                                : AppColors.border,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ─ النص ──────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: i == 0 ? 6 : 6,
                    bottom: isLast ? 0 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: current || done
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: done
                              ? AppColors.accent
                              : current
                                  ? AppColors.textMain
                                  : AppColors.textMuted,
                        ),
                      ),
                      if (current)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            'الآن',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

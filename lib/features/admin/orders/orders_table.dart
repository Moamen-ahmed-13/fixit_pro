import 'package:fixit_pro/features/admin/analytics/admin_bloc.dart';
import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class LiveOrdersTable extends StatelessWidget {
  final List<OrderModel> orders;
  final List<TechnicianSummary> technicians;

  const LiveOrdersTable({
    super.key,
    required this.orders,
    required this.technicians,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Text(
                  '📋 الطلبات الجارية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(width: 8),
                _LiveBadge(),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${orders.length} طلب',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'لا يوجد طلبات نشطة الآن',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            ...orders.take(8).map((order) => _OrderRow(
                  order: order,
                  technicians: technicians,
                )),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  final List<TechnicianSummary> technicians;
  const _OrderRow({required this.order, required this.technicians});

  // ✅ SlaType enum — مش String
  Color get _slaColor {
    switch (order.slaType) {
      case SlaType.emergency: return AppColors.danger;
      case SlaType.urgent:    return AppColors.warning;
      default:                return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsDispatch =
        order.status == OrderStatus.pending && order.technicianId == null;
    final availableTechs =
        technicians.where((t) => t.isOnline && !t.isBusy).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '#${order.id.substring(0, 6).toUpperCase()}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  '${order.deviceEmoji} ${order.deviceType} — ${order.brand}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ✅ SlaType enum — مش String
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _slaColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.slaType == SlaType.emergency
                      ? '⚡ طارئ'
                      : order.slaType == SlaType.urgent
                          ? '🔶 عاجل'
                          : '🕐 عادي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _slaColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              _StatusChip(status: order.status),
              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  '📍 ${order.address}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (needsDispatch && availableTechs.isNotEmpty)
                GestureDetector(
                  onTap: () =>
                      _showDispatchSheet(context, order, availableTechs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.4)),
                    ),
                    child: const Text(
                      '⚡ توزيع فني',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                )
              else if (needsDispatch)
                const Text(
                  '⏳ بدون فني',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDispatchSheet(
    BuildContext context,
    OrderModel order,
    List<TechnicianSummary> techs,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختار فني للطلب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 16),
              ...techs.take(5).map((tech) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('👨‍🔧',
                              style: TextStyle(fontSize: 18))),
                    ),
                    title: Text(
                      tech.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 12),
                        Text(
                          ' ${tech.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          ' — ${tech.todayOrders} طلب اليوم',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        context.read<AdminBloc>().add(
                              AdminOrderDispatched(order.id, tech.id),
                            );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'تعيين',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  static const _map = {
    OrderStatus.pending:    ('انتظار',     AppColors.warning),
    OrderStatus.assigned:   ('تم التعيين', AppColors.accent),
    OrderStatus.onTheWay:   ('في الطريق',  AppColors.primary),
    OrderStatus.inProgress: ('جاري',       AppColors.primary),
    OrderStatus.completed:  ('مكتمل',      AppColors.accent),
    OrderStatus.cancelled:  ('ملغي',       AppColors.danger),
  };

  @override
  Widget build(BuildContext context) {
    final info = _map[status] ?? ('؟', AppColors.textMuted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        info.$1,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: info.$2,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _ctrl,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
              color: AppColors.accent, shape: BoxShape.circle),
        ),
      );
}
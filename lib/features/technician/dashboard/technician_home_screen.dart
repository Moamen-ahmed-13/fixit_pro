import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:fixit_pro/features/technician/dashboard/incoming_request_card.dart';
import 'package:fixit_pro/features/technician/dashboard/technician_home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class TechnicianHomeScreen extends StatelessWidget {
  const TechnicianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TechnicianHomeBloc()..add(TechnicianHomeStarted()),
      child: const _TechnicianView(),
    );
  }
}

class _TechnicianView extends StatefulWidget {
  const _TechnicianView();
  @override
  State<_TechnicianView> createState() => _TechnicianViewState();
}

class _TechnicianViewState extends State<_TechnicianView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(),
          const _MapTab(),
          const _OrdersHistoryTab(),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _TechBottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TechnicianHomeBloc, TechnicianHomeState>(
      builder: (context, state) {
        if (state is TechnicianHomeLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is TechnicianHomeError) {
          return Center(
            child: Text(state.msg,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: AppColors.textMuted)),
          );
        }
        if (state is! TechnicianHomeData) return const SizedBox();

        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.bgCard,
              onRefresh: () async =>
                  context.read<TechnicianHomeBloc>().add(TechnicianHomeStarted()),
              child: CustomScrollView(
                slivers: [

                  // ── Header ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _TechHeader(state: state),
                  ),

                  // ── طلب جديد وارد ───────────────────────────────────
                  if (state.incomingRequest != null &&
                      state.stats.isOnline)
                    SliverToBoxAdapter(
                      child: IncomingRequestCard(
                        order: state.incomingRequest!,
                        isProcessing: state.isProcessing,
                      ),
                    ),

                  // ── جدول اليوم ──────────────────────────────────────
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Text(
                        '📅 جدول اليوم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ),

                  if (state.todaySchedule.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptySchedule(isOnline: state.stats.isOnline),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ScheduleItem(
                          order: state.todaySchedule[i],
                          onUpdateStatus: (OrderStatus newStatus) =>
                              context.read<TechnicianHomeBloc>().add(
                                    OrderStatusUpdated(
                                      state.todaySchedule[i].id,
                                      newStatus,
                                    ),
                                  ),
                        ),
                        childCount: state.todaySchedule.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Header الفني ─────────────────────────────────────────────────────────────
class _TechHeader extends StatelessWidget {
  final TechnicianHomeData state;
  const _TechHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.stats;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1a2a3a), AppColors.bgDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // الصف العلوي: اسم + Online toggle
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أهلاً 👋',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    state.techName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Online / Offline toggle
              GestureDetector(
                onTap: () => context
                    .read<TechnicianHomeBloc>()
                    .add(ToggleOnlineStatus()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: s.isOnline
                        ? AppColors.accent.withOpacity(0.12)
                        : AppColors.bgCard2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: s.isOnline
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulseDot(color: s.isOnline
                          ? AppColors.accent
                          : AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        s.isOnline ? 'متاح' : 'غير متاح',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: s.isOnline
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              _StatBox(
                value: '${s.todayOrders}',
                label: 'طلبات اليوم',
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _StatBox(
                value: s.rating.toStringAsFixed(1),
                label: 'تقييمي ⭐',
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              _StatBox(
                value: '${s.todayEarnings.toInt()} ج',
                label: 'أرباح اليوم',
                color: AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  )),
              const SizedBox(height: 3),
              Text(label,
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

// ─── Schedule Item ────────────────────────────────────────────────────────────
class _ScheduleItem extends StatelessWidget {
  final OrderModel order;
  final Function(OrderStatus) onUpdateStatus;
  const _ScheduleItem({required this.order, required this.onUpdateStatus});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.assigned:   return AppColors.warning;
      case OrderStatus.onTheWay:   return AppColors.primary;
      case OrderStatus.inProgress: return AppColors.accent;
      case OrderStatus.completed:  return AppColors.accent;
      default:                     return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              // الوقت
              Column(
                children: [
                  Text(
                    '${order.scheduledAt.hour}:${order.scheduledAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _statusColor,
                    ),
                  ),
                  Text(
                    order.scheduledAt.hour < 12 ? 'ص' : 'م',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 1, height: 40,
                  color: AppColors.border),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.deviceEmoji} ${order.deviceType} — ${order.brand}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '📍 ${order.address}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          // أزرار تحديث الحالة
          if (order.status != OrderStatus.completed) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (order.status == OrderStatus.assigned)
                  Expanded(
                    child: _ActionBtn(
                      label: '🚗 في الطريق',
                      color: AppColors.primary,
                      onTap: () => onUpdateStatus(OrderStatus.onTheWay),
                    ),
                  ),
                if (order.status == OrderStatus.onTheWay) ...[
                  Expanded(
                    child: _ActionBtn(
                      label: '🔧 بدأت',
                      color: AppColors.accent,
                      onTap: () => onUpdateStatus(OrderStatus.inProgress),
                    ),
                  ),
                ],
                if (order.status == OrderStatus.inProgress) ...[
                  Expanded(
                    child: _ActionBtn(
                      label: '📋 تقرير',
                      color: AppColors.warning,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/technician/report',
                        arguments: order.id,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ),
        ),
      );
}

class _EmptySchedule extends StatelessWidget {
  final bool isOnline;
  const _EmptySchedule({required this.isOnline});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(isOnline ? '🎉' : '😴',
                style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              isOnline
                  ? 'مفيش طلبات دلوقتي\nاستنى شوية هييجي طلب جديد'
                  : 'أنت مش متاح\nفعّل الـ Online عشان تستقبل طلبات',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
}

// ─── Pulse Dot ────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

// ─── Placeholder Tabs ─────────────────────────────────────────────────────────
class _MapTab extends StatelessWidget {
  const _MapTab();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('🗺️ الخريطة',
            style: TextStyle(fontFamily: 'Cairo', color: AppColors.textMain, fontSize: 18)));
}

class _OrdersHistoryTab extends StatelessWidget {
  const _OrdersHistoryTab();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('📋 سجل الطلبات',
            style: TextStyle(fontFamily: 'Cairo', color: AppColors.textMain, fontSize: 18)));
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('👤 ملفي',
            style: TextStyle(fontFamily: 'Cairo', color: AppColors.textMain, fontSize: 18)));
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
class _TechBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _TechBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.home_rounded,          label: 'الرئيسية'),
      (icon: Icons.map_rounded,            label: 'الخريطة'),
      (icon: Icons.receipt_long_rounded,  label: 'الطلبات'),
      (icon: Icons.person_rounded,         label: 'ملفي'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.accent.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(items[i].icon,
                            color: active
                                ? AppColors.accent
                                : AppColors.textMuted,
                            size: 24),
                      ),
                      const SizedBox(height: 2),
                      Text(items[i].label,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppColors.accent
                                : AppColors.textMuted,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

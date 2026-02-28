import 'package:fixit_pro/features/admin/analytics/admin_bloc.dart';
import 'package:fixit_pro/features/admin/analytics/kpi_card.dart';
import 'package:fixit_pro/features/admin/orders/orders_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc()..add(AdminStarted()),
      child: const _AdminView(),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bgDark,
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                // ── Sidebar ────────────────────────────────────────────
                _Sidebar(
                  currentTab: state is AdminData ? state.currentTab : 0,
                  onTap: (i) => context
                      .read<AdminBloc>()
                      .add(AdminTabChanged(i)),
                ),

                // ── المحتوى الرئيسي ──────────────────────────────────
                Expanded(
                  child: _buildContent(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AdminState state) {
    if (state is AdminLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state is AdminError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(state.msg,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<AdminBloc>().add(AdminStarted()),
              child: const Text('حاول تاني'),
            ),
          ],
        ),
      );
    }
    if (state is! AdminData) return const SizedBox();

    switch (state.currentTab) {
      case 0: return _OverviewTab(state: state);
      case 1: return _OrdersTab(state: state);
      case 2: return _TechniciansTab(state: state);
      case 3: return _DispatchTab(state: state);
      default: return _OverviewTab(state: state);
    }
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTap;
  const _Sidebar({required this.currentTab, required this.onTap});

  static const _items = [
    (icon: Icons.dashboard_rounded,   label: 'Overview'),
    (icon: Icons.receipt_long_rounded,label: 'الطلبات'),
    (icon: Icons.people_rounded,      label: 'الفنيين'),
    (icon: Icons.send_rounded,        label: 'Dispatch'),
    (icon: Icons.bar_chart_rounded,   label: 'التقارير'),
    (icon: Icons.support_agent_rounded,label:'الشكاوى'),
    (icon: Icons.settings_rounded,    label: 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          left: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                            child: Text('🔧',
                                style: TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 10),
                      const Text('FixIt Pro',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMain,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('لوحة الإدارة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      )),
                ],
              ),
            ),

            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),

            // Items
            ...List.generate(_items.length, (i) {
              final active = i == currentTab;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      right: BorderSide(
                        color: active
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _items[i].icon,
                        size: 18,
                        color: active
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _items[i].label,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0: Overview
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final AdminData state;
  const _OverviewTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final k = state.kpis;
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.bgCard,
        onRefresh: () async =>
            context.read<AdminBloc>().add(AdminStarted()),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── TopBar ──────────────────────────────────────────────
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'لوحة التحكم',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LiveDot(),
                        ],
                      ),
                      Text(
                        _todayDate(),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _TopBarBtn(
                    icon: Icons.refresh_rounded,
                    label: 'تحديث',
                    onTap: () =>
                        context.read<AdminBloc>().add(AdminStarted()),
                  ),
                  const SizedBox(width: 10),
                  _TopBarBtn(
                    icon: Icons.add_rounded,
                    label: 'طلب يدوي',
                    primary: true,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── KPIs Row 1 ────────────────────────────────────────
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  KpiCard(
                    emoji: '📋',
                    value: '${k.todayOrders}',
                    label: 'طلبات اليوم',
                    color: AppColors.primary,
                    change: '▲ 18% عن أمس',
                    changeUp: true,
                  ),
                  KpiCard(
                    emoji: '✅',
                    value: '${k.completionRate.toInt()}%',
                    label: 'معدل الإنجاز',
                    color: AppColors.accent,
                    change: '▲ 5%',
                    changeUp: true,
                  ),
                  KpiCard(
                    emoji: '💰',
                    value: '${k.todayRevenue.toInt()} ج',
                    label: 'إيرادات اليوم',
                    color: AppColors.warning,
                    change: '▲ 22%',
                    changeUp: true,
                  ),
                  KpiCard(
                    emoji: '⭐',
                    value: k.avgRating.toStringAsFixed(1),
                    label: 'متوسط التقييم',
                    color: const Color(0xFFFF6B6B),
                    change: '▼ 0.1',
                    changeUp: false,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // KPIs Row 2
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  KpiCard(
                    emoji: '🔧',
                    value: '${k.availableTechs}',
                    label: 'فنيين متاحين',
                    color: AppColors.accent,
                  ),
                  KpiCard(
                    emoji: '⚡',
                    value: '${k.activeOrders}',
                    label: 'طلبات جارية',
                    color: AppColors.warning,
                  ),
                  KpiCard(
                    emoji: '⏰',
                    value: '${k.avgResponseMins.toInt()} د',
                    label: 'متوسط الاستجابة',
                    color: AppColors.primary,
                  ),
                  KpiCard(
                    emoji: '😤',
                    value: '${k.openComplaints}',
                    label: 'شكاوى مفتوحة',
                    color: AppColors.danger,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── الرسم البياني + الفنيين ───────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart
                  Expanded(
                    flex: 3,
                    child: _WeeklyChart(data: state.weeklyChart),
                  ),
                  const SizedBox(width: 16),
                  // SLA
                  Expanded(
                    flex: 2,
                    child: _SlaWidget(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── جدول الطلبات ─────────────────────────────────────
              LiveOrdersTable(
                orders: state.liveOrders,
                technicians: state.technicians,
              ),

              const SizedBox(height: 20),

              // ── الفنيين ───────────────────────────────────────────
              _TechsWidget(techs: state.technicians),
            ],
          ),
        ),
      ),
    );
  }

  String _todayDate() {
    const days = ['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'];
    const months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    final now = DateTime.now();
    return '${days[now.weekday % 7]}، ${now.day} ${months[now.month]} ${now.year}';
  }
}

// ─── Weekly Chart ─────────────────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _WeeklyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxCount = data.isEmpty
        ? 1
        : data.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 الطلبات — آخر 7 أيام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final count = d['count'] as int;
                final ratio = maxCount == 0 ? 0.1 : count / maxCount;
                final isLast = d == data.last;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$count',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9,
                              color: AppColors.textMuted,
                            )),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: (ratio * 70).clamp(4.0, 70.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLast
                                  ? [AppColors.accent, AppColors.accent.withOpacity(0.3)]
                                  : [AppColors.primary, AppColors.primary.withOpacity(0.3)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: data.map((d) => Expanded(
              child: Text(
                d['day'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── SLA Widget ───────────────────────────────────────────────────────────────
class _SlaWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('عادي (24h)',    0.94, AppColors.accent),
      ('عاجل (6h)',     0.88, AppColors.warning),
      ('طوارئ (4h)',    0.79, AppColors.danger),
      ('First Fix',     0.85, AppColors.primary),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏱️ الالتزام بالـ SLA',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              )),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.$1,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.textMuted,
                            )),
                        Text(
                          '${(item.$2 * 100).toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.$3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.$2,
                        backgroundColor: AppColors.border,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(item.$3),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Techs Widget ─────────────────────────────────────────────────────────────
class _TechsWidget extends StatelessWidget {
  final List<TechnicianSummary> techs;
  const _TechsWidget({required this.techs});

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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text('🔧 الفنيين',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    )),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          ...techs.take(6).map((t) => _TechRow(tech: t)),
        ],
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  final TechnicianSummary tech;
  const _TechRow({required this.tech});

  @override
  Widget build(BuildContext context) {
    final statusColor = !tech.isOnline
        ? AppColors.textMuted
        : tech.isBusy
            ? AppColors.primary
            : AppColors.accent;
    final statusLabel = !tech.isOnline
        ? 'غير متاح'
        : tech.isBusy
            ? 'مشغول'
            : 'متاح';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: statusColor.withOpacity(0.3), width: 2),
                ),
                child: const Center(
                    child: Text('👨‍🔧',
                        style: TextStyle(fontSize: 18))),
              ),
              Positioned(
                bottom: 0, left: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.bgCard, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tech.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    )),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.warning, size: 12),
                  Text(' ${tech.rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      )),
                ],
              ),
              Text('${tech.todayOrders} طلب',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textMuted,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder Tabs ─────────────────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  final AdminData state;
  const _OrdersTab({required this.state});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: LiveOrdersTable(
        orders: state.liveOrders,
        technicians: state.technicians,
      ),
    ),
  );
}

class _TechniciansTab extends StatelessWidget {
  final AdminData state;
  const _TechniciansTab({required this.state});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: _TechsWidget(techs: state.technicians),
    ),
  );
}

class _DispatchTab extends StatelessWidget {
  final AdminData state;
  const _DispatchTab({required this.state});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📡 Dispatch — طلبات بدون فني',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              )),
          const SizedBox(height: 16),
          Expanded(
            child: LiveOrdersTable(
              orders: state.pendingOrders,
              technicians: state.technicians,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _TopBarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _TopBarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: primary
                ? AppColors.primary
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: primary ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color: primary ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary ? Colors.white : AppColors.textMuted,
                  )),
            ],
          ),
        ),
      );
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}
class _LiveDotState extends State<_LiveDot>
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
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(
      width: 8, height: 8,
      decoration: const BoxDecoration(
          color: AppColors.accent, shape: BoxShape.circle),
    ),
  );
}

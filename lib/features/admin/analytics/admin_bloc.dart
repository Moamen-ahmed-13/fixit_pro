import 'dart:async';
import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Models ───────────────────────────────────────────────────────────────────
class AdminKpis {
  final int todayOrders;
  final int activeOrders;
  final int availableTechs;
  final int openComplaints;
  final double completionRate;
  final double avgResponseMins;
  final double todayRevenue;
  final double avgRating;

  const AdminKpis({
    this.todayOrders      = 0,
    this.activeOrders     = 0,
    this.availableTechs   = 0,
    this.openComplaints   = 0,
    this.completionRate   = 0,
    this.avgResponseMins  = 0,
    this.todayRevenue     = 0,
    this.avgRating        = 0,
  });
}

class TechnicianSummary {
  final String id;
  final String name;
  final bool isOnline;
  final bool isBusy;
  final double rating;
  final int todayOrders;
  const TechnicianSummary({
    required this.id, required this.name,
    required this.isOnline, required this.isBusy,
    required this.rating, required this.todayOrders,
  });
}

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class AdminEvent {}
class AdminStarted          extends AdminEvent {}
class AdminTabChanged       extends AdminEvent { final int tab; AdminTabChanged(this.tab); }
class AdminOrderDispatched  extends AdminEvent { final String orderId; final String techId; AdminOrderDispatched(this.orderId, this.techId); }
class AdminOrderCancelled   extends AdminEvent { final String orderId; AdminOrderCancelled(this.orderId); }

// ─── States ───────────────────────────────────────────────────────────────────
abstract class AdminState {}
class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}
class AdminError   extends AdminState { final String msg; AdminError(this.msg); }

class AdminData extends AdminState {
  final int currentTab;
  final AdminKpis kpis;
  final List<OrderModel> liveOrders;
  final List<OrderModel> pendingOrders;   // بدون فني
  final List<TechnicianSummary> technicians;
  final List<Map<String, dynamic>> weeklyChart; // [{day, count}]

  AdminData({
    this.currentTab    = 0,
    required this.kpis,
    required this.liveOrders,
    required this.pendingOrders,
    required this.technicians,
    required this.weeklyChart,
  });

  AdminData copyWith({
    int? currentTab,
    AdminKpis? kpis,
    List<OrderModel>? liveOrders,
    List<OrderModel>? pendingOrders,
    List<TechnicianSummary>? technicians,
    List<Map<String, dynamic>>? weeklyChart,
  }) => AdminData(
    currentTab:   currentTab   ?? this.currentTab,
    kpis:         kpis         ?? this.kpis,
    liveOrders:   liveOrders   ?? this.liveOrders,
    pendingOrders: pendingOrders ?? this.pendingOrders,
    technicians:  technicians  ?? this.technicians,
    weeklyChart:  weeklyChart  ?? this.weeklyChart,
  );
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final _db = FirebaseFirestore.instance;
  StreamSubscription? _ordersSub;
  StreamSubscription? _techsSub;

  AdminBloc() : super(AdminInitial()) {
    on<AdminStarted>(_onStarted);
    on<AdminTabChanged>(_onTabChanged);
    on<AdminOrderDispatched>(_onDispatched);
    on<AdminOrderCancelled>(_onCancelled);
  }

  Future<void> _onStarted(AdminStarted _, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // طلبات اليوم
      final todaySnap = await _db.collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      final todayOrders = todaySnap.docs.map(OrderModel.fromFirestore).toList();

      // الطلبات النشطة الآن
      final activeSnap = await _db.collection('orders')
          .where('status', whereIn: ['pending','assigned','onTheWay','inProgress'])
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      final activeOrders = activeSnap.docs.map(OrderModel.fromFirestore).toList();

      // الطلبات بدون فني
      final pendingOrders = activeOrders
          .where((o) => o.status == OrderStatus.pending && o.technicianId == null)
          .toList();

      // الفنيين
      final techsSnap = await _db.collection('technicians')
          .orderBy('rating', descending: true)
          .limit(20)
          .get();
      final techs = techsSnap.docs.map((d) {
        final data = d.data();
        return TechnicianSummary(
          id:          d.id,
          name:        data['name']        ?? 'فني',
          isOnline:    data['isOnline']    ?? false,
          isBusy:      (data['activeOrders'] ?? 0) > 0,
          rating:      (data['rating']     as num?)?.toDouble() ?? 4.0,
          todayOrders: (data['todayOrders'] as int?) ?? 0,
        );
      }).toList();

      // الإيرادات
      final completedToday = todayOrders
          .where((o) => o.status == OrderStatus.completed).toList();
      final revenue = completedToday
          .fold<double>(0, (s, o) => s + (o.finalPrice ?? 0));
      final completionRate = todayOrders.isEmpty
          ? 0.0
          : completedToday.length / todayOrders.length * 100;

      // شكاوى مفتوحة
      final complaintsSnap = await _db.collection('complaints')
          .where('status', isEqualTo: 'open').count().get();
      final openComplaints = complaintsSnap.count ?? 0;

      // رسم بياني آخر 7 أيام
      final chart = await _buildWeeklyChart();

      final kpis = AdminKpis(
        todayOrders:     todayOrders.length,
        activeOrders:    activeOrders.length,
        availableTechs:  techs.where((t) => t.isOnline && !t.isBusy).length,
        openComplaints:  openComplaints,
        completionRate:  completionRate,
        avgResponseMins: 24,
        todayRevenue:    revenue,
        avgRating:       4.7,
      );

      emit(AdminData(
        kpis:          kpis,
        liveOrders:    activeOrders,
        pendingOrders: pendingOrders,
        technicians:   techs,
        weeklyChart:   chart,
      ));

      // Stream real-time على الطلبات النشطة
      _listenToLiveOrders(emit);

    } catch (e) {
      emit(AdminError('حصل خطأ: $e'));
    }
  }

  void _listenToLiveOrders(Emitter emit) {
    _ordersSub = _db.collection('orders')
        .where('status', whereIn: ['pending','assigned','onTheWay','inProgress'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      if (state is! AdminData) return;
      final current = state as AdminData;
      final orders  = snap.docs.map(OrderModel.fromFirestore).toList();
      final pending = orders.where((o) =>
          o.status == OrderStatus.pending && o.technicianId == null).toList();
      emit(current.copyWith(
        liveOrders:    orders,
        pendingOrders: pending,
        kpis: AdminKpis(
          todayOrders:    current.kpis.todayOrders,
          activeOrders:   orders.length,
          availableTechs: current.kpis.availableTechs,
          openComplaints: current.kpis.openComplaints,
          completionRate: current.kpis.completionRate,
          avgResponseMins:current.kpis.avgResponseMins,
          todayRevenue:   current.kpis.todayRevenue,
          avgRating:      current.kpis.avgRating,
        ),
      ));
    });
  }

  Future<List<Map<String, dynamic>>> _buildWeeklyChart() async {
    final days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });
    final chart = <Map<String, dynamic>>[];
    for (final day in days) {
      final next = day.add(const Duration(days: 1));
      final snap = await _db.collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(day))
          .where('createdAt', isLessThan: Timestamp.fromDate(next))
          .count().get();
      chart.add({'day': '${day.day}/${day.month}', 'count': snap.count ?? 0});
    }
    return chart;
  }

  void _onTabChanged(AdminTabChanged e, Emitter emit) {
    if (state is AdminData) {
      emit((state as AdminData).copyWith(currentTab: e.tab));
    }
  }

  Future<void> _onDispatched(AdminOrderDispatched e, Emitter emit) async {
    await _db.collection('orders').doc(e.orderId).update({
      'technicianId': e.techId,
      'status':       'assigned',
      'assignedAt':   FieldValue.serverTimestamp(),
    });
  }

  Future<void> _onCancelled(AdminOrderCancelled e, Emitter emit) async {
    await _db.collection('orders').doc(e.orderId).update({
      'status': 'cancelled',
    });
  }

  @override
  Future<void> close() {
    _ordersSub?.cancel();
    _techsSub?.cancel();
    return super.close();
  }
}

import 'dart:async';
import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class TechnicianStats {
  final int todayOrders;
  final int completedOrders;
  final double rating;
  final double todayEarnings;
  final bool isOnline;
  const TechnicianStats({
    this.todayOrders = 0,
    this.completedOrders = 0,
    this.rating = 0,
    this.todayEarnings = 0,
    this.isOnline = false,
  });
}

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class TechnicianHomeEvent {}
class TechnicianHomeStarted    extends TechnicianHomeEvent {}
class ToggleOnlineStatus       extends TechnicianHomeEvent {}
class OrderAccepted            extends TechnicianHomeEvent { final String orderId; OrderAccepted(this.orderId); }
class OrderRejected            extends TechnicianHomeEvent { final String orderId; OrderRejected(this.orderId); }
class OrderStatusUpdated       extends TechnicianHomeEvent { final String orderId; final OrderStatus status; OrderStatusUpdated(this.orderId, this.status); }

// ─── States ───────────────────────────────────────────────────────────────────
abstract class TechnicianHomeState {}
class TechnicianHomeInitial extends TechnicianHomeState {}
class TechnicianHomeLoading extends TechnicianHomeState {}
class TechnicianHomeError   extends TechnicianHomeState { final String msg; TechnicianHomeError(this.msg); }

class TechnicianHomeData extends TechnicianHomeState {
  final String techName;
  final TechnicianStats stats;
  final List<OrderModel> todaySchedule;   // الطلبات المقبولة
  final OrderModel? incomingRequest;       // طلب جديد بانتظار القبول
  final bool isProcessing;                 // جاري قبول/رفض

  TechnicianHomeData({
    required this.techName,
    required this.stats,
    required this.todaySchedule,
    this.incomingRequest,
    this.isProcessing = false,
  });

  TechnicianHomeData copyWith({
    String? techName,
    TechnicianStats? stats,
    List<OrderModel>? todaySchedule,
    OrderModel? incomingRequest,
    bool clearIncoming = false,
    bool? isProcessing,
  }) => TechnicianHomeData(
    techName:        techName        ?? this.techName,
    stats:           stats           ?? this.stats,
    todaySchedule:   todaySchedule   ?? this.todaySchedule,
    incomingRequest: clearIncoming ? null : (incomingRequest ?? this.incomingRequest),
    isProcessing:    isProcessing    ?? this.isProcessing,
  );
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class TechnicianHomeBloc extends Bloc<TechnicianHomeEvent, TechnicianHomeState> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription? _ordersSub;
  StreamSubscription? _locationSub;
  Timer? _locationTimer;

  TechnicianHomeBloc() : super(TechnicianHomeInitial()) {
    on<TechnicianHomeStarted>(_onStarted);
    on<ToggleOnlineStatus>(_onToggleOnline);
    on<OrderAccepted>(_onAccepted);
    on<OrderRejected>(_onRejected);
    on<OrderStatusUpdated>(_onStatusUpdated);
  }

  Future<void> _onStarted(TechnicianHomeStarted _, Emitter<TechnicianHomeState> emit) async {
    emit(TechnicianHomeLoading());
    try {
      final uid     = _auth.currentUser!.uid;
      final techDoc = await _db.collection('technicians').doc(uid).get();
      final data    = techDoc.data() ?? {};

      final stats = TechnicianStats(
        todayOrders:    (data['todayOrders']    as int?)    ?? 0,
        completedOrders:(data['completedOrders'] as int?)   ?? 0,
        rating:         (data['rating']         as num?)?.toDouble() ?? 4.5,
        todayEarnings:  (data['todayEarnings']  as num?)?.toDouble() ?? 0,
        isOnline:       (data['isOnline']        as bool?)  ?? false,
      );

      emit(TechnicianHomeData(
        techName: data['name'] ?? 'الفني',
        stats: stats,
        todaySchedule: [],
      ));

      // Stream على الطلبات المسندة ليه اليوم
      _listenToOrders(uid, emit);

      // لو أونلاين — ابدأ GPS
      if (stats.isOnline) _startLocationUpdates(uid);

    } catch (e) {
      emit(TechnicianHomeError('حصل خطأ، حاول تاني'));
    }
  }

  void _listenToOrders(String uid, Emitter emit) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    _ordersSub = _db
      .collection('orders')
      .where('technicianId', isEqualTo: uid)
      .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .orderBy('scheduledAt')
      .snapshots()
      .listen((snap) {
        if (state is! TechnicianHomeData) return;
        final current = state as TechnicianHomeData;
        final orders = snap.docs.map(OrderModel.fromFirestore).toList();
        emit(current.copyWith(todaySchedule: orders));
      });

    // Stream على الطلبات الجديدة (pending بدون فني)
    _db.collection('orders')
      .where('status', isEqualTo: 'pending')
      .where('technicianId', isNull: true)
      .limit(1)
      .snapshots()
      .listen((snap) {
        if (state is! TechnicianHomeData) return;
        final current = state as TechnicianHomeData;
        if (snap.docs.isEmpty) {
          emit(current.copyWith(clearIncoming: true));
        } else {
          final order = OrderModel.fromFirestore(snap.docs.first);
          emit(current.copyWith(incomingRequest: order));
        }
      });
  }

  Future<void> _onToggleOnline(ToggleOnlineStatus _, Emitter emit) async {
    if (state is! TechnicianHomeData) return;
    final current = state as TechnicianHomeData;
    final uid = _auth.currentUser!.uid;
    final newStatus = !current.stats.isOnline;

    await _db.collection('technicians').doc(uid).update({
      'isOnline': newStatus,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    if (newStatus) {
      _startLocationUpdates(uid);
    } else {
      _locationTimer?.cancel();
    }

    emit(current.copyWith(
      stats: TechnicianStats(
        todayOrders:     current.stats.todayOrders,
        completedOrders: current.stats.completedOrders,
        rating:          current.stats.rating,
        todayEarnings:   current.stats.todayEarnings,
        isOnline:        newStatus,
      ),
    ));
  }

  Future<void> _onAccepted(OrderAccepted event, Emitter emit) async {
    if (state is! TechnicianHomeData) return;
    final current = state as TechnicianHomeData;
    final uid = _auth.currentUser!.uid;
    emit(current.copyWith(isProcessing: true));

    await _db.collection('orders').doc(event.orderId).update({
      'technicianId': uid,
      'status':       'assigned',
      'assignedAt':   FieldValue.serverTimestamp(),
    });

    emit(current.copyWith(clearIncoming: true, isProcessing: false));
  }

  Future<void> _onRejected(OrderRejected event, Emitter emit) async {
    if (state is! TechnicianHomeData) return;
    final current = state as TechnicianHomeData;
    emit(current.copyWith(clearIncoming: true, isProcessing: false));
  }

  Future<void> _onStatusUpdated(OrderStatusUpdated event, Emitter emit) async {
    await _db.collection('orders').doc(event.orderId).update({
      'status': event.status.name,
      if (event.status == OrderStatus.inProgress)
        'startedAt': FieldValue.serverTimestamp(),
      if (event.status == OrderStatus.completed)
        'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── GPS ────────────────────────────────────────────────────────────────────
  void _startLocationUpdates(String uid) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _db.collection('technicians').doc(uid).update({
          'currentLocation': GeoPoint(pos.latitude, pos.longitude),
        });
      } catch (_) {}
    });
  }

  @override
  Future<void> close() {
    _ordersSub?.cancel();
    _locationTimer?.cancel();
    return super.close();
  }
}

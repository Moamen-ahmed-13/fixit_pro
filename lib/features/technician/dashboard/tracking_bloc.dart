import 'dart:async';
import 'package:fixit_pro/features/customer/home/order_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Models ───────────────────────────────────────────────────────────────────
class TechnicianLocation {
  final double lat;
  final double lng;
  final String name;
  final double rating;
  final String phone;
  final String level;
  TechnicianLocation({
    required this.lat, required this.lng,
    required this.name, required this.rating,
    required this.phone, required this.level,
  });
}

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class TrackingEvent {}
class TrackingStarted extends TrackingEvent { final String orderId; TrackingStarted(this.orderId); }
class TrackingStopped extends TrackingEvent {}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class TrackingState {}
class TrackingInitial  extends TrackingState {}
class TrackingLoading  extends TrackingState {}
class TrackingError    extends TrackingState { final String msg; TrackingError(this.msg); }

class TrackingData extends TrackingState {
  final OrderModel order;
  final TechnicianLocation? techLocation;
  final int? etaMinutes;
  TrackingData({
    required this.order,
    this.techLocation,
    this.etaMinutes,
  });
  // نسخة محدثة
  TrackingData copyWith({
    OrderModel? order,
    TechnicianLocation? techLocation,
    int? etaMinutes,
  }) => TrackingData(
    order:        order        ?? this.order,
    techLocation: techLocation ?? this.techLocation,
    etaMinutes:   etaMinutes   ?? this.etaMinutes,
  );
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final _db = FirebaseFirestore.instance;
  StreamSubscription? _orderSub;
  StreamSubscription? _locationSub;

  TrackingBloc() : super(TrackingInitial()) {
    on<TrackingStarted>(_onStarted);
    on<TrackingStopped>(_onStopped);
  }

  Future<void> _onStarted(TrackingStarted event, Emitter<TrackingState> emit) async {
    emit(TrackingLoading());

    // ─ Stream الطلب (real-time) ───────────────────────────────────────────────
    await emit.forEach<DocumentSnapshot>(
      _db.collection('orders').doc(event.orderId).snapshots(),
      onData: (snap) {
        if (!snap.exists) return TrackingError('الطلب مش موجود');
        final order = OrderModel.fromFirestore(snap);

        // لو في فني معين — ابدأ track موقعه
        if (order.technicianId != null) {
          _startLocationTracking(order.technicianId!);
        }

        final current = state is TrackingData ? state as TrackingData : null;
        return TrackingData(
          order: order,
          techLocation: current?.techLocation,
          etaMinutes: current?.etaMinutes,
        );
      },
      onError: (_, __) => TrackingError('حصل خطأ في الاتصال'),
    );
  }

  void _startLocationTracking(String techId) {
    _locationSub?.cancel();
    _locationSub = _db
        .collection('technicians')
        .doc(techId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || state is! TrackingData) return;
      final data = snap.data() as Map<String, dynamic>;
      final loc  = data['currentLocation'] as GeoPoint?;
      if (loc == null) return;

      final current = state as TrackingData;
      // تقدير الـ ETA بناءً على المسافة (simplified)
      final eta = _estimateEta(
        loc.latitude, loc.longitude,
        current.order.location?.latitude ?? 30.0444,
        current.order.location?.longitude ?? 31.2357,
      );

      emit(current.copyWith(
        techLocation: TechnicianLocation(
          lat:    loc.latitude,
          lng:    loc.longitude,
          name:   data['name']   ?? 'الفني',
          rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
          phone:  data['phone']  ?? '',
          level:  data['level']  ?? 'Senior',
        ),
        etaMinutes: eta,
      ));
    });
  }

  // تقدير بسيط للـ ETA بالدقائق (1 كم ≈ 3 دقائق في القاهرة)
  int _estimateEta(double lat1, double lng1, double lat2, double lng2) {
    final dlat = (lat2 - lat1).abs();
    final dlng = (lng2 - lng1).abs();
    final distKm = (dlat + dlng) * 111; // تقريب
    return (distKm * 3).round().clamp(2, 120);
  }

  void _onStopped(TrackingStopped _, Emitter emit) {
    _orderSub?.cancel();
    _locationSub?.cancel();
    emit(TrackingInitial());
  }

  @override
  Future<void> close() {
    _orderSub?.cancel();
    _locationSub?.cancel();
    return super.close();
  }
}

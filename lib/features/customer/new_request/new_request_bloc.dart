import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// ─── Data classes ─────────────────────────────────────────────────────────────
class RequestData {
  final String deviceType;
  final String brand;
  final String issue;
  final String address;
  final GeoPoint? location;
  final DateTime? scheduledAt;
  final String slaType;   // normal | urgent | emergency
  final String paymentMethod;

  const RequestData({
    this.deviceType = '',
    this.brand = '',
    this.issue = '',
    this.address = '',
    this.location,
    this.scheduledAt,
    this.slaType = 'normal',
    this.paymentMethod = 'cash',
  });

  RequestData copyWith({
    String? deviceType, String? brand, String? issue,
    String? address, GeoPoint? location, DateTime? scheduledAt,
    String? slaType, String? paymentMethod,
  }) => RequestData(
    deviceType:    deviceType    ?? this.deviceType,
    brand:         brand         ?? this.brand,
    issue:         issue         ?? this.issue,
    address:       address       ?? this.address,
    location:      location      ?? this.location,
    scheduledAt:   scheduledAt   ?? this.scheduledAt,
    slaType:       slaType       ?? this.slaType,
    paymentMethod: paymentMethod ?? this.paymentMethod,
  );

  bool get isStep1Valid => deviceType.isNotEmpty && brand.isNotEmpty;
  bool get isStep2Valid => issue.isNotEmpty;
  bool get isStep3Valid => scheduledAt != null && address.isNotEmpty;
}

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class NewRequestEvent {}

class StepChanged      extends NewRequestEvent { final int step; StepChanged(this.step); }
class DeviceSelected   extends NewRequestEvent { final String type; final String brand; DeviceSelected(this.type, this.brand); }
class IssueSelected    extends NewRequestEvent { final String issue; IssueSelected(this.issue); }
class ScheduleSelected extends NewRequestEvent { final DateTime dt; final String sla; ScheduleSelected(this.dt, this.sla); }
class AddressSet       extends NewRequestEvent { final String address; final GeoPoint loc; AddressSet(this.address, this.loc); }
class PaymentSelected  extends NewRequestEvent { final String method; PaymentSelected(this.method); }
class RequestSubmitted extends NewRequestEvent {}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class NewRequestState {}

class NewRequestForm extends NewRequestState {
  final int currentStep;   // 1..4
  final RequestData data;
  final bool isSubmitting;
  NewRequestForm({
    this.currentStep = 1,
    this.data = const RequestData(),
    this.isSubmitting = false,
  });
  NewRequestForm copyWith({int? currentStep, RequestData? data, bool? isSubmitting}) =>
    NewRequestForm(
      currentStep:   currentStep   ?? this.currentStep,
      data:          data          ?? this.data,
      isSubmitting:  isSubmitting  ?? this.isSubmitting,
    );
}

class NewRequestSuccess extends NewRequestState { final String orderId; NewRequestSuccess(this.orderId); }
class NewRequestError   extends NewRequestState { final String msg;     NewRequestError(this.msg); }

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class NewRequestBloc extends Bloc<NewRequestEvent, NewRequestState> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  NewRequestBloc({String? initialDevice})
      : super(NewRequestForm(
          data: RequestData(deviceType: initialDevice ?? ''),
        )) {
    on<StepChanged>(_onStep);
    on<DeviceSelected>(_onDevice);
    on<IssueSelected>(_onIssue);
    on<ScheduleSelected>(_onSchedule);
    on<AddressSet>(_onAddress);
    on<PaymentSelected>(_onPayment);
    on<RequestSubmitted>(_onSubmit);
  }

  void _onStep(StepChanged e, Emitter emit) {
    final s = state as NewRequestForm;
    emit(s.copyWith(currentStep: e.step));
  }

  void _onDevice(DeviceSelected e, Emitter emit) {
    final s = state as NewRequestForm;
    emit(s.copyWith(
      data: s.data.copyWith(deviceType: e.type, brand: e.brand),
      currentStep: 2,
    ));
  }

  void _onIssue(IssueSelected e, Emitter emit) {
    final s = state as NewRequestForm;
    emit(s.copyWith(
      data: s.data.copyWith(issue: e.issue),
      currentStep: 3,
    ));
  }

  void _onSchedule(ScheduleSelected e, Emitter emit) {
    final s = state as NewRequestForm;
    emit(s.copyWith(
      data: s.data.copyWith(scheduledAt: e.dt, slaType: e.sla),
      currentStep: 4,
    ));
  }

  void _onAddress(AddressSet e, Emitter emit) {
    final s = state as NewRequestForm;
    emit(s.copyWith(
      data: s.data.copyWith(address: e.address, location: e.loc),
    ));
  }

  void _onPayment(PaymentSelected e, Emitter emit) {
    final s = state as NewRequestForm;
    emit(s.copyWith(data: s.data.copyWith(paymentMethod: e.method)));
  }

  Future<void> _onSubmit(RequestSubmitted e, Emitter emit) async {
    final s = state as NewRequestForm;
    emit(s.copyWith(isSubmitting: true));
    try {
      final uid = _auth.currentUser!.uid;
      final ref = await _db.collection('orders').add({
        'customerId':       uid,
        'technicianId':     null,
        'deviceType':       s.data.deviceType,
        'brand':            s.data.brand,
        'issue':            s.data.issue,
        'status':           'pending',
        'slaType':          s.data.slaType,
        'address':          s.data.address,
        'location':         s.data.location,
        'scheduledAt':      Timestamp.fromDate(s.data.scheduledAt!),
        'createdAt':        FieldValue.serverTimestamp(),
        'paymentMethod':    s.data.paymentMethod,
        'paymentStatus':    'pending',
        'estimatedPriceMin': _getEstimate(s.data.deviceType).min,
        'estimatedPriceMax': _getEstimate(s.data.deviceType).max,
      });
      emit(NewRequestSuccess(ref.id));
    } catch (err) {
      emit(NewRequestError('حصل خطأ، حاول تاني'));
    }
  }

  // تقدير السعر حسب نوع الجهاز
  ({double min, double max}) _getEstimate(String deviceType) {
    switch (deviceType) {
      case 'ac':     return (min: 150, max: 400);
      case 'fridge': return (min: 100, max: 350);
      case 'washer': return (min: 80,  max: 280);
      case 'gas':    return (min: 50,  max: 200);
      default:       return (min: 80,  max: 300);
    }
  }
}

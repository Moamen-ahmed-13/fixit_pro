import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'auth_event.dart';
part 'auth_state.dart';

// ─── Internal events (مش بيشوفهم المستخدم) ──────────────────────────────────
class _AutoVerified extends AuthEvent {
  final PhoneAuthCredential credential;
  _AutoVerified(this.credential);
}

class _VerificationFailed extends AuthEvent {
  final String code;
  _VerificationFailed(this.code);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _verificationId;
  String? _pendingPhone;

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);               // ✅ تحقق من الجلسة عند الفتح
    on<PhoneSubmitted>(_onPhoneSubmitted);
    on<VerificationCodeSent>(_onVerificationCodeSent);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<ResetAuth>((_, emit) => emit(AuthInitial()));
    on<RoleSelected>(_onRoleSelected);           // ✅ اختيار الـ role
    // Internal handlers
    on<_AutoVerified>(_onAutoVerified);
    on<_VerificationFailed>(_onVerificationFailed);
  }

  // ─── تحقق من الجلسة عند فتح التطبيق ─────────────────────────────────────
  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(AuthInitial()); // مفيش جلسة → شاشة الـ phone
      return;
    }
    // في يوزر logged in → جيب الـ role من Firestore
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? 'customer';
      emit(AuthSuccess(role));
    } catch (_) {
      emit(AuthSuccess('customer'));
    }
  }

  // ─── إرسال OTP ────────────────────────────────────────────────────────────
  Future<void> _onPhoneSubmitted(
    PhoneSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthPhoneLoading());
    _pendingPhone = event.phoneNumber;

    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: '+2${event.phoneNumber}',
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) {
        if (!completer.isCompleted) completer.complete();
        add(_AutoVerified(credential));
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.complete();
        add(_VerificationFailed(e.code));
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
        add(VerificationCodeSent(verificationId));
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  void _onVerificationCodeSent(
    VerificationCodeSent event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthOtpSent(_pendingPhone ?? ''));
  }

  // ─── التحقق من الـ OTP ────────────────────────────────────────────────────
  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (_verificationId == null) {
      emit(AuthError('انتهت الجلسة، حاول مرة تانية'));
      return;
    }
    emit(AuthOtpVerifying());
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: event.otp,
      );
      await _signInWithCredential(credential, emit);
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code)));
    }
  }

  // ─── Auto verify (Android SMS Retriever) ──────────────────────────────────
  Future<void> _onAutoVerified(
    _AutoVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthOtpVerifying());
    try {
      await _signInWithCredential(event.credential, emit);
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code)));
    }
  }

  void _onVerificationFailed(
    _VerificationFailed event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthError(_mapFirebaseError(event.code)));
  }

  // ─── تسجيل الدخول + جلب الـ role ─────────────────────────────────────────
  Future<void> _signInWithCredential(
    PhoneAuthCredential credential,
    Emitter<AuthState> emit,
  ) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user!.uid;

    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        // ✅ يوزر جديد → اعرض شاشة اختيار الـ role
        await _db.collection('users').doc(uid).set({
          'phone': userCredential.user!.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });
        emit(AuthNeedsRole(uid));
      } else {
        final role = doc.data()?['role'] ?? 'customer';
        emit(AuthSuccess(role));
      }
    } catch (e) {
      emit(AuthNeedsRole(uid)); // Firestore error → خليه يختار الـ role
    }
  }

  // ─── حفظ الـ role بعد الاختيار ───────────────────────────────────────────
  Future<void> _onRoleSelected(
    RoleSelected event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _db.collection('users').doc(event.uid).update({
        'role': event.role,
      });
    } catch (_) {}
    emit(AuthSuccess(event.role));
  }

  // ─── ترجمة أخطاء Firebase ─────────────────────────────────────────────────
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'رقم الموبايل غلط';
      case 'invalid-verification-code':
        return 'الكود اللي دخلته غلط';
      case 'session-expired':
        return 'انتهت مدة الكود، اطلب كود جديد';
      case 'too-many-requests':
        return 'محاولات كتير، استنى شوية وحاول تاني';
      case 'network-request-failed':
        return 'مفيش انترنت، تحقق من الاتصال';
      default:
        return 'حصل خطأ، حاول مرة تانية';
    }
  }
}
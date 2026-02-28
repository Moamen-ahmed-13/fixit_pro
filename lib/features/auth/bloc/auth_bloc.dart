import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class AuthEvent {}

class AuthPhoneSubmitted extends AuthEvent {
  final String phone;
  AuthPhoneSubmitted(this.phone);
}

class AuthOtpSubmitted extends AuthEvent {
  final String otp;
  AuthOtpSubmitted(this.otp);
}

class AuthRoleSelected extends AuthEvent {
  final String role;
  AuthRoleSelected(this.role);
}

class AuthCheckStatus extends AuthEvent {}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String verificationId;
  AuthOtpSent(this.verificationId);
}

class AuthOtpError extends AuthState {
  final String message;
  AuthOtpError(this.message);
}

class AuthPhoneError extends AuthState {
  final String message;
  AuthPhoneError(this.message);
}

/// يوصل لده لما المستخدم لسه ماختارش دور (أول مرة)
class AuthNeedsRoleSelection extends AuthState {}

/// يوصل لده لما الـ role محفوظ — يروح على الشاشة الصح مباشرة
class AuthAuthenticated extends AuthState {
  final String role;   // 'customer' | 'technician' | 'admin'
  AuthAuthenticated(this.role);
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? _verificationId;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthPhoneSubmitted>(_onPhoneSubmitted);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthRoleSelected>(_onRoleSelected);
  }

  /// يُشغَّل عند بدء الـ app — لو المستخدم مسجل دخول بالفعل
  Future<void> _onCheckStatus(
      AuthCheckStatus event, Emitter<AuthState> emit) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(AuthInitial());
      return;
    }
    emit(AuthLoading());
    await _routeByRole(user.uid, emit);
  }

  /// إرسال رقم الهاتف
  Future<void> _onPhoneSubmitted(
      AuthPhoneSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _auth.verifyPhoneNumber(
      phoneNumber: event.phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verify (Android only)
        try {
          final result = await _auth.signInWithCredential(credential);
          await _handleSignIn(result.user!.uid, emit);
        } catch (_) {}
      },
      verificationFailed: (FirebaseAuthException e) {
        emit(AuthPhoneError(e.message ?? 'خطأ في الاتصال'));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        emit(AuthOtpSent(verificationId));
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// التحقق من الـ OTP
  Future<void> _onOtpSubmitted(
      AuthOtpSubmitted event, Emitter<AuthState> emit) async {
    if (_verificationId == null) return;
    emit(AuthLoading());
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: event.otp,
      );
      final result = await _auth.signInWithCredential(credential);
      await _handleSignIn(result.user!.uid, emit);
    } on FirebaseAuthException catch (e) {
      emit(AuthOtpError(e.message ?? 'كود غلط'));
    }
  }

  /// بعد اختيار الدور (أول مرة فقط)
  Future<void> _onRoleSelected(
      AuthRoleSelected event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(AuthInitial());
      return;
    }
    await _db.collection('users').doc(uid).set({
      'role': event.role,
      'phone': _auth.currentUser?.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    emit(AuthAuthenticated(event.role));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _handleSignIn(String uid, Emitter<AuthState> emit) async {
    await _routeByRole(uid, emit);
  }

  /// يجيب الـ role من Firestore — لو مفيش → يطلب اختيار
  Future<void> _routeByRole(String uid, Emitter<AuthState> emit) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final role = doc.data()?['role'] as String?;

      if (role == null || role.isEmpty) {
        // أول مرة — محتاج يختار دور
        emit(AuthNeedsRoleSelection());
      } else {
        // عنده دور محفوظ → روح عليه مباشرة
        emit(AuthAuthenticated(role));
      }
    } catch (_) {
      emit(AuthNeedsRoleSelection());
    }
  }
}
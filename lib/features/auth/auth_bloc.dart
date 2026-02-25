import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _verificationId;

  AuthBloc() : super(AuthInitial()) {
    on<PhoneSubmitted>(_onPhoneSubmitted);
    on<VerificationCodeSent>(_onVerificationCodeSent);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<ResetAuth>((_, emit) => emit(AuthInitial()));
  }

  // ─── إرسال كود OTP عبر Firebase ───────────────────────────────────────────
  Future<void> _onPhoneSubmitted(
    PhoneSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthPhoneLoading());

    await _auth.verifyPhoneNumber(
      // مصر كود +20، غيّره لو محتاج
      phoneNumber: '+2${event.phoneNumber}',
      timeout: const Duration(seconds: 60),

      // ✅ تلقائي على أجهزة Android (SMS Retriever)
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _signInWithCredential(credential, emit);
      },

      // ❌ فشل الإرسال
      verificationFailed: (FirebaseAuthException e) {
        emit(AuthError(_mapFirebaseError(e.code)));
      },

      // 📲 الكود اتبعت — روح لشاشة OTP
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        add(VerificationCodeSent(verificationId));
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _onVerificationCodeSent(
    VerificationCodeSent event,
    Emitter<AuthState> emit,
  ) {
    // نحتاج phoneNumber في الـ state عشان نعرضه في شاشة OTP
    // بنجيبه من الـ event السابق — هنا بنستخدم placeholder
    emit(AuthOtpSent(''));
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

  // ─── تسجيل الدخول + جلب دور المستخدم من Firestore ───────────────────────
  Future<void> _signInWithCredential(
    PhoneAuthCredential credential,
    Emitter<AuthState> emit,
  ) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user!.uid;

    // جلب الـ role من Firestore
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      // مستخدم جديد — افتراضياً customer
      await _db.collection('users').doc(uid).set({
        'role': 'customer',
        'phone': userCredential.user!.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
      emit(AuthSuccess('customer'));
    } else {
      final role = doc.data()?['role'] ?? 'customer';
      emit(AuthSuccess(role));
    }
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
      default:
        return 'حصل خطأ، حاول مرة تانية';
    }
  }
}

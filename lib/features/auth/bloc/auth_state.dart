part of 'auth_bloc.dart';

abstract class AuthState {}

/// الحالة الأولية
class AuthInitial extends AuthState {}

/// جاري إرسال الـ OTP
class AuthPhoneLoading extends AuthState {}

/// تم إرسال الكود — انتقل لشاشة OTP
class AuthOtpSent extends AuthState {
  final String phoneNumber;
  AuthOtpSent(this.phoneNumber);
}

/// جاري التحقق من الكود
class AuthOtpVerifying extends AuthState {}

/// يوزر جديد — محتاج يختار الـ role
class AuthNeedsRole extends AuthState {
  final String uid;
  AuthNeedsRole(this.uid);
}

/// تم تسجيل الدخول بنجاح
class AuthSuccess extends AuthState {
  final String role; // 'customer' | 'technician' | 'admin'
  AuthSuccess(this.role);
}

/// حدث خطأ
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
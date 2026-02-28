part of 'auth_bloc.dart';

abstract class AuthEvent {}

/// فتح التطبيق — بيتحقق من الجلسة الحالية
class AppStarted extends AuthEvent {}

/// المستخدم أدخل رقم الموبايل وضغط "ارسل الكود"
class PhoneSubmitted extends AuthEvent {
  final String phoneNumber;
  PhoneSubmitted(this.phoneNumber);
}

/// Firebase بعت كود التحقق (حدث داخلي)
class VerificationCodeSent extends AuthEvent {
  final String verificationId;
  VerificationCodeSent(this.verificationId);
}

/// المستخدم أدخل الكود OTP وضغط "تحقق"
class OtpSubmitted extends AuthEvent {
  final String otp;
  OtpSubmitted(this.otp);
}

/// إعادة تعيين الحالة (مثلاً عند الرجوع)
class ResetAuth extends AuthEvent {}

/// اليوزر اختار الـ role في شاشة الاختيار
class RoleSelected extends AuthEvent {
  final String uid;
  final String role;
  RoleSelected(this.uid, this.role);
}
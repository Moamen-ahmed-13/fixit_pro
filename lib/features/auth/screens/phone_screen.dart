import 'package:fixit_pro/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // ✅ PhoneSubmitted — يطابق الـ BLoC الجديد
      context.read<AuthBloc>().add(
            PhoneSubmitted(_phoneController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // ✅ AuthOtpSent — يطابق الـ BLoC الجديد
          if (state is AuthOtpSent) {
            Navigator.pushNamed(
              context,
              '/otp',
              arguments: _phoneController.text.trim(),
            );
          }
          // ✅ AuthError — يطابق الـ BLoC الجديد
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message,
                    style: const TextStyle(fontFamily: 'Cairo')),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),

                        // ── اللوجو ─────────────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text('🔧', style: TextStyle(fontSize: 36)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textMain,
                                  ),
                                  children: [
                                    TextSpan(text: 'Fix'),
                                    TextSpan(
                                      text: 'It ',
                                      style: TextStyle(color: AppColors.primary),
                                    ),
                                    TextSpan(text: 'Pro'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'صيانة بيتك في إيدك',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 56),

                        // ── العنوان ────────────────────────────────────────
                        const Text(
                          'أهلاً بيك! 👋',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'أدخل رقم موبايلك وهنبعتلك كود تأكيد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textMuted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── حقل الموبايل ──────────────────────────────────
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textMain,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            hintText: '01x xxxx xxxx',
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              letterSpacing: 2,
                            ),
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇪🇬', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+20',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: AppColors.border,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'أدخل رقم الموبايل';
                            if (val.length < 10) return 'رقم الموبايل ناقص';
                            if (!val.startsWith('01')) return 'الرقم لازم يبدأ بـ 01';
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),

                        const SizedBox(height: 16),

                        // ── ملاحظة ─────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.2),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Text('🔒', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'بياناتك محمية ومش هتتشارك مع أي حد',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppColors.accent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── زرار الإرسال ───────────────────────────────────
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            // ✅ AuthPhoneLoading — يطابق الـ BLoC الجديد
                            final isLoading = state is AuthPhoneLoading;
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor:
                                      AppColors.primary.withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 8,
                                  shadowColor: AppColors.primary.withOpacity(0.4),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'إرسال كود التأكيد',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // ── شروط الاستخدام ────────────────────────────────
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(text: 'بالمتابعة بتوافق على '),
                                TextSpan(
                                  text: 'شروط الاستخدام',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' و'),
                                TextSpan(
                                  text: 'سياسة الخصوصية',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
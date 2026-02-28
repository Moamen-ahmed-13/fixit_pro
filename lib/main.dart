import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/phone_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/role_selector_screen.dart';
import 'features/customer/home/screens/customer_home_screen.dart';
import 'features/customer/new_request/screens/new_request_screen.dart';
import 'features/customer/tracking/screens/tracking_screen.dart';
import 'features/customer/search/screens/search_screen.dart';
import 'features/customer/orders/customer_orders_screen.dart';
import 'features/customer/profile/customer_profile_screen.dart';
import 'features/technician/dashboard/technician_home_screen.dart';
import 'features/technician/reports/screens/service_report_screen.dart';
import 'features/technician/profile/technician_profile_screen.dart';
import 'features/shared/chat/chat_screen.dart';
import 'features/shared/notifications/notifications_screen.dart';
import 'features/shared/payments/payments_screen.dart';
import 'features/admin/analytics/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FixItProApp());
}

class FixItProApp extends StatelessWidget {
  const FixItProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc()..add(AppStarted()),
      child: MaterialApp(
        title: 'FixIt Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('ar'),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const _AppRouter(),
        routes: {
          '/auth':                 (_) => const PhoneScreen(),
          '/otp':                  (_) => const OtpScreen(),
          '/role-selector':        (_) => const RoleSelectorScreen(),
          '/customer/home':        (_) => const CustomerHomeScreen(),
          '/customer/new-request': (_) => const NewRequestScreen(),
          '/customer/tracking':    (_) => const TrackingScreen(),
          '/customer/search':      (_) => const SearchScreen(),
          '/customer/orders':      (_) => const CustomerOrdersScreen(),
          '/customer/profile':     (_) => const CustomerProfileScreen(),
          '/technician/home':      (_) => const TechnicianHomeScreen(),
          '/technician/report':    (_) => const ServiceReportScreen(),
          '/technician/profile':   (_) => const TechnicianProfileScreen(),
          '/chat':                 (_) => const ChatScreen(),
          '/notifications':        (_) => const NotificationsScreen(),
          '/payments':             (_) => const PaymentsScreen(),
          '/admin/dashboard':      (_) => const AdminDashboardScreen(),
        },
      ),
    );
  }
}

// ─── App Router (Splash) ──────────────────────────────────────────────────────
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
        // ✅ يوزر جديد → شاشة اختيار الـ role
        if (state is AuthNeedsRole) {
          Navigator.pushReplacementNamed(context, '/role-selector',
              arguments: state.uid);
        }
        // ✅ AuthSuccess — يطابق الـ BLoC الجديد (بدل AuthAuthenticated)
        if (state is AuthSuccess) {
          switch (state.role) {
            case 'customer':
              Navigator.pushReplacementNamed(context, '/customer/home');
            case 'technician':
              Navigator.pushReplacementNamed(context, '/technician/home');
            case 'admin':
              Navigator.pushReplacementNamed(context, '/admin/dashboard');
          }
        }
      },
      child: const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🔧', style: TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'FixIt Pro',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
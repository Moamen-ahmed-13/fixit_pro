import 'package:fixit_pro/features/admin/analytics/admin_dashboard_screen.dart';
import 'package:fixit_pro/features/technician/dashboard/technician_home_screen.dart';
import 'package:fixit_pro/features/technician/reports/screens/service_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';

// Auth
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/phone_screen.dart';
import 'features/auth/screens/otp_screen.dart';

// Customer
import 'features/customer/home/bloc/home_bloc.dart';
import 'features/customer/home/screens/customer_home_screen.dart';
import 'features/customer/new_request/screens/new_request_screen.dart';
import 'features/customer/tracking/screens/tracking_screen.dart';
import 'features/customer/search/screens/search_screen.dart';

// Technician

// Admin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await Firebase.initializeApp();
  runApp(const FixItProApp());
}

class FixItProApp extends StatelessWidget {
  const FixItProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => AuthBloc())],
      child: MaterialApp(
        title: 'FixIt Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('ar'),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        initialRoute: '/auth',
        routes: {
          // ── Auth ────────────────────────────────────────────────────
          '/auth': (_) => const PhoneScreen(),
          '/otp': (_) => const OtpScreen(),

          // ── Customer ────────────────────────────────────────────────
          '/customer/home': (_) => const CustomerHomeScreen(),
          '/customer/new-request': (_) => const NewRequestScreen(),
          '/customer/tracking': (_) => const TrackingScreen(),
          '/customer/search': (_) => const SearchScreen(),

          // ── Technician ──────────────────────────────────────────────
          '/technician/home': (_) => const TechnicianHomeScreen(),
          '/technician/report': (_) => const ServiceReportScreen(),

          // ── Admin ───────────────────────────────────────────────────
          '/admin/dashboard': (_) => const AdminDashboardScreen(),
        },
      ),
    );
  }
}

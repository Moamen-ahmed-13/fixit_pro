import 'package:fixit_pro/features/admin/analytics/admin_dashboard_screen.dart';
import 'package:fixit_pro/features/auth/auth_bloc.dart';
import 'package:fixit_pro/features/auth/otp_screen.dart';
import 'package:fixit_pro/features/auth/phone_screen.dart';
import 'package:fixit_pro/features/customer/home/customer_home_screen.dart';
import 'package:fixit_pro/features/technician/dashboard/technician_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // شاشة vertical فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar شفافة
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
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
      ],
      child: MaterialApp(
        title: 'FixIt Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,

        // RTL عربي
        locale: const Locale('ar'),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),

        // الشاشة الأولى
        initialRoute: '/auth',
        routes: {
          '/auth':              (_) => const PhoneScreen(),
          '/otp':               (_) => const OtpScreen(),
          // هنضيف الباقي لما نبنيهم
          '/customer/home':  (_) => const CustomerHomeScreen(),
          '/technician/home':(_) => const TechnicianHomeScreen(),
          '/admin/dashboard':(_) => const AdminDashboardScreen(),
        },
      ),
    );
  }
}

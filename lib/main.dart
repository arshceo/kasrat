import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/ustad_theme.dart';
import 'features/alarm/services/alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Alarm Service and Notifications
  await AlarmService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Supabase.initialize(
    url: 'https://lombvuwhcxeiveftglur.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvbWJ2dXdoY3hlaXZlZnRnbHVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMDAwNTMsImV4cCI6MjA4OTg3NjA1M30.hFFw0pSW1SiVp_fcS6H0qmIbkEFSDm3FkIoAsyX_Eac',
  );

  runApp(
    const ProviderScope(
      child: UstadApp(),
    ),
  );
}

class UstadApp extends StatelessWidget {
  const UstadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'USTAD AI',
      debugShowCheckedModeBanner: false,
      theme: UstadTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/ustad_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/alarm/services/alarm_service.dart';
import 'core/services/settings_service.dart';
import 'core/constants/app_constants.dart';

// ----------------------------------------------------------------------
// ISOLATE 1: THE WAKE-UP ALARM
// ----------------------------------------------------------------------
@pragma('vm:entry-point')
void alarmCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AlarmService.initialize();
  print('SYSTEM: Executing Wake-Up Protocol');
  await AlarmService.triggerFullScreenIntent();
}

// ----------------------------------------------------------------------
// ISOLATE 2: THE 2-HOUR PENALTY EXECUTIONER (Silent Background Check)
// ----------------------------------------------------------------------
@pragma('vm:entry-point')
void penaltyCheckCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lombvuwhcxeiveftglur.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvbWJ2dXdoY3hlaXZlZnRnbHVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMDAwNTMsImV4cCI6MjA4OTg3NjA1M30.hFFw0pSW1SiVp_fcS6H0qmIbkEFSDm3FkIoAsyX_Eac',
  );

  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    print('SYSTEM: 2-Hour Window Expired. Checking Mission Status...');
    // Query your DB to see if today's workout is marked complete
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await supabase
        .from('missions')
        .select('status')
        .eq('user_id', user.id)
        .eq('date', today)
        .maybeSingle();

    if (response == null || response['status'] != 'COMPLETED') {
      print('SYSTEM: Mission Failed. Deducting ₹${CommercialConstants.collateralAmount}.');
      await supabase.rpc(
        'deduct_penalty',
        params: {'user_id': user.id, 'amount': CommercialConstants.collateralAmount},
      );
    } else {
      print('SYSTEM: Mission Completed. Collateral Safe.');
    }
  } catch (e) {
    print('Error during penalty check: $e');
  }
}
// ----------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('alarm_settings');

  await SettingsService().init();
  await AlarmService.initialize();
  await AlarmService.rescheduleAlarmFromHive();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvbWJ2dXdoY3hlaXZlZnRnbHVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMDAwNTMsImV4cCI6MjA4OTg3NjA1M30.hFFw0pSW1SiVp_fcS6H0qmIbkEFSDm3FkIoAsyX_Eac',
  );

  runApp(const ProviderScope(child: UstadApp()));
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

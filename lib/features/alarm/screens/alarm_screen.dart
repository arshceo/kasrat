import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/features/alarm/services/alarm_service.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  void _dismissAndStartDeathClock(BuildContext context) async {
    // 1. Stop the ringing alarm
    await AlarmProtocolService.stopAlarm();

    // 2. The 2-hour deadline was already set when the alarm was scheduled.
    // We just need to navigate the user to the Command Screen to see the countdown.
    debugPrint('SYSTEM: Alarm Dismissed. Proceeding to COMMAND.');
    context.go(AppRoutes.command);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'WAKE UP',
                  style: GoogleFonts.orbitron(
                    color: Colors.redAccent,
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'YOU HAVE 2 HOURS TO COMPLETE YOUR ASSIGNED KINETIC PROTOCOL.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'FAILURE RESULTS IN IMMEDIATE ₹${CommercialConstants.collateralAmount.toInt()} FORFEITURE.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 80),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ), // Brutalist sharp edges
                    ),
                    onPressed: () => _dismissAndStartDeathClock(context),
                    child: Text(
                      'DISMISS & START TIMER',
                      style: GoogleFonts.orbitron(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

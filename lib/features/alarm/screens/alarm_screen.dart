import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../../../main.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class AlarmScreen extends StatelessWidget {
  void _dismissAndStartDeathClock(BuildContext context) async {
    // Stop the audio player here
    // _audioPlayer.stop();

    // Schedule the Penalty Check for exactly 2 hours from now
    // ID 200 is specifically for the penalty background check
    await AndroidAlarmManager.oneShot(
      const Duration(hours: 2),
      200,
      penaltyCheckCallback, // This calls the isolate in main.dart
      exact: true,
      wakeup: true,
    );

    print('SYSTEM: 2-Hour Death Clock Started');
    Navigator.pop(context);
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

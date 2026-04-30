import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/features/dashboard/providers/workout_provider.dart';

class LoggingView extends StatelessWidget {
  final WorkoutState state;
  final TextEditingController repController;
  final FocusNode repFocusNode;

  const LoggingView({
    super.key,
    required this.state,
    required this.repController,
    required this.repFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    // Current is already incremented if we just finished, but phase is logging
    // Wait, in notifier, completeSet increments currentIndex. 
    // So if phase == logging, it means we are logging for (currentIndex - 1) if we incremented?
    // Actually, in the screen logic, we set phase to logging BEFORE calling completeSet.
    // So currentIndex is still the one we just did.
    final current = state.sets[state.currentIndex];

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('// PERFORMANCE CAPTURE', style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.neonRed, fontWeight: FontWeight.bold)),  
          const SizedBox(height: 12),
          Text(current.name, style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text('HOW MANY REPS DID YOU EXECUTE?', style: GoogleFonts.spaceMono(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 48),
          TextField(
            controller: repController,
            focusNode: repFocusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.neonRed),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              fillColor: AppColors.surfaceContainerLow,
              filled: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.outlineVariant)),     
              hintText: '00',
              hintStyle: GoogleFonts.orbitron(color: AppColors.surfaceContainerHighest),
            ),
          ),
          const SizedBox(height: 24),
          Text('GOAL WAS: ${current.targetReps} REPS', style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

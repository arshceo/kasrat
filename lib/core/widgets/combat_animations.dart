import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../audio/fauj_audio_engine.dart';

/// Global tactical feedback overlays for combat events.
class CombatAnimations {
  /// Instantly draws a 6px Red border that fades out.
  static void showRepFlash(BuildContext context) {
    FaujAudioEngine().playRep();
    
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => _RepFlashOverlay(onComplete: () => entry.remove()),
    );
    
    overlay.insert(entry);
  }

  /// Full-screen deep mission completion overlay.
  static void showMissionComplete(BuildContext context) {
    FaujAudioEngine().playMissionComplete();
    
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => _MissionCompleteOverlay(onComplete: () => entry.remove()),
    );
    
    overlay.insert(entry);
  }
}

class _RepFlashOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const _RepFlashOverlay({required this.onComplete});

  @override
  State<_RepFlashOverlay> createState() => _RepFlashOverlayState();
}

class _RepFlashOverlayState extends State<_RepFlashOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 25), // 50ms hold
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 75), // 150ms fade
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD32F2F), width: 6),
          ),
        ),
      ),
    );
  }
}

class _MissionCompleteOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const _MissionCompleteOverlay({required this.onComplete});

  @override
  State<_MissionCompleteOverlay> createState() => _MissionCompleteOverlayState();
}

class _MissionCompleteOverlayState extends State<_MissionCompleteOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Auto-remove after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onComplete());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Material(
        color: const Color(0xFF8B0000).withOpacity(0.8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              '// PROTOCOL COMPLETE',
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

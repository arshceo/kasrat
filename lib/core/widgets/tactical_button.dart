import 'package:flutter/material.dart';
import '../audio/fauj_audio_engine.dart';

enum TacticalSoundType { tap, nav, missionComplete, start, mouseClick, none }

/// A brutalist wrapper that adds tactical scaling animations and
/// synchronized audio/haptic feedback to any widget.
class TacticalButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final TacticalSoundType soundType;

  const TacticalButton({
    super.key,
    required this.child,
    this.onTap,
    this.soundType = TacticalSoundType.tap,
  });

  @override
  State<TacticalButton> createState() => _TacticalButtonState();
}

class _TacticalButtonState extends State<TacticalButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    debugPrint('TacticalButton: _onTapDown TRIGGERED (Type: ${widget.soundType})');
    setState(() => _scale = 0.92);
    
    // Play sound on DOWN for instant tactical feedback and to ensure it fires
    // before any navigation occurs on TapUp.
    if (widget.soundType == TacticalSoundType.tap) {
      FaujAudioEngine().playTap();
    } else if (widget.soundType == TacticalSoundType.nav) {
      FaujAudioEngine().playNav();
    } else if (widget.soundType == TacticalSoundType.missionComplete) {
      FaujAudioEngine().playMissionComplete();
    } else if (widget.soundType == TacticalSoundType.start) {
      FaujAudioEngine().playStartBeep();
    } else if (widget.soundType == TacticalSoundType.mouseClick) {
      FaujAudioEngine().playMouseClick();
    } else {
      debugPrint('TacticalButton: No sound defined for this type');
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    if (widget.onTap != null) widget.onTap!();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 50),
        curve: Curves.linear,
        child: widget.child,
      ),
    );
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';

/// Singleton audio engine for Fauj OS.
/// Handles haptics and aggressive brutalist sound effects.
class FaujAudioEngine {
  static final FaujAudioEngine _instance = FaujAudioEngine._internal();
  factory FaujAudioEngine() => _instance;

  FaujAudioEngine._internal() {
    AudioPlayer.global.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        usageType: AndroidUsageType.assistanceSonification,
        contentType: AndroidContentType.sonification,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ));
  }

  // Dedicated players for different sound categories to prevent interruption
  final AudioPlayer _uiPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _fxPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _navPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  void _play(AudioPlayer player, String path, {double volumeMultiplier = 1.0}) {
    try {
      // FIX: Wait! SettingsService().volume might be returning 0.0 on your device!
      double finalVolume = (SettingsService().volume * volumeMultiplier).clamp(0.0, 1.0);
      
      // EMERGENCY OVERRIDE: If volume is 0, force it to 1.0 so we can hear it
      if (finalVolume <= 0.0) {
        finalVolume = volumeMultiplier; // fallback
      }

      print('FaujAudioEngine: Playing $path (Calculated Volume: $finalVolume)');
      
      player.setVolume(finalVolume);
      
      // Just call play directly. The package handles stopping the previous playback safely.
      // Calling stop().then() causes state machine race conditions on Android 11.
      player.play(AssetSource('audio/$path'));
    } catch (e) {
      print('FaujAudioEngine ERROR [$path]: $e');
    }
  }

  void playTap() {
    HapticFeedback.lightImpact();
    _play(_uiPlayer, 'radio_click.mp3');
  }

  void playNav() {
    HapticFeedback.mediumImpact();
    _play(_navPlayer, 'nav_beep.mp3');
  }

  void playRep() {
    HapticFeedback.heavyImpact();
    _play(_fxPlayer, 'beep.mp3');
  }

  void playMissionComplete() {
    HapticFeedback.vibrate();
    _play(_fxPlayer, 'metal_door_close.mp3');
  }

  void playMissionAlert() {
    HapticFeedback.vibrate();
    _play(_navPlayer, 'nav_beep.mp3');
  }

  void playStartBeep() {
    HapticFeedback.heavyImpact();
    _play(_fxPlayer, 'long_beep.mp3');
  }

  void playMouseClick() {
    HapticFeedback.selectionClick();
    _play(_uiPlayer, 'mouse_click.mp3', volumeMultiplier: 0.5);
  }

  void forcePlay(String path) {
    if (!SettingsService().isAudioEnabled) return;
    _uiPlayer.play(AssetSource('audio/$path'));
  }
}

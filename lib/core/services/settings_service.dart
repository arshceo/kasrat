import 'package:shared_preferences/shared_preferences.dart';

enum FormStrictness { easy, medium, hard }

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  FormStrictness get getFormStrictness {
    final val = _prefs?.getString('form_strictness') ?? 'medium';
    return FormStrictness.values.firstWhere(
      (e) => e.name == val,
      orElse: () => FormStrictness.medium,
    );
  }

  Future<void> setFormStrictness(FormStrictness strictness) async {
    await _prefs?.setString('form_strictness', strictness.name);
  }

  bool get isAudioEnabled => _prefs?.getBool('is_audio_enabled') ?? true;
  Future<void> setAudioEnabled(bool enabled) async {
    await _prefs?.setBool('is_audio_enabled', enabled);
  }

  double get volume => _prefs?.getDouble('app_volume') ?? 1.0;
  Future<void> setVolume(double value) async {
    await _prefs?.setDouble('app_volume', value);
  }
}

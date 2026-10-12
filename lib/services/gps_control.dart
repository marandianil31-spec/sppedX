import 'package:shared_preferences/shared_preferences.dart';

class GpsControl {
  GpsControl._();

  static final GpsControl instance = GpsControl._();

  static const String _key = 'gps_tracking_enabled';

  bool _enabled = true;

  bool get isEnabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

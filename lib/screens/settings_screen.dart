import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/gps_control.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundAlerts = true;
  bool _vibration = true;
  bool _keepScreenOn = true;
  bool _showAverageSpeed = true;
  bool _useMph = false;
  bool _gpsTracking = true;

  bool _loading = true;

  static const Color background = Color(0xFF0B111B);
  static const Color cardColor = Color(0xFF18212F);
  static const Color accent = Color(0xFF35D9FF);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await GpsControl.instance.load();

    if (!mounted) return;

    setState(() {
      _soundAlerts = prefs.getBool('sound_alerts') ?? true;
      _vibration = prefs.getBool('vibration') ?? true;
      _keepScreenOn = prefs.getBool('keep_screen_on') ?? true;
      _showAverageSpeed =
          prefs.getBool('show_average_speed') ?? true;
      _useMph = prefs.getBool('use_mph') ?? false;
      _gpsTracking = GpsControl.instance.isEnabled;
      _loading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _changeSetting(
    String key,
    bool value,
    void Function(bool) update,
  ) async {
    setState(() => update(value));
    await _saveSetting(key, value);
  }

  Future<void> _changeGpsTracking(bool value) async {
    await GpsControl.instance.setEnabled(value);

    if (!mounted) return;

    setState(() {
      _gpsTracking = value;
    });

    _showMessage(
      value
          ? 'GPS tracking enabled. Open Speedometer to start.'
          : 'GPS tracking disabled.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'SpeedX',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.speed,
        color: accent,
        size: 42,
      ),
      applicationLegalese: 'Your journey. Your speed.',
      children: const [
        SizedBox(height: 12),
        Text(
          'SpeedX is a GPS-based speedometer app '
          'for tracking speed and trip distance.',
        ),
        SizedBox(height: 8),
        Text(
          'GPS readings may vary depending on your '
          'device, signal and surroundings.',
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        top: 24,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: accent,
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF173B55),
                  Color(0xFF18212F),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.settings_suggest,
                  size: 42,
                  color: accent,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customize SpeedX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Make your driving experience yours.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _sectionTitle('GPS CONTROL'),

          _settingTile(
            icon: Icons.gps_fixed,
            title: 'GPS Tracking',
            subtitle: _gpsTracking
                ? 'GPS tracking is enabled'
                : 'GPS tracking is disabled',
            value: _gpsTracking,
            onChanged: _changeGpsTracking,
          ),

          _sectionTitle('SPEEDOMETER'),

          _settingTile(
            icon: Icons.speed,
            title: 'Speed Unit',
            subtitle: _useMph
                ? 'Miles per hour (mph)'
                : 'Kilometers per hour (km/h)',
            value: _useMph,
            onChanged: (value) => _changeSetting(
              'use_mph',
              value,
              (v) => _useMph = v,
            ),
          ),

          _settingTile(
            icon: Icons.analytics_outlined,
            title: 'Average Speed',
            subtitle: 'Show average speed during a trip',
            value: _showAverageSpeed,
            onChanged: (value) => _changeSetting(
              'show_average_speed',
              value,
              (v) => _showAverageSpeed = v,
            ),
          ),

          _sectionTitle('EXPERIENCE'),

          _settingTile(
            icon: Icons.volume_up_outlined,
            title: 'Sound Alerts',
            subtitle: 'Enable speed alert sounds',
            value: _soundAlerts,
            onChanged: (value) => _changeSetting(
              'sound_alerts',
              value,
              (v) => _soundAlerts = v,
            ),
          ),

          _settingTile(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Enable vibration feedback',
            value: _vibration,
            onChanged: (value) => _changeSetting(
              'vibration',
              value,
              (v) => _vibration = v,
            ),
          ),

          _settingTile(
            icon: Icons.phone_android,
            title: 'Keep Screen On',
            subtitle: 'Preference for keeping the display awake',
            value: _keepScreenOn,
            onChanged: (value) => _changeSetting(
              'keep_screen_on',
              value,
              (v) => _keepScreenOn = v,
            ),
          ),

          _sectionTitle('ABOUT'),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: accent,
              ),
              title: const Text(
                'About SpeedX',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.white60),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.white54,
              ),
              onTap: _showAbout,
            ),
          ),

          const SizedBox(height: 28),

          const Center(
            child: Text(
              'SPEEDX • YOUR JOURNEY, YOUR SPEED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

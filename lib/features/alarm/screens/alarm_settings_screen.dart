import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/alarm_service.dart';

class AlarmSettingsScreen extends StatefulWidget {
  const AlarmSettingsScreen({super.key});

  @override
  State<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}

class _AlarmSettingsScreenState extends State<AlarmSettingsScreen> {
  TimeOfDay? _selectedTime;
  final Box _alarmBox = Hive.box('alarm_settings');
  bool _hasPermissions = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadSavedTime();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isCheckingPermissions = true);
    
    // Check Notification and Exact Alarm permissions
    final notificationStatus = await Permission.notification.status;
    
    // For Android 12+, we need scheduleExactAlarm
    bool exactAlarmGranted = true;
    if (await Permission.scheduleExactAlarm.isDenied) {
      exactAlarmGranted = false;
    }

    setState(() {
      _hasPermissions = notificationStatus.isGranted && exactAlarmGranted;
      _isCheckingPermissions = false;
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await _checkPermissions();
  }

  void _loadSavedTime() {
    final savedHour = _alarmBox.get('hour');
    final savedMinute = _alarmBox.get('minute');
    if (savedHour != null && savedMinute != null) {
      setState(() => _selectedTime = TimeOfDay(hour: savedHour, minute: savedMinute));
    }
  }

  Future<void> _pickTime() async {
    if (!_hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CRITICAL: ALARM PERMISSIONS REQUIRED FOR PROTOCOL.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.red,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
      _scheduleAlarm(picked);
    }
  }

  void _scheduleAlarm(TimeOfDay time) {
    AlarmProtocolService.setDailyAlarm(time.hour, time.minute);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PROTOCOL ARMED: ${time.format(context)} daily.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('ALARM PROTOCOL', style: GoogleFonts.orbitron(color: Colors.red, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isCheckingPermissions 
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_hasPermissions) ...[
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'PERMISSIONS DENIED',
                  style: GoogleFonts.orbitron(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'USTAD CANNOT WAKE YOU UP WITHOUT NOTIFICATION & EXACT ALARM ACCESS.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _requestPermissions,
                  child: Text('GRANT ACCESS', style: GoogleFonts.orbitron(color: Colors.white)),
                ),
              ] else ...[
                Text('DAILY WAKEUP TARGET', style: GoogleFonts.spaceMono(color: Colors.grey)),
                const SizedBox(height: 16),
                Text(
                  _selectedTime?.format(context) ?? '--:--',
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: _pickTime,
                  child: Text('MODIFY TARGET', style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                Text(
                  'STRICT 2-HOUR PENALTY WINDOW APPLIES AFTER THIS TIME.',
                  style: GoogleFonts.spaceMono(color: Colors.red.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

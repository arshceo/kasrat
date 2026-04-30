import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/alarm_service.dart';

class AlarmSettingsScreen extends StatefulWidget {
  const AlarmSettingsScreen({super.key});

  @override
  State<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}

class _AlarmSettingsScreenState extends State<AlarmSettingsScreen> {
  TimeOfDay? _selectedTime;
  final Box _alarmBox = Hive.box('alarm_settings');

  @override
  void initState() {
    super.initState();
    _loadSavedTime();
  }

  void _loadSavedTime() {
    final savedHour = _alarmBox.get('hour');
    final savedMinute = _alarmBox.get('minute');
    if (savedHour != null && savedMinute != null) {
      setState(() => _selectedTime = TimeOfDay(hour: savedHour, minute: savedMinute));
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.red, surface: Colors.black),
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
    // Uses the existing background isolate logic in AlarmService
    AlarmService.setDailyAlarm(time.hour, time.minute);
    debugPrint('SYSTEM: Alarm armed for ${time.hour}:${time.minute}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text('PROTOCOL SETTINGS', style: GoogleFonts.orbitron(color: Colors.red))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('WAKEUP TIME', style: GoogleFonts.spaceGrotesk(color: Colors.grey)),
            const SizedBox(height: 10),
            Text(
              _selectedTime?.format(context) ?? '--:--',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              onPressed: _pickTime,
              child: Text('SET TARGET', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

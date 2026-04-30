import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'active_mission_screen.dart';
import 'armory_screen.dart';

class CommandTabRouter extends StatefulWidget {
  const CommandTabRouter({super.key});

  @override
  State<CommandTabRouter> createState() => _CommandTabRouterState();
}

class _CommandTabRouterState extends State<CommandTabRouter> {
  bool _isLoading = true;
  bool _isPaid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkMissionStatus();
  }

  Future<void> _checkMissionStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = "USER NOT AUTHENTICATED.";
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select('is_paid')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _isPaid = response?['is_paid'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "DB LINK FAILURE: \$e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.neonRed),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Text(
            _errorMessage!,
            style: GoogleFonts.spaceMono(color: AppColors.danger),
          ),
        ),
      );
    }

    return _isPaid ? const ActiveMissionScreen() : const ArmoryScreen();
  }
}

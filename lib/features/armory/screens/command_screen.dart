import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/features/alarm/services/alarm_service.dart';

class CommandScreen extends StatefulWidget {
  const CommandScreen({super.key});

  @override
  State<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends State<CommandScreen> {
  final _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _challengeStream;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  bool _isTimerActive = false;

  @override
  void initState() {
    super.initState();
    // Silences the alarm immediately upon entry
    AlarmProtocolService.stopAlarm();
    
    final userId = _supabase.auth.currentUser!.id;
    
    // Stream the latest challenge for this user
    _challengeStream = _supabase
        .from('daily_challenges')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);
  }

  void _startCountdown(DateTime deadline) {
    if (_isTimerActive) return;
    _isTimerActive = true;
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = deadline.difference(now);

      if (difference.isNegative) {
        timer.cancel();
        _isTimerActive = false;
        _handleFailure(); 
      } else {
        if (mounted) {
          setState(() {
            _timeRemaining = difference;
          });
        }
      }
    });
  }

  Future<void> _handleFailure() async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      // Find the latest active challenge and mark as failed
      final latest = await _supabase
          .from('daily_challenges')
          .select('id, status')
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latest != null) {
        await _supabase
            .from('daily_challenges')
            .update({'status': 'failed'})
            .eq('id', latest['id']);
        
        // Also wipe profile balance to sync legacy views
        await _supabase
            .from('profiles')
            .update({'staked_balance': 0, 'challenge_status': 'failed'})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error processing failure: $e');
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _restartRazorpayFlow() async {
    final uri = Uri.parse('https://ustad.ai'); // Your terminal/payment link
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _challengeStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('COMMUNICATIONS ERROR', style: GoogleFonts.spaceMono(color: AppColors.neonRed)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildNoActiveChallenge();
          }

          final challenge = snapshot.data!.first;
          final status = challenge['status'] as String;
          final balance = challenge['stake_amount'] ?? 0;
          final deadlineStr = challenge['deadline_time'] as String?;
          
          if (status == 'active' && deadlineStr != null) {
            _startCountdown(DateTime.parse(deadlineStr).toLocal());
          } else {
            _countdownTimer?.cancel();
            _isTimerActive = false;
          }

          final isFailed = status == 'failed';
          final isActive = status == 'active';

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(isFailed),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatusIndicator(status),
                          const SizedBox(height: 40),
                          Text(
                            'CURRENT CHALLENGE STAKE',
                            style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10, letterSpacing: 2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isFailed ? '₹0' : '₹$balance',
                            style: GoogleFonts.orbitron(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: isFailed ? AppColors.danger : AppColors.neonRed,
                              shadows: [
                                if (!isFailed)
                                  const Shadow(color: AppColors.redGlow, blurRadius: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                          
                          if (isActive) ...[
                            _buildActiveTimerView(),
                          ] else if (isFailed) ...[
                            _buildFailureView(),
                          ] else if (status == 'pending') ...[
                            _buildPendingView(),
                          ] else if (status == 'completed') ...[
                            _buildSuccessView(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool failed) {
    return Container(
      width: double.infinity,
      color: failed ? AppColors.danger : AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'COMMAND CENTER v2.0',
            style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              failed ? 'STATUS: COMPROMISED' : 'STATUS: SECURE',
              style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    final bool failed = status == 'failed';
    final bool active = status == 'active';
    
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: failed ? AppColors.danger : (active ? Colors.amber : AppColors.neonRed), 
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          failed ? Icons.lock_open : (active ? Icons.timer : Icons.security),
          size: 48,
          color: failed ? AppColors.danger : (active ? Colors.amber : AppColors.neonRed),
        ),
      ),
    );
  }

  Widget _buildActiveTimerView() {
    return Column(
      children: [
        Text(
          'PENALTY WINDOW EXPIRES IN:',
          style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          _formatDuration(_timeRemaining),
          style: GoogleFonts.orbitron(
            fontSize: 48,
            color: _timeRemaining.inMinutes < 15 ? AppColors.danger : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neonRed.withOpacity(0.5)),
            color: AppColors.redGlow.withOpacity(0.1),
          ),
          child: Column(
            children: [
              Text(
                'ACTION REQUIRED',
                style: GoogleFonts.orbitron(color: AppColors.neonRed, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'COMPLETE YOUR ASSIGNED DRILL IMMEDIATELY TO PROTECT YOUR STAKE.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 10),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context), // Go back to dashboard to start workout
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonRed,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: Text('COMMENCE DRILL', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFailureView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            'PROTOCOL BREACHED',
            style: GoogleFonts.orbitron(color: AppColors.danger, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            'YOU FAILED TO COMPLETE THE DRILL WITHIN THE 2-HOUR WINDOW. YOUR STAKE HAS BEEN FORFEITED.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: _restartRazorpayFlow,
            child: Text(
              'STAKE AGAIN FOR TOMORROW', 
              style: GoogleFonts.orbitron(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingView() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 32),
        const SizedBox(height: 12),
        Text(
          'STAKE VERIFIED',
          style: GoogleFonts.orbitron(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'AWAITING NEXT ALARM SIGNAL...',
          style: GoogleFonts.spaceMono(color: Colors.white24, fontSize: 10, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const Icon(Icons.verified, color: AppColors.success, size: 48),
        const SizedBox(height: 16),
        Text(
          'MISSION ACCOMPLISHED',
          style: GoogleFonts.orbitron(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'YOUR STAKE IS SECURE. PREPARE FOR TOMORROW\'S DEPLOYMENT.',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildNoActiveChallenge() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 64),
          const SizedBox(height: 24),
          Text(
            'NO ACTIVE PROTOCOL',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'YOU MUST STAKE COLLATERAL TO START THE DISCIPLINE PROTOCOL.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _restartRazorpayFlow,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonRed),
            child: Text('STAKE NOW', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

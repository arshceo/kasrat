import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'dart:async';
import 'dart:math';

class DeploymentAuthScreen extends StatefulWidget {
  final String protocolId;
  final String protocolTitle;

  const DeploymentAuthScreen({
    super.key,
    required this.protocolId,
    required this.protocolTitle,
  });

  @override
  State<DeploymentAuthScreen> createState() => _DeploymentAuthScreenState();
}

class _DeploymentAuthScreenState extends State<DeploymentAuthScreen> {
  late String _authCode;
  bool _isPaid = false;
  bool _isLoading = true;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _authCode = _generateMemorableCode();
    _syncCodeToDatabase();
    _checkPaymentStatus();
    _startRealtimeSync();

    // Auto-copy on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Clipboard.setData(ClipboardData(text: _authCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AUTH CODE AUTO-COPIED TO CLIPBOARD'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  String _generateMemorableCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _syncCodeToDatabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('terminals').upsert({
        'id': user.id, // Using user ID as primary key for the terminal session
        'user_id': user.id,
        'code': _authCode,
        'protocol_id': widget.protocolId,
        'status': 'PENDING',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  void _startRealtimeSync() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _statusSubscription = Supabase.instance.client
        .from('terminals')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final status = data.first['status'];
            if (status == 'AUTHORIZED') {
              setState(() {
                _isPaid = true;
              });
            }
          }
        });
  }

  Future<void> _checkPaymentStatus() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final terminal = await Supabase.instance.client
            .from('terminals')
            .select('status')
            .eq('id', user.id)
            .maybeSingle();
        
        if (mounted && terminal != null) {
          setState(() {
            _isPaid = terminal['status'] == 'AUTHORIZED';
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchTerminal() async {
    // Auto-copy for convenience
    await Clipboard.setData(ClipboardData(text: _authCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CODE COPIED TO CLIPBOARD')),
      );
    }

    final uri = Uri.parse('https://ustad.ai'); // Replace with actual home page URL if different
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const SizedBox(height: 40),
              Text(
                'DEPLOYMENT AUTHENTICATION',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'SKIN IN THE GAME REQUIRED',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: AppColors.neonRed,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    Text(
                      'YOUR AUTHENTICATION CODE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _authCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CODE COPIED TO CLIPBOARD')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        color: Colors.black,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _authCode,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 28, // Increased for visibility
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.neonRed,
                                  letterSpacing: 8, // More space between chars
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Icon(Icons.copy, size: 24, color: AppColors.neonRed),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TAP TO COPY CODE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Copy this code and paste it into the Ustad Terminal to authorize your deployment.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.neonRed))
              else if (_isPaid)
                Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'PAYMENT VERIFIED',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.greenAccent,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AUTHENTICATION SUCCESSFUL.\nDEPLOYMENT AUTHORIZED.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TacticalButton(
                      onTap: _launchTerminal,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        color: Colors.white,
                        child: Center(
                          child: Text(
                            'GO TO WEBSITE',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                TacticalButton(
                  onTap: _launchTerminal,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: AppColors.neonRed,
                    child: Center(
                      child: Text(
                        'GO TO WEBSITE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Waiting for external verification...',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
}

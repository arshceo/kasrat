import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/features/auth/services/auth_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasrat_ai/features/dashboard/providers/dashboard_provider.dart';

class DeploymentAuthScreen extends ConsumerStatefulWidget {
  final String protocolId;
  final String protocolTitle;
  final int durationDays;
  final String userName;

  const DeploymentAuthScreen({
    super.key,
    required this.protocolId,
    required this.protocolTitle,
    required this.durationDays,
    required this.userName,
  });

  @override
  ConsumerState<DeploymentAuthScreen> createState() => _DeploymentAuthScreenState();
}

class _DeploymentAuthScreenState extends ConsumerState<DeploymentAuthScreen> {
  String? _authCode;       // Null until resolved from DB or generated fresh
  bool _isPaid = false;
  bool _isSyncing = true;  // True until we finish writing to DB
  bool _isInitialising = true; // True during first load
  StreamSubscription? _statusSubscription;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    // Step 1: Check if we ALREADY have an active terminal (code) in the DB.
    // Only generate a new code if there isn't one already for this user.
    _initTerminal();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  String _generateMemorableCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Entry point: Checks for an existing pending terminal before doing anything.
  Future<void> _initTerminal() async {
    setState(() => _isInitialising = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Check if there's already a terminal record for this user
      final existing = await Supabase.instance.client
          .from('terminals')
          .select('code, status')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (existing != null) {
        final existingStatus = existing['status'] as String?;
        final existingCode = existing['code'] as String?;

        if (existingStatus == 'AUTHORIZED') {
          // Terminal says AUTHORIZED — but we MUST verify the profile is actually paid.
          // The previous payment may have updated the terminal but failed to update profiles (RLS).
          // Trusting terminal alone causes a false "Payment Verified" state.
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('is_paid')
              .eq('id', user.id)
              .maybeSingle();

          if (!mounted) return;

          final isPaidInProfile = profile?['is_paid'] == true;

          if (isPaidInProfile) {
            // Both terminal AND profile confirm payment — genuine success
            setState(() {
              _authCode = existingCode ?? _generateMemorableCode();
              _isPaid = true;
              _isSyncing = false;
              _isInitialising = false;
            });
            return;
          } else {
            // Terminal is AUTHORIZED but profile is NOT paid — stale terminal from a failed payment.
            // Reset to PENDING with a fresh code so the user can pay again cleanly.
            debugPrint('STALE AUTHORIZED terminal detected. Profile is_paid=false. Resetting...');
            final freshCode = _generateMemorableCode();
            setState(() {
              _authCode = freshCode;
              _isInitialising = false;
            });
            await _syncCodeToDatabase(freshCode);
            _startRealtimeSync();
            _startHeartbeat();
            _autoCopyCode();
            return;
          }
        } else if (existingCode != null && existingCode.isNotEmpty) {
          // There's an existing PENDING code — reuse it so the website can still find it
          setState(() {
            _authCode = existingCode;
            _isSyncing = false;
            _isInitialising = false;
          });
          debugPrint('REUSING existing terminal code: $_authCode');
          _startRealtimeSync();
          _startHeartbeat();
          _autoCopyCode();
          return;
        }
      }

      // No existing record — generate a fresh code and write it
      final newCode = _generateMemorableCode();
      setState(() {
        _authCode = newCode;
        _isInitialising = false;
      });
      await _syncCodeToDatabase(newCode);
      _startRealtimeSync();
      _startHeartbeat();
      _autoCopyCode();
    } catch (e) {
      debugPrint('Terminal init error: $e');
      if (mounted) setState(() => _isInitialising = false);
    }
  }

  void _autoCopyCode() {
    if (_authCode == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: _authCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AUTH CODE AUTO-COPIED TO CLIPBOARD'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  Future<void> _syncCodeToDatabase(String code) async {
    setState(() => _isSyncing = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String finalName = '';

      final profile = await AuthService.getProfile();
      if (profile != null && profile['display_name'] != null) {
        final dbName = (profile['display_name'] as String).trim();
        if (dbName.isNotEmpty && dbName.toUpperCase() != 'RECRUIT') {
          finalName = dbName;
        }
      }

      if (finalName.isEmpty) {
        final metaName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
        if (metaName != null && metaName.toString().trim().isNotEmpty) {
          finalName = metaName.toString().trim();
        }
      }

      if (finalName.isEmpty) {
        final email = user.email;
        if (email != null && email.contains('@')) {
          finalName = email.split('@')[0].toUpperCase();
        }
      }

      if (finalName.isEmpty) finalName = 'OPERATOR';

      debugPrint('Syncing terminal: id=${user.id} code=$code name=$finalName');

      await Supabase.instance.client.from('terminals').upsert({
        'id': user.id,
        'user_id': user.id,
        'user_name': finalName,
        'code': code,
        'protocol_id': widget.protocolId,
        'protocol_title': widget.protocolTitle,
        'duration_days': widget.durationDays,
        'status': 'PENDING',
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() => _isSyncing = false);
        debugPrint('Terminal sync SUCCESS: $code');
      }
    } on PostgrestException catch (e) {
      debugPrint('Postgrest Error: ${e.message} (${e.code})');
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SYNC ERROR: ${e.message.toUpperCase()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      debugPrint('Sync error: $e');
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _startRealtimeSync() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _statusSubscription?.cancel();
    _statusSubscription = Supabase.instance.client
        .from('terminals')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final status = data.first['status'];
            if (status == 'AUTHORIZED' && !_isPaid) {
              _onPaymentAuthorized();
            }
          }
        });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _isPaid) {
        timer.cancel();
        return;
      }
      _silentStatusCheck(); // Does NOT set _isLoading — no spinner flash
    });
  }

  /// Polls the DB without showing a loading spinner (heartbeat use only)
  Future<void> _silentStatusCheck() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final terminal = await Supabase.instance.client
          .from('terminals')
          .select('status')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      if (terminal != null && terminal['status'] == 'AUTHORIZED' && !_isPaid) {
        _onPaymentAuthorized();
      }
    } catch (e) {
      debugPrint('Heartbeat check error: $e');
    }
  }

  /// Called when payment is confirmed — updates UI, refreshes dashboard, then pops
  void _onPaymentAuthorized() {
    HapticFeedback.heavyImpact();
    setState(() => _isPaid = true);
    _heartbeatTimer?.cancel();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _goToDashboard();
    });
  }

  void _goToDashboard() {
    // Force a full profile re-fetch so dashboard shows updated mission immediately
    ref.read(dashboardProvider.notifier).initialize();
    Navigator.of(context).pop();
  }

  Future<void> _launchTerminal() async {
    if (_authCode != null) {
      await Clipboard.setData(ClipboardData(text: _authCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CODE COPIED TO CLIPBOARD')),
        );
      }
    }

    final uri = Uri.parse('https://ustadai.vercel.app/');
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

                // Code display box
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: _isInitialising
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.neonRed),
                        )
                      : Column(
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
                                if (_authCode == null) return;
                                Clipboard.setData(ClipboardData(text: _authCode!));
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
                                        _authCode ?? '------',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.neonRed,
                                          letterSpacing: 8,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (_isSyncing)
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.neonRed,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
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

                // Action area — no isLoading spinner; only reacts to _isPaid
                if (_isPaid)
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
                        onTap: _goToDashboard,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              'BACK TO DASHBOARD',
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
                  Column(
                    children: [
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white30,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'WAITING FOR PAYMENT VERIFICATION...',
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
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

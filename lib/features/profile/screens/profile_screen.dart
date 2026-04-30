import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/services/settings_service.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';
import '../../auth/services/auth_service.dart';
import '../../leaderboard/logic/league_engine.dart';

/// Screen B-04: DISCIPLINE PROFILE — Account, permissions, re-calibrate, logout.
/// Design: Stitch "Discipline Profile" HTML — brutalist, zero rounding.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  List<dynamic> _history = [];
  bool _isLoading = true;
  DateTime? _lastMetricsDate;
  int? _hoverIndex; // For graph scrubbing
  bool _showVolumeSlider = false;

  String get currentLeague {
    if (_profile == null) return 'UNCLASSIFIED';

    final hasBaseline =
        (_profile!['baseline_squats'] ?? 0) > 0 &&
        (_profile!['baseline_pushups'] ?? 0) > 0;

    return LeagueEngine.calculateLeague(
      pushups: (_profile!['max_pushups'] as int?) ?? 0,
      squats: (_profile!['max_squats'] as int?) ?? 0,
      situps: (_profile!['max_situps'] as int?) ?? 0,
      challengesWon: (_profile!['challenges_won'] as int?) ?? 0,
      hasCompletedBaseline: hasBaseline,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getProfile();
    final user = Supabase.instance.client.auth.currentUser;

    DateTime? lastDate;
    List<dynamic> history = [];

    if (user != null) {
      try {
        final historyRes = await Supabase.instance.client
            .from('user_metrics_history')
            .select()
            .eq('user_id', user.id)
            .order('logged_at', ascending: true);

        history = historyRes;

        // Auto-heal: If profile has data but history is empty, create first log
        if (history.isEmpty &&
            profile != null &&
            profile['height_cm'] != null &&
            profile['weight_kg'] != null) {
          final firstLog = {
            'user_id': user.id,
            'height_cm': profile['height_cm'],
            'weight_kg': profile['weight_kg'],
            'logged_at': DateTime.now().toIso8601String(),
          };
          await Supabase.instance.client
              .from('user_metrics_history')
              .insert(firstLog);
          history = [firstLog];
        }

        if (history.isNotEmpty) {
          lastDate = DateTime.parse(history.last['logged_at']).toLocal();
        }
      } catch (e) {
        debugPrint('Error loading metrics history: $e');
      }
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _history = history;
        _lastMetricsDate = lastDate;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 4, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text(
                    'LOGOUT?',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFF2A2A2A)),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to logout? Your progress will be saved, but you will need to sign in again to continue.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: const Color(0xFF2A2A2A),
                        alignment: Alignment.center,
                        child: Text(
                          'STAY',
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: AppColors.danger,
                        alignment: Alignment.center,
                        child: Text(
                          'CONFIRM LOGOUT',
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            color: Colors.white,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true && mounted) {
      await AuthService.signOut();
      if (mounted) context.go(AppRoutes.bouncerLogin);
    }
  }

  Future<void> _deleteLog(String logId) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 4, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text(
                    'DELETE LOG?',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'This record will be deleted forever. Are you sure?',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: const Color(0xFF2A2A2A),
                        alignment: Alignment.center,
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: AppColors.danger,
                        alignment: Alignment.center,
                        child: Text(
                          'DELETE',
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            color: Colors.white,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Delete the log
      await Supabase.instance.client
          .from('user_metrics_history')
          .delete()
          .eq('id', logId);

      // 2. Refresh local state
      await _loadProfile();

      // 3. Sync profile table if needed
      // If we just deleted the log that was current, _loadProfile above updated _profile from db,
      // but we might need to push the 'new' latest to profiles table if it wasn't already there.
      if (_history.isNotEmpty) {
        final latest = _history.last;
        await Supabase.instance.client
            .from('profiles')
            .update({
              'height_cm': latest['height_cm'],
              'weight_kg': latest['weight_kg'],
            })
            .eq('id', user.id);
      } else {
        // No logs left? Optionally clear or keep last known.
        // We'll keep clear for consistency.
        await Supabase.instance.client
            .from('profiles')
            .update({'height_cm': null, 'weight_kg': null})
            .eq('id', user.id);
      }

      // Final re-load to ensure everything is in sync
      await _loadProfile();
    } catch (e) {
      debugPrint('Error deleting log: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final currentDay = (_profile?['current_day'] as int?) ?? 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neonRed,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildOperativeCard(user, currentDay),
                          const SizedBox(height: 20),
                          _buildPersonalBests(),
                          const SizedBox(height: 20),
                          _buildBodyMetrics(),
                          const SizedBox(height: 20),
                          _buildProgressGraph(),
                          const SizedBox(height: 20),
                          _buildActionSection(context),
                          const SizedBox(height: 20),
                          _buildRankTestingSection(context),
                          const SizedBox(height: 12),
                          _buildOperativeControl(),
                          const SizedBox(height: 20),
                          _buildTerminateButton(),
                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              'BETA_V1.0',
                              style: GoogleFonts.orbitron(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted.withOpacity(0.5),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.military_tech_outlined,
            color: AppColors.neonRed,
            size: 18,
          ),
          const SizedBox(width: 10),
          if (!_showVolumeSlider)
            Expanded(
              child: Text(
                'MY FITNESS PROFILE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 3,
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.neonRed,
                        inactiveTrackColor: AppColors.surfaceContainerHigh,
                        thumbColor: Colors.white,
                        overlayColor: AppColors.neonRed.withOpacity(0.2),
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: SettingsService().volume,
                        onChanged: (val) {
                          setState(() {
                            SettingsService().setVolume(val);
                            // Auto-mute if pulled to zero
                            if (val == 0) {
                              SettingsService().setAudioEnabled(false);
                            } else if (!SettingsService().isAudioEnabled) {
                              SettingsService().setAudioEnabled(true);
                            }
                          });
                        },
                        onChangeEnd: (val) {
                          if (val == 0) {
                            FaujAudioEngine().forcePlay('radio_click.mp3');
                          } else if (val == 1.0) {
                            FaujAudioEngine().forcePlay('beep.mp3');
                          }
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${(SettingsService().volume * 100).toInt()}%',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      FaujAudioEngine().playMouseClick();
                      setState(() => _showVolumeSlider = false);
                    },
                    child: Text(
                      'CLOSE',
                      style: GoogleFonts.orbitron(
                        fontSize: 8,
                        color: AppColors.neonRed,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            onPressed: () async {
              if (!_showVolumeSlider) {
                setState(() => _showVolumeSlider = true);
                FaujAudioEngine().playMouseClick();
                return;
              }
              final current = SettingsService().isAudioEnabled;
              final turningOn = !current;
              await SettingsService().setAudioEnabled(turningOn);
              if (turningOn) {
                FaujAudioEngine().forcePlay('beep.mp3');
              } else {
                FaujAudioEngine().forcePlay('radio_click.mp3');
              }
              setState(() {});
            },
            icon: Icon(
              !SettingsService().isAudioEnabled
                  ? Icons.volume_off_rounded
                  : SettingsService().volume == 0
                  ? Icons.volume_mute_rounded
                  : SettingsService().volume < 0.5
                  ? Icons.volume_down_rounded
                  : Icons.volume_up_rounded,
              color: SettingsService().isAudioEnabled
                  ? AppColors.neonRed
                  : AppColors.textMuted,
              size: 24,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBests() {
    final squats = (_profile?['baseline_squats'] as int?) ?? 0;
    final pushups = (_profile?['baseline_pushups'] as int?) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// MY BEST RECORDS',
          style: GoogleFonts.orbitron(
            fontSize: 9,
            color: AppColors.textMuted,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPBItem('SQUATS', squats, Icons.expand_more)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPBItem(
                'PUSHUPS',
                pushups,
                Icons.keyboard_double_arrow_up,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPBItem(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.neonRed, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 8,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            'MAX REPS',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetrics() {
    final height = (_profile?['height_cm'] as num?)?.toDouble() ?? 0.0;
    final weight = (_profile?['weight_kg'] as num?)?.toDouble() ?? 0.0;

    String lastUpdated = '--';
    if (_lastMetricsDate != null) {
      lastUpdated =
          '${_lastMetricsDate!.day}/${_lastMetricsDate!.month}/${_lastMetricsDate!.year}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '// BODY MEASUREMENTS',
              style: GoogleFonts.orbitron(
                fontSize: 9,
                color: AppColors.textMuted,
                letterSpacing: 3,
              ),
            ),
            Text(
              'UPDATED: $lastUpdated',
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                color: AppColors.neonRed.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FaujAudioEngine().playMouseClick();
                  _showHistoryDialog();
                },
                child: _buildMetricMiniCard(
                  'HEIGHT',
                  height > 0 ? height.toStringAsFixed(1) : '--',
                  'CM',
                  Icons.straighten,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FaujAudioEngine().playMouseClick();
                  _showHistoryDialog();
                },
                child: _buildMetricMiniCard(
                  'WEIGHT',
                  weight > 0 ? weight.toStringAsFixed(1) : '--',
                  'KG',
                  Icons.monitor_weight_outlined,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressGraph() {
    final hasData = _history.isNotEmpty;
    final firstDate = hasData
        ? DateTime.parse(_history.first['logged_at']).toLocal()
        : DateTime.now();
    final firstDateStr = hasData
        ? '${firstDate.day}/${firstDate.month}'
        : '--/--';

    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '// WEIGHT PROGRESS',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: AppColors.neonRed,
                  letterSpacing: 3,
                ),
              ),
              const Icon(Icons.show_chart, color: AppColors.neonRed, size: 14),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onPanUpdate: hasData && _history.length > 1
                ? (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final localPos = details.localPosition;
                    setState(() {
                      final stepX =
                          (box.size.width - 40) / (_history.length - 1);
                      double normalizedX = (localPos.dx - 20).clamp(
                        0,
                        box.size.width - 40,
                      );
                      _hoverIndex = (normalizedX / stepX).round().clamp(
                        0,
                        _history.length - 1,
                      );
                    });
                  }
                : null,
            onPanEnd: (_) => setState(() => _hoverIndex = null),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: _MetricLineChartPainter(
                      data: _history
                          .map((e) => (e['weight_kg'] as num).toDouble())
                          .toList(),
                      hoverIndex: _hoverIndex,
                      history: _history,
                    ),
                  ),
                  if (!hasData)
                    Center(
                      child: Text(
                        'LOG YOUR WEIGHT TO SEE PROGRESS',
                        style: GoogleFonts.orbitron(
                          fontSize: 8,
                          color: AppColors.textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOG: $firstDateStr',
                style: GoogleFonts.spaceMono(
                  fontSize: 8,
                  color: AppColors.textMuted,
                ),
              ),
              if (_hoverIndex != null)
                Text(
                  'SCRUBBING: ${_history[_hoverIndex!]['weight_kg']}KG',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    color: AppColors.neonRed,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (hasData)
                Text(
                  'CURRENT: ${_history.last['weight_kg']}KG',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  'NO DATA',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricMiniCard(
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 8,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperativeCard(dynamic user, int currentDay) {
    final name =
        (_profile?['display_name'] as String?)?.toUpperCase() ?? 'RECRUIT';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(left: BorderSide(color: AppColors.neonRed, width: 4)),
      ),
      child: Row(
        children: [
          // Emblem / Insignia
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withOpacity(0.5),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                1,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
                0,
                1,
                1,
                1,
                0,
                -0.1,
              ]),
              child: Image.asset(
                _getInsigniaPath(currentLeague),
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_outline,
                  color: AppColors.neonRed,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentLeague.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonRed,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (_profile?['age'] != null)
                      _buildInlineDetail('AGE', '${_profile?['age']}'),
                    if (_profile?['gender'] != null)
                      _buildInlineDetail(
                        'SEX',
                        (_profile?['gender'] as String).toUpperCase(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Day badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.neonRed,
            child: Column(
              children: [
                Text(
                  'DAY',
                  style: GoogleFonts.orbitron(
                    fontSize: 7,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$currentDay',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 7,
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// ACTIONS',
          style: GoogleFonts.orbitron(
            fontSize: 9,
            color: AppColors.textMuted,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),

        // REDO STRENGTH TEST button — primary monolith
        GestureDetector(
          onTap: () async {
            await context.push(AppRoutes.strengthTestSetup);
            _loadProfile();
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RE-TAKE STRENGTH TEST',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Update your starting strength level',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // NEW: Log Progress button (Quick Log)
        GestureDetector(
          onTap: () async {
            await context.push(AppRoutes.progressLog);
            _loadProfile();
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.neonRed.withOpacity(0.9),
              border: Border.all(color: AppColors.neonRed),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_chart, color: Colors.black, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOG PROGRESS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'RECORD NEW WEIGHT & BODY DIMENSIONS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.black.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Update Bio details button
        GestureDetector(
          onTap: () async {
            await context.push(AppRoutes.userMetrics);
            _loadProfile();
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPDATE BIO DETAILS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'EDIT AGE, GENDER, OR HEIGHT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // View History button
        GestureDetector(
          onTap: () => _showHistoryDialog(),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VIEW LOG HISTORY',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Review previous dimension logs',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperativeControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// ACCOUNT SETTINGS', // Renamed for clarity and consistency
          style: GoogleFonts.orbitron(
            fontSize: 9,
            color: AppColors.textMuted,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        _settingsRow(
          Icons.notifications_active_outlined,
          'ALARM PROTOCOLS',
          'Set your wake-up time',
          onTap: () => context.push(AppRoutes.alarmSettings),
        ),
        const SizedBox(height: 8),
        _settingsRow(
          Icons.language_outlined,
          'LANGUAGE',
          'Urdu / Hindi / English',
          onTap: () => context.push(AppRoutes.languageSelection),
        ),
        const SizedBox(height: 8),
        _buildStrictnessRow(),
      ],
    );
  }

  Widget _buildStrictnessRow() {
    final currentStrictness = SettingsService().getFormStrictness.name
        .toUpperCase();

    return GestureDetector(
      onTap: () => _showStrictnessDialog(),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF1A1A1A),
        child: Row(
          children: [
            const Icon(
              Icons.accessibility_new_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FORM STRICTNESS: $currentStrictness',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Adjust range of motion requirements',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStrictnessDialog() async {
    final strictness = await showDialog<FormStrictness>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CHOOSE FORM SETTINGS',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFF2A2A2A)),
              const SizedBox(height: 16),
              _buildStrictnessOption(
                ctx,
                FormStrictness.easy,
                'EASY',
                'Forgiving range of motion. Recommended for beginners or users with mobility limits.',
              ),
              const SizedBox(height: 8),
              _buildStrictnessOption(
                ctx,
                FormStrictness.medium,
                'MEDIUM',
                'Standard. Solid range of motion for adequate results.',
              ),
              const SizedBox(height: 8),
              _buildStrictnessOption(
                ctx,
                FormStrictness.hard,
                'HARD',
                'Ass to grass strict. Full extension required. No cheating.',
              ),
            ],
          ),
        ),
      ),
    );

    if (strictness != null && mounted) {
      await SettingsService().setFormStrictness(strictness);
      setState(() {});
    }
  }

  Widget _buildStrictnessOption(
    BuildContext context,
    FormStrictness value,
    String title,
    String desc,
  ) {
    final isActive = SettingsService().getFormStrictness == value;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.neonRed.withOpacity(0.1)
              : const Color(0xFF1A1A1A),
          border: Border.all(
            color: isActive ? AppColors.neonRed : const Color(0xFF2A2A2A),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isActive ? AppColors.neonRed : AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF1A1A1A),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 20,
            ), // Standardized
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminateButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.06),
          border: Border.all(color: AppColors.danger.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.power_settings_new,
              color: AppColors.danger,
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              'LOGOUT',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.danger,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog() {
    // Reverse the pre-loaded history for descending chips in list
    final listHistory = _history.reversed.toList();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PAST LOGS',
                style: GoogleFonts.orbitron(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFF2A2A2A)),
              const SizedBox(height: 16),
              if (listHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'NO LOGS FOUND.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: listHistory.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = listHistory[index];
                      final date = DateTime.parse(item['logged_at']).toLocal();
                      final dateStr = '${date.day}/${date.month}/${date.year}';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFF1A1A1A),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 10,
                                      color: AppColors.neonRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'HT: ${item['height_cm']} CM',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item['weight_kg']} KG',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              if (listHistory.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _deleteLog(listHistory.first['id']);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'DELETE LAST LOG',
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        color: AppColors.danger,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: const Color(0xFF2A2A2A),
                  alignment: Alignment.center,
                  child: Text(
                    'BACK',
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankTestingSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.neonRed.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hub_outlined,
                color: AppColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'SYSTEM TESTS',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Preview jaw-dropping rank unlock animations.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppColors.textMuted.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTestRankButton(
                context,
                'RECRUIT',
                'assets/images/recruit.png',
              ),
              _buildTestRankButton(
                context,
                'SOLDIER',
                'assets/images/soldier.png',
              ),
              _buildTestRankButton(
                context,
                'COMMANDO',
                'assets/images/commando.png',
              ),
              _buildTestRankButton(
                context,
                'BLACK OPS',
                'assets/images/black_ops.png',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestRankButton(
    BuildContext context,
    String rankName,
    String assetPath,
  ) {
    return GestureDetector(
      onTap: () {
        FaujAudioEngine().playTap();
        context.push(
          AppRoutes.rankUnlocked,
          extra: {'rankName': rankName, 'insigniaPath': assetPath},
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2A2A2A)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          rankName,
          style: GoogleFonts.orbitron(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MetricLineChartPainter extends CustomPainter {
  final List<double> data;
  final int? hoverIndex;
  final List<dynamic> history;

  _MetricLineChartPainter({
    required this.data,
    this.hoverIndex,
    required this.history,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid lines behind (always visible for premium look)
    final gridPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (data.isEmpty) return;

    // 2. Draw horizontal baseline for single log
    if (data.length == 1) {
      final y = size.height / 2;
      final baselinePaint = Paint()
        ..color = AppColors.neonRed.withOpacity(0.5)
        ..strokeWidth = 2;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), baselinePaint);

      // Also draw a small indicator dot at the end
      canvas.drawCircle(
        Offset(size.width, y),
        4,
        Paint()..color = Colors.white,
      );
      return;
    }

    // 3. Draw Trend Line for 2+ logs
    final paint = Paint()
      ..color = AppColors.neonRed
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.neonRed.withOpacity(0.3),
          AppColors.neonRed.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final minVal = data.reduce((a, b) => a < b ? a : b) * 0.98;
    final maxVal = data.reduce((a, b) => a > b ? a : b) * 1.02;
    final range = maxVal - minVal;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Hover effect
    if (hoverIndex != null) {
      final hIdx = hoverIndex!;
      final hX = hIdx * stepX;
      final hY = size.height - ((data[hIdx] - minVal) / range * size.height);

      // Vertical line
      final hoverLinePaint = Paint()
        ..color = Colors.white24
        ..strokeWidth = 1;
      canvas.drawLine(Offset(hX, 0), Offset(hX, size.height), hoverLinePaint);

      // Data point dot
      canvas.drawCircle(Offset(hX, hY), 6, Paint()..color = AppColors.neonRed);
      canvas.drawCircle(Offset(hX, hY), 3, Paint()..color = Colors.white);

      // Label
      final date = DateTime.parse(history[hIdx]['logged_at']).toLocal();
      final dateStr = '${date.day}/${date.month}';

      _drawText(
        canvas,
        '${data[hIdx]}KG | $dateStr',
        Offset(hX, hY - 20),
        size,
      );
    } else {
      // Default endpoint dot
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(
          size.width,
          size.height - ((data.last - minVal) / range * size.height),
        ),
        4,
        dotPaint,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.spaceMono(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Adjust position to stay in bounds
    double x = position.dx - (textPainter.width / 2);
    if (x < 0) x = 0;
    if (x + textPainter.width > size.width) x = size.width - textPainter.width;

    textPainter.paint(canvas, Offset(x, position.dy));
  }

  @override
  bool shouldRepaint(covariant _MetricLineChartPainter oldDelegate) {
    return oldDelegate.hoverIndex != hoverIndex;
  }
}

String _getInsigniaPath(String league) {
  final l = league.toLowerCase();
  if (l.contains('black ops')) return 'assets/images/black_ops.png';
  if (l.contains('commando')) return 'assets/images/commando.png';
  if (l.contains('soldier')) return 'assets/images/soldier.png';
  return 'assets/images/recruit.png';
}

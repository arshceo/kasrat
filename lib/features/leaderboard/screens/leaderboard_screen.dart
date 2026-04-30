import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import '../logic/league_engine.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _topOperatives = [];
  Map<String, dynamic>? _currentUserProfile;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  int _safeInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  Future<void> _fetchLeaderboard({bool force = false}) async {
    // Prevent double-fetching if already in a refresh state
    if (_isRefreshing && force) return;

    setState(() {
      if (force) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;

      // 1. Fetch all assessed users
      final response = await Supabase.instance.client
          .from('profiles')
          .select(
            'display_name, email, current_league, max_pushups, max_squats, max_situps, baseline_pushups, baseline_squats, challenges_won, created_at, id',
          );

      final List<Map<String, dynamic>> rawProfiles =
          List<Map<String, dynamic>>.from(response);

      // Deduplicate by ID
      final Map<String, Map<String, dynamic>> uniqueMap = {};
      for (var p in rawProfiles) {
        if (p['id'] != null) uniqueMap[p['id']] = p;
      }
      final List<Map<String, dynamic>> profiles = uniqueMap.values.toList();

      // 2. Identify current user's profile
      if (user != null) {
        _currentUserProfile = profiles.firstWhere(
          (p) => p['id'] == user.id,
          orElse: () => {},
        );
      }

      // 3. Sorting Logic
      profiles.sort((a, b) {
        final int aMaxP = _safeInt(a['max_pushups']);
        final int aBaseP = _safeInt(a['baseline_pushups']);
        final int aMaxS = _safeInt(a['max_squats']);
        final int aBaseS = _safeInt(a['baseline_squats']);
        final int aSit = _safeInt(a['max_situps']);

        final totalA =
            (aMaxP > aBaseP ? aMaxP : aBaseP) +
            (aMaxS > aBaseS ? aMaxS : aBaseS) +
            aSit;

        final int bMaxP = _safeInt(b['max_pushups']);
        final int bBaseP = _safeInt(b['baseline_pushups']);
        final int bMaxS = _safeInt(b['max_squats']);
        final int bBaseS = _safeInt(b['baseline_squats']);
        final int bSit = _safeInt(b['max_situps']);

        final totalB =
            (bMaxP > bBaseP ? bMaxP : bBaseP) +
            (bMaxS > bBaseS ? bMaxS : bBaseS) +
            bSit;

        // Priority 1: Total Reps
        if (totalB != totalA) return totalB.compareTo(totalA);

        // Priority 2: Challenges Won
        final chA = a['challenges_won'] ?? 0;
        final chB = b['challenges_won'] ?? 0;
        if (chB != chA) return chB.compareTo(chA);

        // Priority 3: Creation Date (Older wins)
        final dateA =
            DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final dateB =
            DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      if (mounted) {
        setState(() {
          _topOperatives = profiles;
          _isLoading = false;
          _isRefreshing = false;
          if (force) _lastRefreshTime = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('ERROR FETCHING LEADERBOARD: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _handleManualRefresh() {
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inSeconds < 60) {
      final remaining = 60 - now.difference(_lastRefreshTime!).inSeconds;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PROTOCOL RELOAD IN COOLDOWN: $remaining SECONDS REMAINING',
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          backgroundColor: AppColors.neonRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _fetchLeaderboard(force: true);
  }

  String _getInsigniaPath(String leagueName) {
    final l = leagueName.toLowerCase();
    if (l.contains('legendary')) return 'assets/images/legendary.png';
    if (l.contains('black ops')) return 'assets/images/black_ops.png';
    if (l.contains('commando')) return 'assets/images/commando.png';
    if (l.contains('soldier') || l.contains('candidate')) {
      return 'assets/images/soldier.png';
    }
    return 'assets/images/recruit.png';
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is unassessed (no pushups OR squats baseline recorded)
    final bool isUnassessed =
        (_currentUserProfile?['baseline_pushups'] ?? 0) == 0 &&
        (_currentUserProfile?['baseline_squats'] ?? 0) == 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                if (_currentUserProfile != null) _buildPersonalCombatHUD(),
                Expanded(child: _buildWarzoneList()),
              ],
            ),

            // Rankings are now always visible
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.neonRed),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'WARZONE RANKINGS',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              TacticalButton(
                soundType: TacticalSoundType.mouseClick,
                onTap: _isRefreshing ? () {} : _handleManualRefresh,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.refresh,
                    color: _isRefreshing
                        ? AppColors.textMuted
                        : AppColors.neonRed.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),
              if (_isRefreshing)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.neonRed,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCombatHUD() {
    final bool isUnassessed =
        (_currentUserProfile?['baseline_pushups'] ?? 0) <= 0 &&
        (_currentUserProfile?['baseline_squats'] ?? 0) <= 0;

    final league = isUnassessed
        ? 'UNCLASSIFIED'
        : (_currentUserProfile?['current_league'] ?? 'RECRUIT')
              .toString()
              .toUpperCase();

    int targetPush = 30;
    int targetSquat = 40;
    int targetSit = 30;
    String nextLeague = 'SOLDIER';
    bool maxed = false;

    if (league.contains('COMMANDO')) {
      targetPush = 100;
      targetSquat = 100;
      targetSit = 100;
      nextLeague = 'BLACK OPS (OPM PROTOCOL)';
    } else if (league.contains('SOLDIER') || league.contains('CANDIDATE')) {
      if (league.contains('SOLDIER') && !league.contains('CANDIDATE')) {
        targetPush = 60;
        targetSquat = 80;
        targetSit = 50;
        nextLeague = 'COMMANDO';
      } else {
        targetPush = 30;
        targetSquat = 40;
        targetSit = 30;
        nextLeague = 'SOLDIER';
      }
    }

    if (league.contains('BLACK OPS')) maxed = true;

    final int maxP = (_currentUserProfile?['max_pushups'] ?? 0) as int;
    final int baseP = (_currentUserProfile?['baseline_pushups'] ?? 0) as int;
    final curPush = maxP > baseP ? maxP : baseP;

    final int maxS = (_currentUserProfile?['max_squats'] ?? 0) as int;
    final int baseS = (_currentUserProfile?['baseline_squats'] ?? 0) as int;
    final curSquat = maxS > baseS ? maxS : baseS;

    final curSit = (_currentUserProfile?['max_situps'] ?? 0) as int;

    if (maxed) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        color: AppColors.neonRed.withOpacity(0.1),
        child: Text(
          '// MAX OPERATIONAL CAPACITY REACHED',
          textAlign: TextAlign.center,
          style: GoogleFonts.orbitron(
            color: AppColors.neonRed,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TacticalButton(
                      soundType: TacticalSoundType.nav,
                      onTap: () {
                        context.push(
                          AppRoutes.rankUnlocked,
                          extra: {
                            'rankName': league,
                            'insigniaPath': _getInsigniaPath(league),
                            'isSilent': true,
                          },
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                1, 0, 0, 0, 0,
                                0, 1, 0, 0, 0,
                                0, 0, 1, 0, 0,
                                2, 2, 2, 0, -0.4,
                              ]),
                              child: Image.asset(
                                _getInsigniaPath(league),
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.shield,
                                      color: Colors.white10,
                                      size: 24,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT LEAGUE',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white54,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                league,
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TacticalButton(
                      soundType: TacticalSoundType.nav,
                      onTap: () {
                        context.push(
                          AppRoutes.rankUnlocked,
                          extra: {
                            'rankName': nextLeague,
                            'insigniaPath': _getInsigniaPath(nextLeague),
                            'isSilent': true,
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neonRed.withOpacity(0.05),
                          border: Border.all(
                            color: AppColors.neonRed.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                1, 0, 0, 0, 0,
                                0, 1, 0, 0, 0,
                                0, 0, 1, 0, 0,
                                2, 2, 2, 0, -0.4,
                              ]),
                              child: Image.asset(
                                _getInsigniaPath(nextLeague),
                                height: 28,
                                width: 28,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'NEXT UP: $nextLeague',
                              style: GoogleFonts.orbitron(
                                color: AppColors.neonRed,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TacticalButton(
                soundType: TacticalSoundType.nav,
                onTap: _showIntelSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.neonRed,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    '[ LEAGUES ]',
                    style: GoogleFonts.spaceMono(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHUDBar('PUSHUPS', curPush, targetPush),
          const SizedBox(height: 12),
          _buildHUDBar('SQUATS', curSquat, targetSquat),
          const SizedBox(height: 12),
          _buildHUDBar('SITUPS', curSit, targetSit),
        ],
      ),
    );
  }

  Widget _buildHUDBar(String label, int current, int target) {
    double progress = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.spaceMono(fontSize: 10),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  TextSpan(
                    text: '$current / $target',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.spaceMono(
                color: AppColors.neonRed,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF333333),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonRed),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  void _showIntelSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '// CLASSIFIED LEAGUE THRESHOLDS',
                        style: GoogleFonts.orbitron(
                          color: AppColors.neonRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildIntelRow(
                        '[Ω] LEGENDARY (APEX OPERATIVE)',
                        '200 PUSH | 200 SQUAT | 200 SIT',
                        AppColors.neonRed,
                        'assets/images/legendary.png',
                      ),
                      const SizedBox(height: 20),
                      _buildIntelRow(
                        '[X] BLACK OPS (OPM PROTOCOL)',
                        '100 PUSH | 100 SQUAT | 100 SIT',
                        Colors.white,
                        'assets/images/black_ops.png',
                      ),
                      const SizedBox(height: 20),
                      _buildIntelRow(
                        '>>> COMMANDO',
                        '60 PUSH | 80 SQUAT | 50 SIT',
                        Colors.white,
                        'assets/images/commando.png',
                      ),
                      const SizedBox(height: 20),
                      _buildIntelRow(
                        '>> SOLDIER',
                        '30 PUSH | 40 SQUAT | 30 SIT',
                        Colors.white,
                        'assets/images/soldier.png',
                      ),
                      const SizedBox(height: 20),
                      _buildIntelRow(
                        '> RECRUIT',
                        'ENLISTED & ACTIVE',
                        Colors.white,
                        'assets/images/recruit.png',
                      ),
                    ],
                  ),
                ),
              ),
              // Sticky Close Button
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: TacticalButton(
                    soundType: TacticalSoundType.tap,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        color: Colors.black,
                      ),
                      child: Center(
                        child: Text(
                          'CLOSE',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntelRow(
    String rank,
    String requirements,
    Color textColor,
    String insigniaPath,
  ) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
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
              insigniaPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.shield, color: Colors.white10, size: 24),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rank,
                style: GoogleFonts.orbitron(
                  color: textColor.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  requirements,
                  maxLines: 1,
                  style: GoogleFonts.spaceMono(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarzoneList() {
    final List<Map<String, dynamic>> operatives = _topOperatives;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final int myIndex = operatives.indexWhere(
      (op) => op['id'] == currentUserId,
    );

    // Create the display list (duplicates user at top if found)
    final List<Map<String, dynamic>?> itemsToDisplay = operatives.isEmpty
        ? List.generate(10, (i) => null)
        : (myIndex != -1 ? [operatives[myIndex], ...operatives] : operatives);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: itemsToDisplay.length,
      itemBuilder: (context, index) {
        final operative = itemsToDisplay[index];
        final bool isPinned =
            index == 0 && myIndex != -1 && operative?['id'] == currentUserId;

        // Use true rank for the pinned item, otherwise sequential
        final int displayRank = isPinned
            ? (myIndex + 1)
            : (myIndex != -1 ? index : index + 1);

        final bool isMe = operative?['id'] == currentUserId;

        String name =
            operative?['display_name'] ??
            operative?['email']?.split('@')[0] ??
            'DUMMY_OPERATIVE';

        if (isPinned) {
          name = '$name [PINNED]';
        } else if (isMe) {
          name = '$name [YOU]';
        }

        final int curPush =
            _safeInt(operative?['max_pushups']) >
                _safeInt(operative?['baseline_pushups'])
            ? _safeInt(operative?['max_pushups'])
            : _safeInt(operative?['baseline_pushups']);
        final int curSquat =
            _safeInt(operative?['max_squats']) >
                _safeInt(operative?['baseline_squats'])
            ? _safeInt(operative?['max_squats'])
            : _safeInt(operative?['baseline_squats']);
        final int curSit = _safeInt(operative?['max_situps'] ?? 0);
        final int curWins = _safeInt(operative?['challenges_won'] ?? 0);

        final String league = LeagueEngine.calculateLeague(
          pushups: curPush,
          squats: curSquat,
          situps: curSit,
          challengesWon: curWins,
          hasCompletedBaseline: true, // Force ranking for display
        ).toUpperCase();

        final bool isAWOL =
            (operative?['current_league']?.toString().toUpperCase().contains(
              'AWOL',
            ) ??
            false);

        final total = curPush + curSquat + curSit;

        final String insigniaPath = _getInsigniaPath(league);

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: isMe
                ? AppColors.neonRed.withOpacity(0.15)
                : (isPinned
                      ? Colors.white.withOpacity(0.1)
                      : (index % 2 != 0
                            ? Colors.white.withOpacity(0.08)
                            : Colors.transparent)),
            collapsedBackgroundColor: isMe
                ? AppColors.neonRed.withOpacity(0.2)
                : (isPinned
                      ? Colors.white.withOpacity(0.05)
                      : (index % 2 != 0
                            ? Colors.white.withOpacity(0.1)
                            : Colors.transparent)),
            leading: SizedBox(
              width: 100, // Adjusted for larger boxed icon
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '#$displayRank',
                      style: GoogleFonts.spaceMono(
                        color: isPinned
                            ? AppColors.neonRed
                            : (operative == null
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (operative != null)
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      alignment: Alignment.center,
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
                          2,
                          2,
                          2,
                          0,
                          -0.4,
                        ]),
                        child: Image.asset(
                          insigniaPath,
                          height: 40, // Larger logo
                          width: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.shield,
                                color: Colors.white24,
                                size: 16,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            title: Text(
              name.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.spaceGrotesk(
                color: isMe
                    ? AppColors.neonRed
                    : (operative == null
                          ? Colors.white.withOpacity(0.15)
                          : AppColors.textPrimary),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            subtitle: Text(
              league,
              style: GoogleFonts.spaceMono(
                color: isMe
                    ? Colors.white
                    : (isAWOL
                          ? Colors.yellow
                          : (operative == null
                                ? Colors.white.withOpacity(0.05)
                                : AppColors.textMuted)),
                fontSize: 10,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  operative == null ? '---' : total.toString(),
                  style: GoogleFonts.orbitron(
                    color: AppColors.neonRed,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'TOTAL OUTPUT',
                  style: GoogleFonts.inter(
                    color: Colors.white24,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            children: [
              if (operative != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(left: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    border: Border(
                      left: BorderSide(color: AppColors.neonRed, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDossierStat('PUSH', curPush),
                      _buildDossierStat('SQUAT', curSquat),
                      _buildDossierStat('SIT', curSit),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDossierStat(String label, dynamic value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 9),
        ),
        Text(
          value.toString(),
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

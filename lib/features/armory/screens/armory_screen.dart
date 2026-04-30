import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/core/services/ustad_ai_service.dart';
import '../../auth/services/auth_service.dart';
import '../models/protocol.dart';

class ArmoryScreen extends StatefulWidget {
  const ArmoryScreen({super.key});

  @override
  State<ArmoryScreen> createState() => _ArmoryScreenState();
}

class _ArmoryScreenState extends State<ArmoryScreen> {
  String _selectedCategory = 'ALL';
  int _selectedDuration = 28;
  bool _isGeneratingProtocol = false;
  List<Protocol> _protocols = List.from(staticProtocols);
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersistedDossiers();
  }

  Future<void> _loadPersistedDossiers() async {
    try {
      final profile = await AuthService.getProfile();
      final List<dynamic> jsonList = profile?['ai_challenge_dossiers'] as List<dynamic>? ?? [];
      final Map<String, dynamic>? activeJson = profile?['active_protocol_data'] as Map<String, dynamic>?;
      
      final List<Protocol> loaded = jsonList.map((j) {
        final map = j as Map<String, dynamic>;
        return _mapJsonToProtocol(map);
      }).toList();

      if (activeJson != null) {
        final activeProtocol = _mapJsonToProtocol(activeJson);
        // Ensure active is in the list, if not already there by ID
        if (!loaded.any((p) => p.id == activeProtocol.id)) {
          loaded.insert(0, activeProtocol);
        }
      }

      if (loaded.isNotEmpty) {
        setState(() {
          _protocols = loaded;
        });
      }
    } catch (e) {
      debugPrint('Error loading persisted dossiers: $e');
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Protocol _mapJsonToProtocol(Map<String, dynamic> map) {
    return Protocol(
      id: map['id'],
      title: map['title'],
      durationDays: map['durationDays'],
      difficulty: map['difficulty'],
      bgIcon: IconData(map['bgIconCode'] ?? Icons.bolt.codePoint, fontFamily: 'MaterialIcons'),
      exerciseFocus: map['exerciseFocus'],
      outcomes: List<String>.from(map['outcomes'] ?? []),
      exercises: List<String>.from(map['exercises'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      description: map['description'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      imagePath: map['imagePath'] ?? 'assets/images/muscle_schematic.jpg',
      isRecommended: map['isRecommended'] ?? false,
    );
  }

  final List<String> _categories = [
    'ALL',
    'STRENGTH',
    'FAT LOSS',
    'DISCIPLINE',
  ];

  @override
  Widget build(BuildContext context) {
    // Filter based on tags manually for now or add category field to model
    var filteredProtocols = _selectedCategory == 'ALL'
        ? List<Protocol>.from(_protocols)
        : _protocols.where((p) {
            final category = _selectedCategory.toUpperCase();
            return p.tags.any((t) {
              final tag = t.toUpperCase();
              if (category == 'STRENGTH' && tag.contains('STRENGTH')) return true;
              if (category == 'FAT LOSS' && (tag.contains('FAT') || tag.contains('LOSE'))) return true;
              if (category == 'DISCIPLINE' && (tag.contains('HABIT') || tag.contains('DISCIPLINE'))) return true;
              return tag == category;
            });
          }).toList();

    // Task 3: Sort AI recommended to the top
    filteredProtocols.sort((a, b) {
      if (a.isRecommended && !b.isRecommended) return -1;
      if (!a.isRecommended && b.isRecommended) return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryPicker(),
            Expanded(
              child: _isInitialLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.neonRed))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                itemCount: filteredProtocols.length,
                itemBuilder: (context, index) {
                  final protocol = filteredProtocols[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildChallengeCard(context, protocol),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'CHOOSE YOUR CHALLENGE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a 28-day curriculum designed to transform your physique and discipline.',
            style: GoogleFonts.rajdhani(
               fontSize: 15,
               color: AppColors.textSecondary,
               fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _isGeneratingProtocol
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.neonRed),
                )
                : Column(
                    children: [
                      _buildDurationPicker(),
                      const SizedBox(height: 12),
                      TacticalButton(
                        onTap: _generateDynamicDossier,
                        soundType: TacticalSoundType.start,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.neonRed.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.neonRed),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, color: AppColors.neonRed, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'GENERATE AI DOSSIER',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ],
      ),
    );
  }

  Future<void> _generateDynamicDossier() async {
    setState(() => _isGeneratingProtocol = true);
    
    // Simulate tactical delay for "intelligence gathering"
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      final profile = await AuthService.getProfile();
      final pushupMax = profile?['baseline_pushups'] as int? ?? 10;
      final squatMax = profile?['baseline_squats'] as int? ?? 15;
      final age = profile?['age']?.toString();
      final gender = profile?['gender'] as String?;
      final weight = (profile?['weight_kg'] as num?)?.toDouble();
      final height = (profile?['height_cm'] as num?)?.toDouble();
      final persona = profile?['commander_persona'] as String?;

      final service = UstadAiService();
      final dossiers = await service.generateChallengeDossier(
        pushupMax: pushupMax,
        squatMax: squatMax,
        age: age,
        gender: gender,
        weightKg: weight,
        heightCm: height,
        durationDays: _selectedDuration,
        primaryGoal: 'Elite multi-path physiological optimization.',
      );

      final List<Protocol> newProtocols = dossiers.map((dossier) {
        return Protocol(
          id: 'ai_gen_${dossier.protocolName}_${DateTime.now().millisecondsSinceEpoch}',
          title: dossier.protocolName.isNotEmpty ? dossier.protocolName.toUpperCase() : 'OPERATIONAL DOSSIER',
          durationDays: _selectedDuration,
          difficulty: dossier.difficultyTag,
          bgIcon: Icons.psychology,
          exerciseFocus: dossier.difficultyTag,
          outcomes: dossier.guaranteedOutcomes,
          exercises: dossier.coreArsenal,
          instructions: [
            'Dossier Rationale: ${dossier.systemRationale}',
            ...dossier.roadmapPhases.map((e) => '${e['phase_title']}: ${e['phase_objective']}')
          ],
          description: dossier.systemRationale,
          tags: [dossier.tag.toUpperCase()],
          imagePath: 'assets/images/muscle_schematic.jpg',
          isRecommended: true,
        );
      }).toList();

      // MERGE WITH EXISTING DOSSIERS
      final latestProfile = await AuthService.getProfile();
      final List<dynamic> existingJsonList = latestProfile?['ai_challenge_dossiers'] as List<dynamic>? ?? [];
      final List<Protocol> mergedProtocols = existingJsonList.map((j) => _mapJsonToProtocol(j as Map<String, dynamic>)).toList();

      for (var p in newProtocols) {
        if (!mergedProtocols.any((merged) => merged.title == p.title)) {
          mergedProtocols.insert(0, p);
        }
      }
      
      // Keep only last 8 dossiers to prevent bloat
      if (mergedProtocols.length > 8) {
        mergedProtocols.removeRange(8, mergedProtocols.length);
      }

      final Map<String, dynamic>? activeJson = latestProfile?['active_protocol_data'] as Map<String, dynamic>?;
      if (activeJson != null) {
        final activeProtocol = _mapJsonToProtocol(activeJson);
        if (!mergedProtocols.any((p) => p.id == activeProtocol.id)) {
          mergedProtocols.insert(0, activeProtocol);
        }
      }

      setState(() {
        _protocols = mergedProtocols;
      });

      // PERSIST TO DATABASE
      final List<Map<String, dynamic>> jsonToSave = mergedProtocols.map((p) => {
        'id': p.id,
        'title': p.title,
        'durationDays': p.durationDays,
        'difficulty': p.difficulty,
        'bgIconCode': p.bgIcon.codePoint,
        'exerciseFocus': p.exerciseFocus,
        'outcomes': p.outcomes,
        'exercises': p.exercises,
        'instructions': p.instructions,
        'description': p.description,
        'tags': p.tags,
        'imagePath': p.imagePath,
        'isRecommended': p.isRecommended,
      }).toList();

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'ai_challenge_dossiers': jsonToSave})
            .eq('id', userId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('INTEL RECEIVED: MULTI-OBJECTIVE DOSSIERS COMPILED', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    } catch (e) {
      debugPrint('AI Gen Error: $e');
      if (mounted) {
        // TACTICAL ERROR HANDLING: Instead of saying "it broke", we frame it as a comms delay or Ustad being busy.
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black,
            shape: const RoundedRectangleBorder(side: BorderSide(color: AppColors.neonRed)),
            title: Text('COMMUNICATIONS INTERFERENCE', 
                style: GoogleFonts.spaceMono(color: AppColors.neonRed, fontWeight: FontWeight.bold)),
            content: Text(
              'THE COMMAND CENTER IS CURRENTLY EXPERIENCING HIGH LATENCY OR RECRUIT OVERLOAD.\n\nUSTAD IS BUSY ANALYZING OTHER RECRUITS. RETRY IN 60 SECONDS.',
              style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('[ ACKNOWLEDGED ]', style: GoogleFonts.spaceMono(color: AppColors.neonRed)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingProtocol = false);
    }
  }

  Widget _buildDurationPicker() {
    final durations = [7, 15, 28, 60];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT OPERATIONAL WINDOW (DAYS):',
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: durations.map((d) {
            final isSelected = _selectedDuration == d;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TacticalButton(
                soundType: TacticalSoundType.mouseClick,
                onTap: () => setState(() => _selectedDuration = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.neonRed : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.neonRed : const Color(0xFF2A2A2A),
                    ),
                  ),
                  child: Text(
                    '$d',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return TacticalButton(
            soundType: TacticalSoundType.mouseClick,
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.neonRed : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '[ $cat ]',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF555555),
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, Protocol protocol) {
    return TacticalButton(
      onTap: () {
        context.push(AppRoutes.challengeDetails, extra: protocol);
      },
      soundType: TacticalSoundType.nav,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          border: Border.all(
            color: protocol.isRecommended
                ? AppColors.neonRed
                : const Color(0xFF2A2A2A),
            width: protocol.isRecommended ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (protocol.isRecommended)
              Container(
                color: AppColors.neonRed,
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                child: Text(
                  '// TARGET MATCH: AI OPTIMIZED FOR YOUR BASELINE',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                  ),
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.darken,
                    child: CustomPaint(
                      foregroundPainter: ScanlinePainter(),
                      child: Image.asset(
                        protocol.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            protocol.bgIcon,
                            size: 60,
                            color: AppColors.neonRed.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: AppColors.neonRed,
                    child: Text(
                      protocol.difficulty.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    protocol.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    protocol.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'DUR: ${protocol.durationDays} DAYS | FOCUS: ${protocol.exerciseFocus.toUpperCase()}',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFFAAAAAA),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import '../../auth/services/auth_service.dart';

/// W-00: Audio Protocol — Language Selection.
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;
  final FlutterTts _tts = FlutterTts();

  final _languages = [
    _LanguageOption(
      'pa',
      'PUNJABI',
      'REGIONAL_01',
      'FREQUENCY: HIGH_INTENSITY',
      0.33,
      Icons.volume_up,
    ),
    _LanguageOption(
      'hi',
      'HINDI',
      'REGIONAL_02',
      'FREQUENCY: DISCIPLINE_CORE',
      1.0,
      Icons.check_circle,
    ),
    _LanguageOption(
      'en',
      'ENGLISH',
      'GLOBAL_01',
      'FREQUENCY: NEUTRAL_COMMAND',
      0.25,
      Icons.language,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(0.8);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (_selectedLanguage == null) return;
    await _tts.stop();
    await AuthService.updateProfile(language: _selectedLanguage!);
    if (mounted) context.go(AppRoutes.commanderSelection);
  }

  Future<void> _selectLanguage(_LanguageOption lang) async {
    setState(() => _selectedLanguage = lang.code);
    await _tts.stop();

    String tagline = "";
    if (lang.code == 'pa') {
      await _tts.setLanguage('pa-IN');
      tagline = "ਉਸਤਾਦ ਤੁਹਾਨੂੰ ਤੋੜੇਗਾ";
    } else if (lang.code == 'hi') {
      await _tts.setLanguage('hi-IN');
      tagline = "उस्ताद तुम्हें तोड़ेगा";
    } else {
      await _tts.setLanguage('en-US');
      tagline = "THE USTAD WILL BREAK YOU";
    }

    await _tts.speak(tagline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.terminal,
                        color: AppColors.neonRed,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'USTAD AI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonRed,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'STATION_W-00',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonRed.withValues(alpha: 0.5),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.sensors,
                        color: AppColors.neonRed.withValues(alpha: 0.8),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '01',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonRed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'INITIALIZE\nAUDIO PROTOCOL',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.0,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'SELECT COMMAND VOICE FREQUENCY. LANGUAGE LOCK IS PERMANENT FOR DURATION OF PROTOCOL.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Language Cards
                  ..._languages.map((lang) {
                    final isSelected = _selectedLanguage == lang.code;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildLanguageCard(lang, isSelected),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Metadata Footer
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceGlass,
                            border: Border(
                              left: BorderSide(
                                color: AppColors.neonRed,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VOICE_ENGINE',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'NEURAL_USTAD_V4.2',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGlass,
                            border: Border(
                              left: BorderSide(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LATENCY',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '0.042MS [LINK]',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40), // Space for bottom button
                ],
              ),
            ),

            // Fixed Bottom Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedLanguage != null ? _proceed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonRed,
                  disabledBackgroundColor: AppColors.surfaceGlass,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 24,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            color: _selectedLanguage != null
                                ? Colors.white
                                : AppColors.textMuted,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'PROCEED TO PROFILING',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: _selectedLanguage != null
                                    ? Colors.white
                                    : AppColors.textMuted,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_right_alt,
                      color: _selectedLanguage != null
                          ? Colors.white
                          : AppColors.textMuted,
                      size: 28,
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

  Widget _buildLanguageCard(_LanguageOption lang, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        height: 140,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceGlass.withValues(alpha: 0.7)
              : AppColors.surfaceGlass.withValues(alpha: 0.3),
          border: Border.all(
            color: isSelected ? AppColors.neonRed : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.neonRed.withValues(alpha: 0.15),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                isSelected ? Icons.check_circle : lang.icon,
                color: isSelected
                    ? AppColors.neonRed
                    : AppColors.textMuted.withValues(alpha: 0.3),
                size: 32,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.regionalTag,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.neonRed
                            : AppColors.textMuted,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? AppColors.neonRed
                            : AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      color: AppColors.surfaceGlass,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: lang.progress,
                        child: Container(
                          color: isSelected
                              ? AppColors.neonRed
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lang.frequencyText,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.neonRed
                            : AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String code;
  final String title;
  final String regionalTag;
  final String frequencyText;
  final double progress;
  final IconData icon;
  const _LanguageOption(
    this.code,
    this.title,
    this.regionalTag,
    this.frequencyText,
    this.progress,
    this.icon,
  );
}

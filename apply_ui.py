import os

armory_code = """import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../models/protocol.dart';
import 'challenge_detail_screen.dart';

class ArmoryScreen extends StatelessWidget {
  const ArmoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.menu, color: Color(0xFFFFB4A8)),
            const SizedBox(width: 16),
            Text(
              'USTAD AI',
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFFFFB4A8),
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -1.5,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF131313),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: const Color(0xFFFF5540), height: 4.0),
        ),
        automaticallyImplyLeading: false,
        actions: const [
          Icon(Icons.settings, color: Color(0xFFFFB4A8)),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFFFF5540), width: 8),
                  ),
                ),
                padding: const EdgeInsets.only(left: 16.0),
                margin: const EdgeInsets.only(bottom: 48.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE PROTOCOLS',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SYSTEM STATUS: ACTIVE // MISSION READY',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFF5540),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(staticProtocols.length, (index) {
                final protocol = staticProtocols[index];
                final String numberStr = (index + 1).toString().padLeft(2, '0');
                return _buildProtocolCard(context, protocol, numberStr);
              }),
              const SizedBox(height: 64),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning, color: Color(0xFFFF5540), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRITICAL ADVISORY',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFF5540),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'EXECUTION REQUIRES 100% FOCUS.\\nPARTIAL EFFORT IS CALCULATED AS FAILURE.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                color: const Color(0xFF353535),
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT LOAD',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFF5540),
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          '94.2%',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(0.25),
                        _buildBar(0.50),
                        _buildBar(0.75),
                        _buildBar(1.0),
                        _buildBar(0.85),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double heightFactor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 16,
      height: 48 * heightFactor,
      color: const Color(0xFFFF5540),
    );
  }

  Widget _buildProtocolCard(BuildContext context, Protocol protocol, String number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B1B),
        border: Border(
          left: BorderSide(color: Color(0x4D603E39), width: 4),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Text(
              number,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF353535),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  protocol.bgIcon,
                  size: 48,
                  color: const Color(0xFFFFB4A8),
                ),
                const SizedBox(height: 16),
                Text(
                  'PROTOCOL: ${protocol.title.replaceAll(" ", "_")}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0x33603E39))),
                  ),
                  child: Text(
                    protocol.description.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFEBBBB4),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  color: const Color(0xFF353535),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'TARGET: ${protocol.exerciseFocus.toUpperCase()}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChallengeDetailScreen(protocol: protocol),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFB4A8), Color(0xFFFF5540)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        child: Text(
                          'INITIATE ANALYSIS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF410000),
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(color: const Color(0x33FF5540), width: 4),
          ),
        ],
      ),
    );
  }
}
"""

detail_code = """import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/protocol.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Protocol protocol;

  const ChallengeDetailScreen({super.key, required this.protocol});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  String _selectedWindow = 'civilian';
  TimeOfDay _customOperatorTime = const TimeOfDay(hour: 6, minute: 0);

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _customOperatorTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF5540),
              onPrimary: Colors.white,
              surface: Color(0xFF1B1B1B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customOperatorTime = picked;
      });
    }
  }

  String get _formattedOperatorTime {
    final h = _customOperatorTime.hour.toString().padLeft(2, '0');
    final m = _customOperatorTime.minute.toString().padLeft(2, '0');
    return '\$h:\$m';
  }

  Future<void> _launchCheckout() async {
    HapticFeedback.heavyImpact();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERROR: NO ACTIVE USER SESSION',
              style: GoogleFonts.spaceMono(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF690005),
          ),
        );
      }
      return;
    }

    final windowModeParam = _selectedWindow == 'operator'
        ? 'workout-\${_formattedOperatorTime.replaceAll(':', '')}'
        : _selectedWindow;

    final checkoutUrl = Uri.parse(
      'https://faujos.com/checkout?user_id=\${user.id}&protocol_id=\${widget.protocol.id}&window_mode=\$windowModeParam',
    );

    try {
      if (!await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'FAILURE AVERTED: COULD NOT OPEN BROWSER.',
                style: GoogleFonts.spaceMono(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF690005),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Launch exception: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      appBar: AppBar(
        title: Text(
          'CONFIGURE DEPLOYMENT',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFFFB4A8),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -1,
          ),
        ),
        backgroundColor: const Color(0xFF131313),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: const Color(0xFFFF5540), height: 4.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFB4A8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFFFF5540), width: 8),
                ),
              ),
              padding: const EdgeInsets.only(left: 16.0),
              margin: const EdgeInsets.only(bottom: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.protocol.title.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SYSTEM STATUS: AWAITING CONFIGURATION',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFF5540),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              'SETTING A: ENGAGEMENT WINDOW',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFF5540),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            _buildConfigOption(
              title: 'CIVILIAN MODE (24H)',
              description: 'Complete the daily drill anytime before 23:59. Forgiving, but requires all-day discipline.',
              isSelected: _selectedWindow == 'civilian',
              onTap: () => setState(() => _selectedWindow = 'civilian'),
            ),
            const SizedBox(height: 16),
            _buildConfigOption(
              title: 'OPERATOR MODE (CUSTOM TIME)',
              description: 'Pick the exact daily workout time. You have 30 minutes to get in front of the camera. Miss it, and the challenge ends.',
              isSelected: _selectedWindow == 'operator',
              onTap: () => setState(() => _selectedWindow = 'operator'),
            ),
            if (_selectedWindow == 'operator') ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickCustomTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF353535),
                    border: Border(left: BorderSide(color: Color(0xFFFF5540), width: 4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAILY WORKOUT TIME',
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFFFFB4A8),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '30 MIN MAX. GET ON CAMERA.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE2E2E2),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formattedOperatorTime,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 48),

            Text(
              'SETTING B: MISFIRE MECHANIC',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFF5540),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1B1B1B),
                border: Border(left: BorderSide(color: Color(0xFF690005), width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE BLOOD DEBT (1x USE ONLY)',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFB4AB), // Error light
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Phones die. Alarms fail. You get exactly ONE Misfire pass for the 28 days. The catch? The next day incurs a "Blood Debt" (+25% rep penalty). Fail the debt, and your ₹200 deposit is seized immediately.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFE2E2E2),
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: const Color(0xFF131313),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _launchCheckout,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFB4A8), Color(0xFFFF5540)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'I BET ₹200 I WILL DESTROY THIS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF410000),
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigOption({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B), // Surface container low
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFFFF5540) : const Color(0x33603E39),
              width: 4,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? const Color(0xFFFF5540) : const Color(0xFF603E39),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFE2E2E2), // On-surface
                      height: 1.5,
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
"""

import pathlib
pth1 = pathlib.Path('lib/features/armory/screens/armory_screen.dart')
pth2 = pathlib.Path('lib/features/armory/screens/challenge_detail_screen.dart')

pth1.write_text(armory_code, encoding='utf-8')
pth2.write_text(detail_code, encoding='utf-8')
print("Successfully wrote UI changes")

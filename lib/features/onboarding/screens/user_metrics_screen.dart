import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class UserMetricsScreen extends StatefulWidget {
  const UserMetricsScreen({super.key});

  @override
  State<UserMetricsScreen> createState() => _UserMetricsScreenState();
}

class _UserMetricsScreenState extends State<UserMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _useMetricHeight = true; // cm vs ft/in
  bool _useMetricWeight = true; // kg vs lbs
  
  final _heightController = TextEditingController();
  final _ftController = TextEditingController();
  final _inController = TextEditingController();
  final _weightController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'MALE'; // Default
  
  bool _isLoading = false;
  bool _isRelogging = false;

  @override
  void dispose() {
    _heightController.dispose();
    _ftController.dispose();
    _inController.dispose();
    _weightController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadExistingMetrics();
  }

  Future<void> _loadExistingMetrics() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final res = await Supabase.instance.client
        .from('profiles')
        .select('height_cm, weight_kg, display_name, age, gender')
        .eq('id', user.id)
        .maybeSingle();

    if (res != null && mounted) {
      setState(() {
        _isRelogging = true;
        if (res['height_cm'] != null) {
          _heightController.text = res['height_cm'].toString();
          // Initialize ft/in if metric is false later, but for now we default to CM
        }
        if (res['weight_kg'] != null) {
          _weightController.text = res['weight_kg'].toString();
        }
        if (res['display_name'] != null) {
          _nameController.text = res['display_name'].toString();
        }
        if (res['age'] != null) {
          _ageController.text = res['age'].toString();
        }
        if (res['gender'] != null) {
          _gender = res['gender'].toString().toUpperCase();
        }
      });
    }
  }

  Future<void> _saveMetrics() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'PLEASE FILL ALL FIELDS',
            style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      double heightCm;
      if (_useMetricHeight) {
        heightCm = double.parse(_heightController.text);
      } else {
        final ft = double.parse(_ftController.text);
        final inches = double.parse(_inController.text);
        heightCm = (ft * 30.48) + (inches * 2.54);
      }

      double weightKg;
      if (_useMetricWeight) {
        weightKg = double.parse(_weightController.text);
      } else {
        weightKg = double.parse(_weightController.text) * 0.453592;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // 1. Update current profile
        await Supabase.instance.client.from('profiles').update({
          'display_name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text),
          'gender': _gender.toLowerCase(),
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'onboarding_complete': true,
        }).eq('id', user.id);

        // 2. Log to history
        await Supabase.instance.client.from('user_metrics_history').insert({
          'user_id': user.id,
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'logged_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                'MEASUREMENTS SAVED',
                style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      }

      if (mounted) {
        if (_isRelogging) {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            // Fallback for direct links
            context.go(AppRoutes.profile);
          }
        } else {
          // Initial onboarding -> Dashboard
          context.go(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      debugPrint('CRITICAL ERROR SAVING METRICS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              'PROFILE UPDATE FAILED: ${e.toString().toUpperCase()}',
              style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Grid
          CustomPaint(
            size: Size.infinite,
            painter: _BrutalistGridPainter(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'BIO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'DATA',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neonRed,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We need your measurements to calculate calories and progress.',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _nameController,
                      label: 'DISPLAY NAME',
                      hint: 'ENTER YOUR NAME',
                      suffix: 'NAME',
                      keyboardType: TextInputType.name,
                      allowDecimal: false,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _ageController,
                            label: 'AGE',
                            hint: 'YEARS',
                            suffix: 'YRS',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GENDER',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildGenderToggle(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // HEIGHT SECTION
                    _buildSectionHeader('HEIGHT', _useMetricHeight ? 'CM' : 'FT/IN', () {
                      setState(() => _useMetricHeight = !_useMetricHeight);
                    }),
                    const SizedBox(height: 16),
                    if (_useMetricHeight)
                      _buildTextField(
                        controller: _heightController,
                        label: 'CENTIMETERS',
                        hint: '175',
                        suffix: 'CM',
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _ftController,
                              label: 'FEET',
                              hint: '5',
                              suffix: 'FT',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _inController,
                              label: 'INCHES',
                              hint: '10',
                              suffix: 'IN',
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 32),

                    // WEIGHT SECTION
                    _buildSectionHeader('WEIGHT', _useMetricWeight ? 'KG' : 'LBS', () {
                      setState(() => _useMetricWeight = !_useMetricWeight);
                    }),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _weightController,
                      label: _useMetricWeight ? 'KILOGRAMS' : 'POUNDS',
                      hint: _useMetricWeight ? '70' : '155',
                      suffix: _useMetricWeight ? 'KG' : 'LBS',
                    ),

                    const SizedBox(height: 64),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveMetrics,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonRed,
                        disabledBackgroundColor: AppColors.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              _isRelogging ? 'UPDATE BIO' : 'COMPLETE PROFILE',
                              style: GoogleFonts.orbitron(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String unit, VoidCallback onToggle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '// $title',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        TextButton(
          onPressed: onToggle,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'SWITCH TO ${unit == 'CM' ? 'FT/IN' : 'CM/KG'}',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: AppColors.neonRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = _gender == 'MALE' ? 'FEMALE' : 'MALE';
        });
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _gender,
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.swap_horiz, color: AppColors.neonRed, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true),
    bool allowDecimal = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.spaceMono(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: keyboardType == TextInputType.number || keyboardType == const TextInputType.numberWithOptions(decimal: true)
                ? [FilteringTextInputFormatter.allow(RegExp(allowDecimal ? r'[0-9.]' : r'[0-9]'))]
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              suffixText: suffix,
              suffixStyle: GoogleFonts.spaceMono(
                color: AppColors.neonRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'REQUIRED';
              if (keyboardType == TextInputType.number && double.tryParse(value) == null) return 'INVALID';
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _BrutalistGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceContainerHigh.withOpacity(0.3)
      ..strokeWidth = 1;

    const double spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';
import '../services/diet_gemini_service.dart';

class DietSetupScreen extends StatefulWidget {
  const DietSetupScreen({super.key});

  @override
  State<DietSetupScreen> createState() => _DietSetupScreenState();
}

class _DietSetupScreenState extends State<DietSetupScreen> {
  String _selectedGoal = 'MAINTENANCE';
  String _selectedPreference = 'VEG';
  String _selectedBudget = 'MEDIUM (300/DAY)';
  
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _exclusionsController = TextEditingController();
  
  bool _isGenerating = false;

  final List<String> _goals = ['FAT LOSS', 'MAINTENANCE', 'MASS GAIN'];
  final List<String> _preferences = ['VEG', 'NON-VEG', 'OVO-VEG', 'VEGAN'];
  final List<String> _budgets = ['LOW (100/DAY)', 'MEDIUM (300/DAY)', 'HIGH (1000/DAY)', 'LIMITLESS'];

  @override
  void dispose() {
    _locationController.dispose();
    _exclusionsController.dispose();
    super.dispose();
  }

  Future<void> _generateDietPlan() async {
    FaujAudioEngine().playTap();
    
    setState(() {
      _isGenerating = true;
    });
    
    try {
      final location = _locationController.text.trim().isEmpty ? 'Generic' : _locationController.text.trim();
      final exclusions = _exclusionsController.text.trim().isEmpty ? 'None' : _exclusionsController.text.trim();
      
      final dietPlanResult = await DietGeminiService.generateDietPlan(
        goal: _selectedGoal,
        preference: _selectedPreference,
        location: location,
        budget: _selectedBudget,
        exclusions: exclusions,
      );
      
      if (mounted) {
        setState(() => _isGenerating = false);
        if (dietPlanResult != null) {
          context.push(
            AppRoutes.dietPreview, 
            extra: {'dietPlan': dietPlanResult},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FAILED TO GENERATE DIET PLAN.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR: $e', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10)),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'DIET SETUP',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '// SET UP YOUR DIET PLAN',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neonRed,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('CHOOSE YOUR GOAL'),
              _buildChoiceChips(_goals, _selectedGoal, (v) => setState(() => _selectedGoal = v)),
              
              const SizedBox(height: 24),
              _buildSectionTitle('DIETARY PREFERENCE'),
              _buildChoiceChips(_preferences, _selectedPreference, (v) => setState(() => _selectedPreference = v)),

              const SizedBox(height: 24),
              _buildSectionTitle('YOUR BUDGET'),
              _buildChoiceChips(_budgets, _selectedBudget, (v) => setState(() => _selectedBudget = v)),
              
              const SizedBox(height: 24),
              _buildSectionTitle('LOCATION (CUISINE ADAPTATION)'),
              const SizedBox(height: 8),
              _buildTextField(_locationController, 'E.G., PUNJAB, GUJARAT, CALIFORNIA...'),

              const SizedBox(height: 24),
              _buildSectionTitle('EXCLUSIONS (ALLERGIES / DISLIKES)'),
              const SizedBox(height: 8),
              _buildTextField(_exclusionsController, 'COMMA SEPARATED LIST...'),

              const SizedBox(height: 48),
              
              TacticalButton(
                soundType: TacticalSoundType.nav,
                onTap: _isGenerating ? () {} : _generateDietPlan,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isGenerating ? Colors.grey[800] : AppColors.neonRed,
                  ),
                  child: Center(
                    child: _isGenerating
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Text(
                          'GENERATE DIET PLAN',
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 2,
                          ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '>> $title',
        style: GoogleFonts.spaceMono(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildChoiceChips(List<String> options, String selected, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () {
            FaujAudioEngine().playMouseClick();
            onSelect(opt);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.neonRed.withOpacity(0.2) : Colors.black,
              border: Border.all(color: isSelected ? AppColors.neonRed : AppColors.outlineVariant),
            ),
            child: Text(
              opt,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: isSelected ? AppColors.neonRed : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.spaceMono(color: AppColors.textMuted, fontSize: 10),
        filled: true,
        fillColor: const Color(0xFF111111),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.neonRed),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

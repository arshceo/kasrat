import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class ProgressLogScreen extends StatefulWidget {
  const ProgressLogScreen({super.key});

  @override
  State<ProgressLogScreen> createState() => _ProgressLogScreenState();
}

class _ProgressLogScreenState extends State<ProgressLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _armsController = TextEditingController();
  final _thighsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _armsController.dispose();
    _thighsController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final weight = double.parse(_weightController.text);
      final chest = double.tryParse(_chestController.text);
      final waist = double.tryParse(_waistController.text);
      final arms = double.tryParse(_armsController.text);
      final thighs = double.tryParse(_thighsController.text);

      // 1. Update Profile (current weight)
      await Supabase.instance.client.from('profiles').update({
        'weight_kg': weight,
      }).eq('id', user.id);

      // 2. Add to History with dimensions
      await Supabase.instance.client.from('user_metrics_history').insert({
        'user_id': user.id,
        'weight_kg': weight,
        'chest_cm': chest,
        'waist_cm': waist,
        'arms_cm': arms,
        'thighs_cm': thighs,
        'logged_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'PROGRESS RECORDED',
              style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('LOG FAILED: $e'),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'LOG PROGRESS',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('BODY WEIGHT'),
              _buildLogField(_weightController, 'WEIGHT', 'KG', true),
              const SizedBox(height: 32),

              _buildSectionTitle('BODY DIMENSIONS (OPTIONAL)'),
              Row(
                children: [
                  Expanded(child: _buildLogField(_chestController, 'CHEST', 'CM', false)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildLogField(_waistController, 'WAIST', 'CM', false)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildLogField(_armsController, 'ARMS', 'CM', false)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildLogField(_thighsController, 'THIGHS', 'CM', false)),
                ],
              ),
              const SizedBox(height: 48),

              GestureDetector(
                onTap: _isLoading ? null : _saveLog,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  color: AppColors.neonRed,
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'RECORD LOG',
                          style: GoogleFonts.orbitron(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 2,
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
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          color: AppColors.neonRed,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLogField(TextEditingController controller, String label, String suffix, bool required) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Container(
          color: const Color(0xFF0D0D0D),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.spaceMono(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: GoogleFonts.spaceMono(color: AppColors.textMuted, fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            validator: (value) {
              if (required && (value == null || value.isEmpty)) return 'ERR';
              return null;
            },
          ),
        ),
      ],
    );
  }
}

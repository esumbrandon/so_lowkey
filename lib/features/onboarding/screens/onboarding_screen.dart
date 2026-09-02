import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final _aliasController = TextEditingController();
  final _answerController = TextEditingController();

  String _batteryStatus = 'medium';
  String _replyPace = 'few_days';
  String _selectedPrompt = "A niche rabbit hole I fell down recently:";

  final List<String> _prompts = [
    "A niche rabbit hole I fell down recently:",
    "My ideal weekend with zero obligations looks like:",
    "An unpopular opinion I hold quietly:",
    "A hobby I enjoy strictly in silence:",
  ];

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _aliasController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_aliasController.text.trim().isEmpty) {
      setState(() {
        _currentStep = 0;
        _error = 'Please choose an alias before continuing.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'alias': _aliasController.text.trim(),
        'battery_status': _batteryStatus,
        'reply_pace': _replyPace,
        'spark_prompt': _selectedPrompt,
        'spark_answer': _answerController.text.trim(),
        'is_discoverable': true,
        'max_active_chats': 3,
      });

      if (mounted) context.go('/lounges');
    } catch (e) {
      setState(
        () => _error =
            'Something went wrong saving your profile. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step ${_currentStep + 1} of 3',
                style: const TextStyle(
                  color: AppColors.biscuit,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentStep(),
                ),
              ),
              if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.terracotta),
                  ),
                ),
              ],
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Quiet Corner',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No public profiles, no search indexing, and no pressure to reveal your real identity.',
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _aliasController,
              decoration: InputDecoration(
                labelText: 'Choose an Alias',
                labelStyle: const TextStyle(color: AppColors.biscuit),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Your Pacing',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We never show "typing..." or read markers. Let others know your normal response cadence.',
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            const Text(
              'Initial Battery Level',
              style: TextStyle(
                color: AppColors.biscuit,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['recharging', 'low', 'medium', 'full'].map((lvl) {
                final isSelected = _batteryStatus == lvl;
                return ChoiceChip(
                  label: Text(lvl),
                  selected: isSelected,
                  selectedColor: AppColors.biscuit,
                  backgroundColor: AppColors.surface,
                  onSelected: (val) => setState(() => _batteryStatus = lvl),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Expected Reply Cadence',
              style: TextStyle(
                color: AppColors.biscuit,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _replyPace,
              dropdownColor: AppColors.surfaceElevated,
              items: const [
                DropdownMenuItem(
                  value: 'same_day',
                  child: Text('Within the same day'),
                ),
                DropdownMenuItem(
                  value: 'few_days',
                  child: Text('Within a few days (Comfortable)'),
                ),
                DropdownMenuItem(
                  value: 'slow_mail',
                  child: Text('Slow Mail (Weekly pacing)'),
                ),
              ],
              onChanged: (val) => setState(() => _replyPace = val!),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );
      case 2:
      default:
        return SingleChildScrollView(
          key: const ValueKey(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Skip the Small Talk',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick a prompt to show on your discovery card so people can begin with real depth.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              ..._prompts.map(
                (p) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.biscuit,
                  title: Text(p, style: const TextStyle(fontSize: 14)),
                  value: p,
                  groupValue: _selectedPrompt,
                  onChanged: (val) => setState(() => _selectedPrompt = val!),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your answer here...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildBottomButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentStep == 2
              ? AppColors.sage
              : AppColors.biscuit,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isSubmitting
            ? null
            : () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _submitOnboarding();
                }
              },
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Text(
                _currentStep == 2 ? 'Enter Sanctuary' : 'Continue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

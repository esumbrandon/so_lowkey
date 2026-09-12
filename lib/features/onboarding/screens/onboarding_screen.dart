import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_data.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final _aliasController = TextEditingController();
  final _answerController = TextEditingController();
  final _countryController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();

  String _batteryStatus = 'medium';
  String _replyPace = 'few_days';
  String _selectedPrompt = "A niche rabbit hole I fell down recently:";
  final Set<String> _selectedCircles = {};

  static const int _totalSteps = 4;

  final List<String> _prompts = [
    "A niche rabbit hole I fell down recently:",
    "My ideal weekend with zero obligations looks like:",
    "An unpopular opinion I hold quietly:",
    "A hobby I enjoy strictly in silence:",
  ];

  @override
  void dispose() {
    _aliasController.dispose();
    _answerController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    if (!isSupabaseConfigured) {
      if (mounted) context.go('/connections');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'alias': _aliasController.text.trim(),
      'battery_status': _batteryStatus,
      'reply_pace': _replyPace,
      'spark_prompt': _selectedPrompt,
      'spark_answer': _answerController.text.trim(),
      'is_discoverable': true,
      'max_active_chats': 3,
      'country': _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      'region': _regionController.text.trim().isEmpty
          ? null
          : _regionController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'circles': _selectedCircles.toList(),
    });

    if (mounted) context.go('/connections');
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _aliasController.text.trim().isNotEmpty;
      case 1:
        return true; // battery + reply pace always have defaults
      case 2:
        return _answerController.text.trim().isNotEmpty;
      case 3:
        return true; // location + circles are optional
      default:
        return true;
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
              // ── Progress indicator ──────────────────────────────────
              Row(
                children: [
                  Text(
                    'Step ${_currentStep + 1} of $_totalSteps',
                    style: const TextStyle(
                        color: AppColors.biscuit,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.biscuit),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentStep(),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      // ── Step 1: Alias ─────────────────────────────────────────────────
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
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Choose an Alias',
                labelStyle: const TextStyle(color: AppColors.biscuit),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        );

      // ── Step 2: Pacing ────────────────────────────────────────────────
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
            const Text('Initial Battery Level',
                style: TextStyle(
                    color: AppColors.biscuit, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children:
                  ['recharging', 'low', 'medium', 'full'].map((lvl) {
                final isSelected = _batteryStatus == lvl;
                return ChoiceChip(
                  label: Text(lvl),
                  selected: isSelected,
                  selectedColor: AppColors.biscuit,
                  backgroundColor: AppColors.surface,
                  onSelected: (val) =>
                      setState(() => _batteryStatus = lvl),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Expected Reply Cadence',
                style: TextStyle(
                    color: AppColors.biscuit, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _replyPace,
              dropdownColor: AppColors.surfaceElevated,
              items: const [
                DropdownMenuItem(
                    value: 'same_day',
                    child: Text('Within the same day')),
                DropdownMenuItem(
                    value: 'few_days',
                    child: Text('Within a few days (Comfortable)')),
                DropdownMenuItem(
                    value: 'slow_mail',
                    child: Text('Slow Mail (Weekly pacing)')),
              ],
              onChanged: (val) =>
                  setState(() => _replyPace = val!),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        );

      // ── Step 3: Spark Prompt ──────────────────────────────────────────
      case 2:
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
              ..._prompts.map((p) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.biscuit,
                    title:
                        Text(p, style: const TextStyle(fontSize: 14)),
                    value: p,
                    groupValue: _selectedPrompt,
                    onChanged: (val) =>
                        setState(() => _selectedPrompt = val!),
                  )),
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Write your answer here...',
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        );

      // ── Step 4: Location & Circles ────────────────────────────────────
      case 3:
      default:
        return SingleChildScrollView(
          key: const ValueKey(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Circle & Location',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Optional — helps you discover nerds in your region who share your interests. Nothing is publicly indexed.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Location fields
              const Text(
                'Location',
                style: TextStyle(
                    color: AppColors.biscuit, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: 'Country',
                  prefixIcon: const Icon(Icons.public_outlined,
                      color: AppColors.textMuted, size: 20),
                  labelStyle:
                      const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _regionController,
                      decoration: InputDecoration(
                        labelText: 'Region / State',
                        prefixIcon: const Icon(Icons.terrain_outlined,
                            color: AppColors.textMuted, size: 20),
                        labelStyle:
                            const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        prefixIcon: const Icon(Icons.location_city_outlined,
                            color: AppColors.textMuted, size: 20),
                        labelStyle:
                            const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Circles (interests)
              Row(
                children: [
                  const Text(
                    'Your Circles',
                    style: TextStyle(
                        color: AppColors.biscuit,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_selectedCircles.length} selected)',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Select up to 5 interest circles so others can discover you.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAllCircles.map((circle) {
                  final isSelected = _selectedCircles.contains(circle);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCircles.remove(circle);
                        } else if (_selectedCircles.length < 5) {
                          _selectedCircles.add(circle);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.sage.withValues(alpha: 0.18)
                            : AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.sage
                              : AppColors.surfaceElevated,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        circle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.sage
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
    }
  }

  Widget _buildBottomButton() {
    final isLast = _currentStep == _totalSteps - 1;
    final canProceed = _canProceed();

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLast ? AppColors.sage : AppColors.biscuit,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.surface,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: canProceed
            ? () {
                if (!isLast) {
                  setState(() => _currentStep++);
                } else {
                  _submitOnboarding();
                }
              }
            : null,
        child: Text(
          isLast ? 'Enter Sanctuary' : 'Continue',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

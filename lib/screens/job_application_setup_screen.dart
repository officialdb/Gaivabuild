import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/master_profile.dart';
import '../theme/app_theme.dart';
import 'tailoring_processing_screen.dart';

class JobApplicationSetupScreen extends StatefulWidget {
  final MasterProfile? masterProfile;

  const JobApplicationSetupScreen({super.key, this.masterProfile});

  @override
  State<JobApplicationSetupScreen> createState() =>
      _JobApplicationSetupScreenState();
}

class _JobApplicationSetupScreenState extends State<JobApplicationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobTitleController = TextEditingController(text: 'Staff Flutter Engineer');
  final _companyController = TextEditingController(text: 'Stripe Inc.');
  final _jdController = TextEditingController();

  String _selectedTone = 'Professional';
  final List<String> _tones = [
    'Professional',
    'Direct & Concise',
    'Enthusiastic',
    'Analytical',
  ];

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    _jdController.dispose();
    super.dispose();
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _jdController.text = data.text!;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pasted Job Description from clipboard!'),
            backgroundColor: AppTheme.accent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty.'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    }
  }



  void _startTailoring() {
    if (!_formKey.currentState!.validate()) return;

    final profile = widget.masterProfile ??
        MasterProfile.empty();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TailoringProcessingScreen(
          jobTitle: _jobTitleController.text.trim(),
          company: _companyController.text.trim(),
          jobDescription: _jdController.text.trim(),
          tone: _selectedTone,
          masterProfile: profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _jdController.text.length;
    final bool hasEnoughContent = charCount >= 50;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Tailor for New Job'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            children: [
              const SizedBox(height: 8), // Extra top breathing room before Target Job Title
              // Target Job Title
              TextFormField(
                controller: _jobTitleController,
                decoration: const InputDecoration(
                  labelText: 'Target Job Title *',
                  hintText: 'e.g. Senior Mobile Lead',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Target Company
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Target Company (Optional)',
                  hintText: 'e.g. Stripe, Google, Acme Corp',
                  prefixIcon: Icon(Icons.business_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 22),

              // Tone selector
              const Text(
                'Tone & Formatting Style',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tones.map((tone) {
                    final isSelected = _selectedTone == tone;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(tone),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedTone = tone);
                          }
                        },
                        selectedColor: AppTheme.cobaltBlue,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondaryLight,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.cobaltBlue
                              : AppTheme.borderLight,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // JD Input Section Header (Overflow Protected)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text(
                    'Pasted Job Description *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.paste_rounded, size: 15),
                        label: const Text('Paste'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppTheme.cobaltBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Large Multi-line TextFormField
              TextFormField(
                controller: _jdController,
                maxLines: 10,
                minLines: 6,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppTheme.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Paste the full job description here (responsibilities, required qualifications, tech stack)...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please paste a job description';
                  }
                  if (val.trim().length < 50) {
                    return 'Job description is too short (min 50 characters for AI analysis)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Character counter & validity indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          hasEnoughContent
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: hasEnoughContent
                              ? AppTheme.accent
                              : AppTheme.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            hasEnoughContent
                                ? 'Sufficient context for ATS'
                                : 'Min 50 chars needed',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasEnoughContent
                                  ? AppTheme.accent
                                  : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$charCount chars',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Prominent Action Button
              ElevatedButton.icon(
                onPressed: hasEnoughContent ? _startTailoring : null,
                icon: const Icon(Icons.bolt_rounded, size: 22),
                label: const Text(
                  'Tailor My CV',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.accent, // Emerald Green
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 14),

              // Trust Guardrail footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: AppTheme.accent,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anti-Hallucination: Strictly rewrites only your Master Profile facts.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

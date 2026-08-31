import 'package:flutter/material.dart';
import '../models/cover_letter.dart';
import '../models/tailored_application.dart';
import '../theme/app_theme.dart';
import 'cover_letter_editor_screen.dart';
import 'final_pdf_preview_screen.dart';

class CoverLetterUpsellModal extends StatefulWidget {
  final TailoredJobApplication application;

  const CoverLetterUpsellModal({
    super.key,
    required this.application,
  });

  @override
  State<CoverLetterUpsellModal> createState() => _CoverLetterUpsellModalState();
}

class _CoverLetterUpsellModalState extends State<CoverLetterUpsellModal> {
  String _selectedTone = 'Professional';
  String _selectedScenario = 'Standard Application';

  final List<String> _tones = [
    'Professional',
    'Direct & Concise',
    'Enthusiastic',
  ];

  final List<String> _scenarios = [
    'Standard Application',
    'Career Pivot / Transition',
    'Gap in Employment',
    'Fast-Growth Startup',
  ];

  void _generateCoverLetter() {
    Navigator.of(context).pop(); // Close modal

    final coverLetter = CoverLetter.fromApplication(
      app: widget.application,
      tone: _selectedTone,
      scenario: _selectedScenario,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoverLetterEditorScreen(
          application: widget.application,
          coverLetter: coverLetter,
        ),
      ),
    );
  }

  void _skipToExport() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FinalPdfPreviewScreen(
          application: widget.application,
          coverLetter: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.accent),
                    SizedBox(width: 6),
                    Text(
                      'CV APPROVED & ATS OPTIMIZED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Subtitle
          const Text(
            'Generate Matching Cover Letter?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reuse the active Job Description context to generate a high-impact narrative in under 10 seconds.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryDark.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Context Toggles: Tone
          const Text(
            'Tone of Voice',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
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
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedTone = tone);
                    },
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.cardDark.withValues(alpha: 0.4),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textSecondaryDark,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryLight
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Context Toggles: Application Scenario
          const Text(
            'Application Scenario',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedScenario,
            dropdownColor: AppTheme.surfaceDark,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _scenarios.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedScenario = val);
            },
          ),
          const SizedBox(height: 24),

          // Primary Generate Action
          ElevatedButton.icon(
            onPressed: _generateCoverLetter,
            icon: const Icon(Icons.auto_awesome, size: 20),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primary,
            ),
            label: const Text(
              'Generate Cover Letter (1-Tap)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),

          // Skip Action
          TextButton(
            onPressed: _skipToExport,
            child: const Text(
              'Skip to Final PDF Export',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

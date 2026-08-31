import 'package:flutter/material.dart';
import '../models/tailored_application.dart';
import '../theme/app_theme.dart';
import 'smart_document_review_screen.dart';

class AtsDashboardScreen extends StatefulWidget {
  final TailoredJobApplication application;

  const AtsDashboardScreen({
    super.key,
    required this.application,
  });

  @override
  State<AtsDashboardScreen> createState() => _AtsDashboardScreenState();
}

class _AtsDashboardScreenState extends State<AtsDashboardScreen> {
  late TailoredJobApplication _app;

  @override
  void initState() {
    super.initState();
    _app = widget.application;
  }

  void _addMissingSkillToProfile(String skill) {
    setState(() {
      final updatedMissing = List<String>.from(_app.missingKeywords)..remove(skill);
      final updatedMatched = List<String>.from(_app.matchedKeywords)..add(skill);
      final newScore = (_app.atsMatchScore + 4).clamp(0, 98);

      _app = TailoredJobApplication(
        id: _app.id,
        jobTitle: _app.jobTitle,
        targetCompany: _app.targetCompany,
        rawJobDescription: _app.rawJobDescription,
        tone: _app.tone,
        atsMatchScore: newScore,
        matchedKeywords: updatedMatched,
        missingKeywords: updatedMissing,
        sections: _app.sections,
        createdAt: _app.createdAt,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$skill" to Master Profile! Score updated to ${_app.atsMatchScore}%.'),
        backgroundColor: AppTheme.accent,
      ),
    );
  }

  void _navigateToReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmartDocumentReviewScreen(application: _app),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _app.atsMatchScore;
    final Color scoreColor = score >= 80
        ? AppTheme.accent
        : (score >= 60 ? AppTheme.warning : AppTheme.danger);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ATS Match Analysis'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // Target Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _app.jobTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@ ${_app.targetCompany} • Tone: ${_app.tone}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryDark.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Circular ATS Gauge Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: score / 100.0,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                              letterSpacing: -1,
                            ),
                          ),
                          const Text(
                            'ATS MATCH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppTheme.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'High ATS Keyword Alignment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your curated Master Profile nodes cover the primary technical hard skills demanded in the job description.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryDark.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3-Metric Sub-score Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SubScoreItem(
                          label: 'Keyword Match',
                          value: '${_app.matchedKeywords.length}/${_app.matchedKeywords.length + _app.missingKeywords.length}',
                          color: AppTheme.accent,
                        ),
                        Container(width: 1, height: 28, color: Colors.white12),
                        const _SubScoreItem(
                          label: 'Formatting',
                          value: '100% ATS',
                          color: AppTheme.primaryLight,
                        ),
                        Container(width: 1, height: 28, color: Colors.white12),
                        _SubScoreItem(
                          label: 'Curated Bullets',
                          value: '${_app.sections.fold<int>(0, (sum, s) => sum + s.bullets.length)} Total',
                          color: AppTheme.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Green Chips: Matched Keywords Rail
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppTheme.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Keywords Found & Matched (${_app.matchedKeywords.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _app.matchedKeywords.map((kw) {
                return Chip(
                  avatar: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppTheme.accent,
                  ),
                  label: Text(
                    kw,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: AppTheme.accent.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Red/Outlined Chips: Missing Required Skills
            if (_app.missingKeywords.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Missing Required Skills (${_app.missingKeywords.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Tap + to add',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryDark.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _app.missingKeywords.map((kw) {
                  return ActionChip(
                    avatar: const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppTheme.warning,
                    ),
                    label: Text(
                      kw,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryDark,
                      ),
                    ),
                    backgroundColor: AppTheme.surfaceDark,
                    side: BorderSide(
                      color: AppTheme.warning.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _addMissingSkillToProfile(kw),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Proceed Button to Block-by-Block Review
            ElevatedButton.icon(
              onPressed: _navigateToReview,
              icon: const Icon(Icons.rate_review_rounded, size: 20),
              label: const Text(
                'Review Document Block-by-Block',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SubScoreItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SubScoreItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryDark.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}


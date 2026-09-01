import 'dart:async';
import 'package:flutter/material.dart';
import '../models/master_profile.dart';
import '../services/auth_service.dart';
import '../services/offline_store_service.dart';
import '../services/resume_parser_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_shimmer.dart';
import 'profile_dashboard_screen.dart';

class ParsingStateScreen extends StatefulWidget {
  final String? fileName;
  final String? sourceName;
  final List<int>? bytes;

  const ParsingStateScreen({
    super.key,
    this.fileName,
    this.sourceName,
    this.bytes,
  });

  @override
  State<ParsingStateScreen> createState() => _ParsingStateScreenState();
}

class _ParsingStateScreenState extends State<ParsingStateScreen>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _stepTimer;

  final List<String> _parsingSteps = [
    'Analyzing document structure and layout...',
    'Extracting work history and achievement statements...',
    'Categorizing technical, soft, and tool competencies...',
    'Synthesizing Master Profile schema & syncing Auth Postgres...',
  ];

  final List<String> _extractedPills = [];
  MasterProfile? _parsedProfile;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _parseDocumentBytes().then((_) => _startPipeline());
  }

  Future<void> _parseDocumentBytes() async {
    final user = AuthService().currentUser;
    final docName = widget.fileName ?? widget.sourceName ?? 'Uploaded Resume.pdf';
    final docBytes = widget.bytes ?? [];

    // Perform real candidate text extraction from uploaded document
    try {
      if (docName.startsWith('http')) {
        _parsedProfile = await ResumeParserService.parseLinkedInUrl(docName);
      } else {
        _parsedProfile = await ResumeParserService.parseResumeDocument(
          fileName: docName,
          bytes: docBytes,
          userEmail: user?.email,
          userName: user?.fullName,
        );
      }
    } catch(e) {
      debugPrint('Error parsing CV: $e');
      // Fallback empty profile on error
      _parsedProfile = MasterProfile.empty(name: user?.fullName, email: user?.email);
    }

    // Populate live extracted pills from real candidate profile
    final pillList = <String>[];
    if (_parsedProfile!.fullName != 'Candidate') {
      pillList.add(_parsedProfile!.fullName);
    }
    if (_parsedProfile!.title.isNotEmpty) {
      pillList.add(_parsedProfile!.title);
    }
    for (final s in _parsedProfile!.skills) {
      pillList.add(s.name);
    }
    for (final e in _parsedProfile!.experiences) {
      pillList.add(e.company);
    }

    _extractedPills.addAll(pillList.take(6));
  }

  void _startPipeline() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (!mounted) return;

      if (_currentStepIndex < _parsingSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
      } else {
        timer.cancel();
        await _saveExtractedProfileAndNavigate();
      }
    });
  }

  Future<void> _saveExtractedProfileAndNavigate() async {
    final user = AuthService().currentUser;
    final profile = _parsedProfile ??
        MasterProfile.empty(name: user?.fullName, email: user?.email);

    // Save full snapshot to local cache
    await OfflineStoreService.saveCachedProfile(profile.toJson());

    // Persist extracted Master Profile to Auth Postgres backend table master_profiles
    try {
      await AuthService().upsertMasterProfile(profile: profile);
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ProfileDashboardScreen(initialProfile: profile),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.fileName ?? widget.sourceName ?? 'Uploaded Resume';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Document Icon with Pulsing Effect
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.cobaltBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cobaltBlue.withValues(alpha: 0.2),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    size: 36,
                    color: AppTheme.cobaltBlue,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Parsing $displayName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryLight,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Extracting work history, skills, and qualifications to build your Master Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.cobaltBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Step ${_currentStepIndex + 1} of ${_parsingSteps.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.cobaltBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _parsingSteps[_currentStepIndex],
                        key: ValueKey<int>(_currentStepIndex),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryLight,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: (_currentStepIndex + 1) / _parsingSteps.length,
                      backgroundColor: AppTheme.borderLight,
                      color: AppTheme.cobaltBlue,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Real-time Extracted Skill Badges
              if (_extractedPills.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Extracted Entities',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _extractedPills.map((pill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.accent),
                          const SizedBox(width: 6),
                          Text(
                            pill,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),
              const SkeletonExperienceCard(),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/master_profile.dart';
import '../models/tailored_application.dart';
import '../services/ai_tailoring_service.dart';
import '../theme/app_theme.dart';
import 'ats_dashboard_screen.dart';

class TailoringProcessingScreen extends StatefulWidget {
  final String jobTitle;
  final String company;
  final String jobDescription;
  final String tone;
  final MasterProfile masterProfile;

  const TailoringProcessingScreen({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.jobDescription,
    required this.tone,
    required this.masterProfile,
  });

  @override
  State<TailoringProcessingScreen> createState() =>
      _TailoringProcessingScreenState();
}

class _TailoringProcessingScreenState extends State<TailoringProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _currentStepIndex = 0;
  double _progress = 0.1;
  Timer? _stepTimer;
  Timer? _progressTimer;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Analyzing Job Requirements',
      'subtitle': 'Extracting core skills, responsibilities & ATS keywords...',
      'icon': Icons.psychology_rounded,
    },
    {
      'title': 'Querying Master Profile RAG Engine',
      'subtitle': 'Matching facts, experience & metrics from vector DB...',
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'title': 'Generating Anti-Hallucination Bullets',
      'subtitle': 'Aligning experience to job context without fabrication...',
      'icon': Icons.bolt_rounded,
    },
    {
      'title': 'Finalizing ATS Scoring & Layout',
      'subtitle': 'Checking section density, ATS score & keyword match...',
      'icon': Icons.verified_rounded,
    },
  ];

  final List<String> _liveTokens = [
    'Parsing job keywords...',
    'Matching profile experience...',
    'Scoring ATS density...',
  ];
  TailoredJobApplication? resultApplication;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startTimers();
    _triggerAiGeneration();
  }

  void _startTimers() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 0.95) {
          _progress += 0.008;
        }
      });
    });

    _stepTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentStepIndex < _steps.length - 1) {
          _currentStepIndex++;
        } else {
          _stepTimer?.cancel();
          _progressTimer?.cancel();
        }
      });
    });
  }

  bool _hasError = false;
  String _errorMessage = '';

  Future<void> _triggerAiGeneration() async {
    try {
      final aiApp = await AiTailoringService.generateTailoredApplication(
        jobTitle: widget.jobTitle,
        company: widget.company,
        rawJd: widget.jobDescription,
        masterProfile: widget.masterProfile,
        tone: widget.tone,
      );
      if (mounted) {
        setState(() {
          resultApplication = aiApp;
          _progress = 1.0;
          _currentStepIndex = _steps.length;
          _progressTimer?.cancel();
          _stepTimer?.cancel();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _progress = 1.0;
          _currentStepIndex = _steps.length;
          _progressTimer?.cancel();
          _stepTimer?.cancel();
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stepTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _openReview() {
    if (resultApplication == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate tailored CV from live API')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AtsDashboardScreen(application: resultApplication!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = _progress >= 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agentic RAG Engine'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Glowing Animated AI Processing Orb
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppTheme.accent.withValues(alpha: 0.15)
                              : AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _hasError ? null : (isCompleted
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                            : AppTheme.primaryGradient),
                        color: _hasError ? Colors.red : null,
                        boxShadow: [
                          BoxShadow(
                            color: (_hasError ? Colors.red : (isCompleted ? AppTheme.accent : AppTheme.primary))
                                .withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _hasError ? Icons.error_outline_rounded : (isCompleted
                            ? Icons.check_circle_outline_rounded
                            : Icons.auto_awesome),
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title & Target Job Card
              Center(
                child: Column(
                  children: [
                    Text(
                      _hasError
                          ? 'Tailoring Failed'
                          : (isCompleted
                              ? 'Tailoring Complete!'
                              : 'Tailoring CV for ${widget.jobTitle}'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppTheme.textPrimaryDark,
                      ),
                    ),
                    if (_hasError) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        '@ ${widget.company} • ${widget.tone} Tone',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Step Progress Text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ready for Review',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _hasError ? Colors.red : AppTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceDark,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _hasError ? Colors.red : AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Steps List (Glowing Cards)
              Expanded(
                child: ListView.builder(
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    final isStepCompleted = index < _currentStepIndex;
                    final isCurrent = index == _currentStepIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hasError && isCurrent
                              ? Colors.red.withValues(alpha: 0.3)
                              : (isCurrent
                                  ? AppTheme.primary.withValues(alpha: 0.3)
                                  : (isStepCompleted
                                      ? AppTheme.accent.withValues(alpha: 0.3)
                                      : AppTheme.surfaceDark.withValues(alpha: 0.1))),
                          width: isCurrent || isStepCompleted ? 1.5 : 1,
                        ),
                        boxShadow: isCurrent && !_hasError
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          // Status Icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _hasError && isCurrent
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : (isStepCompleted
                                      ? AppTheme.accent.withValues(alpha: 0.15)
                                      : (isCurrent
                                          ? AppTheme.primary.withValues(alpha: 0.15)
                                          : AppTheme.surfaceDark.withValues(alpha: 0.3))),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isCurrent && !_hasError
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                      ),
                                    )
                                  : Icon(
                                      _hasError && isCurrent
                                          ? Icons.error
                                          : (isStepCompleted ? Icons.check : Icons.hourglass_empty),
                                      size: 18,
                                      color: _hasError && isCurrent
                                          ? Colors.red
                                          : (isStepCompleted ? AppTheme.accent : AppTheme.textSecondaryDark),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Step Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step['title'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrent || isStepCompleted
                                        ? AppTheme.textPrimaryDark
                                        : AppTheme.textSecondaryDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  step['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondaryDark.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Live Match Tokens Stream
              if (_liveTokens.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _liveTokens.map((token) {
                    return Chip(
                      label: Text(
                        token,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                      backgroundColor: AppTheme.surfaceDark,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Review CV Button
              ElevatedButton.icon(
                onPressed: _hasError ? () => Navigator.of(context).pop() : (isCompleted ? _openReview : null),
                icon: Icon(_hasError ? Icons.arrow_back : Icons.rate_review_outlined),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasError ? Colors.red : AppTheme.accent,
                ),
                label: Text(
                  _hasError
                      ? 'Go Back'
                      : (isCompleted
                          ? 'Review Tailored CV (${resultApplication?.atsMatchScore}% Match)'
                          : 'Synthesizing Tailored CV...'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/master_profile.dart';
import '../services/auth_service.dart';
import '../services/offline_store_service.dart';
import '../theme/app_theme.dart';
import 'account_settings_screen.dart';
import 'data_ingestion_sheet.dart';
import 'job_application_setup_screen.dart';

class ProfileDashboardScreen extends StatefulWidget {
  final MasterProfile? initialProfile;
  const ProfileDashboardScreen({super.key, this.initialProfile});

  @override
  State<ProfileDashboardScreen> createState() => _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState extends State<ProfileDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MasterProfile _profile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile!;
    } else {
      final user = AuthService().currentUser;
      _profile = MasterProfile.empty(
        name: user?.fullName,
        email: user?.email,
      );
    }
    _initOfflineAndSync();
  }

  Future<void> _initOfflineAndSync() async {
    if (widget.initialProfile != null) {
      await _saveAndSyncProfile();
      return;
    }
    final cached = await OfflineStoreService.getCachedProfile();
    if (cached != null && mounted) {
      setState(() {
        _profile = MasterProfile.fromJson(cached);
      });
    }
    await _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final remoteData = await AuthService().fetchMasterProfile();
      if (remoteData != null && mounted) {
        final remoteProfile = MasterProfile.fromJson(remoteData);

        final localHasData = _profile.experiences.isNotEmpty ||
            _profile.skills.isNotEmpty ||
            _profile.education.isNotEmpty;
        final remoteHasData = remoteProfile.experiences.isNotEmpty ||
            remoteProfile.skills.isNotEmpty ||
            remoteProfile.education.isNotEmpty;

        if (!localHasData || remoteHasData) {
          setState(() {
            _profile = remoteProfile;
          });
          await OfflineStoreService.saveCachedProfile(remoteProfile.toJson());
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndSyncProfile() async {
    await OfflineStoreService.saveCachedProfile(_profile.toJson());
    try {
      await AuthService().upsertMasterProfile(profile: _profile);
    } catch (_) {}
  }

  void _openDataIngestionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DataIngestionBottomSheet(
        onBuildManually: _openAddExperienceDialog,
      ),
    );
  }

  void _openAddExperienceDialog() {
    final titleCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final bulletCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Work Experience'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Job Title *',
                  hintText: 'e.g. Senior Software Engineer',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company / Organization *',
                  hintText: 'e.g. Apex Tech Solutions',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        hintText: 'Jan 2022',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        hintText: 'Present',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bulletCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Key Responsibility / Achievement',
                  hintText: 'Architected mobile & backend systems...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final company = companyCtrl.text.trim();
              if (title.isEmpty || company.isEmpty) return;

              final bullets = <ExperienceBullet>[];
              if (bulletCtrl.text.trim().isNotEmpty) {
                bullets.add(
                  ExperienceBullet(
                    id: 'b_${DateTime.now().millisecondsSinceEpoch}',
                    text: bulletCtrl.text.trim(),
                  ),
                );
              }

              final newExp = WorkExperience(
                id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                company: company,
                title: title,
                location: 'Remote / On-site',
                startDate: startCtrl.text.trim().isNotEmpty ? startCtrl.text.trim() : '2022',
                endDate: endCtrl.text.trim().isNotEmpty ? endCtrl.text.trim() : 'Present',
                isCurrent: endCtrl.text.trim().toLowerCase().contains('present') || endCtrl.text.trim().isEmpty,
                bullets: bullets,
              );

              setState(() {
                _profile = _profile.copyWith(
                  experiences: [..._profile.experiences, newExp],
                );
              });
              _saveAndSyncProfile();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAddEducationDialog() {
    final institutionCtrl = TextEditingController();
    final degreeCtrl = TextEditingController();
    final fieldCtrl = TextEditingController();
    final yearCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Education / Certification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: degreeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Degree / Certification Title *',
                  hintText: 'e.g. HND Software Engineering or Cisco Cybersecurity',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: institutionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Institution / Provider *',
                  hintText: 'e.g. Federal Polytechnic Nekede or Cisco Academy',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fieldCtrl,
                decoration: const InputDecoration(
                  labelText: 'Field of Study',
                  hintText: 'e.g. Computer Science',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearCtrl,
                decoration: const InputDecoration(
                  labelText: 'Completion Year',
                  hintText: 'e.g. 2023',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final degree = degreeCtrl.text.trim();
              final inst = institutionCtrl.text.trim();
              if (degree.isEmpty || inst.isEmpty) return;

              final newEdu = EducationEntry(
                id: 'edu_${DateTime.now().millisecondsSinceEpoch}',
                institution: inst,
                degree: degree,
                fieldOfStudy: fieldCtrl.text.trim().isNotEmpty ? fieldCtrl.text.trim() : 'Computer Science',
                startYear: '2020',
                endYear: yearCtrl.text.trim().isNotEmpty ? yearCtrl.text.trim() : '2023',
              );

              setState(() {
                _profile = _profile.copyWith(
                  education: [..._profile.education, newEdu],
                );
              });
              _saveAndSyncProfile();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openEditEducationDialog(EducationEntry edu, int index) {
    final institutionCtrl = TextEditingController(text: edu.institution);
    final degreeCtrl = TextEditingController(text: edu.degree);
    final fieldCtrl = TextEditingController(text: edu.fieldOfStudy);
    final yearCtrl = TextEditingController(text: edu.endYear);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Education / Certification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: degreeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Degree / Certification Title *',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: institutionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Institution / Provider *',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fieldCtrl,
                decoration: const InputDecoration(
                  labelText: 'Field of Study',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearCtrl,
                decoration: const InputDecoration(
                  labelText: 'Completion Year',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final degree = degreeCtrl.text.trim();
              final inst = institutionCtrl.text.trim();
              if (degree.isEmpty || inst.isEmpty) return;

              final updatedEdu = edu.copyWith(
                institution: inst,
                degree: degree,
                fieldOfStudy: fieldCtrl.text.trim(),
                endYear: yearCtrl.text.trim(),
              );

              final list = List<EducationEntry>.from(_profile.education);
              list[index] = updatedEdu;

              setState(() {
                _profile = _profile.copyWith(education: list);
              });
              _saveAndSyncProfile();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteEducation(int index) {
    final deleted = _profile.education[index];
    final updatedList = List<EducationEntry>.from(_profile.education)..removeAt(index);

    setState(() {
      _profile = _profile.copyWith(education: updatedList);
    });
    _saveAndSyncProfile();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${deleted.degree}"'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.amber,
          onPressed: () {
            final restoredList = List<EducationEntry>.from(_profile.education)
              ..insert(index, deleted);
            setState(() {
              _profile = _profile.copyWith(education: restoredList);
            });
            _saveAndSyncProfile();
          },
        ),
      ),
    );
  }

  void _openAddSkillDialog() {
    final skillController = TextEditingController();
    SkillCategory selectedCategory = SkillCategory.hard;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: skillController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Skill Name',
                  hintText: 'e.g. Flutter, PostgreSQL, System Design',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SkillCategory>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: SkillCategory.hard, child: Text('Technical / Hard Skill')),
                  DropdownMenuItem(value: SkillCategory.tool, child: Text('Tools & Software')),
                  DropdownMenuItem(value: SkillCategory.soft, child: Text('Soft Skills')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCategory = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = skillController.text.trim();
                if (text.isNotEmpty) {
                  final newSkill = SkillItem(
                    id: 'sk_${DateTime.now().millisecondsSinceEpoch}',
                    name: text,
                    category: selectedCategory,
                  );
                  setState(() {
                    _profile = _profile.copyWith(skills: [..._profile.skills, newSkill]);
                  });
                  _saveAndSyncProfile();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSkill(String skillId) {
    setState(() {
      _profile = _profile.copyWith(
        skills: _profile.skills.where((s) => s.id != skillId).toList(),
      );
    });
    _saveAndSyncProfile();
  }

  void _deleteExperience(int index) {
    final deletedExp = _profile.experiences[index];
    final updatedList = List<WorkExperience>.from(_profile.experiences)..removeAt(index);

    setState(() {
      _profile = _profile.copyWith(experiences: updatedList);
    });
    _saveAndSyncProfile();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${deletedExp.company} experience'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.amber,
          onPressed: () {
            final restoredList = List<WorkExperience>.from(_profile.experiences)
              ..insert(index, deletedExp);
            setState(() {
              _profile = _profile.copyWith(experiences: restoredList);
            });
            _saveAndSyncProfile();
          },
        ),
      ),
    );
  }

  void _onFabPressed() {
    _openDataIngestionSheet();
  }

  double _calculateCompleteness() {
    int score = 0;
    if (_profile.fullName.isNotEmpty && _profile.fullName != 'Candidate') score += 20;
    if (_profile.title.isNotEmpty) score += 15;
    if (_profile.email.isNotEmpty) score += 15;
    if (_profile.experiences.isNotEmpty) score += 25;
    if (_profile.skills.isNotEmpty) score += 15;
    if (_profile.education.isNotEmpty) score += 10;
    return score.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final completenessScore = _calculateCompleteness();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Master Profile',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: AppTheme.cobaltBlue),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const JobApplicationSetupScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimaryLight),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AccountSettingsScreen(
                    profile: _profile,
                    onProfileUpdated: (updated) {
                      setState(() {
                        _profile = updated;
                      });
                      _saveAndSyncProfile();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _refreshProfile,
              child: Column(
                children: [
                  // Candidate Profile Summary Header Card
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryLight,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _profile.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.cobaltBlue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (_profile.location.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppTheme.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _profile.location,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            if (_profile.email.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 14,
                                    color: AppTheme.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _profile.email,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            if (_profile.linkedInUrl != null && _profile.linkedInUrl!.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.link_rounded,
                                    size: 14,
                                    color: AppTheme.cobaltBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _profile.linkedInUrl!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.cobaltBlue,
                                    ),
                                  ),
                                ],
                              ),
                            if (_profile.githubUrl != null && _profile.githubUrl!.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.code_rounded,
                                    size: 14,
                                    color: AppTheme.textPrimaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _profile.githubUrl!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Completeness Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Master Profile: ${completenessScore.toInt()}% Complete',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryLight,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_profile.experiences.length} roles • ${_profile.skills.length} skills',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Selector
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.cobaltBlue,
                    unselectedLabelColor: AppTheme.textSecondaryLight,
                    indicatorColor: AppTheme.cobaltBlue,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    tabs: [
                      Tab(text: 'Experience (${_profile.experiences.length})'),
                      Tab(text: 'Skills (${_profile.skills.length})'),
                      Tab(text: 'Education (${_profile.education.length})'),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _ExperienceTabView(
                          experiences: _profile.experiences,
                          onUploadCv: _openDataIngestionSheet,
                          onAddExperience: _openAddExperienceDialog,
                          onDeleteExp: _deleteExperience,
                        ),
                        _SkillsTabView(
                          skills: _profile.skills,
                          onAddSkill: _openAddSkillDialog,
                          onDeleteSkill: _deleteSkill,
                        ),
                        _EducationTabView(
                          education: _profile.education,
                          onAddEducation: _openAddEducationDialog,
                          onEditEducation: _openEditEducationDialog,
                          onDeleteEducation: _deleteEducation,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFabPressed,
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ExperienceTabView extends StatelessWidget {
  final List<WorkExperience> experiences;
  final VoidCallback onUploadCv;
  final VoidCallback onAddExperience;
  final Function(int) onDeleteExp;

  const _ExperienceTabView({
    required this.experiences,
    required this.onUploadCv,
    required this.onAddExperience,
    required this.onDeleteExp,
  });

  @override
  Widget build(BuildContext context) {
    if (experiences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_outline_rounded,
              size: 48,
              color: AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            const Text(
              'No work experience added yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload your CV to automatically populate your profile',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: onUploadCv,
                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  label: const Text(
                    '+ Upload CV',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onAddExperience,
                  icon: const Icon(Icons.add, color: AppTheme.cobaltBlue),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: const BorderSide(color: AppTheme.cobaltBlue),
                  ),
                  label: const Text(
                    'Add Role',
                    style: TextStyle(color: AppTheme.cobaltBlue, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: experiences.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final exp = experiences[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.cobaltBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: AppTheme.cobaltBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exp.company,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.cobaltBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${exp.startDate} - ${exp.endDate}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                            if (exp.isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PRESENT',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'delete') onDeleteExp(index);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (exp.bullets.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 10),
                ...exp.bullets.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobaltBlue)),
                        Expanded(
                          child: Text(
                            b.text,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textPrimaryLight,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SkillsTabView extends StatelessWidget {
  final List<SkillItem> skills;
  final VoidCallback onAddSkill;
  final Function(String) onDeleteSkill;

  const _SkillsTabView({
    required this.skills,
    required this.onAddSkill,
    required this.onDeleteSkill,
  });

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.psychology_outlined,
              size: 48,
              color: AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            const Text(
              'No skills added yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddSkill,
              icon: const Icon(Icons.add, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              label: const Text('Add Skill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map(
                (skill) => Chip(
                  label: Text(
                    skill.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.borderLight),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => onDeleteSkill(skill.id),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _EducationTabView extends StatelessWidget {
  final List<EducationEntry> education;
  final VoidCallback onAddEducation;
  final Function(EducationEntry edu, int index) onEditEducation;
  final Function(int index) onDeleteEducation;

  const _EducationTabView({
    required this.education,
    required this.onAddEducation,
    required this.onEditEducation,
    required this.onDeleteEducation,
  });

  @override
  Widget build(BuildContext context) {
    if (education.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 48,
              color: AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            const Text(
              'No education or certifications added yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddEducation,
              icon: const Icon(Icons.add, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              label: const Text(
                '+ Add Education / Certification',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: education.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final edu = education[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edu.degree,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          edu.institution,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.cobaltBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Completion / Graduation: ${edu.endYear}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        onEditEducation(edu, index);
                      } else if (val == 'delete') {
                        onDeleteEducation(index);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppTheme.cobaltBlue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

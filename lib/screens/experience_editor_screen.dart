import 'package:flutter/material.dart';
import '../models/master_profile.dart';
import '../theme/app_theme.dart';

class ExperienceEditorScreen extends StatefulWidget {
  final WorkExperience? experience;
  final Function(WorkExperience) onSave;

  const ExperienceEditorScreen({
    super.key,
    this.experience,
    required this.onSave,
  });

  @override
  State<ExperienceEditorScreen> createState() => _ExperienceEditorScreenState();
}

class _ExperienceEditorScreenState extends State<ExperienceEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late bool _isCurrent;

  late List<TextEditingController> _bulletControllers;

  @override
  void initState() {
    super.initState();
    final exp = widget.experience;
    _titleController = TextEditingController(text: exp?.title ?? '');
    _companyController = TextEditingController(text: exp?.company ?? '');
    _locationController = TextEditingController(text: exp?.location ?? '');
    _startDateController = TextEditingController(text: exp?.startDate ?? '');
    _endDateController = TextEditingController(text: exp?.endDate ?? '');
    _isCurrent = exp?.isCurrent ?? false;

    if (exp != null && exp.bullets.isNotEmpty) {
      _bulletControllers = exp.bullets
          .map((b) => TextEditingController(text: b.text))
          .toList();
    } else {
      _bulletControllers = [
        TextEditingController(
          text:
              'Architected core system features resulting in 25% performance improvement.',
        ),
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    for (var c in _bulletControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addBullet() {
    setState(() {
      _bulletControllers.add(TextEditingController());
    });
  }

  void _removeBullet(int index) {
    if (_bulletControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one achievement bullet point is required.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    setState(() {
      final removed = _bulletControllers.removeAt(index);
      removed.dispose();
    });
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final bullets = _bulletControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map(
          (c) => ExperienceBullet(
            id: 'b_${DateTime.now().millisecondsSinceEpoch}_${c.hashCode}',
            text: c.text.trim(),
          ),
        )
        .toList();

    if (bullets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one bullet point with text.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final newOrUpdatedExperience = WorkExperience(
      id: widget.experience?.id ??
          'exp_${DateTime.now().millisecondsSinceEpoch}',
      company: _companyController.text.trim(),
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      startDate: _startDateController.text.trim(),
      endDate: _isCurrent ? 'Present' : _endDateController.text.trim(),
      isCurrent: _isCurrent,
      bullets: bullets,
    );

    widget.onSave(newOrUpdatedExperience);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.experience != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Experience' : 'Add Experience'),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            children: [
              // Role Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Role Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppTheme.textPrimaryLight),
                      decoration: const InputDecoration(
                        labelText: 'Job Title *',
                        hintText: 'e.g. Senior Mobile Engineer',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Job title is required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyController,
                      style: const TextStyle(color: AppTheme.textPrimaryLight),
                      decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        hintText: 'e.g. Google, Stripe, Startup Inc.',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Company name is required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(color: AppTheme.textPrimaryLight),
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'e.g. New York, NY (Remote)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startDateController,
                            style: const TextStyle(color: AppTheme.textPrimaryLight),
                            decoration: const InputDecoration(
                              labelText: 'Start Date *',
                              hintText: 'e.g. Jan 2022',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _endDateController,
                            enabled: !_isCurrent,
                            style: const TextStyle(color: AppTheme.textPrimaryLight),
                            decoration: InputDecoration(
                              labelText: _isCurrent ? 'Present' : 'End Date',
                              hintText: 'e.g. Present',
                              prefixIcon: const Icon(Icons.event_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'I currently work here',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      value: _isCurrent,
                      activeColor: AppTheme.accent,
                      onChanged: (val) {
                        setState(() {
                          _isCurrent = val ?? false;
                          if (_isCurrent) {
                            _endDateController.text = 'Present';
                          } else {
                            _endDateController.text = '';
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // The Bullet Point Engine Header (Overflow Protected)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievement Bullets',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryLight,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Discrete cards for AI curation',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addBullet,
                    icon: const Icon(Icons.add_circle_outline, size: 17),
                    label: const Text('Add Bullet'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.cobaltBlue,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Helper Callout
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppTheme.cobaltBlue,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Separate your achievements into individual cards so the AI can match them cleanly.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondaryLight,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Dynamic Reorderable Bullet List
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bulletControllers.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = _bulletControllers.removeAt(oldIndex);
                    _bulletControllers.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  return Container(
                    key: ValueKey(_bulletControllers[index]),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            padding: const EdgeInsets.only(top: 8, right: 6),
                            child: const Icon(
                              Icons.drag_indicator_rounded,
                              color: AppTheme.textSecondaryLight,
                              size: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _bulletControllers[index],
                            maxLines: null,
                            minLines: 2,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: AppTheme.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Describe an impact or metric (e.g. "Led squad of 5 engineers to deliver...")',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppTheme.borderLight),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.danger,
                            size: 20,
                          ),
                          onPressed: () => _removeBullet(index),
                          tooltip: 'Delete Bullet',
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Save Button (Emerald Green CTA)
              ElevatedButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.check_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                label: Text(
                  isEditing ? 'Update Work Experience' : 'Add to Master Profile',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

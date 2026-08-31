import 'package:flutter/material.dart';
import '../models/tailored_application.dart';
import '../theme/app_theme.dart';
import 'cover_letter_upsell_modal.dart';

class SmartDocumentReviewScreen extends StatefulWidget {
  final TailoredJobApplication application;

  const SmartDocumentReviewScreen({
    super.key,
    required this.application,
  });

  @override
  State<SmartDocumentReviewScreen> createState() =>
      _SmartDocumentReviewScreenState();
}

class _SmartDocumentReviewScreenState extends State<SmartDocumentReviewScreen> {
  late TailoredJobApplication _app;

  @override
  void initState() {
    super.initState();
    _app = widget.application;
  }

  void _toggleApproval(TailoredBullet bullet) {
    setState(() {
      bullet.isApproved = !bullet.isApproved;
    });
  }

  void _revertBullet(TailoredBullet bullet) {
    setState(() {
      bullet.tailoredText = bullet.originalText;
      bullet.isApproved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reverted bullet to original Master Profile text.'),
        backgroundColor: AppTheme.textPrimaryLight,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _editBullet(TailoredBullet bullet) {
    final controller = TextEditingController(text: bullet.tailoredText);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Edit Tailored Bullet',
          style: TextStyle(color: AppTheme.textPrimaryLight, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 3,
          autofocus: true,
          style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textPrimaryLight),
          decoration: const InputDecoration(
            hintText: 'Edit your achievement statement...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                setState(() {
                  bullet.tailoredText = newText;
                  bullet.isApproved = true;
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save & Approve'),
          ),
        ],
      ),
    );
  }

  void _approveAll() {
    setState(() {
      for (final section in _app.sections) {
        for (final bullet in section.bullets) {
          bullet.isApproved = true;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All achievement blocks approved!'),
        backgroundColor: AppTheme.accent,
      ),
    );
  }

  void _proceedToCoverLetterUpsell() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CoverLetterUpsellModal(application: _app),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalBullets = 0;
    int approvedBullets = 0;

    for (final s in _app.sections) {
      for (final b in s.bullets) {
        totalBullets++;
        if (b.isApproved) approvedBullets++;
      }
    }

    final bool allApproved = totalBullets > 0 && approvedBullets == totalBullets;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Smart Document Review'),
        actions: [
          if (!allApproved)
            TextButton(
              onPressed: _approveAll,
              child: const Text(
                'Approve All',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.cobaltBlue,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: allApproved
                    ? AppTheme.accent.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: allApproved
                      ? AppTheme.accent.withValues(alpha: 0.4)
                      : AppTheme.borderLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    allApproved
                        ? Icons.check_circle
                        : Icons.pending_actions_outlined,
                    size: 15,
                    color: allApproved ? AppTheme.accent : AppTheme.warning,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$approvedBullets/$totalBullets Approved',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: allApproved ? AppTheme.accent : AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _proceedToCoverLetterUpsell,
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent, // Emerald Green CTA
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: Text(
                  allApproved ? 'Proceed to Upsell & Export' : 'Approve & Continue',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Anti-Hallucination Guardrail Banner (High Contrast)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: AppTheme.cobaltBlue,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anti-Hallucination Guardrail: AI only rewrote vocabulary & syntax to match ATS requirements. Zero facts were invented.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryLight,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section list
            ..._app.sections.map((section) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header (High Contrast)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            section.company,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          section.dateRange,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.role,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.cobaltBlue,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bullets
                    ...section.bullets.map((bullet) {
                      return _BulletReviewCard(
                        bullet: bullet,
                        onToggleApprove: () => _toggleApproval(bullet),
                        onEdit: () => _editBullet(bullet),
                        onRevert: () => _revertBullet(bullet),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BulletReviewCard extends StatefulWidget {
  final TailoredBullet bullet;
  final VoidCallback onToggleApprove;
  final VoidCallback onEdit;
  final VoidCallback onRevert;

  const _BulletReviewCard({
    required this.bullet,
    required this.onToggleApprove,
    required this.onEdit,
    required this.onRevert,
  });

  @override
  State<_BulletReviewCard> createState() => _BulletReviewCardState();
}

class _BulletReviewCardState extends State<_BulletReviewCard> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.bullet;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: b.isApproved
              ? AppTheme.borderLight
              : AppTheme.cobaltBlue.withValues(alpha: 0.5),
          width: b.isApproved ? 1 : 1.5,
        ),
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
          // Card Header with High-Contrast Badge & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: b.isModified
                        ? const Color(0xFFE0F2FE) // Crisp Sky Tint
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: b.isModified
                          ? const Color(0xFFBAE6FD)
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: b.isModified
                            ? AppTheme.cobaltBlue
                            : AppTheme.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        b.isModified ? 'AI Tailored' : 'Original',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: b.isModified
                              ? AppTheme.cobaltBlue
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showOriginal = !_showOriginal;
                    });
                  },
                  child: Text(
                    _showOriginal ? 'Hide Master Profile' : 'Compare Original',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.cobaltBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tailored Text Body (High Contrast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Text(
              b.tailoredText,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),

          // Optional Original Diff Block
          if (_showOriginal) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORIGINAL MASTER PROFILE FACT:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b.originalText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimaryLight,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.borderLight),

          // Action Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: widget.onToggleApprove,
                  icon: Icon(
                    b.isApproved
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: b.isApproved
                        ? AppTheme.accent
                        : AppTheme.textSecondaryLight,
                  ),
                  label: Text(
                    b.isApproved ? 'Approved' : 'Approve',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: b.isApproved
                          ? AppTheme.accent
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppTheme.textSecondaryLight,
                  ),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onRevert,
                  icon: const Icon(
                    Icons.undo_rounded,
                    size: 16,
                    color: AppTheme.textSecondaryLight,
                  ),
                  label: const Text(
                    'Revert',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

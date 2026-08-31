import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cover_letter.dart';
import '../models/tailored_application.dart';
import '../theme/app_theme.dart';
import 'final_pdf_preview_screen.dart';

class CoverLetterEditorScreen extends StatefulWidget {
  final TailoredJobApplication application;
  final CoverLetter coverLetter;

  const CoverLetterEditorScreen({
    super.key,
    required this.application,
    required this.coverLetter,
  });

  @override
  State<CoverLetterEditorScreen> createState() =>
      _CoverLetterEditorScreenState();
}

class _CoverLetterEditorScreenState extends State<CoverLetterEditorScreen> {
  late CoverLetter _letter;

  @override
  void initState() {
    super.initState();
    _letter = widget.coverLetter;
  }

  void _regenerateBlock(CoverLetterBlock block, int index) {
    if (block.alternatives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more variations available for this block.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() {
      final current = block.content;
      final next = block.alternatives.removeAt(0);
      block.alternatives.add(current);
      block.content = next;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Regenerated "${block.title}" with fresh AI variation!'),
        backgroundColor: AppTheme.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editBlock(CoverLetterBlock block) {
    final controller = TextEditingController(text: block.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Edit ${block.title}'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          minLines: 4,
          autofocus: true,
          style: const TextStyle(fontSize: 14, height: 1.45),
          decoration: const InputDecoration(
            hintText: 'Edit block narrative...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  block.content = text;
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save Block'),
          ),
        ],
      ),
    );
  }

  void _copyFullCoverLetter() {
    Clipboard.setData(ClipboardData(text: _letter.fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied full Cover Letter to clipboard!'),
        backgroundColor: AppTheme.accent,
      ),
    );
  }

  void _proceedToFinalExport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FinalPdfPreviewScreen(
          application: widget.application,
          coverLetter: _letter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modular Cover Letter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Full Letter',
            onPressed: _copyFullCoverLetter,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyFullCoverLetter,
                icon: const Icon(Icons.content_copy_rounded, size: 16),
                label: const Text('Copy Text'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _proceedToFinalExport,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: const Text(
                  'Final PDF Preview',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          children: [
            // Metadata Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_letter.targetRole} @ ${_letter.targetCompany}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tone: ${_letter.tone} • ${_letter.scenario}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryDark.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Instruction Note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 18,
                    color: AppTheme.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dislike a paragraph? Tap "Regenerate" on that block to get a fresh variation without rewriting the rest of your letter.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryDark.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Modular Block List
            ..._letter.blocks.asMap().entries.map((entry) {
              final index = entry.key;
              final block = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Block Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _BlockTypeIcon(type: block.type),
                              const SizedBox(width: 8),
                              Text(
                                block.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryDark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${block.alternatives.length + 1} Variations',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Block Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Text(
                        block.content,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Colors.white10),

                    // Localized Actions Toolbar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _regenerateBlock(block, index),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: AppTheme.primaryLight,
                            ),
                            label: const Text(
                              'Regenerate Block',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _editBlock(block),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppTheme.textSecondaryDark,
                            ),
                            label: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryDark,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            color: AppTheme.textSecondaryDark,
                            tooltip: 'Copy Block',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: block.content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Copied "${block.title}"'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

class _BlockTypeIcon extends StatelessWidget {
  final CoverLetterBlockType type;

  const _BlockTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case CoverLetterBlockType.hook:
        icon = Icons.anchor_rounded;
        color = AppTheme.primaryLight;
        break;
      case CoverLetterBlockType.proof1:
        icon = Icons.bolt_rounded;
        color = AppTheme.secondary;
        break;
      case CoverLetterBlockType.proof2:
        icon = Icons.groups_rounded;
        color = AppTheme.accent;
        break;
      case CoverLetterBlockType.close:
        icon = Icons.handshake_outlined;
        color = AppTheme.warning;
        break;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

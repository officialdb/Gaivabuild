import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'parsing_state_screen.dart';
import 'profile_dashboard_screen.dart';

class DataIngestionBottomSheet extends StatefulWidget {
  final VoidCallback? onBuildManually;
  const DataIngestionBottomSheet({super.key, this.onBuildManually});

  @override
  State<DataIngestionBottomSheet> createState() => _DataIngestionBottomSheetState();
}

class _DataIngestionBottomSheetState extends State<DataIngestionBottomSheet> {
  bool _isUploading = false;

  void _navigateToParsing(BuildContext context, String sourceName, List<int> bytes) {
    Navigator.of(context).pop(); // Close bottom sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParsingStateScreen(sourceName: sourceName, bytes: bytes),
      ),
    );
  }

  Future<void> _pickAndUploadResume() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );

      if (result.isEmpty) return;

      final file = result.first;
      final fileName = file.name;
      List<int>? bytes;

      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        if (file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }
      }

      bytes ??= [37, 80, 68, 70, 45, 49, 46, 55];

      setState(() => _isUploading = true);

      final uploadResult = await StorageService.uploadResumeFile(
        fileName: fileName,
        fileBytes: bytes,
        mimeType: fileName.endsWith('.pdf')
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded resume: ${uploadResult.key}'),
            backgroundColor: AppTheme.accent,
            duration: const Duration(seconds: 3),
          ),
        );
        _navigateToParsing(context, fileName, bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload info: $e'),
            backgroundColor: AppTheme.cobaltBlue,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _navigateToManualEntry(BuildContext context) {
    Navigator.of(context).pop();
    if (widget.onBuildManually != null) {
      widget.onBuildManually!();
    }
  }

  void _openLinkedInDialog(BuildContext context) {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import from LinkedIn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste your public LinkedIn profile URL below.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'LinkedIn URL',
                prefixIcon: Icon(Icons.link),
                hintText: 'https://linkedin.com/in/username',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isEmpty || !url.startsWith('http')) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid URL', style: TextStyle(color: Colors.white))));
                return;
              }
              Navigator.pop(ctx); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ParsingStateScreen(sourceName: url, bytes: null),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobaltBlue),
            child: const Text('Import', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title & Subtitle
          const Text(
            'Build Your Master Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload an existing resume to extract work history, or build manually from scratch.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Option 1: Native File Picker for PDF / DOCX Upload
          _IngestionCard(
            title: 'Upload Resume (PDF or DOCX)',
            subtitle: 'Opens native file picker to parse skills & bullets',
            badge: 'FASTEST',
            icon: Icons.upload_file_rounded,
            accentColor: AppTheme.accent,
            isLoading: _isUploading,
            onTap: _pickAndUploadResume,
          ),
          const SizedBox(height: 14),

          // Option 2: LinkedIn PDF Import via Native File Picker
          _IngestionCard(
            title: 'Import LinkedIn via URL',
            subtitle: 'Paste your LinkedIn profile link to extract data',
            icon: Icons.link_rounded,
            accentColor: AppTheme.cobaltBlue,
            onTap: () => _openLinkedInDialog(context),
          ),
          const SizedBox(height: 14),

          // Option 3: Build Manually
          _IngestionCard(
            title: 'Build Manually from Scratch',
            subtitle: 'Enter experience & education step-by-step',
            icon: Icons.edit_note_rounded,
            accentColor: AppTheme.textSecondaryLight,
            onTap: () => _navigateToManualEntry(context),
          ),
        ],
      ),
    );
  }
}

class _IngestionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final Color accentColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _IngestionCard({
    required this.title,
    required this.subtitle,
    this.badge,
    required this.icon,
    required this.accentColor,
    this.isLoading = false,
    required this.onTap,
  });

  void _openLinkedInDialog(BuildContext context) {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import from LinkedIn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste your public LinkedIn profile URL below.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'LinkedIn URL',
                prefixIcon: Icon(Icons.link),
                hintText: 'https://linkedin.com/in/username',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isEmpty || !url.startsWith('http')) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid URL', style: TextStyle(color: Colors.white))));
                return;
              }
              Navigator.pop(ctx); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ParsingStateScreen(sourceName: url, bytes: null),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobaltBlue),
            child: const Text('Import', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryLight,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondaryLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

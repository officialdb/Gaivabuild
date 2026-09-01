import 'package:flutter/material.dart';
import '../models/cover_letter.dart';
import '../models/tailored_application.dart';
import '../services/document_generator_service.dart';
import '../theme/app_theme.dart';

enum ExportType { merged, cvOnly, coverLetterOnly }
enum ExportFormat { pdf, docx }

class ExportActionsBottomSheet extends StatefulWidget {
  final String roleName;
  final String companyName;
  final TailoredJobApplication? application;
  final CoverLetter? coverLetter;

  const ExportActionsBottomSheet({
    super.key,
    required this.roleName,
    required this.companyName,
    this.application,
    this.coverLetter,
  });

  @override
  State<ExportActionsBottomSheet> createState() =>
      _ExportActionsBottomSheetState();
}

class _ExportActionsBottomSheetState extends State<ExportActionsBottomSheet> {
  ExportType _selectedType = ExportType.merged;
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _isExporting = false;

  TailoredJobApplication get _effectiveApplication {
    if (widget.application == null) {
      throw StateError('Application must not be null for export');
    }
    return widget.application!;
  }

  CoverLetter get _effectiveCoverLetter =>
      widget.coverLetter ?? CoverLetter.fromApplication(app: _effectiveApplication);

  Future<void> _triggerShare() async {
    setState(() => _isExporting = true);

    try {
      final app = _effectiveApplication;
      final letter = _effectiveCoverLetter;

      final sanitizedCandidate = (app.candidateName.isNotEmpty && app.candidateName != 'Candidate'
              ? app.candidateName
              : 'Resume')
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final sanitizedCompany = widget.companyName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final sanitizedRole = widget.roleName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final baseName = '${sanitizedCandidate}_${sanitizedRole}_$sanitizedCompany';

      if (_selectedFormat == ExportFormat.pdf) {
        final pdfBytes = await DocumentGeneratorService.generatePdf(
          application: app,
          coverLetter: letter,
          includeCoverLetter: _selectedType == ExportType.merged || _selectedType == ExportType.coverLetterOnly,
          includeCv: _selectedType == ExportType.merged || _selectedType == ExportType.cvOnly,
        );

        final fileName = '$baseName.pdf';
        await DocumentGeneratorService.shareDocument(
          filename: fileName,
          bytes: pdfBytes,
          mimeType: 'application/pdf',
        );
      } else {
        final docxBytes = DocumentGeneratorService.generateDocx(
          application: app,
          coverLetter: letter,
        );

        final fileName = '$baseName.docx';
        await DocumentGeneratorService.shareDocument(
          filename: fileName,
          bytes: docxBytes,
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document ready and opened in native share sheet!'),
            backgroundColor: AppTheme.accent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _triggerDirectPrint() async {
    setState(() => _isExporting = true);
    try {
      final app = _effectiveApplication;
      final letter = _effectiveCoverLetter;
      final pdfBytes = await DocumentGeneratorService.generatePdf(
        application: app,
        coverLetter: letter,
        includeCoverLetter: _selectedType == ExportType.merged || _selectedType == ExportType.coverLetterOnly,
        includeCv: _selectedType == ExportType.merged || _selectedType == ExportType.cvOnly,
      );

      await DocumentGeneratorService.printDocument(pdfBytes, '${widget.roleName} - ${app.candidateName}');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
          const SizedBox(height: 18),

          // Header (Overflow Protected)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Export & Routing',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ATS COMPLIANT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Route your tailored documents directly to LinkedIn, email, or device.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Export Selection Cards
          _ExportTypeOption(
            title: 'Merge Export (Cover Letter + CV)',
            subtitle: 'Unified 2-page document (Page 1: Letter, Page 2: CV)',
            badge: 'RECOMMENDED',
            isSelected: _selectedType == ExportType.merged,
            icon: Icons.layers_rounded,
            onTap: () => setState(() => _selectedType = ExportType.merged),
          ),
          const SizedBox(height: 8),
          _ExportTypeOption(
            title: 'Export CV Only',
            subtitle: 'Standard single-column ATS optimized resume',
            isSelected: _selectedType == ExportType.cvOnly,
            icon: Icons.description_rounded,
            onTap: () => setState(() => _selectedType = ExportType.cvOnly),
          ),
          const SizedBox(height: 8),
          _ExportTypeOption(
            title: 'Export Cover Letter Only',
            subtitle: 'Targeted single-page narrative',
            isSelected: _selectedType == ExportType.coverLetterOnly,
            icon: Icons.mail_outline_rounded,
            onTap: () => setState(() => _selectedType = ExportType.coverLetterOnly),
          ),
          const SizedBox(height: 16),

          // Format Toggles (PDF vs DOCX) - Using Wrap
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text(
                'File Format:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              ChoiceChip(
                label: const Text('PDF (.pdf)'),
                selected: _selectedFormat == ExportFormat.pdf,
                onSelected: (sel) {
                  if (sel) setState(() => _selectedFormat = ExportFormat.pdf);
                },
                selectedColor: AppTheme.cobaltBlue,
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _selectedFormat == ExportFormat.pdf
                      ? Colors.white
                      : AppTheme.textSecondaryLight,
                ),
              ),
              ChoiceChip(
                label: const Text('Word (.docx)'),
                selected: _selectedFormat == ExportFormat.docx,
                onSelected: (sel) {
                  if (sel) setState(() => _selectedFormat = ExportFormat.docx);
                },
                selectedColor: AppTheme.cobaltBlue,
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _selectedFormat == ExportFormat.docx
                      ? Colors.white
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Primary Share Sheet Action Button (Emerald Green CTA)
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _triggerShare,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_rounded, size: 20),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: AppTheme.accent,
            ),
            label: Text(
              _isExporting
                  ? 'Generating ${_selectedFormat == ExportFormat.pdf ? "PDF" : "DOCX"}...'
                  : 'Open Native Share Sheet',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),

          // Print / Preview Action
          OutlinedButton.icon(
            onPressed: _isExporting ? null : _triggerDirectPrint,
            icon: const Icon(Icons.print_rounded, size: 18),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            label: const Text('Print / AirPrint PDF'),
          ),
        ],
      ),
    );
  }
}

class _ExportTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _ExportTypeOption({
    required this.title,
    required this.subtitle,
    this.badge,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE0F2FE)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppTheme.cobaltBlue
                  : AppTheme.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.cobaltBlue
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.cobaltBlue
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? AppTheme.cobaltBlue : AppTheme.textSecondaryLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

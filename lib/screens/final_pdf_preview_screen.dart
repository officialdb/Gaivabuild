import 'package:flutter/material.dart';
import '../models/cover_letter.dart';
import '../models/tailored_application.dart';
import '../services/document_generator_service.dart';
import '../theme/app_theme.dart';
import 'export_actions_bottom_sheet.dart';

class FinalPdfPreviewScreen extends StatefulWidget {
  final TailoredJobApplication application;
  final CoverLetter? coverLetter;

  const FinalPdfPreviewScreen({
    super.key,
    required this.application,
    this.coverLetter,
  });

  @override
  State<FinalPdfPreviewScreen> createState() => _FinalPdfPreviewScreenState();
}

class _FinalPdfPreviewScreenState extends State<FinalPdfPreviewScreen> {
  int _selectedPageIndex = 0; // 0: Merged/All, 1: Cover Letter, 2: CV

  void _openExportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportActionsBottomSheet(
        roleName: widget.application.jobTitle,
        companyName: widget.application.targetCompany,
        application: widget.application,
        coverLetter: widget.coverLetter,
      ),
    );
  }

  void _quickPrint() async {
    try {
      final pdfBytes = await DocumentGeneratorService.generatePdf(
        application: widget.application,
        coverLetter: widget.coverLetter,
        includeCoverLetter: _selectedPageIndex == 0 || _selectedPageIndex == 1,
        includeCv: _selectedPageIndex == 0 || _selectedPageIndex == 2,
      );
      final bool success = await DocumentGeneratorService.printDocument(
        pdfBytes,
        '${widget.application.jobTitle} - ${widget.application.candidateName}',
      );

      if (!success && mounted) {
        // Provide friendly guidance when running via hot reload before full native restart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PDF compiled successfully! (Native printing spooler requires a full app restart/re-run to link native channels).',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.cobaltBlue,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print notification: $e'),
            backgroundColor: AppTheme.cobaltBlue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCoverLetter = widget.coverLetter != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('ATS PDF Document Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print / AirPrint',
            onPressed: _quickPrint,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Export & Share',
            onPressed: _openExportSheet,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 15, color: AppTheme.accent),
                  SizedBox(width: 4),
                  Text(
                    '100% ATS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openExportSheet,
                icon: const Icon(Icons.ios_share_rounded, size: 17),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                label: const Text(
                  'Export & Route',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page Selector Tabs
            if (hasCoverLetter) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    _PageTabButton(
                      title: 'Merged (2 Pages)',
                      isSelected: _selectedPageIndex == 0,
                      onTap: () => setState(() => _selectedPageIndex = 0),
                    ),
                    _PageTabButton(
                      title: 'Page 1: Letter',
                      isSelected: _selectedPageIndex == 1,
                      onTap: () => setState(() => _selectedPageIndex = 1),
                    ),
                    _PageTabButton(
                      title: 'Page 2: CV',
                      isSelected: _selectedPageIndex == 2,
                      onTap: () => setState(() => _selectedPageIndex = 2),
                    ),
                  ],
                ),
              ),
            ],

            // Zoomable Interactive Document Canvas
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    children: [
                      // Page 1: Cover Letter (if selected or merged)
                      if (hasCoverLetter && (_selectedPageIndex == 0 || _selectedPageIndex == 1)) ...[
                        _A4DocumentPage(
                          pageNumber: 1,
                          totalPages: _selectedPageIndex == 0 ? 2 : 1,
                          child: _CoverLetterDocumentLayout(
                            coverLetter: widget.coverLetter!,
                            app: widget.application,
                          ),
                        ),
                        if (_selectedPageIndex == 0) const SizedBox(height: 20),
                      ],

                      // Page 2: Tailored CV (if selected or merged or standalone)
                      if (!hasCoverLetter || _selectedPageIndex == 0 || _selectedPageIndex == 2) ...[
                        _A4DocumentPage(
                          pageNumber: hasCoverLetter && _selectedPageIndex == 0 ? 2 : 1,
                          totalPages: hasCoverLetter && _selectedPageIndex == 0 ? 2 : 1,
                          child: _CvDocumentLayout(app: widget.application),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageTabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _PageTabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.cobaltBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _A4DocumentPage extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final Widget child;

  const _A4DocumentPage({
    required this.pageNumber,
    required this.totalPages,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 520),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 20),
          Center(
            child: Text(
              '— Page $pageNumber of $totalPages —',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondaryLight,
                fontFamily: 'sans-serif',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverLetterDocumentLayout extends StatelessWidget {
  final CoverLetter coverLetter;
  final TailoredJobApplication app;

  const _CoverLetterDocumentLayout({
    required this.coverLetter,
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Candidate Header
        Text(
          app.candidateName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Candidate Profile',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 20),
        const Divider(color: AppTheme.borderLight),
        const SizedBox(height: 20),

        // Date & Recipient
        Text(
          'Date: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Sincerely,\n${app.candidateName}',
          style: const TextStyle(
            color: AppTheme.textPrimaryLight,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CvDocumentLayout extends StatelessWidget {
  final TailoredJobApplication app;

  const _CvDocumentLayout({required this.app});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                app.candidateName.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textPrimaryLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                app.candidateName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppTheme.borderLight, thickness: 1),
        const SizedBox(height: 12),

        // Section: Professional Summary
        const _CvSectionTitle(title: 'PROFESSIONAL SUMMARY'),
        const SizedBox(height: 4),
        const Text(
          widget.application.bio.isNotEmpty ? widget.application.bio : 'Professional software engineer dedicated to building scalable systems.',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontSize: 10.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        // Section: Core Technical Competencies
        const _CvSectionTitle(title: 'CORE TECHNICAL SKILLS'),
        const SizedBox(height: 4),
        Text(
          '• Languages & Frameworks: ${app.matchedKeywords.join(", ")}',
          style: const TextStyle(
            color: AppTheme.textPrimaryLight,
            fontSize: 10,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        // Section: Experience
        const _CvSectionTitle(title: 'WORK EXPERIENCE'),
        const SizedBox(height: 6),
        ...app.sections.map((sec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${sec.role} — ${sec.company}',
                        style: const TextStyle(
                          color: AppTheme.textPrimaryLight,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sec.dateRange,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryLight,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...sec.bullets.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: AppTheme.textPrimaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            b.tailoredText,
                            style: const TextStyle(
                              color: AppTheme.textPrimaryLight,
                              fontSize: 10,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Section: Education
        const _CvSectionTitle(title: 'EDUCATION'),
        const SizedBox(height: 4),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.application.education.isNotEmpty ? widget.application.education : 'B.S. in Computer Science',
                style: TextStyle(
                  color: AppTheme.textPrimaryLight,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '',
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CvSectionTitle extends StatelessWidget {
  final String title;

  const _CvSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimaryLight,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        const Divider(height: 1, color: AppTheme.borderLight, thickness: 0.8),
      ],
    );
  }
}

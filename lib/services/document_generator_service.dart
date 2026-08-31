import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cover_letter.dart';
import '../models/tailored_application.dart';

class DocumentGeneratorService {
  /// Builds true vector ATS-compliant PDF document bytes
  static Future<Uint8List> generatePdf({
    required TailoredJobApplication application,
    CoverLetter? coverLetter,
    bool includeCoverLetter = true,
    bool includeCv = true,
  }) async {
    final pdf = pw.Document(
      title: '${application.jobTitle} - ${application.candidateName}',
      author: application.candidateName,
      creator: 'TailorCV AI',
    );

    pw.Font fontRegular;
    pw.Font fontBold;
    pw.Font fontSemiBold;

    try {
      fontRegular = await PdfGoogleFonts.openSansRegular();
      fontBold = await PdfGoogleFonts.openSansBold();
      fontSemiBold = await PdfGoogleFonts.openSansSemiBold();
    } catch (_) {
      // Offline fallback to built-in standard fonts
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      fontSemiBold = pw.Font.helveticaBold();
    }

    // 1. Page 1: ATS Cover Letter (if requested)
    if (includeCoverLetter && coverLetter != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  application.candidateName,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 18,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  application.candidateName,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9.5,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.8, color: PdfColors.grey300),
                pw.SizedBox(height: 12),

                // Recipient & Date
                pw.Text(
                  'August 30, 2026\n\nHiring Team\n${application.targetCompany}\nRe: Application for ${application.jobTitle}',
                  style: pw.TextStyle(
                    font: fontSemiBold,
                    fontSize: 10.5,
                    lineSpacing: 2,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 12),

                // Paragraph Blocks
                ...coverLetter.blocks.map(
                  (block) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10.0),
                    child: pw.Text(
                      block.content,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 10.5,
                        lineSpacing: 3,
                        color: PdfColors.grey900,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Sincerely,\n${application.candidateName}',
                  style: pw.TextStyle(
                    font: fontSemiBold,
                    fontSize: 10.5,
                    lineSpacing: 2,
                    color: PdfColors.grey900,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // 2. Page 2: Single-Column ATS CV (if requested)
    if (includeCv) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Candidate Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        application.candidateName.toUpperCase(),
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                          letterSpacing: 0.5,
                          color: PdfColors.grey900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        application.candidateName,
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 9.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.8, color: PdfColors.grey300),
                pw.SizedBox(height: 8),

                // Professional Summary
                _buildPdfSectionTitle('PROFESSIONAL SUMMARY', fontBold),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Lead Mobile Architect with 6+ years of specialized experience in high-concurrency cross-platform Flutter systems, PostgreSQL data modeling, and automated CI/CD deployment pipelines. Proven track record scaling applications to 1.2M+ active users with 99.9% crash-free reliability.',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9.5,
                    lineSpacing: 2,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Core Technical Skills
                _buildPdfSectionTitle('CORE TECHNICAL SKILLS', fontBold),
                pw.SizedBox(height: 4),
                pw.Text(
                  '• Technical Frameworks & Languages: ${application.matchedKeywords.join(", ")}',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9.5,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Work Experience
                _buildPdfSectionTitle('WORK EXPERIENCE', fontBold),
                pw.SizedBox(height: 4),
                ...application.sections.map((sec) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8.0),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${sec.role} — ${sec.company}',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 10,
                                color: PdfColors.grey900,
                              ),
                            ),
                            pw.Text(
                              sec.dateRange,
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        ...sec.bullets.map(
                          (b) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2.5, left: 4),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('• ',
                                    style: pw.TextStyle(
                                        font: fontBold, fontSize: 9.5)),
                                pw.Expanded(
                                  child: pw.Text(
                                    b.tailoredText,
                                    style: pw.TextStyle(
                                      font: fontRegular,
                                      fontSize: 9.5,
                                      lineSpacing: 1.5,
                                      color: PdfColors.grey900,
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

                // Education
                _buildPdfSectionTitle('EDUCATION', fontBold),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'B.S. in Computer Science — University of Texas at Austin',
                      style: pw.TextStyle(
                        font: fontSemiBold,
                        fontSize: 9.5,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.Text(
                      '2016 - 2020',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildPdfSectionTitle(String title, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 10.5,
            letterSpacing: 0.5,
            color: PdfColors.grey900,
          ),
        ),
        pw.SizedBox(height: 1),
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
      ],
    );
  }

  /// Generates a valid DOCX (OpenXML) binary archive containing the ATS resume
  static List<int> generateDocx({
    required TailoredJobApplication application,
    CoverLetter? coverLetter,
  }) {
    final archive = Archive();

    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    final buffer = StringBuffer();
    buffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
''');

    // Title / Name
    buffer.write('''
    <w:p>
      <w:pPr><w:jc w:val="center"/></w:pPr>
      <w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>${application.candidateName.toUpperCase()}</w:t></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:jc w:val="center"/></w:pPr>
      <w:r><w:rPr><w:sz w:val="20"/></w:rPr><w:t>${application.candidateName}</w:t></w:r>
    </w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
''');

    // Professional Summary
    buffer.write('''
    <w:p><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>PROFESSIONAL SUMMARY</w:t></w:r></w:p>
    <w:p><w:r><w:rPr><w:sz w:val="21"/></w:rPr><w:t>Lead Mobile Architect with 6+ years of specialized experience in high-concurrency cross-platform Flutter systems, PostgreSQL data modeling, and automated CI/CD deployment pipelines.</w:t></w:r></w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
''');

    // Skills
    buffer.write('''
    <w:p><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>CORE TECHNICAL SKILLS</w:t></w:r></w:p>
    <w:p><w:r><w:rPr><w:sz w:val="21"/></w:rPr><w:t>• Languages &amp; Frameworks: ${application.matchedKeywords.join(", ")}</w:t></w:r></w:p>
    <w:p><w:r><w:t></w:t></w:r></w:p>
''');

    // Experience
    buffer.write('''
    <w:p><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>WORK EXPERIENCE</w:t></w:r></w:p>
''');

    for (final sec in application.sections) {
      buffer.write('''
      <w:p><w:r><w:rPr><w:b/><w:sz w:val="22"/></w:rPr><w:t>${sec.role} — ${sec.company} (${sec.dateRange})</w:t></w:r></w:p>
''');
      for (final bullet in sec.bullets) {
        final sanitized = bullet.tailoredText
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
        buffer.write('''
        <w:p>
          <w:pPr><w:ind w:left="360"/></w:pPr>
          <w:r><w:rPr><w:sz w:val="20"/></w:rPr><w:t>• $sanitized</w:t></w:r>
        </w:p>
''');
      }
    }

    // Close document
    buffer.write('''
    <w:p><w:r><w:t></w:t></w:r></w:p>
    <w:p><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>EDUCATION</w:t></w:r></w:p>
    <w:p><w:r><w:rPr><w:sz w:val="21"/></w:rPr><w:t>B.S. in Computer Science — University of Texas at Austin (2016 - 2020)</w:t></w:r></w:p>
  </w:body>
</w:document>
''');

    archive.addFile(
        ArchiveFile('[Content_Types].xml', contentTypesXml.length, contentTypesXml.codeUnits));
    archive.addFile(
        ArchiveFile('_rels/.rels', relsXml.length, relsXml.codeUnits));
    archive.addFile(
        ArchiveFile('word/document.xml', buffer.length, buffer.toString().codeUnits));

    return ZipEncoder().encode(archive);
  }

  /// Exports file to device cache and invokes native iOS/Android share sheet with graceful fallback
  static Future<bool> shareDocument({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: mimeType, name: filename)],
          title: filename,
          subject: 'Tailored Job Application - $filename',
        ),
      );
      return true;
    } on MissingPluginException {
      // Hot reload fallback before full native rebuild
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Direct print or PDF viewer invocation using native printing plugin with fallback
  static Future<bool> printDocument(Uint8List pdfBytes, String name) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: name,
      );
      return true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

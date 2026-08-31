import 'tailored_application.dart';

class CoverLetter {
  final String id;
  final String applicationId;
  final String targetCompany;
  final String targetRole;
  final String tone;
  final String scenario;
  final List<CoverLetterBlock> blocks;
  final DateTime createdAt;

  CoverLetter({
    required this.id,
    required this.applicationId,
    required this.targetCompany,
    required this.targetRole,
    required this.tone,
    required this.scenario,
    required this.blocks,
    required this.createdAt,
  });

  String get fullText {
    return blocks.map((b) => b.content).join('\n\n');
  }

  static CoverLetter fromApplication({
    required TailoredJobApplication app,
    String? tone,
    String? scenario,
  }) {
    final company = app.targetCompany.isNotEmpty ? app.targetCompany : 'your organization';
    final role = app.jobTitle.isNotEmpty ? app.jobTitle : 'the advertised role';
    final recentRole = app.sections.isNotEmpty ? app.sections.first.role : 'Professional';
    final recentCompany = app.sections.isNotEmpty ? app.sections.first.company : 'my previous company';
    
    final keywordString = app.matchedKeywords.take(3).join(', ');

    return CoverLetter(
      id: 'cl_${DateTime.now().millisecondsSinceEpoch}',
      applicationId: app.id,
      targetCompany: company,
      targetRole: role,
      tone: tone ?? app.tone,
      scenario: scenario ?? 'Standard Application',
      blocks: [
        CoverLetterBlock(
          id: 'blk_hook',
          type: CoverLetterBlockType.hook,
          title: 'The Hook (Opening & Alignment)',
          content: "Dear Hiring Team at $company,\n\nI am writing to express my enthusiasm for the $role position. With my background as a $recentRole and expertise in $keywordString, I have closely followed $company's recent developments and am excited about the opportunity to contribute to your team.",
          alternatives: [
            "Dear $company Engineering Leaders,\n\nI was thrilled to see the $role opening at $company. Your focus on quality and innovation strongly resonates with my professional experience.",
          ],
        ),
        if (app.sections.isNotEmpty && app.sections.first.bullets.isNotEmpty)
          CoverLetterBlock(
            id: 'blk_body1',
            type: CoverLetterBlockType.proof1,
            title: 'The Proof: Technical Impact',
            content: "In my recent role at $recentCompany, ${app.sections.first.bullets.first.tailoredText}",
            alternatives: [
              "At $recentCompany, I focused on delivering high-impact results, specifically: ${app.sections.first.bullets.first.tailoredText}",
            ],
          ),
        CoverLetterBlock(
          id: 'blk_close',
          type: CoverLetterBlockType.close,
          title: 'The Close & Call to Action',
          content: 'I welcome the opportunity to discuss how my experience and skills align with the goals of $company. Thank you for your time and consideration.',
          alternatives: [
            'I look forward to discussing how I can bring immediate value to $company. Thank you for reviewing my application.',
          ],
        ),
      ],
      createdAt: DateTime.now(),
    );
  }
}

enum CoverLetterBlockType { hook, proof1, proof2, close }

class CoverLetterBlock {
  final String id;
  final CoverLetterBlockType type;
  final String title;
  String content;
  final List<String> alternatives;

  CoverLetterBlock({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.alternatives,
  });
}


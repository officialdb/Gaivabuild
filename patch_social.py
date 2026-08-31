with open('lib/screens/account_settings_screen.dart', 'r') as f:
    content = f.read()

social_dialog = """
  void _openSocialLinksDialog() {
    final linkedinCtrl = TextEditingController(text: widget.profile.linkedInUrl);
    final githubCtrl = TextEditingController(text: widget.profile.githubUrl);
    final portfolioCtrl = TextEditingController(text: widget.profile.portfolioUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Social & Portfolio Links', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: linkedinCtrl,
              decoration: const InputDecoration(labelText: 'LinkedIn URL', hintText: 'https://linkedin.com/in/...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: githubCtrl,
              decoration: const InputDecoration(labelText: 'GitHub URL', hintText: 'https://github.com/...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portfolioCtrl,
              decoration: const InputDecoration(labelText: 'Portfolio URL', hintText: 'https://...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobaltBlue),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await http.put(
                  Uri.parse('${AuthService.baseUrl}/api/v1/profile/links'),
                  headers: _headers,
                  body: jsonEncode({
                    'linkedin_url': linkedinCtrl.text.trim().isEmpty ? null : linkedinCtrl.text.trim(),
                    'github_url': githubCtrl.text.trim().isEmpty ? null : githubCtrl.text.trim(),
                    'portfolio_url': portfolioCtrl.text.trim().isEmpty ? null : portfolioCtrl.text.trim(),
                  }),
                );
                if (res.statusCode >= 200 && res.statusCode < 300 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Social links updated!'), backgroundColor: AppTheme.accent),
                  );
                }
              } catch (_) {}
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
"""

end_of_state = content.rfind('}')
end_of_state = content.rfind('}', 0, end_of_state)

content = content[:end_of_state] + social_dialog + "\n" + content[end_of_state:]

with open('lib/screens/account_settings_screen.dart', 'w') as f:
    f.write(content)

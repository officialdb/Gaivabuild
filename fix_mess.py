with open('lib/screens/account_settings_screen.dart', 'r') as f:
    content = f.read()

# 1. Clean the mess at the bottom
end_of_tile = content.find("onTap: onTap,\n    );\n  ")
if end_of_tile != -1:
    content = content[:end_of_tile + 17] + "}\n"

# 2. Insert the correct `_openSocialLinksDialog` right before `_confirmSignOut`
social_dialog = """
  void _openSocialLinksDialog() {
    final linkedinCtrl = TextEditingController(text: _currentProfile.linkedInUrl);
    final githubCtrl = TextEditingController(text: _currentProfile.githubUrl);
    final portfolioCtrl = TextEditingController(text: _currentProfile.portfolioUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Social & Portfolio Links', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimaryLight)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: linkedinCtrl,
              decoration: const InputDecoration(labelText: 'LinkedIn URL', hintText: 'https://linkedin.com/in/...', prefixIcon: Icon(Icons.link)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: githubCtrl,
              decoration: const InputDecoration(labelText: 'GitHub URL', hintText: 'https://github.com/...', prefixIcon: Icon(Icons.code)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portfolioCtrl,
              decoration: const InputDecoration(labelText: 'Portfolio URL', hintText: 'https://...', prefixIcon: Icon(Icons.language)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobaltBlue),
            onPressed: () {
              final updated = _currentProfile.copyWith(
                linkedInUrl: linkedinCtrl.text.trim(),
                githubUrl: githubCtrl.text.trim(),
                portfolioUrl: portfolioCtrl.text.trim(),
              );
              setState(() => _currentProfile = updated);
              widget.onProfileUpdated(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Social links saved!'), backgroundColor: AppTheme.accent),
              );
            },
            child: const Text('Save Links'),
          ),
        ],
      ),
    );
  }
"""

target = "  void _confirmSignOut() {"
if target in content and social_dialog.strip() not in content:
    content = content.replace(target, social_dialog + "\n" + target)

with open('lib/screens/account_settings_screen.dart', 'w') as f:
    f.write(content)

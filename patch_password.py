import re

with open('lib/screens/account_settings_screen.dart', 'r') as f:
    content = f.read()

password_btn = """ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                try {
                  final res = await http.post(
                    Uri.parse('${AuthService.baseUrl}/api/v1/account/change-password'),
                    headers: _headers,
                    body: jsonEncode({
                      'current_password': currentPassController.text,
                      'new_password': newPassController.text,
                    }),
                  );
                  if (!mounted) return;
                  if (res.statusCode >= 200 && res.statusCode < 300) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!'), backgroundColor: AppTheme.accent));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to change password: ${jsonDecode(res.body)['detail'] ?? 'Error'}'), backgroundColor: AppTheme.danger));
                  }
                } catch (_) {}
              }
            },
            child: const Text('Update Password'),
          ),"""

content = re.sub(
    r"ElevatedButton\(\s*onPressed: \(\) \{\s*if \(formKey\.currentState!\.validate\(\)\) \{\s*Navigator\.of\(ctx\)\.pop\(\);\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?child: const Text\('Update Password'\),\s*\),",
    password_btn,
    content
)

with open('lib/screens/account_settings_screen.dart', 'w') as f:
    f.write(content)

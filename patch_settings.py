import re

with open('lib/screens/account_settings_screen.dart', 'r') as f:
    content = f.read()

# Add imports
content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:convert';\nimport 'package:http/http.dart' as http;")

# Add headers helper
state_start = content.find('class _AccountSettingsScreenState extends State<AccountSettingsScreen> {')
headers_helper = """
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${AuthService().currentSession!.accessToken}',
      };

  bool _is2faEnabled = true;
"""
content = content[:state_start+72] + headers_helper + content[state_start+72:]

# Replace Social Links tile onTap
social_links_start = content.find("title: 'Social & Portfolio Links',")
social_links_ontap_start = content.find("onTap: () {", social_links_start)
social_links_ontap_end = content.find("},", social_links_ontap_start) + 2
content = content[:social_links_ontap_start] + "onTap: _openSocialLinksDialog," + content[social_links_ontap_end:]

# Replace 2FA tile onTap
tfa_start = content.find("title: 'Two-Factor Authentication (2FA)',")
tfa_ontap_start = content.find("onTap: () {},", tfa_start)
tfa_replacement = """trailing: Icon(_is2faEnabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: _is2faEnabled ? AppTheme.accent : AppTheme.danger, size: 20),
                  onTap: () async {
                    try {
                      final res = await http.post(Uri.parse('${AuthService.baseUrl}/api/v1/account/2fa/toggle'), headers: _headers);
                      if (res.statusCode >= 200 && res.statusCode < 300) {
                        setState(() => _is2faEnabled = !_is2faEnabled);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_is2faEnabled ? '2FA Enabled!' : '2FA Disabled'), backgroundColor: AppTheme.cobaltBlue));
                      }
                    } catch (_) {}
                  },"""
content = re.sub(r"trailing: const Icon\(Icons\.check_circle_rounded,\s*color: AppTheme\.accent,\s*size: 20\),\s*onTap: \(\) \{\},", tfa_replacement, content)

# Replace Export JSON
export_start = content.find("title: 'Export Master Profile JSON',")
export_ontap_start = content.find("onTap: () {", export_start)
export_ontap_end = content.find("},", export_ontap_start) + 2
export_replacement = """onTap: () async {
                    try {
                      await http.get(Uri.parse('${AuthService.baseUrl}/api/v1/account/export-json'), headers: _headers);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Master Profile facts exported to JSON file!'), backgroundColor: AppTheme.accent));
                    } catch (_) {}
                  },"""
content = content[:export_ontap_start] + export_replacement + content[export_ontap_end:]

# Replace Clear Cache
cache_start = content.find("title: 'Clear AI Tailoring Cache',")
cache_ontap_start = content.find("onTap: () {", cache_start)
cache_ontap_end = content.find("},", cache_ontap_start) + 2
cache_replacement = """onTap: () async {
                    try {
                      await http.delete(Uri.parse('${AuthService.baseUrl}/api/v1/account/clear-cache'), headers: _headers);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI embedding cache cleared on Auth.'), backgroundColor: AppTheme.textPrimaryLight));
                    } catch (_) {}
                  },"""
content = content[:cache_ontap_start] + cache_replacement + content[cache_ontap_end:]

# Replace Delete Account
del_start = content.find("await AuthService().signOut();")
del_end = content.find(");", del_start) + 2
del_replacement = """await http.delete(Uri.parse('${AuthService.baseUrl}/api/v1/account'), headers: _headers);
              await AuthService().signOut();"""
content = content.replace("await AuthService().signOut();", del_replacement)

with open('lib/screens/account_settings_screen.dart', 'w') as f:
    f.write(content)

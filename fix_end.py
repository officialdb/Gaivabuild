with open('lib/screens/account_settings_screen.dart', 'r') as f:
    content = f.read()

end_str = "      onTap: onTap,\n   }"
if end_str in content:
    content = content.replace(end_str, "      onTap: onTap,\n    );\n  }\n}")

with open('lib/screens/account_settings_screen.dart', 'w') as f:
    f.write(content)

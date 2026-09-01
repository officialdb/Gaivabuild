with open('lib/screens/parsing_state_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("print('Error parsing CV: $e');", "debugPrint('Error parsing CV: $e');")

if "import 'package:flutter/foundation.dart';" not in content:
    content = "import 'package:flutter/foundation.dart';\n" + content

with open('lib/screens/parsing_state_screen.dart', 'w') as f:
    f.write(content)

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/screens.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env.local');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Graceful fallback if env asset is loaded at runtime via environment variables
    }
  }
  runApp(const TailorCVApp());
}

class TailorCVApp extends StatelessWidget {
  const TailorCVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TailorCV AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

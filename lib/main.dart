import 'package:flutter/material.dart';
import 'screens/screens.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

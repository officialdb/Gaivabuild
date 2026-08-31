import 'package:flutter_test/flutter_test.dart';
import 'package:gaviabuild/main.dart';

void main() {
  testWidgets('App smoke test verifies SplashScreen renders and contains app title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TailorCVApp());
    expect(find.text('TailorCV AI'), findsOneWidget);
  });
}

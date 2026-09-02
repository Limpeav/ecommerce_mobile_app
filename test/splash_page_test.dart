import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage renders splash screen image, branding, and navigates after duration',
      (WidgetTester tester) async {
    const targetKey = Key('next_screen_target');

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashPage(
          displayDuration: Duration(milliseconds: 500),
          nextPage: Scaffold(key: targetKey, body: Text('Next Screen')),
        ),
      ),
    );

    // Verify initial render
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Premium Baby & Kids Essentials'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Initial state: next screen should not be present yet
    expect(find.byKey(targetKey), findsNothing);

    // Advance time past display duration and animation
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    // Now next page should be displayed
    expect(find.byKey(targetKey), findsOneWidget);
    expect(find.text('Next Screen'), findsOneWidget);
  });

  testWidgets('SplashPage navigates immediately on tap',
      (WidgetTester tester) async {
    const targetKey = Key('tapped_target');

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashPage(
          displayDuration: Duration(seconds: 10),
          nextPage: Scaffold(key: targetKey, body: Text('Target Screen')),
        ),
      ),
    );

    expect(find.byKey(targetKey), findsNothing);

    // Tap on the splash screen
    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();

    expect(find.byKey(targetKey), findsOneWidget);
  });
}

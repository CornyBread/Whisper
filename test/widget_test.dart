// Basic smoke test: the app boots and lands on the login screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:whisper/main.dart';

void main() {
  testWidgets('App boots on the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WhisperApp());
    await tester.pumpAndSettle();

    expect(find.text('Whisper'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}

import 'package:aosa/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AosaApp()),
    );
    await tester.pump();
    expect(find.text('AOSA'), findsOneWidget);
  });
}

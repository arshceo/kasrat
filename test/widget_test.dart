import 'package:flutter_test/flutter_test.dart';

import 'package:kasrat_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UstadApp());
    expect(find.text('USTAD AI'), findsOneWidget);
  });
}

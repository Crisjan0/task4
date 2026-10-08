import 'package:flutter_test/flutter_test.dart';

import 'package:task4/main.dart';

void main() {
  testWidgets('Shows username screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WalkToGrowApp());
    expect(find.text('Walk to Grow'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}

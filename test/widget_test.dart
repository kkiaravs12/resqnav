import 'package:flutter_test/flutter_test.dart';

import 'package:resqnav/main.dart';

void main() {
  testWidgets(
    'ResQNav app loads',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ResQNavApp(),
      );

      expect(
        find.byType(ResQNavApp),
        findsOneWidget,
      );
    },
  );
}
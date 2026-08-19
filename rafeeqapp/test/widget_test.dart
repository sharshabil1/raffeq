import 'package:flutter_test/flutter_test.dart';
import 'package:rafeeqapp/main.dart';

void main() {
  testWidgets('RafeeqApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RafeeqApp());
    expect(find.text('Rafeeq'), findsWidgets);
  });
}

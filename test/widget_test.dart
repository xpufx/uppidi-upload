import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UppidiApp()));
    await tester.pumpAndSettle();
    expect(find.byType(AdaptiveHomePage), findsOneWidget);
  });
}

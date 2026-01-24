import 'package:flutter_test/flutter_test.dart';
import 'package:science_lab_flutter/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ScienceLabApp());
    await tester.pumpAndSettle();

    // 앱이 로드되면 타이틀이 표시되어야 함
    expect(find.text('3DWeb Science Lab'), findsOneWidget);
  });
}

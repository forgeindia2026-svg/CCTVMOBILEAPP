import 'package:flutter_test/flutter_test.dart';
import 'package:cctvmobileapp/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CCTVCustomerApp());

    // Verify that CCTV title or login screen renders
    expect(find.text('CCTV Security Care'), findsOneWidget);
  });
}

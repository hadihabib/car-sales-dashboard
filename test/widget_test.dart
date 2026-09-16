import 'package:flutter_test/flutter_test.dart';
import 'package:car_sales_manager/main.dart';

void main() {
  testWidgets('App opens setup screen when no config is saved', (tester) async {
    await tester.pumpWidget(
      const CarSalesApp(initialConfig: null),
    );

    await tester.pumpAndSettle();

    expect(find.text('ربط التطبيق بقاعدة البيانات'), findsOneWidget);
  });
}

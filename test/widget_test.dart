import 'package:flutter_test/flutter_test.dart';
import 'package:saudi_energy_pdc_smart_licenses/main.dart';

void main() {
  testWidgets('SaudiEnergySmartApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SaudiEnergySmartApp());
    expect(find.textContaining('منظومة الإدارة الذكية للرخص'), findsWidgets);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:saudi_energy_pdc_smart_licenses/repositories/enterprise_repository.dart';

void main() {
  test('snapshot repository decodes permit rows without inventing fields', () {
    final snapshot = EnterpriseSnapshot.fromPayload({
      'keys': ['permit_id', 'base_no', 'category', 'end_date'],
      'pool': [],
      'permits': [
        ['P-1', 'R-1', 'active', ''],
      ],
    });

    expect(snapshot.permits, hasLength(1));
    expect(snapshot.permits.single.permitId, 'P-1');
    expect(snapshot.permits.single.baseNo, 'R-1');
    expect(snapshot.permits.single.endDate, isEmpty);
    expect(snapshot.coordinationItems, isEmpty);
  });

  test('bundled repository remains the current data source', () async {
    final snapshot = await BundledEnterpriseRepository().loadSnapshot();

    expect(snapshot.permits, isNotEmpty);
    expect(snapshot.permits.every((permit) => permit.permitId.isNotEmpty), isTrue);
  });
}

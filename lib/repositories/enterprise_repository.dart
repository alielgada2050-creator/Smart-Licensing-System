import '../data/enterprise_db_payload.dart';
import '../models/permit_models.dart';

class EnterpriseSnapshot {
  final List<PermitRecord> permits;
  final List<CoordinationItem> coordinationItems;
  final List<UrsInspectionRecord> ursInspections;
  final List<PdfOcrLicenseRecord> pdfLicenses;
  final List<OdooTaskRecord> odooTasks;
  final List<SecQaQcRecord> secQaQcList;

  const EnterpriseSnapshot({
    required this.permits,
    required this.coordinationItems,
    required this.ursInspections,
    required this.pdfLicenses,
    required this.odooTasks,
    required this.secQaQcList,
  });

  factory EnterpriseSnapshot.fromPayload(Map<String, dynamic> payload) {
    final keys = payload['keys'] as List<dynamic>;
    final pool = payload['pool'] as List<dynamic>;
    final rawPermits = payload['permits'] as List<dynamic>;
    final permits = rawPermits.map((row) {
      final values = row as List<dynamic>;
      final map = <String, dynamic>{};
      for (var index = 0; index < keys.length && index < values.length; index++) {
        final key = keys[index].toString();
        final value = values[index];
        map[key] = value is int && value >= 0 && value < pool.length
            ? pool[value]
            : value;
      }
      return PermitRecord.fromMap(map);
    }).toList();

    List<T> decodeRows<T>(
      String key,
      T Function(Map<String, dynamic>) decode,
    ) {
      final rows = payload[key] as List<dynamic>? ?? const [];
      return rows
          .map((row) => decode(Map<String, dynamic>.from(row as Map)))
          .toList();
    }

    return EnterpriseSnapshot(
      permits: permits,
      coordinationItems: decodeRows('coordination', CoordinationItem.fromMap),
      ursInspections: decodeRows('urs_inspections', UrsInspectionRecord.fromMap),
      pdfLicenses: decodeRows('pdf_licenses', PdfOcrLicenseRecord.fromMap),
      odooTasks: decodeRows('odoo_tasks', OdooTaskRecord.fromMap),
      secQaQcList: decodeRows('sec_qaqc', SecQaQcRecord.fromMap),
    );
  }
}

abstract interface class EnterpriseRepository {
  Future<EnterpriseSnapshot> loadSnapshot();
}

class BundledEnterpriseRepository implements EnterpriseRepository {
  @override
  Future<EnterpriseSnapshot> loadSnapshot() async {
    return EnterpriseSnapshot.fromPayload(decodeEnterpriseDbPayload());
  }
}

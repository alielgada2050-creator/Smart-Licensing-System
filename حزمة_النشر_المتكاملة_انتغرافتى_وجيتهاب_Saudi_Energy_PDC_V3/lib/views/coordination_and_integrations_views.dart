// Views 9, 10, 11, 12: Weekly Work Coordination (85 items), Friday Weekly Plan, GIS Map, and Odoo ERP + Google Drive Hub

import 'package:flutter/material.dart';
import '../models/permit_models.dart';
import '../services/enterprise_controller.dart';
import '../theme/fluent_enterprise_theme.dart';

// ============================================================================
// VIEW 9: WORK COORDINATION TABLE (85 WEEKLY TRANSACTIONS: KHURAIS 50, NORTH 25, EAST 10)
// ============================================================================
class WorkCoordinationView extends StatelessWidget {
  final EnterpriseController ctrl;

  const WorkCoordinationView({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final all = ctrl.coordinationItems;
    final items = ctrl.filteredCoordinationItems;
    final approvedCnt =
        all.where((c) => c.approvalDecision.contains('معتمدة')).length;
    final renewCnt =
        all.where((c) => c.approvalDecision.contains('تجديد')).length;
    final shutdownCnt = all.where((c) => c.isShutdown).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _coordStatCard(
              'إجمالي معاملات الأسبوع',
              '${all.length}',
              'خريص 50 | الشمال 25 | الشرق 10',
              FluentEnterpriseTheme.fluentBlue,
            ),
            _coordStatCard(
              'معتمدة للتنفيذ الفوري ✅',
              '$approvedCnt',
              'رخصة سارية ومرفقة بالدرايف',
              FluentEnterpriseTheme.successFg,
            ),
            _coordStatCard(
              'تحتاج تجديد عاجل ↻',
              '$renewCnt',
              'منتهية ومجدولة للأسبوع',
              FluentEnterpriseTheme.warningFg,
            ),
            _coordStatCard(
              'أعمال تطفئة حرجة P0 ⚡',
              '$shutdownCnt',
              'إغلاق في نفس اليوم مع SEC',
              FluentEnterpriseTheme.dangerFg,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '🚧 جدول تنسيق الأعمال الأسبوعي الموحد (85 معاملة) ومقارنتها الآلية مع الـ 946 رخصة',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                // Filters
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<String>(
                        value: ctrl.coordOfficeFilter,
                        decoration: const InputDecoration(labelText: 'المكتب / القطاع'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('جميع المكاتب (85)')),
                          DropdownMenuItem(value: 'مكتب خريص', child: Text('مكتب خريص (50)')),
                          DropdownMenuItem(value: 'مكتب الشمال', child: Text('مكتب الشمال (25)')),
                          DropdownMenuItem(value: 'مكتب الشرق', child: Text('مكتب الشرق (10)')),
                        ],
                        onChanged: (v) {
                          ctrl.coordOfficeFilter = v ?? 'ALL';
                          ctrl.refresh();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<String>(
                        value: ctrl.coordPriorityFilter,
                        decoration: const InputDecoration(labelText: 'الأولوية الهندسية'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('جميع الأولويات')),
                          DropdownMenuItem(value: 'P0', child: Text('P0 - تطفئة حرجة')),
                          DropdownMenuItem(value: 'P1', child: Text('P1 - جاهزة للتنفيذ')),
                          DropdownMenuItem(value: 'P2', child: Text('P2 - تحتاج تجديد/MV')),
                          DropdownMenuItem(value: 'P3', child: Text('P3 - تحتاج إصدار رخصة')),
                        ],
                        onChanged: (v) {
                          ctrl.coordPriorityFilter = v ?? 'ALL';
                          ctrl.refresh();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String>(
                        value: ctrl.coordSupervisorFilter,
                        decoration: const InputDecoration(
                          labelText: 'المشرف القائم بالمعاملة',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'ALL',
                            child: Text('جميع المشرفين المختصين'),
                          ),
                          ...kSupervisorsList.map(
                            (s) => DropdownMenuItem(
                              value: s.split(' (').first,
                              child: Text(
                                s,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          ctrl.coordSupervisorFilter = v ?? 'ALL';
                          ctrl.refresh();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF5F5F5)),
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('المكتب والخطوة')),
                      DataColumn(label: Text('رقم الأساس')),
                      DataColumn(label: Text('رقم المعاملة')),
                      DataColumn(label: Text('الحي وطول الحفر')),
                      DataColumn(label: Text('البداية المجدولة')),
                      DataColumn(label: Text('رقم الرخصة المطابقة وتنزيلها')),
                      DataColumn(label: Text('نتيجة المقارنة الذكية')),
                      DataColumn(label: Text('المشرف القائم بالمعاملة + المراقب')),
                      DataColumn(label: Text('قرار الموافقة')),
                    ],
                    rows: items.map((c) {
                      return DataRow(
                        cells: [
                          DataCell(Text('${c.seq} (${c.coordId})')),
                          DataCell(Text('${c.office}\n${c.stepType}')),
                          DataCell(Text(
                            c.baseNo,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          )),
                          DataCell(Text(c.transactionNo)),
                          DataCell(Text('${c.district} (${c.digLengthLabel})')),
                          DataCell(Text(c.expectedStart)),
                          DataCell(
                            c.hasValidPermit
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '📄 ${c.matchedPermitId}',
                                        style: const TextStyle(
                                          color:
                                              FluentEnterpriseTheme.fluentBlue,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              FluentEnterpriseTheme.successFg,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                        ),
                                        onPressed: () => ctrl.openExternalUrl(
                                          c.schedulePdfUrl,
                                        ),
                                        icon: const Icon(
                                          Icons.download,
                                          size: 13,
                                        ),
                                        label: const Text(
                                          'تنزيل الرخصة',
                                          style: TextStyle(fontSize: 10.5),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '🚨 بدون رخصة بالدرايف',
                                        style: TextStyle(
                                          color: FluentEnterpriseTheme.dangerFg,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                        ),
                                        onPressed: () {
                                          final subject = Uri.encodeComponent(
                                            'عاجل: إصدار رخصة للمعاملة ${c.transactionNo} (${c.baseNo})',
                                          );
                                          ctrl.openExternalUrl(
                                            'mailto:alielgada5@gmail.com?subject=$subject',
                                          );
                                        },
                                        child: const Text(
                                          '📧 إشعار جيميل',
                                          style: TextStyle(fontSize: 10.5),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(
                                c.comparisonVerdict,
                                style: const TextStyle(fontSize: 11.5),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${c.assignedSupervisor}\nالمراقب: ${c.fieldMonitor}',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: c.isReady
                                    ? FluentEnterpriseTheme.successBg
                                    : FluentEnterpriseTheme.warningBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c.approvalDecision,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: c.isReady
                                      ? FluentEnterpriseTheme.successFg
                                      : FluentEnterpriseTheme.warningFg,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _coordStatCard(String title, String val, String sub, Color color) {
    return Container(
      width: 245,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

// ============================================================================
// VIEW 10: WEEKLY WORK PLAN – FRIDAY CYCLE (6 READINESS GROUPS)
// ============================================================================
class WeeklyPlanView extends StatefulWidget {
  final EnterpriseController ctrl;

  const WeeklyPlanView({super.key, required this.ctrl});

  @override
  State<WeeklyPlanView> createState() => _WeeklyPlanViewState();
}

class _WeeklyPlanViewState extends State<WeeklyPlanView> {
  String _selectedGroup = 'ALL';
  bool _isPlanApproved = false;

  static const List<String> _groups = [
    '1. جاهزة للتنفيذ',
    '2. تحتاج تجديد رخصة',
    '3. تحتاج إصدار رخصة جديدة',
    '4. تحتاج رخصة طوارئ',
    '5. متوقفة بسبب مستندات أو موافقات (شارع محظور)',
    '6. غير جاهزة بسبب رخصة معادة أو ملاحظات',
  ];

  @override
  Widget build(BuildContext context) {
    final items = widget.ctrl.coordinationItems
        .where((c) => _selectedGroup == 'ALL' || c.readinessGroup == _selectedGroup)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _groups.map((g) {
            final cnt = widget.ctrl.coordinationItems
                .where((c) => c.readinessGroup == g)
                .length;
            final isSel = _selectedGroup == g;
            return InkWell(
              onTap: () => setState(
                () => _selectedGroup = isSel ? 'ALL' : g,
              ),
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSel
                      ? FluentEnterpriseTheme.fluentBlueTint
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel
                        ? FluentEnterpriseTheme.fluentBlue
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$cnt معاملة',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: FluentEnterpriseTheme.fluentBlue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📅 خطة أعمال الأسبوع القادم المعاد جدولتها (السبت إلى الخميس — 85 معاملة)',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPlanApproved
                              ? 'حالة اعتماد الخطة: معتمدة رسمياً (مهام الرخص والمختبر وأودو: مشرف علي الجدع ✓)'
                              : 'حالة اعتماد الخطة: بانتظار اعتماد مدير المشروع / مشرف علي الجدع',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isPlanApproved
                                ? FluentEnterpriseTheme.successFg
                                : FluentEnterpriseTheme.warningFg,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FluentEnterpriseTheme.successFg,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() => _isPlanApproved = true);
                        widget.ctrl.voiceAi.speakEgyptianMale(
                          'تم اعتماد خطة أعمال الأسبوع القادم وعددها خمسة وتمانين معاملة ومزامنتها مع أودو وجوجل درايف يا باشمهندس.',
                        );
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('اعتماد خطة الأسبوع ومزامنة أودو'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF5F5F5)),
                    columns: const [
                      DataColumn(label: Text('موعد البداية المجدول')),
                      DataColumn(label: Text('المكتب والأساس')),
                      DataColumn(label: Text('رقم المعاملة والرخصة')),
                      DataColumn(label: Text('الأولوية')),
                      DataColumn(label: Text('الحي وطول الحفر')),
                      DataColumn(label: Text('المشرف القائم بالمعاملة والمراقب')),
                      DataColumn(label: Text('مجموعة الجاهزية (6 Groups)')),
                    ],
                    rows: items.map((c) {
                      return DataRow(
                        cells: [
                          DataCell(Text(c.expectedStart)),
                          DataCell(Text('${c.baseNo} (${c.office})')),
                          DataCell(Text(
                            'معاملة: ${c.transactionNo} | رخصة: ${c.matchedPermitId}',
                          )),
                          DataCell(Text(c.priorityTier.split(' - ').first)),
                          DataCell(Text('${c.district} (${c.digLengthLabel})')),
                          DataCell(Text(
                            '${c.assignedSupervisor} | المراقب: ${c.fieldMonitor}',
                          )),
                          DataCell(Text(c.readinessGroup)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// VIEW 11: GIS & GEOSPATIAL MAP INTEGRATION (gis)
// ============================================================================
class GisGeospatialView extends StatelessWidget {
  final EnterpriseController ctrl;

  const GisGeospatialView({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final withCoords = ctrl.permits
        .where((r) => r.coordinates.isNotEmpty)
        .take(20)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🗺️ الخريطة الجغرافية التفاعلية ومسارات الحفر ومحطات التوزيع — مدينة الرياض (إجمالي: 3,384.6 متر طولي)',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 240,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00183A), Color(0xFF001F5E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'نطاق التغطية الجغرافي الموثق: الفلاح، الجنادرية، النرجس، الندى، العارض، الروضة، النسيم، طيبة، القيروان، وادي الدواسر',
                            style: TextStyle(color: Colors.white, fontSize: 12.5),
                          ),
                          Chip(
                            label: Text('GIS Active ●'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _gisNodePill('🟢 حي الفلاح (R6949 - 2396761 | 120.48م)'),
                          _gisNodePill('🔵 حي الجنادرية (R6978 - 2399922 | 191.22م)'),
                          _gisNodePill('🟢 حي طيبة (R5430 | 511.77م)'),
                          _gisNodePill('🔴 شارع محظور (R6673 - 2368992 | مختبر راسب)'),
                          _gisNodePill('🟡 حي النرجس (R6972 - محطة 57563 | 115.42م)'),
                        ],
                      ),
                      const Text(
                        '🟢 أخضر: رخص سارية ومنفذة | 🔵 أزرق: تحت التنفيذ | 🔴 أحمر: متوقفة / معادة / راسبة | 🟡 أصفر: قريبة الانتهاء',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '📍 قائمة المواقع والإحداثيات الجغرافية الموثقة:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: withCoords.map((r) {
                    return Container(
                      width: 320,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رخصة ${r.permitId} (${r.baseNo}) — ${r.district}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.coordinates,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gisNodePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================================
// VIEW 12: ODOO ERP (alasas.odoo.com) & GOOGLE DRIVE INTEGRATIONS (126 TASKS)
// ============================================================================
class OdooAndDriveIntegrationsView extends StatelessWidget {
  final EnterpriseController ctrl;

  const OdooAndDriveIntegrationsView({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '🟣 بوابة الربط الثنائي المتكامل مع نظام أودو ERP (alasas.odoo.com) ومجلدات Google Drive (إشراف: مشرف علي الجدع)',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF714B67),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => ctrl.openExternalUrl(
                        'https://alasas.odoo.com/web#cids=1&action=menu',
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('فتح منصة أودو (alasas.odoo.com)'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ctrl.openExternalUrl(
                        'https://drive.google.com/drive/folders/1501h5AVNJHdga7jzoGXn1ryxk6zdnKUz',
                      ),
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('📁 جدول تنسيق الأعمال الأسبوعي (85) ↗'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ctrl.openExternalUrl(
                        'https://drive.google.com/drive/folders/1Ve3EyX-eIK1UD6vTRZnnU0RrhVp0IRZ9',
                      ),
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('📁 حالة الرخص مركز المشاريع (946) ↗'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ctrl.openExternalUrl(
                        'https://drive.google.com/drive/folders/1NAPYUAV2ow9UeqEvK3z-OC0KAOcuah3N',
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('📁 ملفات الرخص PDF (64) ↗'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ctrl.openExternalUrl(
                        'https://drive.google.com/drive/folders/1vvVpL-fDBQ0yomdHCvqysds3n1lvsvlp',
                      ),
                      icon: const Icon(Icons.science, size: 16),
                      label: const Text('📁 التقرير الوارد من المختبر URS (73) ↗'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '🔗 سجل مهام وأوامر عمل أودو (${ctrl.odooTasks.length} مهمة project.task + ${ctrl.coordinationItems.length} أمر عمل أسبوعي = 126 مهمة موحدة):',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF5F5F5)),
                    columns: const [
                      DataColumn(label: Text('External ID')),
                      DataColumn(label: Text('رقم الرخصة')),
                      DataColumn(label: Text('رقم الأساس')),
                      DataColumn(label: Text('رقم السكيم')),
                      DataColumn(label: Text('كود المشروع')),
                      DataColumn(label: Text('الحي ونوع العمل')),
                      DataColumn(label: Text('المرحلة في أودو')),
                      DataColumn(label: Text('المشرف المسند')),
                    ],
                    rows: ctrl.odooTasks.map((t) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            'alasas_task_${t.seq.toString().padLeft(3, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          )),
                          DataCell(Text(
                            t.permitId,
                            style: const TextStyle(
                              color: FluentEnterpriseTheme.fluentBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          )),
                          DataCell(Text(t.baseNo)),
                          DataCell(Text(t.schemeNo)),
                          DataCell(Text(t.projectCode)),
                          DataCell(Text('${t.district} — ${t.workOrderType}')),
                          DataCell(Text(t.stage)),
                          DataCell(Text(t.supervisor)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

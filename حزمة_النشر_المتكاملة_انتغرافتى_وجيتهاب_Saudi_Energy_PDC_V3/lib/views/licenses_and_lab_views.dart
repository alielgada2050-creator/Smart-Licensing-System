// Views 4, 5, 6, 7, 8: Master Licenses Registry (946), Comparison, Returned (480), URS Lab (73), and OCR PDFs (64)

import 'package:flutter/material.dart';
import '../models/permit_models.dart';
import '../services/enterprise_controller.dart';
import '../theme/fluent_enterprise_theme.dart';
import '../widgets/enterprise_modals.dart';

// ============================================================================
// VIEW 4: MASTER PERMITS REGISTRY (946 PERMITS ACROSS 11 CATEGORIES)
// ============================================================================
class MasterLicensesView extends StatelessWidget {
  final EnterpriseController ctrl;

  const MasterLicensesView({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final filtered = ctrl.filteredPermits;
    final total = filtered.length;
    final totalPages =
        (total / EnterpriseController.licensePageSize).ceil().clamp(1, 999);
    final currentPage = ctrl.currentLicensePage.clamp(1, totalPages);
    final startIdx = (currentPage - 1) * EnterpriseController.licensePageSize;
    final pageItems = filtered
        .skip(startIdx)
        .take(EnterpriseController.licensePageSize)
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ctrl.isVisitorMode
                          ? '🗂️ سجل الرخص العاملة وتحت التنفيذ (وضع الزائر — $total رخصة متاحة للتنزيل)'
                          : '🗂️ السجل الشامل الموحد للرخص (${ctrl.permits.length} رخصة موزعة على 11 فئة تشغيلية)',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FluentEnterpriseTheme.fluentBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final msg =
                            await ctrl.generateAndCopyCsvSheet('COMPARISON_ALL');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('📥 $msg (تم نسخ CSV)')),
                          );
                        }
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('تصدير الشيت الشامل (CSV)'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Filter Pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _catPill(
                      context,
                      'ALL',
                      'الكل (${ctrl.permits.length})',
                      ctrl.selectedLicenseCategory == 'ALL',
                    ),
                    ...kCategoriesSpec.map((c) {
                      final cnt =
                          ctrl.permits.where((r) => r.category == c.key).length;
                      return _catPill(
                        context,
                        c.key,
                        '${c.shortTitle} ($cnt)',
                        ctrl.selectedLicenseCategory == c.key,
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 12),

                // Search & SLA Filters
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        onChanged: (val) {
                          ctrl.licenseSearchQuery = val;
                          ctrl.currentLicensePage = 1;
                          ctrl.refresh();
                        },
                        decoration: const InputDecoration(
                          hintText:
                              'بحث برقم الرخصة، رقم الأساس (R6949)، السكيم، الحي، الاستشاري...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: ctrl.selectedBanFilter,
                        decoration: const InputDecoration(
                          labelText: 'حالة حظر الشارع',
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('جميع الشوارع')),
                          DropdownMenuItem(value: 'محظور', child: Text('شارع محظور فقط')),
                          DropdownMenuItem(value: 'غير محظور', child: Text('غير محظور')),
                        ],
                        onChanged: (v) {
                          ctrl.selectedBanFilter = v ?? '';
                          ctrl.currentLicensePage = 1;
                          ctrl.refresh();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String>(
                        value: ctrl.selectedSlaFilter,
                        decoration: const InputDecoration(
                          labelText: 'مهلة المختبر (60 يوماً)',
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('جميع مدد المختبر')),
                          DropdownMenuItem(value: 'crit', child: Text('حرج ≤15 يوم')),
                          DropdownMenuItem(value: 'warn', child: Text('تنبيه ≤30 يوم')),
                          DropdownMenuItem(value: 'overdue', child: Text('متجاوزة 60 يوماً')),
                          DropdownMenuItem(value: 'done', child: Text('مغلقة نهائياً')),
                        ],
                        onChanged: (v) {
                          ctrl.selectedSlaFilter = v ?? '';
                          ctrl.currentLicensePage = 1;
                          ctrl.refresh();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Licenses Table Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF5F5F5)),
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('رقم الرخصة وتنزيل الدرايف')),
                      DataColumn(label: Text('رقم الأساس')),
                      DataColumn(label: Text('السكيم / المعاملة')),
                      DataColumn(label: Text('الفئة والحالة التشغيلية')),
                      DataColumn(label: Text('الحي والموقع')),
                      DataColumn(label: Text('نهاية الرخصة')),
                      DataColumn(label: Text('مهلة المختبر (+60ي)')),
                      DataColumn(label: Text('حالة URS')),
                      DataColumn(label: Text('المشرف المختص')),
                      DataColumn(label: Text('إجراءات')),
                    ],
                    rows: pageItems.asMap().entries.map((entry) {
                      final idx = startIdx + entry.key + 1;
                      final r = entry.value;
                      final sla = r.calculateSla();
                      return DataRow(
                        cells: [
                          DataCell(Text('$idx')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      showLicense13TabsModal(context, ctrl, r),
                                  child: Text(
                                    r.permitId,
                                    style: const TextStyle(
                                      color: FluentEnterpriseTheme.fluentBlue,
                                      fontWeight: FontWeight.w800,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                  onPressed: () {
                                    final url = r.pdfUrl.isNotEmpty
                                        ? r.pdfUrl
                                        : 'https://drive.google.com/drive/folders/1NAPYUAV2ow9UeqEvK3z-OC0KAOcuah3N';
                                    ctrl.openExternalUrl(url);
                                  },
                                  icon: const Icon(Icons.download, size: 13),
                                  label: const Text(
                                    'تنزيل الرخصة',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(
                            r.baseNo,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          )),
                          DataCell(Text(
                            r.schemeNo.isNotEmpty
                                ? r.schemeNo
                                : r.transactionNo,
                          )),
                          DataCell(_statusBadge(r.category)),
                          DataCell(Text(r.district)),
                          DataCell(Text(sla.endStr)),
                          DataCell(Text(
                            '${sla.labDeadlineStr} (${sla.slaLabel})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: sla.slaTier == 'crit' ||
                                      sla.slaTier == 'overdue'
                                  ? FluentEnterpriseTheme.dangerFg
                                  : FluentEnterpriseTheme.successFg,
                            ),
                          )),
                          DataCell(Text(
                            r.ursResult,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          )),
                          DataCell(Text(r.engineer)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () =>
                                      showLicense13TabsModal(context, ctrl, r),
                                  child: const Text(
                                    '🗂️ 13 تبويباً',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (!ctrl.isVisitorMode)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () =>
                                        ctrl.switchView('tx-editor'),
                                    child: const Text(
                                      '✏️ تعديل',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Pagination Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'عرض ${total == 0 ? 0 : startIdx + 1} – ${(startIdx + pageItems.length)} من إجمالي $total رخصة',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        OutlinedButton(
                          onPressed: currentPage > 1
                              ? () {
                                  ctrl.currentLicensePage = currentPage - 1;
                                  ctrl.refresh();
                                }
                              : null,
                          child: const Text('السابق'),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: FluentEnterpriseTheme.fluentBlueTint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'صفحة $currentPage من $totalPages',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: FluentEnterpriseTheme.fluentBlue,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: currentPage < totalPages
                              ? () {
                                  ctrl.currentLicensePage = currentPage + 1;
                                  ctrl.refresh();
                                }
                              : null,
                          child: const Text('التالي'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _catPill(
    BuildContext context,
    String key,
    String label,
    bool isActive,
  ) {
    return InkWell(
      onTap: () => ctrl.setLicenseCategoryFilter(key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? FluentEnterpriseTheme.fluentBlue
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? FluentEnterpriseTheme.fluentBlue
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String category) {
    Color bg = const Color(0xFFEFF6FF);
    Color fg = FluentEnterpriseTheme.fluentBlue;
    if (category.contains('سارية') || category.contains('مغلقة')) {
      bg = FluentEnterpriseTheme.successBg;
      fg = FluentEnterpriseTheme.successFg;
    } else if (category.contains('معاد') ||
        category.contains('منتهية') ||
        category.contains('راسب')) {
      bg = FluentEnterpriseTheme.dangerBg;
      fg = FluentEnterpriseTheme.dangerFg;
    } else if (category.contains('مختبر')) {
      bg = FluentEnterpriseTheme.warningBg;
      fg = FluentEnterpriseTheme.warningFg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================================
// VIEW 5: LICENSE INTELLIGENCE & COMPARISON (comparison)
// ============================================================================
class LicenseComparisonView extends StatefulWidget {
  final EnterpriseController ctrl;

  const LicenseComparisonView({super.key, required this.ctrl});

  @override
  State<LicenseComparisonView> createState() => _LicenseComparisonViewState();
}

class _LicenseComparisonViewState extends State<LicenseComparisonView> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final rows = widget.ctrl.permits
        .where((r) {
          if (_q.trim().isEmpty) return true;
          final ql = _q.toLowerCase();
          return '${r.permitId} ${r.baseNo} ${r.consultant} ${r.district} ${r.engineer} ${r.category}'
              .toLowerCase()
              .contains(ql);
        })
        .take(80)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🔍 تحليل ومقارنة الرخص وحساب مهلة الـ 60 يوماً لمختبر URS والجهة المسؤولة',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(
                hintText: 'ابحث برقم الأساس أو الرخصة أو المكتب الاستشاري أو الحي للمقارنة...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF5F5F5)),
                columns: const [
                  DataColumn(label: Text('رقم الأساس')),
                  DataColumn(label: Text('رقم الرخصة')),
                  DataColumn(label: Text('الحالة التشغيلية')),
                  DataColumn(label: Text('تاريخ الانتهاء')),
                  DataColumn(label: Text('المتبقي للصلاحية')),
                  DataColumn(label: Text('آخر موعد للمختبر (+60ي)')),
                  DataColumn(label: Text('حالة مهلة الـ 60 يوماً')),
                  DataColumn(label: Text('نتيجة URS')),
                  DataColumn(label: Text('الجهة الحالية')),
                  DataColumn(label: Text('المشرف / المراقب')),
                ],
                rows: rows.map((r) {
                  final dt = r.calculateSla();
                  final entity = r.category.contains('المركز')
                      ? 'مركز مشاريع البنية التحتية RIPC'
                      : (r.category.contains('الاستشاري')
                          ? r.consultant
                          : (r.category.contains('المختبر')
                              ? r.lab
                              : 'الشركة السعودية للكهرباء SEC'));
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        r.baseNo,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      )),
                      DataCell(
                        InkWell(
                          onTap: () =>
                              showLicense13TabsModal(context, widget.ctrl, r),
                          child: Text(
                            r.permitId,
                            style: const TextStyle(
                              color: FluentEnterpriseTheme.fluentBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(r.category)),
                      DataCell(Text(dt.endStr)),
                      DataCell(Text('${dt.validDaysLeft} يوم')),
                      DataCell(Text(dt.labDeadlineStr)),
                      DataCell(Text(
                        dt.slaLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: dt.slaTier == 'crit' || dt.slaTier == 'overdue'
                              ? FluentEnterpriseTheme.dangerFg
                              : FluentEnterpriseTheme.successFg,
                        ),
                      )),
                      DataCell(Text(r.ursResult)),
                      DataCell(Text(entity)),
                      DataCell(Text('${r.engineer} / ${r.inspector}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VIEW 6: RETURNED LICENSES RECOVERY (480 RETURNED: 295 RIPC + 186 CONSULTANT)
// ============================================================================
class ReturnedLicensesView extends StatefulWidget {
  final EnterpriseController ctrl;

  const ReturnedLicensesView({super.key, required this.ctrl});

  @override
  State<ReturnedLicensesView> createState() => _ReturnedLicensesViewState();
}

class _ReturnedLicensesViewState extends State<ReturnedLicensesView> {
  String _srcFilter = 'ALL';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = widget.ctrl.permits;
    final centerRet =
        all.where((r) => r.category == 'معاد من قبل المركز').length;
    final consRet =
        all.where((r) => r.category == 'معاد من قبل الاستشاري').length;
    final labRet = all
        .where((r) => r.category == 'تقرير مختبر راسب (تحتاج إعادة فحص)')
        .length;

    final list = all
        .where((r) {
          final isRet =
              r.category.contains('معاد') || r.category.contains('راسب');
          if (!isRet) return false;
          if (_srcFilter != 'ALL' && r.category != _srcFilter) return false;
          if (_q.isNotEmpty &&
              !'${r.permitId} ${r.baseNo} ${r.returnReason} ${r.notes} ${r.consultant}'
                  .toLowerCase()
                  .contains(_q.toLowerCase())) {
            return false;
          }
          return true;
        })
        .take(65)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryBox(
              'إجمالي الرخص المعادة',
              '${centerRet + consRet + labRet}',
              'خاضعة لآلية المعالجة من 9 خطوات',
              FluentEnterpriseTheme.dangerFg,
            ),
            _summaryBox(
              'معادة من مركز المشاريع RIPC',
              '$centerRet',
              'أبرز الأسباب: تعديل الوضع / ثقب أفقي',
              FluentEnterpriseTheme.dangerFg,
            ),
            _summaryBox(
              'معادة من المكتب الاستشاري',
              '$consRet',
              'بعد حذف 100 رخصة مكررة',
              FluentEnterpriseTheme.warningFg,
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
                Row(
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        value: _srcFilter,
                        decoration: const InputDecoration(
                          labelText: 'جهة الإعادة',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text('جميع جهات الإعادة'),
                          ),
                          DropdownMenuItem(
                            value: 'معاد من قبل المركز',
                            child: Text('معاد من قبل المركز (RIPC)'),
                          ),
                          DropdownMenuItem(
                            value: 'معاد من قبل الاستشاري',
                            child: Text('معاد من قبل الاستشاري'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _srcFilter = v ?? 'ALL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _q = v),
                        decoration: const InputDecoration(
                          hintText: 'ابحث برقم الرخصة أو الأساس أو سبب الإعادة...',
                          prefixIcon: Icon(Icons.search),
                        ),
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
                      DataColumn(label: Text('رقم الرخصة')),
                      DataColumn(label: Text('رقم الأساس')),
                      DataColumn(label: Text('جهة الإعادة')),
                      DataColumn(label: Text('سبب الإعادة الموثق')),
                      DataColumn(label: Text('الإجراء التصحيحي المطلوب')),
                      DataColumn(label: Text('المشرف / المراقب')),
                      DataColumn(label: Text('إجراء')),
                    ],
                    rows: list.map((r) {
                      final reason = r.returnReason.isNotEmpty
                          ? r.returnReason
                          : (r.notes.isNotEmpty
                              ? r.notes
                              : 'استكمال ملاحظات الدمك وصور إعادة الوضع');
                      final corrective = reason.contains('افق')
                          ? 'تعديل طريقة الحفر إلى ثقب أفقي HDD وإرفاق مخطط As-Built'
                          : 'إصلاح الأسفلت والدمك وإرفاق صور قبل وبعد المعالجة';
                      return DataRow(
                        cells: [
                          DataCell(
                            InkWell(
                              onTap: () => showLicense13TabsModal(
                                context,
                                widget.ctrl,
                                r,
                              ),
                              child: Text(
                                r.permitId,
                                style: const TextStyle(
                                  color: FluentEnterpriseTheme.fluentBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(r.baseNo)),
                          DataCell(Text(r.category)),
                          DataCell(Text(
                            reason,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          )),
                          DataCell(Text(corrective)),
                          DataCell(Text('${r.engineer} (${r.inspector})')),
                          DataCell(
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FluentEnterpriseTheme.fluentBlue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => showLicense13TabsModal(
                                context,
                                widget.ctrl,
                                r,
                              ),
                              child: const Text(
                                'معالجة وإعادة تقديم',
                                style: TextStyle(fontSize: 11),
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

  Widget _summaryBox(String title, String val, String sub, Color color) {
    return Container(
      width: 280,
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
          Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

// ============================================================================
// VIEW 7: URS LABORATORY REPORTS & SEC QA/QC (73 INSPECTIONS)
// ============================================================================
class UrsLabView extends StatelessWidget {
  final EnterpriseController ctrl;

  const UrsLabView({super.key, required this.ctrl});

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
                const Text(
                  '🔬 سلة تقارير وفحوصات مختبر URS ومهلة الـ 60 يوماً (بإشراف: مشرف علي الجدع)',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'إجمالي النقاط المختبرة: 211 نقطة (149 نقطة ناجحة ومعتمدة | 62 نقطة راسبة تتطلب إعادة دك وسفلتة) + 12 فحص SEC QA/QC.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF5F5F5)),
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('رقم الرخصة')),
                      DataColumn(label: Text('تاريخ الرخصة')),
                      DataColumn(label: Text('تاريخ الفحص')),
                      DataColumn(label: Text('نوع الاختبار')),
                      DataColumn(label: Text('نقاط ناجحة')),
                      DataColumn(label: Text('نقاط راسبة')),
                      DataColumn(label: Text('نسبة الاجتياز')),
                      DataColumn(label: Text('النتيجة والتفصيل')),
                      DataColumn(label: Text('الإجراء الهندسي المطلوب')),
                    ],
                    rows: ctrl.ursInspections.map((u) {
                      return DataRow(
                        cells: [
                          DataCell(Text('${u.seq}')),
                          DataCell(Text(
                            u.permitId,
                            style: const TextStyle(
                              color: FluentEnterpriseTheme.fluentBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          )),
                          DataCell(Text(u.permitDate)),
                          DataCell(Text(u.testDate)),
                          DataCell(Text(u.testType)),
                          DataCell(Text(
                            '${u.passedPoints}',
                            style: const TextStyle(
                              color: FluentEnterpriseTheme.successFg,
                              fontWeight: FontWeight.w800,
                            ),
                          )),
                          DataCell(Text(
                            '${u.failedPoints}',
                            style: TextStyle(
                              color: u.failedPoints > 0
                                  ? FluentEnterpriseTheme.dangerFg
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w800,
                            ),
                          )),
                          DataCell(Text(u.passRate)),
                          DataCell(Text(u.statusDetail)),
                          DataCell(Text(u.remediationAction)),
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
// VIEW 8: DOCUMENT INTELLIGENCE & OCR (64 PDF LICENSES INCLUDING R6949-2396761)
// ============================================================================
class OcrDocumentIntelligenceView extends StatelessWidget {
  final EnterpriseController ctrl;

  const OcrDocumentIntelligenceView({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📄 ذكاء المستندات وملفات الرخص PDF المستخرجة عبر OCR (${ctrl.pdfLicenses.length} ملف رخصة معتمد شاملة R6949-2396761.pdf)',
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF5F5F5)),
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('اسم ملف PDF على الدرايف')),
                  DataColumn(label: Text('رقم الرخصة')),
                  DataColumn(label: Text('رقم الأساس')),
                  DataColumn(label: Text('المحطة')),
                  DataColumn(label: Text('السكيم')),
                  DataColumn(label: Text('النوع وحالة الحظر')),
                  DataColumn(label: Text('البداية ← النهاية')),
                  DataColumn(label: Text('الأبعاد (طول×عرض×عمق)')),
                  DataColumn(label: Text('الحي')),
                  DataColumn(label: Text('دقة OCR')),
                  DataColumn(label: Text('فتح PDF')),
                ],
                rows: ctrl.pdfLicenses.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final p = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('$i')),
                      DataCell(Text(
                        p.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )),
                      DataCell(Text(
                        p.permitId,
                        style: const TextStyle(
                          color: FluentEnterpriseTheme.fluentBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      )),
                      DataCell(Text(
                        p.baseNo,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      )),
                      DataCell(Text(p.stationNo)),
                      DataCell(Text(p.schemeNo)),
                      DataCell(Text('${p.permitType} (${p.roadBanStatus})')),
                      DataCell(
                        Text('${p.startDate} ← ${p.endDate} (${p.durationDays}ي)'),
                      ),
                      DataCell(
                        Text('${p.lengthM}م × ${p.widthM}م × ${p.depthM}م'),
                      ),
                      DataCell(Text(p.district)),
                      DataCell(Text(
                        '${p.ocrConfidence}%',
                        style: const TextStyle(
                          color: FluentEnterpriseTheme.successFg,
                          fontWeight: FontWeight.w800,
                        ),
                      )),
                      DataCell(
                        OutlinedButton.icon(
                          onPressed: () => ctrl.openExternalUrl(p.driveUrl),
                          icon: const Icon(Icons.picture_as_pdf, size: 14),
                          label: const Text(
                            'PDF الأصلي',
                            style: TextStyle(fontSize: 11),
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
    );
  }
}

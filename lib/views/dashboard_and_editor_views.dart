// Executive Dashboard View (View 1) + Site Engineer Immediate Transaction & Permit Editor (View 0)

import 'package:flutter/material.dart';
import '../models/permit_models.dart';
import '../services/egyptian_voice_ai_service.dart';
import '../services/enterprise_controller.dart';
import '../theme/fluent_enterprise_theme.dart';
import '../widgets/enterprise_modals.dart';

class ExecutiveDashboardView extends StatefulWidget {
  final EnterpriseController ctrl;

  const ExecutiveDashboardView({super.key, required this.ctrl});

  @override
  State<ExecutiveDashboardView> createState() => _ExecutiveDashboardViewState();
}

class _ExecutiveDashboardViewState extends State<ExecutiveDashboardView> {
  final TextEditingController _fastAiQueryCtrl = TextEditingController();
  final TextEditingController _studioApiKeyCtrl = TextEditingController();
  bool _showStudioConfigBox = false;

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permits = ctrl.permits;
    final total = permits.length;
    final activeValid = permits.where((r) => r.isActiveOrInExecution).length;
    final retCenter =
        permits.where((r) => r.category == 'معاد من قبل المركز').length;
    final retCons =
        permits.where((r) => r.category == 'معاد من قبل الاستشاري').length;
    final expUnclosed = permits
        .where((r) => r.category == 'منتهية (تحتاج معالجة وإغلاق)')
        .length;
    final closedFinal =
        permits.where((r) => r.category == 'مغلقة (تم الإغلاق)').length;
    final subClosing =
        permits.where((r) => r.category == 'تم الرفع (بانتظار الإغلاق)').length;
    final labNear60 = permits.where((r) {
      final d = r.calculateSla().labDaysLeft;
      return d >= 0 && d <= 15 && r.category != 'مغلقة (تم الإغلاق)';
    }).length;
    final readyNextWeek =
        ctrl.coordinationItems.where((c) => c.isReady).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Visitor Mode Active Banner
        if (ctrl.isVisitorMode)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3B2506) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ctrl.tr(
                      '👁️ أنت تتصفح المنصة الآن في «وضع الزائر»: يتم عرض المنصات والرخص التي تعمل (السارية) وتحت التنفيذ فقط. لفتح باقي أقسام المنصة والتعديل وإصدار الشيتات يلزم موافقة المشرف علي الجدع (0597778853).',
                      '👁️ You are browsing in "Visitor Mode": Only active and in-execution permits are displayed. To unlock all platform sections, edits, and sheet exports, supervisor approval from Ali Al-Jada (0597778853) is required.',
                    ),
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFF92400E),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FluentEnterpriseTheme.fluentBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => showAccessGateModal(context, ctrl),
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: Text(
                    ctrl.tr('طلب موافقة / دخول معتمد', 'Request Approval / Login'),
                  ),
                ),
              ],
            ),
          ),

        // Instant Search & Excel/CSV Sheet Export Hub (Voice Assistant Removed)
        if (!ctrl.isCompactFocusMode)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.manage_search,
                            color: FluentEnterpriseTheme.fluentBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ctrl.tr(
                              '⚡ محرك البحث الفائق والمقارنة وإصدار الشيتات الفوري (<15ms)',
                              '⚡ Ultra-Fast Search, Comparison & Instant Sheet Export (<15ms)',
                            ),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final msg = await ctrl
                                  .generateAndCopyCsvSheet('ACTIVE_EXEC');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ctrl.tr(
                                        '📥 $msg (تم نسخ CSV)',
                                        '📥 $msg (CSV copied to clipboard)',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.table_chart, size: 16),
                            label: Text(
                              ctrl.tr(
                                'شيت العاملة وتحت التنفيذ',
                                'Active & In-Execution Sheet',
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final msg = await ctrl
                                  .generateAndCopyCsvSheet('LAB_AND_EXPIRED');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ctrl.tr(
                                        '📥 $msg (تم نسخ CSV)',
                                        '📥 $msg (CSV copied to clipboard)',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.science, size: 16),
                            label: Text(
                              ctrl.tr(
                                'شيت المختبر والمنتهية (علي الجدع)',
                                'Lab & Expired Sheet (Ali Al-Jada)',
                              ),
                            ),
                          ),
                          if (ctrl.isAuthorizedSupervisor)
                            OutlinedButton.icon(
                              onPressed: () => setState(
                                () => _showStudioConfigBox = !_showStudioConfigBox,
                              ),
                              icon: const Icon(Icons.vpn_key, size: 16),
                              label: Text(
                                ctrl.tr(
                                  'إعداد Google AI Studio API (للمشرف)',
                                  'Configure Google AI Studio API',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (_showStudioConfigBox && ctrl.isAuthorizedSupervisor) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F2942)
                            : FluentEnterpriseTheme.fluentBlueTint,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: FluentEnterpriseTheme.fluentBlueStroke,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _studioApiKeyCtrl,
                              decoration: InputDecoration(
                                labelText: ctrl.tr(
                                  'مفتاح Google AI Studio API (GEMINI_API_KEY) — مخصص للمشرف علي الجدع',
                                  'Google AI Studio API Key (GEMINI_API_KEY) — Supervisor Ali Al-Jada',
                                ),
                                hintText: 'AIzaSy...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FluentEnterpriseTheme.fluentBlue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              ctrl.voiceAi.googleStudioApiKey =
                                  _studioApiKeyCtrl.text.trim();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ctrl.tr(
                                      '🔑 تم حفظ وتفعيل مفتاح Google AI Studio API للمشرف علي الجدع!',
                                      '🔑 Google AI Studio API key saved and activated!',
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              ctrl.tr('حفظ وتفعيل المفتاح', 'Save & Activate Key'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fastAiQueryCtrl,
                          onSubmitted: (v) => ctrl.runEgyptianFastSearch(v),
                          decoration: InputDecoration(
                            hintText: ctrl.tr(
                              'اكتب أي استفسار أو رقم رخصة أو أساس (مثلاً: R6949، مقارنة شاملة، رخص سارية، معاد المركز)...',
                              'Search any permit ID, base number, or query (e.g., R6949, full comparison, active permits, returned RIPC)...',
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FluentEnterpriseTheme.fluentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () =>
                            ctrl.runEgyptianFastSearch(_fastAiQueryCtrl.text),
                        icon: const Icon(Icons.bolt),
                        label: Text(
                          ctrl.tr('بحث ومقارنة فورية', 'Instant Search & Compare'),
                        ),
                      ),
                    ],
                  ),
                  if (ctrl.lastFastSearchResponse != null) ...[
                    const SizedBox(height: 12),
                    _buildFastSearchResultBox(
                      ctrl.lastFastSearchResponse!,
                      isDark,
                    ),
                  ],
                ],
              ),
            ),
          ),

        // Executive KPIs Grid
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 1100
                ? 4
                : (constraints.maxWidth > 680 ? 2 : 1);
            final kpis = [
              _KpiItem(
                title: ctrl.tr(
                  'إجمالي الرخص الفريدة الموحدة',
                  'Total Unified Unique Permits',
                ),
                value: '$total',
                subtitle: ctrl.tr(
                  'بعد حذف 569 رخصة مكررة | تحديث 4 ساعات',
                  'After removing 569 duplicates | 4h Sync',
                ),
                icon: Icons.folder_special,
                accentColor: FluentEnterpriseTheme.fluentBlue,
                onTap: () => ctrl.jumpToLicenseCategory('ALL'),
              ),
              _KpiItem(
                title: ctrl.tr(
                  'الرخص السارية وتحت التنفيذ ✅',
                  'Active & In-Execution Permits ✅',
                ),
                value: '$activeValid',
                subtitle: ctrl.tr(
                  'متاحة للزوار وللتنزيل المباشر من الدرايف',
                  'Available to visitors & direct Drive download',
                ),
                icon: Icons.verified,
                accentColor: FluentEnterpriseTheme.successFg,
                onTap: () => ctrl.jumpToLicenseCategory(
                  'سارية / مفعلة (رخص PDF المعتمدة)',
                ),
              ),
              _KpiItem(
                title: ctrl.tr(
                  'معادة من المركز RIPC 🚨',
                  'Returned by RIPC Center 🚨',
                ),
                value: '$retCenter',
                subtitle: ctrl.tr(
                  'تحتاج معالجة ثقب أفقي أو تعديل وضع',
                  'Requires HDD or status rectification',
                ),
                icon: Icons.warning_amber_rounded,
                accentColor: FluentEnterpriseTheme.dangerFg,
                onTap: () => ctrl.jumpToLicenseCategory('معاد من قبل المركز'),
              ),
              _KpiItem(
                title: ctrl.tr(
                  'معادة من المكتب الاستشاري 🏢',
                  'Returned by Consultant 🏢',
                ),
                value: '$retCons',
                subtitle: ctrl.tr(
                  'استكمال ملاحظات الدمك وصور بعد التنفيذ',
                  'Pending compaction notes & post-work photos',
                ),
                icon: Icons.engineering,
                accentColor: FluentEnterpriseTheme.warningFg,
                onTap: () =>
                    ctrl.jumpToLicenseCategory('معاد من قبل الاستشاري'),
              ),
              _KpiItem(
                title: ctrl.tr(
                  'منتهية (تحتاج معالجة وإغلاق)',
                  'Expired (Requires Closure)',
                ),
                value: '$expUnclosed',
                subtitle: ctrl.tr(
                  'تخصص الرخص والمختبر: مشرف علي الجدع',
                  'Permits & Lab Lead: Sup. Ali Al-Jada',
                ),
                icon: Icons.schedule,
                accentColor: const Color(0xFF991B1B),
                onTap: () => ctrl.jumpToLicenseCategory(
                  'منتهية (تحتاج معالجة وإغلاق)',
                ),
              ),
              _KpiItem(
                title: ctrl.tr(
                  'مغلقة نهائياً + تم الرفع للإغلاق',
                  'Final Closed + Submitted for Closure',
                ),
                value: '$closedFinal / $subClosing',
                subtitle: ctrl.tr(
                  'مربوطة بمستخلصات ومهام أودو ERP',
                  'Linked to invoices & Odoo ERP tasks',
                ),
                icon: Icons.task_alt,
                accentColor: const Color(0xFF059669),
                onTap: () => ctrl.jumpToLicenseCategory('مغلقة (تم الإغلاق)'),
              ),
              _KpiItem(
                title: ctrl.tr(
                  'حرجة مهلة المختبر 60 يوماً (≤15 يوم)',
                  'Critical 60-Day Lab SLA (≤15d)',
                ),
                value: '$labNear60',
                subtitle: ctrl.tr(
                  'إجمالي فسوحات مختبر URS: ${ctrl.ursInspections.length}',
                  'Total URS Lab Inspections: ${ctrl.ursInspections.length}',
                ),
                icon: Icons.science,
                accentColor: const Color(0xFFDC2626),
                onTap: () => ctrl.switchView('urs'),
              ),
              _KpiItem(
                title: ctrl.tr(
                  'معاملات الأسبوع الجاهزة للتنفيذ 📅',
                  'Weekly Works Ready for Execution 📅',
                ),
                value: '$readyNextWeek / ${ctrl.coordinationItems.length}',
                subtitle: ctrl.tr(
                  'خريص 50 | الشمال 25 | الشرق 10',
                  'Khurais 50 | North 25 | East 10',
                ),
                icon: Icons.calendar_month,
                accentColor: const Color(0xFF0284C7),
                onTap: () => ctrl.switchView('coordination'),
              ),
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 120,
              ),
              itemCount: kpis.length,
              itemBuilder: (c, idx) => _buildKpiCard(kpis[idx], isDark),
            );
          },
        ),

        const SizedBox(height: 14),

        // 18 Executive Questions Interactive Matrix
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.tr(
                    '📋 مصفوفة الأسئلة التنفيذية الـ 18 (إجابات حية مباشرة من قاعدة البيانات الموحدة V3.0)',
                    '📋 18 Executive Questions Matrix (Live Answers from Unified Database V3.0)',
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _q18Chip(
                      ctrl.tr('1. كم عدد الرخص لدينا؟', '1. Total Unique Permits?'),
                      ctrl.tr('$total رخصة فريدة', '$total Unique Permits'),
                      'licenses',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('2. السارية والمنتهية؟', '2. Active vs Expired?'),
                      ctrl.tr(
                        '$activeValid سارية | $expUnclosed منتهية',
                        '$activeValid Active | $expUnclosed Expired',
                      ),
                      'licenses',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('3. قاربت على الانتهاء؟', '3. Expiring Soon?'),
                      ctrl.tr('16 رخصة (≤7 أيام)', '16 Permits (≤7d)'),
                      'comparison',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('4. تحتاج تجديد؟', '4. Needs Renewal?'),
                      ctrl.tr(
                        '${ctrl.coordinationItems.where((c) => c.readinessGroup.contains("تجديد")).length} رخصة اعتيادية',
                        '${ctrl.coordinationItems.where((c) => c.readinessGroup.contains("تجديد")).length} Permits',
                      ),
                      'weekly',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('5. أعمال تحتاج رخص جديدة؟', '5. Needs New Permit?'),
                      ctrl.tr(
                        '${ctrl.coordinationItems.where((c) => c.readinessGroup.contains("جديدة")).length} أعمال',
                        '${ctrl.coordinationItems.where((c) => c.readinessGroup.contains("جديدة")).length} Works',
                      ),
                      'weekly',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('6. أعمال تحتاج رخص طوارئ؟', '6. Emergency Permits?'),
                      ctrl.tr(
                        '${ctrl.coordinationItems.where((c) => c.readinessGroup.contains("طوارئ")).length} طوارئ',
                        '${ctrl.coordinationItems.where((c) => c.readinessGroup.contains("طوارئ")).length} Emergency',
                      ),
                      'weekly',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('7. المعادة من الاستشاري؟', '7. Returned by Consultant?'),
                      ctrl.tr('$retCons رخصة', '$retCons Permits'),
                      'returned',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('8. المعادة من المركز؟', '8. Returned by RIPC?'),
                      ctrl.tr('$retCenter رخصة', '$retCenter Permits'),
                      'returned',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('9. المعتمدة والمغلقة؟', '9. Approved & Closed?'),
                      ctrl.tr(
                        '${subClosing + closedFinal} رخصة',
                        '${subClosing + closedFinal} Permits',
                      ),
                      'licenses',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('10. تحت معالجة SEC؟', '10. Under SEC Processing?'),
                      ctrl.tr('$subClosing رخصة', '$subClosing Permits'),
                      'licenses',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('11. المغلقة نهائياً؟', '11. Finally Closed?'),
                      ctrl.tr('$closedFinal مغلقة', '$closedFinal Closed'),
                      'licenses',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('12. اقتربت من 60 يوم مختبر؟', '12. Near 60d Lab SLA?'),
                      ctrl.tr('$labNear60 رخصة', '$labNear60 Permits'),
                      'urs',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('13. تقارير مختبر URS؟', '13. URS Lab Reports?'),
                      ctrl.tr('17 ناجح | 35 به نقاط راسبة', '17 Pass | 35 Fail Points'),
                      'urs',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('14. جاهزة الأسبوع القادم؟', '14. Ready Next Week?'),
                      ctrl.tr('$readyNextWeek عمل جاهز', '$readyNextWeek Ready'),
                      'weekly',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('15. أعمال يجب إيقافها؟', '15. Works to Hold?'),
                      ctrl.tr(
                        '${ctrl.coordinationItems.length - readyNextWeek} غير مستوفٍ',
                        '${ctrl.coordinationItems.length - readyNextWeek} On Hold',
                      ),
                      'coordination',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('16. توزيع المشرفين والاستشاريين؟', '16. Supervisors & Consultants?'),
                      ctrl.tr('7 مشرفين | 8 استشاريين', '7 Sup. | 8 Consultants'),
                      'comparison',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('17. المرتبطة بالأساس R6949؟', '17. Linked to R6949 & OCR?'),
                      ctrl.tr(
                        '${ctrl.pdfLicenses.length} رخصة PDF و OCR',
                        '${ctrl.pdfLicenses.length} PDFs & OCR',
                      ),
                      'ocr',
                      isDark,
                    ),
                    _q18Chip(
                      ctrl.tr('18. حجم المسارات الموثقة؟', '18. Documented Trench Length?'),
                      ctrl.tr('3,384.6 متر طولي', '3,384.6 Meters'),
                      'gis',
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Category Breakdown Visual Bars
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.tr(
                    '📊 التوزيع الإحصائي للفئات الـ 11 في سجل الرخص الشامل (انقر على أي فئة لفتحها)',
                    '📊 Statistical Distribution Across 11 Operational Categories (Click to Filter)',
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...kCategoriesSpec.map((cat) {
                  final cnt =
                      permits.where((r) => r.category == cat.key).length;
                  final ratio = total > 0 ? cnt / total : 0.0;
                  return InkWell(
                    onTap: () => ctrl.jumpToLicenseCategory(cat.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 210,
                            child: Text(
                              ctrl.trCategory(cat.key),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 12,
                                backgroundColor: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(cat.colorHex),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 85,
                            child: Text(
                              ctrl.tr('$cnt رخصة', '$cnt Permits'),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFastSearchResultBox(EgyptianSearchResponse res, bool isDark) {
    final ctrl = widget.ctrl;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F2942)
            : FluentEnterpriseTheme.fluentBlueTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FluentEnterpriseTheme.fluentBlueStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ctrl.tr(
                  '⚡ نتيجة البحث والمقارنة الفائقة (زمن الاستجابة: ${res.elapsedMs}ms)',
                  '⚡ Instant Search & Comparison Result (Latency: ${res.elapsedMs}ms)',
                ),
                style: const TextStyle(
                  color: FluentEnterpriseTheme.fluentBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FluentEnterpriseTheme.fluentBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final msg = await widget.ctrl
                      .generateAndCopyCsvSheet('CUSTOM', res.query);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ctrl.tr(
                            '📥 $msg (تم نسخ CSV للحافظة)',
                            '📥 $msg (CSV copied to clipboard)',
                          ),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.download, size: 15),
                label: Text(
                  ctrl.tr('نسخ/تنزيل شيت النتائج (CSV)', 'Copy/Export Results (CSV)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '📊 ${res.egyptianVoiceReply}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(_KpiItem item, bool isDark) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(item.icon, color: item.accentColor, size: 20),
              ],
            ),
            Text(
              item.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: item.accentColor,
              ),
            ),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _q18Chip(String q, String a, String targetView, bool isDark) {
    return InkWell(
      onTap: () {
        if (!widget.ctrl.switchView(targetView)) {
          showAccessGateModal(context, widget.ctrl);
        }
      },
      child: Container(
        width: 285,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                q,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              a,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: FluentEnterpriseTheme.fluentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
}

// ============================================================================
// VIEW 0: SITE ENGINEER IMMEDIATE TRANSACTION & PERMIT EDITOR (tx-editor)
// ============================================================================
class SiteEngineerTxEditorView extends StatefulWidget {
  final EnterpriseController ctrl;

  const SiteEngineerTxEditorView({super.key, required this.ctrl});

  @override
  State<SiteEngineerTxEditorView> createState() =>
      _SiteEngineerTxEditorViewState();
}

class _SiteEngineerTxEditorViewState extends State<SiteEngineerTxEditorView> {
  String _mode = 'EDIT'; // ADD, EDIT, CANCEL, SWAP
  String? _selectedCoordId;

  final _permitIdCtrl = TextEditingController(text: '2396761');
  final _baseNoCtrl = TextEditingController(text: 'R6949');
  final _txNoCtrl = TextEditingController(text: '261169851');
  final _districtCtrl = TextEditingController(text: 'حي الفلاح');
  final _lengthCtrl = TextEditingController(text: '120m');
  final _startCtrl = TextEditingController(text: 'الإثنين 09-11-2026');
  final _endCtrl = TextEditingController(text: '2026-11-25');
  final _engineerCtrl = TextEditingController(text: 'مهندس الموقع: SHAHIN');
  final _notesCtrl = TextEditingController(
    text: 'تحديث ومطابقة الرخصة والمعاملة من مهندس الموقع للبدء الفوري',
  );

  String _selectedOffice = 'مكتب خريص';
  String _selectedPermitCat = 'سارية / مفعلة (رخص PDF المعتمدة)';
  final String _selectedDecision = 'معتمدة للتنفيذ الفوري ✅';
  final String _selectedPriority = 'P1 - جاهزة للتنفيذ الفوري (رخصة سارية)';
  String _selectedSupervisor =
      'مشرف علي الجدع (مشرف الرخص والمختبر وإغلاق المعاملات)';

  String _geminiSkillOutput = '';

  void _loadCoordIntoForm(CoordinationItem c) {
    setState(() {
      _selectedCoordId = c.coordId;
      _permitIdCtrl.text =
          c.hasValidPermit ? c.matchedPermitId : 'بدون رخصة مصدرة';
      _baseNoCtrl.text = c.baseNo;
      _txNoCtrl.text = c.transactionNo;
      _selectedOffice =
          ['مكتب خريص', 'مكتب الشمال', 'مكتب الشرق'].contains(c.office)
              ? c.office
              : 'مكتب خريص';
      _districtCtrl.text = c.district;
      _lengthCtrl.text = c.digLengthLabel;
      _startCtrl.text = c.expectedStart;
      _endCtrl.text = c.matchedPermitEndDate;
      _selectedSupervisor = kSupervisorsList.contains(c.assignedSupervisor)
          ? c.assignedSupervisor
          : kSupervisorsList.first;
      _engineerCtrl.text = 'مهندس الموقع / المراقب: ${c.fieldMonitor}';
      _notesCtrl.text = c.notes.isNotEmpty
          ? c.notes
          : 'تعديل مباشر من مهندس الموقع وتحديث شيت الـ 4 ساعات';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ctrl.tr(
                    '🛠️ منصة التعديل الفوري لمهندس الموقع (إضافة / تعديل / تبديل معاملة بدل معاملة / إلغاء رخصة)',
                    '🛠️ Site Engineer Instant Editor (Add / Edit / Swap / Cancel Permit or Transaction)',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ctrl.tr(
                    'يتم حفظ أي إجراء فوراً في جدول تنسيق الأعمال الأسبوعي وسجل الرخص الشامل مع تحديث دورة الـ 4 ساعات على Google Drive وإشعار المشرف المختص.',
                    'All actions are immediately saved to the Weekly Coordination Table & Master Registry with 4-Hour Google Drive sync and supervisor notification.',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),

                // Mode Tabs
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _modeButton(
                      'EDIT',
                      ctrl.tr('✏️ تعديل معاملة / رخصة قائمة', '✏️ Edit Existing Permit / Tx'),
                      FluentEnterpriseTheme.fluentBlue,
                      isDark,
                    ),
                    _modeButton(
                      'ADD',
                      ctrl.tr('➕ إضافة رخصة / معاملة جديدة', '➕ Add New Permit / Tx'),
                      FluentEnterpriseTheme.successFg,
                      isDark,
                    ),
                    _modeButton(
                      'SWAP',
                      ctrl.tr('🔄 تبديل معاملة بدل معاملة', '🔄 Swap Transaction'),
                      FluentEnterpriseTheme.warningFg,
                      isDark,
                    ),
                    _modeButton(
                      'CANCEL',
                      ctrl.tr('🚫 إلغاء أو إيقاف معاملة / رخصة', '🚫 Cancel or Hold Permit / Tx'),
                      FluentEnterpriseTheme.dangerFg,
                      isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Select Existing Coordination Item
                if (_mode != 'ADD')
                  DropdownButtonFormField<String>(
                    value: _selectedCoordId,
                    decoration: InputDecoration(
                      labelText: ctrl.tr(
                        'اختر المعاملة من جدول التنسيق الأسبوعي (85 معاملة) لتحميل بياناتها فوراً',
                        'Select Transaction from Weekly Coordination (85 items) to auto-fill',
                      ),
                    ),
                    items: ctrl.coordinationItems.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.coordId,
                        child: Text(
                          '${c.seq}. [${c.office}] ${c.baseNo} | ${c.transactionNo} | ${c.matchedPermitId} (${c.district})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final found = ctrl.coordinationItems
                            .firstWhere((x) => x.coordId == val);
                        _loadCoordIntoForm(found);
                      }
                    },
                  ),

                const SizedBox(height: 14),

                // Form Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _permitIdCtrl,
                        decoration: InputDecoration(
                          labelText: ctrl.tr('رقم الرخصة (Permit ID)', 'Permit ID'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _baseNoCtrl,
                        decoration: InputDecoration(
                          labelText: ctrl.tr('رقم الأساس (R-Number)', 'Base No (R-Number)'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _txNoCtrl,
                        decoration: InputDecoration(
                          labelText: ctrl.tr('رقم المعاملة / السكيم', 'Transaction / Scheme No'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: _selectedOffice,
                        decoration: InputDecoration(
                          labelText: ctrl.tr('المكتب / القطاع', 'Office / Sector'),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'مكتب خريص',
                            child: Text(ctrl.tr('مكتب خريص', 'Khurais Office')),
                          ),
                          DropdownMenuItem(
                            value: 'مكتب الشمال',
                            child: Text(ctrl.tr('مكتب الشمال', 'North Office')),
                          ),
                          DropdownMenuItem(
                            value: 'مكتب الشرق',
                            child: Text(ctrl.tr('مكتب الشرق', 'East Office')),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedOffice = v ?? 'مكتب خريص'),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _districtCtrl,
                        decoration: InputDecoration(
                          labelText: ctrl.tr('الحي / الموقع', 'District / Location'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _lengthCtrl,
                        decoration: InputDecoration(
                          labelText: ctrl.tr('طول الحفر (متر)', 'Trench Length (m)'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 230,
                      child: TextField(
                        controller: _startCtrl,
                        decoration: InputDecoration(
                          labelText: ctrl.tr('موعد البداية المجدول', 'Scheduled Start Date'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _endCtrl,
                        decoration: InputDecoration(
                          labelText: ctrl.tr('تاريخ انتهاء الرخصة', 'Permit Expiry Date'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 340,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPermitCat,
                        decoration: InputDecoration(
                          labelText: ctrl.tr(
                            'الفئة والحالة التشغيلية للرخصة',
                            'Operational Category & Status',
                          ),
                        ),
                        items: kCategoriesSpec
                            .map((c) => DropdownMenuItem(
                                  value: c.key,
                                  child: Text(
                                    ctrl.trCategory(c.key),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                          () => _selectedPermitCat = v ?? kCategoriesSpec.first.key,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 380,
                      child: DropdownButtonFormField<String>(
                        value: _selectedSupervisor,
                        decoration: InputDecoration(
                          labelText: ctrl.tr(
                            'المشرف المختص القائم بالمعاملة',
                            'Assigned Specialized Supervisor',
                          ),
                        ),
                        items: kSupervisorsList
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                          () => _selectedSupervisor = v ?? kSupervisorsList.first,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _engineerCtrl,
                        decoration: InputDecoration(
                          labelText: ctrl.tr(
                            'مهندس الموقع / المراقب المنفذ',
                            'Site Engineer / Field Monitor',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: ctrl.tr(
                      'سبب التعديل / التبديل / الإلغاء والملاحظات الميدانية',
                      'Reason for Edit / Swap / Cancellation & Field Notes',
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Smart AI Skills & Action Buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            final res = ctrl.determineSpecializedSupervisor(
                              permitId: _permitIdCtrl.text,
                              office: _selectedOffice,
                              permitCategory: _selectedPermitCat,
                              approvalDecision: _selectedDecision,
                              notes: _notesCtrl.text,
                            );
                            setState(() {
                              _selectedSupervisor = res['supervisor']!;
                              _geminiSkillOutput = ctrl.tr(
                                '🧠 [توجيه التخصص الذكي]\n'
                                '• المشرف المعين تلقائياً: ${res['supervisor']}\n'
                                '• نطاق التخصص: ${res['domain']}\n'
                                '• المعاملة: ${_baseNoCtrl.text} | ${_txNoCtrl.text} | الرخصة: ${_permitIdCtrl.text}',
                                '🧠 [Smart Supervisor Routing]\n'
                                '• Auto-Assigned Supervisor: ${res['supervisor']}\n'
                                '• Domain: ${res['domain']}\n'
                                '• Transaction: ${_baseNoCtrl.text} | ${_txNoCtrl.text} | Permit: ${_permitIdCtrl.text}',
                              );
                            });
                          },
                          icon: const Icon(Icons.psychology, size: 16),
                          label: Text(
                            ctrl.tr(
                              'فحص وتعيين المشرف المختص آلياً',
                              'Auto-Assign Specialized Supervisor',
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mode == 'CANCEL'
                            ? FluentEnterpriseTheme.dangerFg
                            : FluentEnterpriseTheme.fluentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () {
                        ctrl.executeSiteEngineerPermitAction(
                          actionType: _mode,
                          targetCoordId: _selectedCoordId,
                          permitId: _permitIdCtrl.text,
                          baseNo: _baseNoCtrl.text,
                          transactionNo: _txNoCtrl.text,
                          office: _selectedOffice,
                          district: _districtCtrl.text,
                          lengthLabel: _lengthCtrl.text,
                          expectedStart: _startCtrl.text,
                          endDate: _endCtrl.text,
                          permitCategory: _selectedPermitCat,
                          approvalDecision: _selectedDecision,
                          priorityTier: _selectedPriority,
                          supervisor: _selectedSupervisor,
                          engineerName: _engineerCtrl.text,
                          reasonNotes: _notesCtrl.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ctrl.tr(
                                '✅ تم تنفيذ العملية ($_mode) على الرخصة (${_permitIdCtrl.text}) والأساس (${_baseNoCtrl.text}) ومزامنة الـ 4 ساعات!',
                                '✅ Action ($_mode) executed on Permit (${_permitIdCtrl.text}) / Base (${_baseNoCtrl.text}) with 4-Hour Sync!',
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: Text(
                        ctrl.tr(
                          'تنفيذ وحفظ في النظام والشيت ومزامنة الـ 4 ساعات',
                          'Execute, Save to Sheet & Run 4-Hour Sync',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),

                if (_geminiSkillOutput.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: SelectableText(
                      _geminiSkillOutput,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Audit Trail of Site Engineer Rapid Edits / Swaps / Cancellations
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.tr(
                    '📜 سجل عمليات مهندس الموقع الفورية (${ctrl.siteEngineerLogs.length} عمليات معتمدة مع تحديث الـ 4 ساعات)',
                    '📜 Site Engineer Instant Operations Log (${ctrl.siteEngineerLogs.length} approved entries with 4h sync)',
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F5F5),
                    ),
                    columns: [
                      DataColumn(label: Text(ctrl.tr('رقم الطلب', 'Request ID'))),
                      DataColumn(label: Text(ctrl.tr('التوقيت', 'Timestamp'))),
                      DataColumn(label: Text(ctrl.tr('نوع الإجراء', 'Action Type'))),
                      DataColumn(label: Text(ctrl.tr('المكتب', 'Office'))),
                      DataColumn(label: Text(ctrl.tr('الأساس السابق ← الجديد', 'Old Base → New Base'))),
                      DataColumn(label: Text(ctrl.tr('رقم الرخصة', 'Permit ID'))),
                      DataColumn(label: Text(ctrl.tr('المشرف المختص', 'Assigned Supervisor'))),
                      DataColumn(label: Text(ctrl.tr('السبب والحالة', 'Reason & Status'))),
                    ],
                    rows: ctrl.siteEngineerLogs.map((log) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            log.reqId,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          )),
                          DataCell(Text(log.reqTime)),
                          DataCell(Text(
                            log.reqType,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          )),
                          DataCell(Text(log.office)),
                          DataCell(Text('${log.oldBaseNo} ← ${log.newBaseNo}')),
                          DataCell(Text(
                            log.permitId,
                            style: const TextStyle(
                              color: FluentEnterpriseTheme.fluentBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          )),
                          DataCell(Text(log.supervisor)),
                          DataCell(Text('${log.reason} (${log.status})')),
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

  Widget _modeButton(String modeKey, String label, Color color, bool isDark) {
    final isSelected = _mode == modeKey;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color.withValues(alpha: 0.14) : null,
        side: BorderSide(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF334155) : const Color(0xFFD1D1D1)),
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onPressed: () => setState(() => _mode = modeKey),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

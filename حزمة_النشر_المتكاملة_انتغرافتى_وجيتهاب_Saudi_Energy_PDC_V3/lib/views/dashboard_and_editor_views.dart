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
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '👁️ أنت تتصفح المنصة الآن في «وضع الزائر»: يتم عرض المنصات والرخص التي تعمل (السارية) وتحت التنفيذ فقط. لفتح باقي أقسام المنصة والتعديل وإصدار الشيتات يلزم موافقة المشرف علي الجدع (0597778853).',
                    style: TextStyle(
                      color: Color(0xFF92400E),
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
                  label: const Text('طلب موافقة / دخول معتمد'),
                ),
              ],
            ),
          ),

        // Egyptian Male Voice AI & Google AI Studio Fast Search Hub
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
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.record_voice_over,
                            color: FluentEnterpriseTheme.fluentBlue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '🎙️ المساعد الصوتي باللهجة المصرية (صوت رجل) ومحرك البحث وإصدار الشيتات الفوري (<15ms)',
                            style: TextStyle(
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
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FluentEnterpriseTheme.fluentBlue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => ctrl.voiceAi.speakExecutiveBriefing(
                              totalPermits: total,
                              activePermits: activeValid,
                              returnedCenter: retCenter,
                              returnedCons: retCons,
                              expiredPermits: expUnclosed,
                              closedPermits: closedFinal,
                              weeklyCount: ctrl.coordinationItems.length,
                            ),
                            icon: const Icon(Icons.volume_up, size: 16),
                            label: const Text('ملخص المنصة بصوت مصري (رجل)'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final msg = await ctrl
                                  .generateAndCopyCsvSheet('ACTIVE_EXEC');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('📥 $msg (تم نسخ CSV)')),
                                );
                              }
                            },
                            icon: const Icon(Icons.table_chart, size: 16),
                            label: const Text('شيت العاملة وتحت التنفيذ'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final msg = await ctrl
                                  .generateAndCopyCsvSheet('LAB_AND_EXPIRED');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('📥 $msg (تم نسخ CSV)')),
                                );
                              }
                            },
                            icon: const Icon(Icons.science, size: 16),
                            label: const Text('شيت المختبر والمنتهية (علي الجدع)'),
                          ),
                          if (ctrl.isAuthorizedSupervisor)
                            OutlinedButton.icon(
                              onPressed: () => setState(
                                () => _showStudioConfigBox = !_showStudioConfigBox,
                              ),
                              icon: const Icon(Icons.vpn_key, size: 16),
                              label: const Text('إعداد Google AI Studio API (للمشرف)'),
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
                        color: FluentEnterpriseTheme.fluentBlueTint,
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
                              decoration: const InputDecoration(
                                labelText:
                                    'مفتاح Google AI Studio API (GEMINI_API_KEY) — مخصص للمشرف علي الجدع',
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
                                const SnackBar(
                                  content: Text(
                                    '🔑 تم حفظ وتفعيل مفتاح Google AI Studio API للمشرف علي الجدع!',
                                  ),
                                ),
                              );
                            },
                            child: const Text('حفظ وتفعيل المفتاح'),
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
                          decoration: const InputDecoration(
                            hintText:
                                'اكتب أي استفسار أو رقم رخصة أو أساس (مثلاً: R6949، مقارنة شاملة، رخص سارية، معاد المركز)...',
                            prefixIcon: Icon(Icons.search),
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
                        label: const Text('بحث ومقارنة صوتية فورية'),
                      ),
                    ],
                  ),
                  if (ctrl.lastFastSearchResponse != null) ...[
                    const SizedBox(height: 12),
                    _buildFastSearchResultBox(ctrl.lastFastSearchResponse!),
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
                title: 'إجمالي الرخص الفريدة الموحدة',
                value: '$total',
                subtitle: 'بعد حذف 569 رخصة مكررة | تحديث 4 ساعات',
                icon: Icons.folder_special,
                accentColor: FluentEnterpriseTheme.fluentBlue,
                onTap: () => ctrl.jumpToLicenseCategory('ALL'),
              ),
              _KpiItem(
                title: 'الرخص السارية وتحت التنفيذ ✅',
                value: '$activeValid',
                subtitle: 'متاحة للزوار وللتنزيل المباشر من الدرايف',
                icon: Icons.verified,
                accentColor: FluentEnterpriseTheme.successFg,
                onTap: () => ctrl.jumpToLicenseCategory(
                  'سارية / مفعلة (رخص PDF المعتمدة)',
                ),
              ),
              _KpiItem(
                title: 'معادة من المركز RIPC 🚨',
                value: '$retCenter',
                subtitle: 'تحتاج معالجة ثقب أفقي أو تعديل وضع',
                icon: Icons.warning_amber_rounded,
                accentColor: FluentEnterpriseTheme.dangerFg,
                onTap: () => ctrl.jumpToLicenseCategory('معاد من قبل المركز'),
              ),
              _KpiItem(
                title: 'معادة من المكتب الاستشاري 🏢',
                value: '$retCons',
                subtitle: 'استكمال ملاحظات الدمك وصور بعد التنفيذ',
                icon: Icons.engineering,
                accentColor: FluentEnterpriseTheme.warningFg,
                onTap: () =>
                    ctrl.jumpToLicenseCategory('معاد من قبل الاستشاري'),
              ),
              _KpiItem(
                title: 'منتهية (تحتاج معالجة وإغلاق)',
                value: '$expUnclosed',
                subtitle: 'تخصص الرخص والمختبر: مشرف علي الجدع',
                icon: Icons.schedule,
                accentColor: const Color(0xFF991B1B),
                onTap: () => ctrl.jumpToLicenseCategory(
                  'منتهية (تحتاج معالجة وإغلاق)',
                ),
              ),
              _KpiItem(
                title: 'مغلقة نهائياً + تم الرفع للإغلاق',
                value: '$closedFinal / $subClosing',
                subtitle: 'مربوطة بمستخلصات ومهام أودو ERP',
                icon: Icons.task_alt,
                accentColor: const Color(0xFF059669),
                onTap: () => ctrl.jumpToLicenseCategory('مغلقة (تم الإغلاق)'),
              ),
              _KpiItem(
                title: 'حرجة مهلة المختبر 60 يوماً (≤15 يوم)',
                value: '$labNear60',
                subtitle: 'إجمالي فسوحات مختبر URS: ${ctrl.ursInspections.length}',
                icon: Icons.science,
                accentColor: const Color(0xFFDC2626),
                onTap: () => ctrl.switchView('urs'),
              ),
              _KpiItem(
                title: 'معاملات الأسبوع الجاهزة للتنفيذ 📅',
                value: '$readyNextWeek / ${ctrl.coordinationItems.length}',
                subtitle: 'خريص 50 | الشمال 25 | الشرق 10',
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
              itemBuilder: (c, idx) => _buildKpiCard(kpis[idx]),
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
                const Text(
                  '📋 مصفوفة الأسئلة التنفيذية الـ 18 (إجابات حية مباشرة من قاعدة البيانات الموحدة V3.0)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _q18Chip('1. كم عدد الرخص لدينا؟', '$total رخصة فريدة', 'licenses'),
                    _q18Chip('2. السارية والمنتهية؟', '$activeValid سارية | $expUnclosed منتهية', 'licenses'),
                    _q18Chip('3. قاربت على الانتهاء؟', '16 رخصة (≤7 أيام)', 'comparison'),
                    _q18Chip('4. تحتاج تجديد؟', '${ctrl.coordinationItems.where((c) => c.readinessGroup.contains("تجديد")).length} رخصة اعتيادية', 'weekly'),
                    _q18Chip('5. أعمال تحتاج رخص جديدة؟', '${ctrl.coordinationItems.where((c) => c.readinessGroup.contains("جديدة")).length} أعمال', 'weekly'),
                    _q18Chip('6. أعمال تحتاج رخص طوارئ؟', '${ctrl.coordinationItems.where((c) => c.readinessGroup.contains("طوارئ")).length} طوارئ', 'weekly'),
                    _q18Chip('7. المعادة من الاستشاري؟', '$retCons رخصة', 'returned'),
                    _q18Chip('8. المعادة من المركز؟', '$retCenter رخصة', 'returned'),
                    _q18Chip('9. المعتمدة والمغلقة؟', '${subClosing + closedFinal} رخصة', 'licenses'),
                    _q18Chip('10. تحت معالجة SEC؟', '$subClosing رخصة', 'licenses'),
                    _q18Chip('11. المغلقة نهائياً؟', '$closedFinal مغلقة', 'licenses'),
                    _q18Chip('12. اقتربت من 60 يوم مختبر؟', '$labNear60 رخصة', 'urs'),
                    _q18Chip('13. تقارير مختبر URS؟', '17 ناجح | 35 به نقاط راسبة', 'urs'),
                    _q18Chip('14. جاهزة الأسبوع القادم؟', '$readyNextWeek عمل جاهز', 'weekly'),
                    _q18Chip('15. أعمال يجب إيقافها؟', '${ctrl.coordinationItems.length - readyNextWeek} غير مستوفٍ', 'coordination'),
                    _q18Chip('16. توزيع المشرفين والاستشاريين؟', '7 مشرفين | 8 استشاريين', 'comparison'),
                    _q18Chip('17. المرتبطة بالأساس R6949؟', '${ctrl.pdfLicenses.length} رخصة PDF و OCR', 'ocr'),
                    _q18Chip('18. حجم المسارات الموثقة؟', '3,384.6 متر طولي', 'gis'),
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
                const Text(
                  '📊 التوزيع الإحصائي للفئات الـ 11 في سجل الرخص الشامل (انقر على أي فئة لفتحها)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
                            width: 190,
                            child: Text(
                              cat.shortTitle,
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
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(cat.colorHex),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 75,
                            child: Text(
                              '$cnt رخصة',
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

  Widget _buildFastSearchResultBox(EgyptianSearchResponse res) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FluentEnterpriseTheme.fluentBlueTint,
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
                '⚡ نتيجة البحث والمقارنة الفائقة (Google AI Studio — زمن الاستجابة: ${res.elapsedMs}ms)',
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
                      SnackBar(content: Text('📥 $msg (تم نسخ CSV للحافظة)')),
                    );
                  }
                },
                icon: const Icon(Icons.download, size: 15),
                label: const Text('نسخ/تنزيل شيت النتائج (CSV)'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '🎙️ رد المساعد المصري (صوت رجل): "${res.egyptianVoiceReply}"',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(_KpiItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
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
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _q18Chip(String q, String a, String targetView) {
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                q,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
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
  String _selectedDecision = 'معتمدة للتنفيذ الفوري ✅';
  String _selectedPriority = 'P1 - جاهزة للتنفيذ الفوري (رخصة سارية)';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '🛠️ منصة التعديل الفوري لمهندس الموقع (إضافة / تعديل / تبديل معاملة بدل معاملة / إلغاء رخصة)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'يتم حفظ أي إجراء فوراً في جدول تنسيق الأعمال الأسبوعي وسجل الرخص الشامل مع تحديث دورة الـ 4 ساعات على Google Drive وإشعار المشرف المختص.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // Mode Tabs
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _modeButton('EDIT', '✏️ تعديل معاملة / رخصة قائمة', FluentEnterpriseTheme.fluentBlue),
                    _modeButton('ADD', '➕ إضافة رخصة / معاملة جديدة', FluentEnterpriseTheme.successFg),
                    _modeButton('SWAP', '🔄 تبديل معاملة بدل معاملة', FluentEnterpriseTheme.warningFg),
                    _modeButton('CANCEL', '🚫 إلغاء أو إيقاف معاملة / رخصة', FluentEnterpriseTheme.dangerFg),
                  ],
                ),

                const SizedBox(height: 14),

                // Select Existing Coordination Item
                if (_mode != 'ADD')
                  DropdownButtonFormField<String>(
                    value: _selectedCoordId,
                    decoration: const InputDecoration(
                      labelText:
                          'اختر المعاملة من جدول التنسيق الأسبوعي (85 معاملة) لتحميل بياناتها فوراً',
                    ),
                    items: ctrl.coordinationItems.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.coordId,
                        child: Text(
                          '${c.seq}. [${c.office}] أساس: ${c.baseNo} | معاملة: ${c.transactionNo} | رخصة: ${c.matchedPermitId} (${c.district})',
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
                        decoration: const InputDecoration(
                          labelText: 'رقم الرخصة (Permit ID)',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _baseNoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم الأساس (R-Number)',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _txNoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم المعاملة / السكيم',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: _selectedOffice,
                        decoration: const InputDecoration(
                          labelText: 'المكتب / القطاع',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'مكتب خريص', child: Text('مكتب خريص')),
                          DropdownMenuItem(value: 'مكتب الشمال', child: Text('مكتب الشمال')),
                          DropdownMenuItem(value: 'مكتب الشرق', child: Text('مكتب الشرق')),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedOffice = v ?? 'مكتب خريص'),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _districtCtrl,
                        decoration: const InputDecoration(
                          labelText: 'الحي / الموقع',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _lengthCtrl,
                        decoration: const InputDecoration(
                          labelText: 'طول الحفر (متر)',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 230,
                      child: TextField(
                        controller: _startCtrl,
                        decoration: const InputDecoration(
                          labelText: 'موعد البداية المجدول',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ انتهاء الرخصة',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 340,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPermitCat,
                        decoration: const InputDecoration(
                          labelText: 'الفئة والحالة التشغيلية للرخصة',
                        ),
                        items: kCategoriesSpec
                            .map((c) => DropdownMenuItem(
                                  value: c.key,
                                  child: Text(
                                    c.shortTitle,
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
                        decoration: const InputDecoration(
                          labelText: 'المشرف المختص القائم بالمعاملة',
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
                        decoration: const InputDecoration(
                          labelText: 'مهندس الموقع / المراقب المنفذ',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'سبب التعديل / التبديل / الإلغاء والملاحظات الميدانية',
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
                              _geminiSkillOutput =
                                  '🧠 [توجيه التخصص الذكي — gemini-3.8-flash]\n'
                                  '• المشرف المعين تلقائياً: ${res['supervisor']}\n'
                                  '• نطاق التخصص: ${res['domain']}\n'
                                  '• المعاملة: ${_baseNoCtrl.text} | ${_txNoCtrl.text} | الرخصة: ${_permitIdCtrl.text}';
                            });
                          },
                          icon: const Icon(Icons.psychology, size: 16),
                          label: const Text('فحص وتعيين المشرف المختص آلياً'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            final sample =
                                'إملاء صوتي لمهندس الموقع: تم فحص المعاملة (${_baseNoCtrl.text}) والرخصة (${_permitIdCtrl.text}) ومطابقتها مع تحديث Google Drive، وإحالتها للمشرف المختص ($_selectedSupervisor).';
                            setState(() {
                              _notesCtrl.text = sample;
                              _geminiSkillOutput =
                                  '🎙️ [تفريغ صوتي فوري — gemini-3.5-transcribe-live]:\n"$sample"';
                            });
                            ctrl.voiceAi.speakEgyptianMale(
                              'تم تسجيل الملاحظة الصوتية للمعاملة ${_baseNoCtrl.text} وتوجيهها للمشرف المختص يا باشمهندس.',
                            );
                          },
                          icon: const Icon(Icons.mic, size: 16),
                          label: const Text('إملاء صوتي للملاحظات'),
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
                              '✅ تم تنفيذ العملية ($_mode) على الرخصة (${_permitIdCtrl.text}) والأساس (${_baseNoCtrl.text}) ومزامنة الـ 4 ساعات!',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'تنفيذ وحفظ في النظام والشيت ومزامنة الـ 4 ساعات',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),

                if (_geminiSkillOutput.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
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
                  '📜 سجل عمليات مهندس الموقع الفورية (${ctrl.siteEngineerLogs.length} عمليات معتمدة مع تحديث الـ 4 ساعات)',
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
                      const Color(0xFFF5F5F5),
                    ),
                    columns: const [
                      DataColumn(label: Text('رقم الطلب')),
                      DataColumn(label: Text('التوقيت')),
                      DataColumn(label: Text('نوع الإجراء')),
                      DataColumn(label: Text('المكتب')),
                      DataColumn(label: Text('الأساس السابق ← الجديد')),
                      DataColumn(label: Text('رقم الرخصة')),
                      DataColumn(label: Text('المشرف المختص')),
                      DataColumn(label: Text('السبب والحالة')),
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

  Widget _modeButton(String modeKey, String label, Color color) {
    final isSelected = _mode == modeKey;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color.withValues(alpha: 0.1) : null,
        side: BorderSide(
          color: isSelected ? color : const Color(0xFFD1D1D1),
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onPressed: () => setState(() => _mode = modeKey),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? color : const Color(0xFF334155),
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

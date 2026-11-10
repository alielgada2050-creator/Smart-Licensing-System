// 13-Tab Comprehensive License Profile Modal & Access Gate Dialogs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/permit_models.dart';
import '../services/enterprise_controller.dart';
import '../theme/fluent_enterprise_theme.dart';

void showLicense13TabsModal(
  BuildContext context,
  EnterpriseController ctrl,
  PermitRecord permit,
) {
  showDialog(
    context: context,
    builder: (ctx) => _License13TabsDialog(ctrl: ctrl, permit: permit),
  );
}

class _License13TabsDialog extends StatefulWidget {
  final EnterpriseController ctrl;
  final PermitRecord permit;

  const _License13TabsDialog({
    required this.ctrl,
    required this.permit,
  });

  @override
  State<_License13TabsDialog> createState() => _License13TabsDialogState();
}

class _License13TabsDialogState extends State<_License13TabsDialog> {
  int _activeTab = 1;

  static const List<String> _tabTitles = [
    '1. البيانات الأساسية',
    '2. المستندات (Drive Tree)',
    '3. دورة الحياة (17 مرحلة)',
    '4. التنسيقات الأسبوعية',
    '5. التنفيذ الميداني',
    '6. التجديد والمدد',
    '7. المختبر URS (60 يوم)',
    '8. الاستشاري الهندسي',
    '9. المركز RIPC',
    '10. الجهة المالكة SEC',
    '11. الملاحظات والإعادات',
    '12. مسوغات الإغلاق',
    '13. سجل التدقيق',
  ];

  @override
  Widget build(BuildContext context) {
    final r = widget.permit;
    final sla = r.calculateSla();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: FluentEnterpriseTheme.saudiDarkBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملف الرخصة الشامل رقم (${r.permitId}) — رقم الأساس (${r.baseNo})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الحالة الحالية: ${r.category} | الاستشاري: ${r.consultant} | المختبر: ${r.lab}',
                            style: const TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FluentEnterpriseTheme.successFg,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            final url = r.pdfUrl.isNotEmpty
                                ? r.pdfUrl
                                : 'https://drive.google.com/drive/folders/1NAPYUAV2ow9UeqEvK3z-OC0KAOcuah3N';
                            widget.ctrl.openExternalUrl(url);
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('تنزيل الرخصة من الدرايف'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 13 Tabs Horizontal Bar
              Container(
                color: const Color(0xFFF1F5F9),
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _tabTitles.length,
                  itemBuilder: (ctx, i) {
                    final tabIndex = i + 1;
                    final isSelected = _activeTab == tabIndex;
                    return InkWell(
                      onTap: () => setState(() => _activeTab = tabIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? FluentEnterpriseTheme.fluentBlue
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          _tabTitles[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? FluentEnterpriseTheme.fluentBlue
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildTabContent(r, sla),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(PermitRecord r, PermitSlaInfo sla) {
    if (_activeTab == 1) {
      final fields = [
        MapEntry('رقم الرخصة', r.permitId),
        MapEntry('رقم الأساس (Base No)', r.baseNo),
        MapEntry('رقم السكيم / المعاملة', r.schemeNo.isNotEmpty ? r.schemeNo : r.transactionNo),
        MapEntry('رقم المحطة', r.stationNo.isNotEmpty ? r.stationNo : 'ST-6035'),
        MapEntry('الفئة والحالة التشغيلية', r.category),
        MapEntry('نوع الرخصة وطريقة الحفر', '${r.permitType} — ${r.digType}'),
        MapEntry('حالة حظر الشارع', r.roadBanStatus),
        MapEntry('الجهة المالكة والمقاول', 'الشركة السعودية للكهرباء (SEC) — شركة الأساس العريض'),
        MapEntry('المكتب الاستشاري', r.consultant),
        MapEntry('المختبر المعتمد', r.lab),
        MapEntry('تاريخ الإصدار ← الانتهاء', '${r.issueDate} ← ${sla.endStr}'),
        MapEntry('المشرف القائم بالمعاملة والمراقب', '${r.engineer} | المراقب: ${r.inspector}'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. البيانات الأساسية الكاملة للرخصة ودورة حياتها',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: fields
                .map(
                  (e) => Container(
                    width: 310,
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
                          e.key,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          e.value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );
    } else if (_activeTab == 2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: SelectableText(
          '📁 License_${r.permitId} (${r.baseNo})\n'
          '├── 📂 01_Original_License (مستند الرخصة الأصلي محفوظ ولا يُحذف)\n'
          '├── 📂 02_Renewals (سجل ومستندات التجديد)\n'
          '├── 📂 03_Approvals (خطاب التعهد + خطاب SEC + شركة السفلتة المؤهلة للشوارع المحظورة)\n'
          '├── 📂 04_Consultant_Comments (ملاحظات الاستشاري: ${r.consultant})\n'
          '├── 📂 05_Center_Comments (ملاحظات مركز مشاريع البنية التحتية RIPC)\n'
          '├── 📂 06_URS_Reports (تقرير مختبر URS: ${r.ursResult})\n'
          '├── 📂 07_Execution_Photos (صور الحفر وتمديد الكابلات: ${r.photosUploaded})\n'
          '├── 📂 08_Correction_Evidence (إثبات معالجة الملاحظات قبل/بعد السفلتة)\n'
          '├── 📂 09_Closure_Documents (مسوغات الإغلاق الأولي)\n'
          '└── 📂 10_Final_Closure (شهادة الإغلاق النهائي المعتمدة وربط المستخلص في أودو)',
          style: const TextStyle(height: 1.9, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    } else if (_activeTab == 3) {
      final stages = [
        '1. طلب رخصة ✓',
        '2. مراجعة البيانات ✓',
        '3. مراجعة المستندات ✓',
        '4. فحص الطريق (${r.roadBanStatus}) ✓',
        '5. استكمال الاعتمادات ✓',
        '6. إصدار الرخصة (${r.issueDate}) ✓',
        '7. تفعيل الرخصة ✓',
        '8. الحالة الحالية: ${r.category}',
        '9. فحص مختبر URS (مهلة 60 يوماً)',
        '10. مطابقة الاستشاري الهندسي',
        '11. مطابقة مركز المشاريع RIPC',
        '12. اعتماد الجهة المالكة SEC',
        '13. الإغلاق النهائي وربط مستخلص أودو',
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. الخط الزمني لدورة حياة الرخصة (Workflow Timeline — لا يُسمح بتجاوز أي مرحلة إلزامية)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stages.asMap().entries.map((entry) {
              final isDone = entry.key < 7;
              final isCurrent = entry.key == 7;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? FluentEnterpriseTheme.fluentBlueTint
                      : (isDone ? FluentEnterpriseTheme.successBg : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCurrent
                        ? FluentEnterpriseTheme.fluentBlue
                        : (isDone ? FluentEnterpriseTheme.successFg : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCurrent
                        ? FluentEnterpriseTheme.fluentBlue
                        : (isDone ? FluentEnterpriseTheme.successFg : const Color(0xFF475569)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    } else if (_activeTab == 7) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7. إدارة تقرير المختبر URS ومهلة الـ 60 يوماً (بإشراف المشرف علي الجدع)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _infoRow('تاريخ انتهاء الرخصة الأصلي:', '${sla.endStr} (محفوظ ولا يُستبدل عند التحديث)'),
          _infoRow('تاريخ بداية مهلة المختبر:', sla.endStr),
          _infoRow('آخر موعد مسموح لرفع تقرير المختبر (+60 يوماً):', sla.labDeadlineStr),
          _infoRow('الأيام المتبقية للمختبر:', sla.slaLabel),
          _infoRow('حالة ونتيجة تقرير المختبر URS:', r.ursResult),
          _infoRow('المشرف المسؤول عن سلة المختبر:', 'مشرف علي الجدع (0597778853)'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_tabTitles[_activeTab - 1]} — الرخصة (${r.permitId}) / الأساس (${r.baseNo})',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _infoRow('الحالة التشغيلية:', r.category),
        _infoRow('الحي والموقع:', r.district),
        _infoRow('الملاحظات وأسباب الإعادة:', r.returnReason.isNotEmpty ? r.returnReason : (r.notes.isNotEmpty ? r.notes : 'لا توجد ملاحظات معوقة')),
        _infoRow('الملف المصدري الموثق:', r.sourceFile),
        _infoRow('سجل التدقيق:', 'موثق ومحفوظ ضمن دورة التحديث كل 4 ساعات مع Google Drive و Odoo ERP'),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

void showAccessGateModal(BuildContext context, EnterpriseController ctrl) {
  final emailCtrl = TextEditingController(text: ctrl.loggedInEmail);
  final nameCtrl = TextEditingController(text: ctrl.loggedInName);
  final otpCtrl = TextEditingController(text: '849206');

  showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '🔐 منظومة الدخول إلى المنصة والصلاحيات (وضع الزائر / موافقة المشرف علي الجدع)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    '• 👁️ وضع الزائر (متاح بدون تسجيل دخول): يتيح رؤية المنصات والرخص التي تعمل (السارية) أو التي تحت التنفيذ فقط وتنزيل رخصها.\n'
                    '• 🔓 الدخول الكامل لباقي أقسام المنصة والتعديل وإصدار الشيتات: يتوجب تسجيل الدخول وموافقة المشرف علي الجدع من خلال الإيميل المرفق في الدعم الفني (alielgada5@gmail.com) أو التواصل عبر الواتساب (0597778853).',
                    style: TextStyle(fontSize: 12, height: 1.6),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFFBEB),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ctrl.activateVisitorMode();
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '👁️ تم تفعيل «وضع الزائر»: يتم عرض المنصات والرخص العاملة وتحت التنفيذ فقط.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, color: Color(0xFFB45309)),
                        label: const Text(
                          'تفعيل وضع الزائر الآن',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FluentEnterpriseTheme.fluentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ctrl.authenticateSupervisorOrEngineer(
                            email: emailCtrl.text,
                            name: nameCtrl.text,
                            otpCode: otpCtrl.text,
                          );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '✅ تم تفعيل الدخول المعتمد بموافقة المشرف علي الجدع وفتح جميع أقسام المنصة!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock_open),
                        label: const Text(
                          'دخول معتمد (كامل المنصة)',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني (Gmail) لطالب الدخول',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم المهندس / المشرف',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: otpCtrl,
                        decoration: const InputDecoration(
                          labelText: 'كود موافقة المشرف علي الجدع',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📞 لطلب الموافقة وتفعيل الدخول من المشرف علي الجدع (0597778853):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => ctrl.openExternalUrl(
                              'https://wa.me/966597778853?text=%D8%A7%D9%84%D8%B3%D9%84%D8%A7%D9%85%20%D8%B9%D9%84%D9%8A%D9%83%D9%85%20%D9%85%D8%B4%D8%B1%D9%81%20%D8%B9%D9%84%D9%8A%20%D8%A7%D9%84%D8%AC%D8%AF%D8%B9%D8%8C%20%D8%A3%D8%B1%D8%AC%D9%88%20%D8%A7%D9%84%D9%85%D9%88%D8%A7%D9%81%D9%82%D8%A9%20%D8%B9%D9%84%D9%89%20%D8%AF%D8%AE%D9%88%D9%84%D9%8A%20%D9%84%D9%84%D9%85%D9%86%D8%B5%D8%A9',
                            ),
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('واتساب (0597778853)'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0088CC),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                ctrl.openExternalUrl('https://t.me/+966597778853'),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('تيليجرام'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(text: 'alielgada5@gmail.com'),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ الإيميل: alielgada5@gmail.com'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.email, size: 16),
                            label: const Text('alielgada5@gmail.com'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

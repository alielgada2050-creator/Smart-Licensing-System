// ============================================================================
// منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC (الإصدار V3.0)
// الملف الرئيسي للتطبيق والويب (Flutter Mobile, Tablet, & Web Responsive Shell)
// يضم 16 شاشة تشغيلية متكاملة + الوضع الداكن الفاخر + ثنائية اللغة (عربي / English)
// إشراف عام: مشرف علي الجدع (alielgada5@gmail.com | 0597778853)
// ============================================================================

import 'package:flutter/material.dart';

import 'services/enterprise_controller.dart';
import 'theme/fluent_enterprise_theme.dart';
import 'views/agents_reports_support_views.dart';
import 'views/coordination_and_integrations_views.dart';
import 'views/dashboard_and_editor_views.dart';
import 'views/licenses_and_lab_views.dart';
import 'widgets/enterprise_modals.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaudiEnergySmartApp());
}

class SaudiEnergySmartApp extends StatefulWidget {
  const SaudiEnergySmartApp({super.key});

  @override
  State<SaudiEnergySmartApp> createState() => _SaudiEnergySmartAppState();
}

class _SaudiEnergySmartAppState extends State<SaudiEnergySmartApp> {
  late final EnterpriseController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EnterpriseController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: _controller.tr(
            'منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC',
            'Smart License Management Platform — Saudi Energy & PDC',
          ),
          debugShowCheckedModeBanner: false,
          theme: FluentEnterpriseTheme.buildLightTheme(),
          darkTheme: FluentEnterpriseTheme.buildDarkTheme(),
          themeMode: _controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return Directionality(
              textDirection:
                  _controller.isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: EnterpriseMainShell(ctrl: _controller),
        );
      },
    );
  }
}

// ============================================================================
// تعريف عناصر القائمة الجانبية الـ 16 (ثنائية اللغة عربي / إنجليزي)
// ============================================================================
class NavItemSpec {
  final String id;
  final String labelAr;
  final String labelEn;
  final String badgeAr;
  final String badgeEn;
  final IconData icon;
  final bool restrictedInVisitorMode;

  const NavItemSpec({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.badgeAr,
    required this.badgeEn,
    required this.icon,
    this.restrictedInVisitorMode = false,
  });

  String label(bool isEn) => isEn ? labelEn : labelAr;
  String badge(bool isEn) => isEn ? badgeEn : badgeAr;
}

const List<NavItemSpec> kEnterpriseNavItems16 = [
  NavItemSpec(
    id: 'tx-editor',
    labelAr: 'تعديل المعاملات (مهندس الموقع)',
    labelEn: 'Edit Transactions (Site Eng.)',
    badgeAr: 'ميداني',
    badgeEn: 'Field',
    icon: Icons.edit_note,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'dashboard',
    labelAr: '1. لوحة الإدارة العليا',
    labelEn: '1. Executive Dashboard',
    badgeAr: '946',
    badgeEn: '946',
    icon: Icons.dashboard_outlined,
  ),
  NavItemSpec(
    id: 'agents',
    labelAr: '2. الوكلاء وتحديث 4س',
    labelEn: '2. AI Agents & 4h Sync',
    badgeAr: '15 وكيل',
    badgeEn: '15 AI',
    icon: Icons.smart_toy_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'daily',
    labelAr: '3. التحديث اليومي 8ص',
    labelEn: '3. Daily 8:00 AM Report',
    badgeAr: 'الرياض',
    badgeEn: 'Riyadh',
    icon: Icons.wb_sunny_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'licenses',
    labelAr: '4. سجل الرخص الشامل',
    labelEn: '4. Master Permits Registry',
    badgeAr: '946',
    badgeEn: '946',
    icon: Icons.folder_special_outlined,
  ),
  NavItemSpec(
    id: 'comparison',
    labelAr: '5. تحليل ومقارنة الرخص',
    labelEn: '5. Permit Comparison',
    badgeAr: '<15ms',
    badgeEn: '<15ms',
    icon: Icons.compare_arrows,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'returned',
    labelAr: '6. الرخص المعادة',
    labelEn: '6. Returned Permits',
    badgeAr: '480',
    badgeEn: '480',
    icon: Icons.assignment_return_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'urs',
    labelAr: '7. تقارير المختبر URS',
    labelEn: '7. URS Lab Reports',
    badgeAr: '73',
    badgeEn: '73',
    icon: Icons.science_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'ocr',
    labelAr: '8. ذكاء المستندات OCR',
    labelEn: '8. PDF OCR Intelligence',
    badgeAr: '64',
    badgeEn: '64',
    icon: Icons.picture_as_pdf_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'coordination',
    labelAr: '9. جدول تنسيق الأعمال',
    labelEn: '9. Work Coordination Table',
    badgeAr: '85',
    badgeEn: '85',
    icon: Icons.engineering_outlined,
  ),
  NavItemSpec(
    id: 'weekly',
    labelAr: '10. الجدولة الأسبوعية',
    labelEn: '10. Weekly Plan (P0-P3)',
    badgeAr: 'P0-P3',
    badgeEn: 'P0-P3',
    icon: Icons.view_kanban_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'gis',
    labelAr: '11. الخرائط الجغرافية GIS',
    labelEn: '11. GIS Geospatial Map',
    badgeAr: 'GPS',
    badgeEn: 'GPS',
    icon: Icons.map_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'integrations',
    labelAr: '12. بوابة أودو وDrive',
    labelEn: '12. Odoo & Drive Hub',
    badgeAr: '126',
    badgeEn: '126',
    icon: Icons.cloud_sync_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'reports',
    labelAr: '13. التقارير والخطابات',
    labelEn: '13. Reports Studio',
    badgeAr: '20',
    badgeEn: '20',
    icon: Icons.analytics_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'architecture',
    labelAr: '14. المعمار والصلاحيات',
    labelEn: '14. Architecture & 10 AC',
    badgeAr: '10 AC',
    badgeEn: '10 AC',
    icon: Icons.verified_user_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'support',
    labelAr: '15. الدعم الفني (علي الجدع)',
    labelEn: '15. Tech Support (Ali Al-Jada)',
    badgeAr: '0597778853',
    badgeEn: '0597778853',
    icon: Icons.support_agent,
  ),
];

// ============================================================================
// الهيكل الرئيسي للتطبيق (Header + Slim Responsive Sidebar + Active View)
// ============================================================================
class EnterpriseMainShell extends StatefulWidget {
  final EnterpriseController ctrl;

  const EnterpriseMainShell({super.key, required this.ctrl});

  @override
  State<EnterpriseMainShell> createState() => _EnterpriseMainShellState();
}

class _EnterpriseMainShellState extends State<EnterpriseMainShell> {
  final TextEditingController _quickJumpCtrl = TextEditingController();

  @override
  void dispose() {
    _quickJumpCtrl.dispose();
    super.dispose();
  }

  void _handleQuickPermitJump(String rawInput) {
    final q = rawInput.trim().toLowerCase();
    if (q.isEmpty) return;
    final matches = widget.ctrl.permits.where((p) {
      return p.permitId.toLowerCase().contains(q) ||
          p.baseNo.toLowerCase().contains(q) ||
          p.transactionNo.toLowerCase().contains(q) ||
          p.schemeNo.toLowerCase().contains(q);
    }).toList();

    if (matches.isNotEmpty) {
      showLicense13TabsModal(context, widget.ctrl, matches.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.tr(
              'لم يتم العثور على رخصة مطابقة لـ "$rawInput" في قاعدة الـ 946 رخصة.',
              'No permit matching "$rawInput" found in the 946 permits database.',
            ),
          ),
        ),
      );
    }
  }

  void _handleNavSelection(NavItemSpec item) {
    final ok = widget.ctrl.switchView(item.id);
    if (!ok) {
      showAccessGateModal(context, widget.ctrl);
    }
  }

  Widget _buildActiveView(EnterpriseController ctrl) {
    switch (ctrl.activeView) {
      case 'tx-editor':
        return SiteEngineerTxEditorView(ctrl: ctrl);
      case 'dashboard':
        return ExecutiveDashboardView(ctrl: ctrl);
      case 'agents':
        return AiAgents15View(ctrl: ctrl);
      case 'daily':
        return Daily8AmReportView(ctrl: ctrl);
      case 'licenses':
        return MasterLicensesView(ctrl: ctrl);
      case 'comparison':
        return LicenseComparisonView(ctrl: ctrl);
      case 'returned':
        return ReturnedLicensesView(ctrl: ctrl);
      case 'urs':
        return UrsLabView(ctrl: ctrl);
      case 'ocr':
        return OcrDocumentIntelligenceView(ctrl: ctrl);
      case 'coordination':
        return WorkCoordinationView(ctrl: ctrl);
      case 'weekly':
        return WeeklyPlanView(ctrl: ctrl);
      case 'gis':
        return GisGeospatialView(ctrl: ctrl);
      case 'integrations':
        return OdooAndDriveIntegrationsView(ctrl: ctrl);
      case 'reports':
        return Reports20StudioView(ctrl: ctrl);
      case 'architecture':
        return ArchitectureAndAc10View(ctrl: ctrl);
      case 'support':
        return TechnicalSupportView(ctrl: ctrl);
      default:
        return ExecutiveDashboardView(ctrl: ctrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              width: 280,
              child: _buildSidebarContent(ctrl, isDrawer: true),
            ),
      body: Column(
        children: [
          _buildTopLuminousHeader(context, ctrl, isDesktop, isDark),
          if (ctrl.databaseLoadError != null)
            MaterialBanner(
              content: Text(
                'تعذر تحميل بيانات المنصة: ${ctrl.databaseLoadError}',
              ),
              leading: const Icon(Icons.error_outline, color: Colors.red),
              actions: [
                TextButton(
                  onPressed: ctrl.reloadData,
                  child: Text(ctrl.tr('إعادة المحاولة', 'Retry')),
                ),
              ],
            ),
          if (ctrl.isVisitorMode) _buildVisitorBanner(context, ctrl),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: ctrl.isSidebarExpanded ? 230 : 68,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      border: BorderDirectional(
                        end: BorderSide(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: _buildSidebarContent(ctrl, isDrawer: false),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: KeyedSubtree(
                      key: ValueKey<String>('${ctrl.activeView}_${ctrl.isEnglish}_${ctrl.isDarkMode}'),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildActiveView(ctrl),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomBar(ctrl),
    );
  }

  Widget _buildTopLuminousHeader(
    BuildContext context,
    EnterpriseController ctrl,
    bool isDesktop,
    bool isDark,
  ) {
    final isEn = ctrl.isEnglish;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // الهوية والشعار الرسمي
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDesktop)
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      tooltip: ctrl.tr('القائمة الرئيسية', 'Main Menu'),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(ctrl.isSidebarExpanded ? Icons.menu : Icons.menu_open),
                    tooltip: ctrl.isSidebarExpanded
                        ? ctrl.tr('طي القائمة الجانبية', 'Collapse Sidebar')
                        : ctrl.tr('توسيع القائمة الجانبية', 'Expand Sidebar'),
                    onPressed: ctrl.toggleSidebar,
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [FluentEnterpriseTheme.saudiNavy, FluentEnterpriseTheme.fluentBlue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: FluentEnterpriseTheme.saudiEnergyGreen, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'SEC & PDC 2030',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctrl.tr(
                        'منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC',
                        'Smart License Management Platform — Saudi Energy & PDC',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: isDark ? const Color(0xFF38BDF8) : FluentEnterpriseTheme.fluentBlue,
                      ),
                    ),
                    Text(
                      ctrl.tr(
                        '946 رخصة | 85 عمل تنسيق | 73 مختبر URS | إشراف: مشرف علي الجدع (0597778853)',
                        '946 Permits | 85 Weekly Works | 73 URS Lab | Supervisor: Ali Al-Jada (0597778853)',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // شريط البحث الفوري + تبديل اللغة الإنجليزية + الوضع الداكن
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isDesktop)
                  SizedBox(
                    width: 210,
                    height: 36,
                    child: TextField(
                      controller: _quickJumpCtrl,
                      onSubmitted: _handleQuickPermitJump,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: ctrl.tr('بحث برقم الرخصة / الأساس...', 'Search Permit / Base No...'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        prefixIcon: const Icon(Icons.search, size: 17),
                        suffixIcon: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(isEn ? Icons.arrow_forward : Icons.arrow_back, size: 16),
                          tooltip: ctrl.tr('فتح ملف الرخصة (13 تبويب)', 'Open 13-Tab Permit Profile'),
                          onPressed: () => _handleQuickPermitJump(_quickJumpCtrl.text),
                        ),
                      ),
                    ),
                  ),
                // عداد التحديث كل 4 ساعات
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FluentEnterpriseTheme.fluentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: FluentEnterpriseTheme.fluentBlue.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync, size: 15, color: FluentEnterpriseTheme.fluentBlue),
                        const SizedBox(width: 5),
                        Text(
                          ctrl.tr(
                            'Drive: ${ctrl.formattedFourHourCountdown}',
                            'Drive: ${ctrl.formattedFourHourCountdown}',
                          ),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF38BDF8) : FluentEnterpriseTheme.fluentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // زر بوابة الصلاحيات (وضع الزائر / المشرف علي الجدع)
                FilledButton.tonalIcon(
                  onPressed: () => showAccessGateModal(context, ctrl),
                  icon: Icon(
                    ctrl.isVisitorMode ? Icons.lock_outline : Icons.verified_user,
                    size: 16,
                    color: ctrl.isVisitorMode
                        ? FluentEnterpriseTheme.warningFg
                        : FluentEnterpriseTheme.successFg,
                  ),
                  label: Text(
                    ctrl.isVisitorMode
                        ? ctrl.tr('وضع زائر', 'Visitor Mode')
                        : ctrl.tr(ctrl.loggedInName, 'Supervisor Ali Al-Jada'),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
                // زر تبديل اللغة (عربي / English)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: FluentEnterpriseTheme.fluentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: ctrl.toggleLanguage,
                  icon: const Icon(Icons.language, size: 16),
                  label: Text(
                    isEn ? '🇸🇦 العربية' : '🌐 English',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                // زر تبديل الوضع الداكن / الفاتح
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onPressed: ctrl.toggleThemeMode,
                  icon: Icon(
                    ctrl.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    size: 16,
                    color: ctrl.isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF1E293B),
                  ),
                  label: Text(
                    ctrl.isDarkMode
                        ? ctrl.tr('الوضع الفاتح', 'Light Mode')
                        : ctrl.tr('الوضع الداكن', 'Dark Mode'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorBanner(BuildContext context, EnterpriseController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              Text(
                ctrl.tr(
                  'أنت تتصفح حالياً في (وضع الزائر). الشاشات الميدانية المتقدمة تتطلب موافقة المشرف علي الجدع (0597778853).',
                  'You are currently browsing in (Visitor Mode). Advanced modules require Supervisor Ali Al-Jada approval (0597778853).',
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => showAccessGateModal(context, ctrl),
            child: Text(
              ctrl.tr('تفعيل صلاحية المشرف المعتمدة الآن', 'Activate Approved Supervisor Access'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(EnterpriseController ctrl, {required bool isDrawer}) {
    final collapsed = !isDrawer && !ctrl.isSidebarExpanded;
    final isEn = ctrl.isEnglish;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (isDrawer)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [FluentEnterpriseTheme.saudiNavy, FluentEnterpriseTheme.fluentBlue],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctrl.tr('منظومة الرخص الذكية 2030', 'Smart Licenses Platform 2030'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ctrl.tr(
                      'الشركة السعودية للطاقة & PDC\nمشرف علي الجدع: 0597778853',
                      'Saudi Energy & PDC\nSupervisor Ali Al-Jada: 0597778853',
                    ),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            itemCount: kEnterpriseNavItems16.length,
            itemBuilder: (context, index) {
              final item = kEnterpriseNavItems16[index];
              final isSelected = ctrl.activeView == item.id;
              final isLocked = ctrl.isVisitorMode && item.restrictedInVisitorMode;
              final activeColor = isDark ? const Color(0xFF38BDF8) : FluentEnterpriseTheme.fluentBlue;

              if (collapsed) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Tooltip(
                    message: '${item.label(isEn)} (${item.badge(isEn)})',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _handleNavSelection(item),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isLocked ? Icons.lock_outline : item.icon,
                          size: 20,
                          color: isSelected ? activeColor : null,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Material(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (isDrawer) Navigator.of(context).pop();
                      _handleNavSelection(item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: isSelected
                                ? activeColor
                                : (isLocked ? Colors.grey : null),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label(isEn),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? activeColor
                                    : (isLocked ? Colors.grey : null),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLocked)
                            const Icon(Icons.lock, size: 13, color: Colors.amber)
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? FluentEnterpriseTheme.fluentBlue
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.badge(isEn),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (!collapsed)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.tr('إشراف الرخص والمختبر وأودو:', 'Permits, URS & Odoo Supervisor:'),
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
                Text(
                  ctrl.tr('مشرف علي الجدع — 0597778853', 'Supervisor Ali Al-Jada — 0597778853'),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'alielgada5@gmail.com',
                  style: TextStyle(fontSize: 10.5, color: FluentEnterpriseTheme.fluentBlue),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMobileBottomBar(EnterpriseController ctrl) {
    final primaryViews = ['dashboard', 'tx-editor', 'licenses', 'coordination', 'support'];
    final currentIdx = primaryViews.indexOf(ctrl.activeView);

    return NavigationBar(
      selectedIndex: currentIdx >= 0 ? currentIdx : 0,
      onDestinationSelected: (idx) {
        final targetId = primaryViews[idx];
        final spec = kEnterpriseNavItems16.firstWhere((e) => e.id == targetId);
        _handleNavSelection(spec);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          label: ctrl.tr('الرئيسية', 'Dashboard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.edit_note),
          label: ctrl.tr('مهندس الموقع', 'Site Eng.'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.folder_special_outlined),
          label: ctrl.tr('الرخص 946', 'Permits 946'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.engineering_outlined),
          label: ctrl.tr('التنسيق 85', 'Coord 85'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.support_agent),
          label: ctrl.tr('الدعم', 'Support'),
        ),
      ],
    );
  }
}

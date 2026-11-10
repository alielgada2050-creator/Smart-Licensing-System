// ============================================================================
// منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC (الإصدار V3.0)
// الملف الرئيسي للتطبيق والويب (Flutter Mobile, Tablet, & Web Responsive Shell)
// يضم 16 شاشة تشغيلية متكاملة + 946 رخصة + 85 عمل تنسيق + 15 وكيلاً ذكياً
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
          title: 'منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC',
          debugShowCheckedModeBanner: false,
          theme: FluentEnterpriseTheme.buildLightTheme(),
          darkTheme: FluentEnterpriseTheme.buildDarkTheme(),
          themeMode: _controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
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
// تعريف عناصر القائمة الجانبية الـ 16 المطابقة للمنصة
// ============================================================================
class NavItemSpec {
  final String id;
  final String label;
  final String badge;
  final IconData icon;
  final bool restrictedInVisitorMode;

  const NavItemSpec({
    required this.id,
    required this.label,
    required this.badge,
    required this.icon,
    this.restrictedInVisitorMode = false,
  });
}

const List<NavItemSpec> kEnterpriseNavItems16 = [
  NavItemSpec(
    id: 'tx-editor',
    label: 'تعديل المعاملات (مهندس الموقع)',
    badge: 'ميداني',
    icon: Icons.edit_note,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'dashboard',
    label: '1. لوحة الإدارة العليا',
    badge: '946',
    icon: Icons.dashboard_outlined,
  ),
  NavItemSpec(
    id: 'agents',
    label: '2. الوكلاء وتحديث 4س',
    badge: '15 وكيل',
    icon: Icons.smart_toy_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'daily',
    label: '3. التحديث اليومي 8ص',
    badge: 'الرياض',
    icon: Icons.wb_sunny_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'licenses',
    label: '4. سجل الرخص الشامل',
    badge: '946',
    icon: Icons.folder_special_outlined,
  ),
  NavItemSpec(
    id: 'comparison',
    label: '5. تحليل ومقارنة الرخص',
    badge: '<15ms',
    icon: Icons.compare_arrows,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'returned',
    label: '6. الرخص المعادة',
    badge: '480',
    icon: Icons.assignment_return_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'urs',
    label: '7. تقارير المختبر URS',
    badge: '73',
    icon: Icons.science_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'ocr',
    label: '8. ذكاء المستندات OCR',
    badge: '64',
    icon: Icons.picture_as_pdf_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'coordination',
    label: '9. جدول تنسيق الأعمال',
    badge: '85',
    icon: Icons.engineering_outlined,
  ),
  NavItemSpec(
    id: 'weekly',
    label: '10. الجدولة الأسبوعية',
    badge: 'P0-P3',
    icon: Icons.view_kanban_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'gis',
    label: '11. الخرائط الجغرافية GIS',
    badge: 'GPS',
    icon: Icons.map_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'integrations',
    label: '12. بوابة أودو وDrive',
    badge: '126',
    icon: Icons.cloud_sync_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'reports',
    label: '13. التقارير والخطابات',
    badge: '20',
    icon: Icons.analytics_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'architecture',
    label: '14. المعمار والصلاحيات',
    badge: '10 AC',
    icon: Icons.verified_user_outlined,
    restrictedInVisitorMode: true,
  ),
  NavItemSpec(
    id: 'support',
    label: '15. الدعم الفني (علي الجدع)',
    badge: '0597778853',
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
          content: Text('لم يتم العثور على رخصة مطابقة لـ "$rawInput" في قاعدة الـ 946 رخصة.'),
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

  void _speakExecutiveSummary(EnterpriseController ctrl) {
    final activeCnt = ctrl.permits.where((p) => p.isActiveOrInExecution).length;
    final retCenter = ctrl.permits.where((p) => p.category == 'معاد من قبل المركز').length;
    final retCons = ctrl.permits.where((p) => p.category == 'معاد من قبل الاستشاري').length;
    final expCnt = ctrl.permits.where((p) => p.category == 'منتهية (تحتاج معالجة وإغلاق)').length;
    final closedCnt = ctrl.permits.where((p) => p.category == 'مغلقة (تم الإغلاق)').length;
    ctrl.voiceAi.speakExecutiveBriefing(
      totalPermits: ctrl.permits.length,
      activePermits: activeCnt,
      returnedCenter: retCenter,
      returnedCons: retCons,
      expiredPermits: expCnt,
      closedPermits: closedCnt,
      weeklyCount: ctrl.coordinationItems.length,
    );
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
          // الشريط العلوي المضيء والمدمج
          _buildTopLuminousHeader(context, ctrl, isDesktop, isDark),
          // شريط تنبيه وضع الزائر إن كان مفعلاً
          if (ctrl.isVisitorMode) _buildVisitorBanner(context, ctrl),
          // المحتوى الرئيسي مع القائمة الجانبية النحيفة
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: ctrl.isSidebarExpanded ? 218 : 68,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF00183A) : Colors.white,
                      border: Border(
                        left: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                    child: _buildSidebarContent(ctrl, isDrawer: false),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: KeyedSubtree(
                      key: ValueKey<String>(ctrl.activeView),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF001430) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
                      tooltip: 'القائمة الرئيسية',
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(ctrl.isSidebarExpanded ? Icons.menu : Icons.menu_open),
                    tooltip: ctrl.isSidebarExpanded ? 'طي القائمة الجانبية' : 'توسيع القائمة الجانبية',
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
                    const Text(
                      'منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Text(
                      '946 رخصة | 85 عمل تنسيق | 73 مختبر URS | إشراف: مشرف علي الجدع (0597778853)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : const Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // شريط البحث الفوري برقم الرخصة + الأزرار التنفيذية
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isDesktop)
                  SizedBox(
                    width: 220,
                    height: 36,
                    child: TextField(
                      controller: _quickJumpCtrl,
                      onSubmitted: _handleQuickPermitJump,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'بحث فوري برقم الرخصة أو الأساس (R6949...)',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        prefixIcon: const Icon(Icons.search, size: 17),
                        suffixIcon: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back, size: 16),
                          tooltip: 'فتح ملف الرخصة (13 تبويب)',
                          onPressed: () => _handleQuickPermitJump(_quickJumpCtrl.text),
                        ),
                      ),
                    ),
                  ),
                // عداد التحديث كل 4 ساعات
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => ctrl.runFourHourAutoSync(silent: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FluentEnterpriseTheme.fluentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: FluentEnterpriseTheme.fluentBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync, size: 15, color: FluentEnterpriseTheme.fluentBlue),
                        const SizedBox(width: 5),
                        Text(
                          'تحديث 4س: ${ctrl.formattedFourHourCountdown}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: FluentEnterpriseTheme.fluentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // زر القراءة الصوتية باللهجة المصرية
                IconButton.filledTonal(
                  tooltip: 'الملخص الصوتي التنفيذي (صوت رجالي مصري)',
                  onPressed: () => _speakExecutiveSummary(ctrl),
                  icon: const Icon(Icons.record_voice_over, size: 18),
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
                    ctrl.isVisitorMode ? 'وضع زائر' : ctrl.loggedInName,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
                // تبديل الثيم الفاتح الهادئ / الداكن الفاخر
                IconButton(
                  tooltip: ctrl.isDarkMode
                      ? 'تفعيل الوضع الفاتح الهادئ (Fluent Light)'
                      : 'تفعيل الوضع الداكن الفاخر',
                  onPressed: ctrl.toggleThemeMode,
                  icon: Icon(
                    ctrl.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 20,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFFFFBEB),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Text(
                'أنت تتصفح حالياً في (وضع الزائر). الشاشات الميدانية المتقدمة تتطلب موافقة المشرف علي الجدع (0597778853).',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
              ),
            ],
          ),
          TextButton(
            onPressed: () => showAccessGateModal(context, ctrl),
            child: const Text(
              'تفعيل صلاحية المشرف المعتمدة الآن',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(EnterpriseController ctrl, {required bool isDrawer}) {
    final collapsed = !isDrawer && !ctrl.isSidebarExpanded;
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
            child: const SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'منظومة الرخص الذكية 2030',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'الشركة السعودية للطاقة & PDC\nمشرف علي الجدع: 0597778853',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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

              if (collapsed) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Tooltip(
                    message: '${item.label} (${item.badge})',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _handleNavSelection(item),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FluentEnterpriseTheme.fluentBlue.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isLocked ? Icons.lock_outline : item.icon,
                          size: 20,
                          color: isSelected ? FluentEnterpriseTheme.fluentBlue : null,
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
                      ? FluentEnterpriseTheme.fluentBlue.withValues(alpha: 0.12)
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
                                ? FluentEnterpriseTheme.fluentBlue
                                : (isLocked ? Colors.grey : null),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? FluentEnterpriseTheme.fluentBlue
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
                                item.badge,
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إشراف الرخص والمختبر وأودو:',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
                Text(
                  'مشرف علي الجدع — 0597778853',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
                Text(
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
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.edit_note), label: 'مهندس الموقع'),
        NavigationDestination(icon: Icon(Icons.folder_special_outlined), label: 'الرخص 946'),
        NavigationDestination(icon: Icon(Icons.engineering_outlined), label: 'التنسيق 85'),
        NavigationDestination(icon: Icon(Icons.support_agent), label: 'الدعم'),
      ],
    );
  }
}

// ============================================================================
// منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC (الإصدار V3.0)
// نقطة الدخول الموحدة لتطبيق الموبايل والتابلت والويب (Flutter Entry Point)
// تستدعي البنية المعيارية الكاملة في مجلد lib/ (16 شاشة + 946 رخصة + 85 عمل تنسيق)
// ============================================================================

export 'lib/data/enterprise_db_payload.dart';
export 'lib/main.dart';
export 'lib/models/permit_models.dart';
export 'lib/services/egyptian_voice_ai_service.dart';
export 'lib/services/enterprise_controller.dart';
export 'lib/theme/fluent_enterprise_theme.dart';
export 'lib/views/agents_reports_support_views.dart';
export 'lib/views/coordination_and_integrations_views.dart';
export 'lib/views/dashboard_and_editor_views.dart';
export 'lib/views/licenses_and_lab_views.dart';
export 'lib/widgets/enterprise_modals.dart';

import 'package:flutter/material.dart';
import 'lib/main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaudiEnergySmartApp());
}

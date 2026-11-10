// Domain Models & SLA Calculation Rules for Saudi Energy & PDC Smart Permits V3.0

class PermitRecord {
  String permitId;
  String requestNo;
  String transactionNo;
  String baseNo;
  String stationNo;
  String schemeNo;
  String category;
  String fieldStatus;
  String permitType;
  String digType;
  String consultant;
  String lab;
  String issueDate;
  String endDate;
  String consProcDate;
  String centerProcDate;
  String refDateFor60;
  String labUploaded;
  String photosUploaded;
  String ursResult;
  String district;
  String engineer;
  String inspector;
  String roadBanStatus;
  String returnReason;
  String notes;
  String coordinates;
  String pdfUrl;
  String sourceFile;

  PermitRecord({
    required this.permitId,
    this.requestNo = '',
    this.transactionNo = '',
    required this.baseNo,
    this.stationNo = '',
    this.schemeNo = '',
    required this.category,
    this.fieldStatus = '',
    this.permitType = 'ترخيص اعتيادي',
    this.digType = 'حفر مفتوح',
    this.consultant = 'شركة التصميم الفني للاستشارات الهندسية',
    this.lab = 'شركة يو أر أس العربية السعودية',
    this.issueDate = '2026-10-15',
    this.endDate = '2026-11-20',
    this.consProcDate = '',
    this.centerProcDate = '',
    this.refDateFor60 = '',
    this.labUploaded = 'نعم',
    this.photosUploaded = 'نعم',
    this.ursResult = 'ناجح',
    this.district = 'الرياض',
    this.engineer = 'مشرف علي الجدع',
    this.inspector = 'SHAHIN',
    this.roadBanStatus = 'غير محظور',
    this.returnReason = '',
    this.notes = '',
    this.coordinates = '',
    this.pdfUrl = '',
    this.sourceFile = 'قاعدة البيانات الموحدة V3.0',
  });

  factory PermitRecord.fromMap(Map<String, dynamic> m) {
    String s(String k, [String def = '']) => (m[k] ?? def).toString();
    return PermitRecord(
      permitId: s('permit_id'),
      requestNo: s('request_no'),
      transactionNo: s('transaction_no'),
      baseNo: s('base_no', 'R6949'),
      stationNo: s('station_no'),
      schemeNo: s('scheme_no'),
      category: s('category', 'سارية / مفعلة (رخص PDF المعتمدة)'),
      fieldStatus: s('field_status'),
      permitType: s('permit_type', 'ترخيص اعتيادي'),
      digType: s('dig_type', 'حفر مفتوح'),
      consultant: s('consultant', 'شركة التصميم الفني للاستشارات الهندسية'),
      lab: s('lab', 'شركة يو أر أس العربية السعودية'),
      issueDate: s('issue_date', '2026-10-15'),
      endDate: s('end_date', '2026-11-15'),
      consProcDate: s('cons_proc_date'),
      centerProcDate: s('center_proc_date'),
      refDateFor60: s('ref_date_for_60'),
      labUploaded: s('lab_uploaded', 'نعم'),
      photosUploaded: s('photos_uploaded', 'نعم'),
      ursResult: s('urs_result', 'ناجح'),
      district: s('district', 'الرياض'),
      engineer: s('engineer', 'مشرف علي الجدع'),
      inspector: s('inspector', 'SHAHIN'),
      roadBanStatus: s('road_ban_status', 'غير محظور'),
      returnReason: s('return_reason'),
      notes: s('notes'),
      coordinates: s('coordinates'),
      pdfUrl: s('pdf_url'),
      sourceFile: s('source_file', 'قاعدة البيانات الموحدة V3.0'),
    );
  }

  Map<String, dynamic> toMap() => {
        'permit_id': permitId,
        'request_no': requestNo,
        'transaction_no': transactionNo,
        'base_no': baseNo,
        'station_no': stationNo,
        'scheme_no': schemeNo,
        'category': category,
        'field_status': fieldStatus,
        'permit_type': permitType,
        'dig_type': digType,
        'consultant': consultant,
        'lab': lab,
        'issue_date': issueDate,
        'end_date': endDate,
        'cons_proc_date': consProcDate,
        'center_proc_date': centerProcDate,
        'ref_date_for_60': refDateFor60,
        'lab_uploaded': labUploaded,
        'photos_uploaded': photosUploaded,
        'urs_result': ursResult,
        'district': district,
        'engineer': engineer,
        'inspector': inspector,
        'road_ban_status': roadBanStatus,
        'return_reason': returnReason,
        'notes': notes,
        'coordinates': coordinates,
        'pdf_url': pdfUrl,
        'source_file': sourceFile,
      };

  bool get isRoadBanned =>
      roadBanStatus.contains('محظور') && !roadBanStatus.contains('غير محظور');

  bool get isActiveOrInExecution =>
      category.contains('سارية') || category.contains('فعالة');

  PermitSlaInfo calculateSla([DateTime? referenceToday]) {
    final today = referenceToday ?? DateTime(2026, 11, 8);
    String rawEnd = endDate.isNotEmpty
        ? endDate
        : (refDateFor60.isNotEmpty
            ? refDateFor60
            : (centerProcDate.isNotEmpty ? centerProcDate : '2026-10-15'));
    if (rawEnd.length > 10) rawEnd = rawEnd.substring(0, 10);

    DateTime endDt = DateTime.tryParse(rawEnd) ?? DateTime(2026, 10, 15);
    int validDaysLeft = endDt.difference(today).inDays;

    // Rule Section 8: تاريخ انتهاء الرخصة + 60 يوماً = آخر موعد لرفع تقرير المختبر
    DateTime labDeadlineDt = endDt.add(const Duration(days: 60));
    String labDeadlineStr =
        '${labDeadlineDt.year.toString().padLeft(4, '0')}-${labDeadlineDt.month.toString().padLeft(2, '0')}-${labDeadlineDt.day.toString().padLeft(2, '0')}';
    int labDaysLeft = labDeadlineDt.difference(today).inDays;

    String slaTier = 'safe';
    String slaLabel = '$labDaysLeft يوم متبقي';

    if (category == 'مغلقة (تم الإغلاق)') {
      slaTier = 'done';
      slaLabel = 'مغلقة نهائياً';
    } else if (labDaysLeft < 0) {
      slaTier = 'overdue';
      slaLabel = 'تجاوز 60 يوم (${labDaysLeft.abs()}-)';
    } else if (labDaysLeft <= 15) {
      slaTier = 'crit';
      slaLabel = 'حرج ≤15 يوم ($labDaysLeft)';
    } else if (labDaysLeft <= 30) {
      slaTier = 'warn';
      slaLabel = 'تنبيه ≤30 يوم ($labDaysLeft)';
    }

    return PermitSlaInfo(
      endStr: rawEnd,
      validDaysLeft: validDaysLeft,
      labDeadlineStr: labDeadlineStr,
      labDaysLeft: labDaysLeft,
      slaTier: slaTier,
      slaLabel: slaLabel,
    );
  }
}

class PermitSlaInfo {
  final String endStr;
  final int validDaysLeft;
  final String labDeadlineStr;
  final int labDaysLeft;
  final String slaTier; // done, safe, warn, crit, overdue
  final String slaLabel;

  const PermitSlaInfo({
    required this.endStr,
    required this.validDaysLeft,
    required this.labDeadlineStr,
    required this.labDaysLeft,
    required this.slaTier,
    required this.slaLabel,
  });
}

class CoordinationItem {
  int seq;
  String coordId;
  String office;
  String stepType;
  String baseNo;
  String baseClean;
  String transactionNo;
  String workOrderNo;
  String district;
  String requestStatusInTable;
  String notes;
  String digLengthLabel;
  double lengthM;
  String expectedStart;
  String fieldMonitor;
  String assignedSupervisor;
  String matchedPermitId;
  String matchedPermitCategory;
  String matchedPermitEndDate;
  String comparisonVerdict;
  String approvalDecision;
  String priorityTier;
  bool isReady;
  String readinessGroup;
  bool isShutdown;
  String schedulePdfUrl;
  String attachedImageUrl;

  CoordinationItem({
    required this.seq,
    required this.coordId,
    required this.office,
    this.stepType = 'موقف العمل اليومي',
    required this.baseNo,
    this.baseClean = '',
    required this.transactionNo,
    this.workOrderNo = '',
    required this.district,
    this.requestStatusInTable = 'تم اصدار الرخصة',
    this.notes = '',
    this.digLengthLabel = '100m',
    this.lengthM = 100.0,
    this.expectedStart = 'الإثنين 09-11-2026',
    this.fieldMonitor = 'SHAHIN',
    this.assignedSupervisor = 'مشرف علي الجدع (مشرف الرخص والمختبر وإغلاق المعاملات)',
    this.matchedPermitId = 'بدون رخصة مصدرة',
    this.matchedPermitCategory = '',
    this.matchedPermitEndDate = '2026-11-24',
    this.comparisonVerdict = '',
    this.approvalDecision = 'معتمدة للتنفيذ الفوري ✅',
    this.priorityTier = 'P1 - جاهزة للتنفيذ الفوري (رخصة سارية)',
    this.isReady = true,
    this.readinessGroup = '1. جاهزة للتنفيذ',
    this.isShutdown = false,
    this.schedulePdfUrl =
        'https://drive.google.com/drive/folders/1501h5AVNJHdga7jzoGXn1ryxk6zdnKUz',
    this.attachedImageUrl = '',
  });

  factory CoordinationItem.fromMap(Map<String, dynamic> m) {
    String s(String k, [String def = '']) => (m[k] ?? def).toString();
    return CoordinationItem(
      seq: int.tryParse(s('seq', '1')) ?? 1,
      coordId: s('coord_id', 'WK-001'),
      office: s('office', 'مكتب خريص'),
      stepType: s('step_type', 'موقف العمل اليومي'),
      baseNo: s('base_no', 'R6949'),
      baseClean: s('base_clean'),
      transactionNo: s('transaction_no'),
      workOrderNo: s('work_order_no'),
      district: s('district', 'الرياض'),
      requestStatusInTable: s('request_status_in_table'),
      notes: s('notes'),
      digLengthLabel: s('dig_length_label', '100m'),
      lengthM: double.tryParse(s('length_m', '100')) ?? 100.0,
      expectedStart: s('expected_start', 'الإثنين 09-11-2026'),
      fieldMonitor: s('field_monitor', 'SHAHIN'),
      assignedSupervisor: s('assigned_supervisor', 'مشرف علي الجدع'),
      matchedPermitId: s('matched_permit_id', 'بدون رخصة مصدرة'),
      matchedPermitCategory: s('matched_permit_category'),
      matchedPermitEndDate: s('matched_permit_end_date', '2026-11-20'),
      comparisonVerdict: s('comparison_verdict'),
      approvalDecision: s('approval_decision', 'معتمدة للتنفيذ الفوري ✅'),
      priorityTier: s('priority_tier', 'P1 - جاهزة للتنفيذ الفوري'),
      isReady: m['is_ready'] == true || s('approval_decision').contains('معتمدة'),
      readinessGroup: s('readiness_group', '1. جاهزة للتنفيذ'),
      isShutdown: m['is_shutdown'] == true,
      schedulePdfUrl: s(
        'schedule_pdf_url',
        'https://drive.google.com/drive/folders/1501h5AVNJHdga7jzoGXn1ryxk6zdnKUz',
      ),
      attachedImageUrl: s('attached_image_url'),
    );
  }

  Map<String, dynamic> toMap() => {
        'seq': seq,
        'coord_id': coordId,
        'office': office,
        'step_type': stepType,
        'base_no': baseNo,
        'base_clean': baseClean,
        'transaction_no': transactionNo,
        'work_order_no': workOrderNo,
        'district': district,
        'request_status_in_table': requestStatusInTable,
        'notes': notes,
        'dig_length_label': digLengthLabel,
        'length_m': lengthM,
        'expected_start': expectedStart,
        'field_monitor': fieldMonitor,
        'assigned_supervisor': assignedSupervisor,
        'matched_permit_id': matchedPermitId,
        'matched_permit_category': matchedPermitCategory,
        'matched_permit_end_date': matchedPermitEndDate,
        'comparison_verdict': comparisonVerdict,
        'approval_decision': approvalDecision,
        'priority_tier': priorityTier,
        'is_ready': isReady,
        'readiness_group': readinessGroup,
        'is_shutdown': isShutdown,
        'schedule_pdf_url': schedulePdfUrl,
        'attached_image_url': attachedImageUrl,
      };

  bool get hasValidPermit =>
      matchedPermitId.isNotEmpty &&
      matchedPermitId != 'بدون رخصة مصدرة' &&
      !matchedPermitId.contains('ملغاة');
}

class UrsInspectionRecord {
  final int seq;
  final String permitId;
  final String permitDate;
  final String testDate;
  final String testType;
  final int passedPoints;
  final int failedPoints;
  final int totalPoints;
  final String passRate;
  final String labResult;
  final String statusDetail;
  final String remediationAction;
  final String notes;
  final String labName;
  final String sourceUrl;

  const UrsInspectionRecord({
    required this.seq,
    required this.permitId,
    required this.permitDate,
    required this.testDate,
    required this.testType,
    required this.passedPoints,
    required this.failedPoints,
    required this.totalPoints,
    required this.passRate,
    required this.labResult,
    required this.statusDetail,
    required this.remediationAction,
    required this.notes,
    required this.labName,
    required this.sourceUrl,
  });

  factory UrsInspectionRecord.fromMap(Map<String, dynamic> m) {
    String s(String k, [String def = '']) => (m[k] ?? def).toString();
    return UrsInspectionRecord(
      seq: int.tryParse(s('seq', '1')) ?? 1,
      permitId: s('permit_id'),
      permitDate: s('permit_date'),
      testDate: s('test_date'),
      testType: s('test_type', 'دمك وسفلتة'),
      passedPoints: int.tryParse(s('passed_points', '0')) ?? 0,
      failedPoints: int.tryParse(s('failed_points', '0')) ?? 0,
      totalPoints: int.tryParse(s('total_points', '0')) ?? 0,
      passRate: s('pass_rate', '100%'),
      labResult: s('lab_result', 'ناجح'),
      statusDetail: s('status_detail'),
      remediationAction: s('remediation_action'),
      notes: s('notes'),
      labName: s('lab_name', 'شركة يو أر أس العربية السعودية'),
      sourceUrl: s('source_url'),
    );
  }
}

class PdfOcrLicenseRecord {
  final String permitId;
  final String baseNo;
  final String stationNo;
  final String schemeNo;
  final String owner;
  final String contractor;
  final String consultant;
  final String lab;
  final String permitType;
  final String status;
  final String category;
  final String startDate;
  final String endDate;
  final int durationDays;
  final String digMethod;
  final double lengthM;
  final double depthM;
  final double widthM;
  final String district;
  final String roadBanStatus;
  final String fileName;
  final String driveUrl;
  final double ocrConfidence;

  const PdfOcrLicenseRecord({
    required this.permitId,
    required this.baseNo,
    required this.stationNo,
    required this.schemeNo,
    required this.owner,
    required this.contractor,
    required this.consultant,
    required this.lab,
    required this.permitType,
    required this.status,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.digMethod,
    required this.lengthM,
    required this.depthM,
    required this.widthM,
    required this.district,
    required this.roadBanStatus,
    required this.fileName,
    required this.driveUrl,
    required this.ocrConfidence,
  });

  factory PdfOcrLicenseRecord.fromMap(Map<String, dynamic> m) {
    String s(String k, [String def = '']) => (m[k] ?? def).toString();
    return PdfOcrLicenseRecord(
      permitId: s('permit_id'),
      baseNo: s('base_no'),
      stationNo: s('station_no'),
      schemeNo: s('scheme_no'),
      owner: s('owner', 'الشركة السعودية للكهرباء SEC'),
      contractor: s('contractor', 'شركة الأساس العريض للمقاولات'),
      consultant: s('consultant'),
      lab: s('lab'),
      permitType: s('permit_type'),
      status: s('status'),
      category: s('category'),
      startDate: s('start_date'),
      endDate: s('end_date'),
      durationDays: int.tryParse(s('duration_days', '20')) ?? 20,
      digMethod: s('dig_method', 'حفر مفتوح'),
      lengthM: double.tryParse(s('length_m', '100')) ?? 100.0,
      depthM: double.tryParse(s('depth_m', '1.2')) ?? 1.2,
      widthM: double.tryParse(s('width_m', '0.6')) ?? 0.6,
      district: s('district'),
      roadBanStatus: s('road_ban_status', 'غير محظور'),
      fileName: s('file_name'),
      driveUrl: s('drive_url'),
      ocrConfidence: double.tryParse(s('ocr_confidence', '99.4')) ?? 99.4,
    );
  }
}

class OdooTaskRecord {
  final int seq;
  final String permitId;
  final String schemeNo;
  final String baseNo;
  final String projectCode;
  final String stage;
  final String district;
  final String workOrderType;
  final String labBasketStatus;
  final String sourceFile;
  final String supervisor;

  const OdooTaskRecord({
    required this.seq,
    required this.permitId,
    required this.schemeNo,
    required this.baseNo,
    required this.projectCode,
    required this.stage,
    required this.district,
    required this.workOrderType,
    required this.labBasketStatus,
    required this.sourceFile,
    required this.supervisor,
  });

  factory OdooTaskRecord.fromMap(Map<String, dynamic> m) {
    String s(String k, [String def = '']) => (m[k] ?? def).toString();
    return OdooTaskRecord(
      seq: int.tryParse(s('seq', '1')) ?? 1,
      permitId: s('permit_id', 'بدون رخصة'),
      schemeNo: s('scheme_no'),
      baseNo: s('base_no'),
      projectCode: s('project_code'),
      stage: s('stage'),
      district: s('district'),
      workOrderType: s('work_order_type'),
      labBasketStatus: s('lab_basket_status'),
      sourceFile: s('source_file'),
      supervisor: s('supervisor', 'مشرف علي الجدع'),
    );
  }
}

class SecQaQcRecord {
  final String testId;
  final String date;
  final String projectSite;
  final String element;
  final String testType;
  final String spec;
  final String actual;
  final String result;
  final String clearanceStatus;
  final String smartAlert;
  final String engineer;

  const SecQaQcRecord({
    required this.testId,
    required this.date,
    required this.projectSite,
    required this.element,
    required this.testType,
    required this.spec,
    required this.actual,
    required this.result,
    required this.clearanceStatus,
    required this.smartAlert,
    required this.engineer,
  });

  factory SecQaQcRecord.fromMap(Map<String, dynamic> m) {
    String s(String k, [String def = '']) => (m[k] ?? def).toString();
    return SecQaQcRecord(
      testId: s('test_id'),
      date: s('date'),
      projectSite: s('project_site'),
      element: s('element'),
      testType: s('test_type'),
      spec: s('spec'),
      actual: s('actual'),
      result: s('result'),
      clearanceStatus: s('clearance_status'),
      smartAlert: s('smart_alert'),
      engineer: s('engineer'),
    );
  }
}

class SiteEngineerActionLog {
  final String reqId;
  final String reqTime;
  final String reqType;
  final String office;
  final String engineerName;
  final String supervisor;
  final String oldBaseNo;
  final String oldTxNo;
  final String newBaseNo;
  final String newTxNo;
  final String permitId;
  final String district;
  final String reason;
  final String status;

  const SiteEngineerActionLog({
    required this.reqId,
    required this.reqTime,
    required this.reqType,
    required this.office,
    required this.engineerName,
    required this.supervisor,
    required this.oldBaseNo,
    required this.oldTxNo,
    required this.newBaseNo,
    required this.newTxNo,
    required this.permitId,
    required this.district,
    required this.reason,
    this.status = 'معتمد ومحفوظ مع تحديث الـ 4 ساعات ✅',
  });
}

class CategorySpec {
  final String key;
  final String shortTitle;
  final int colorHex;

  const CategorySpec({
    required this.key,
    required this.shortTitle,
    required this.colorHex,
  });
}

const List<CategorySpec> kCategoriesSpec = [
  CategorySpec(
    key: 'معاد من قبل المركز',
    shortTitle: 'معاد المركز (RIPC)',
    colorHex: 0xFFEF4444,
  ),
  CategorySpec(
    key: 'منتهية (تحتاج معالجة وإغلاق)',
    shortTitle: 'منتهية تحت المعالجة',
    colorHex: 0xFF991B1B,
  ),
  CategorySpec(
    key: 'معاد من قبل الاستشاري',
    shortTitle: 'معاد الاستشاري',
    colorHex: 0xFFF97316,
  ),
  CategorySpec(
    key: 'سارية / مفعلة (رخص PDF المعتمدة)',
    shortTitle: 'سارية / مفعلة (PDF)',
    colorHex: 0xFF10B981,
  ),
  CategorySpec(
    key: 'فعالة / في التنفيذ',
    shortTitle: 'تحت التنفيذ الميداني',
    colorHex: 0xFF3B82F6,
  ),
  CategorySpec(
    key: 'مغلقة (تم الإغلاق)',
    shortTitle: 'مغلقة نهائياً',
    colorHex: 0xFF059669,
  ),
  CategorySpec(
    key: 'تم الرفع (بانتظار الإغلاق)',
    shortTitle: 'تم الرفع للإغلاق',
    colorHex: 0xFF6366F1,
  ),
  CategorySpec(
    key: 'تم الرفع للمختبر (URS)',
    shortTitle: 'تحت فحص مختبر URS',
    colorHex: 0xFFEAB308,
  ),
  CategorySpec(
    key: 'رخص المحافظات (وادي الدواسر / السليل)',
    shortTitle: 'محافظات (وادي الدواسر)',
    colorHex: 0xFF0D9488,
  ),
  CategorySpec(
    key: 'ملغاة / تحتاج إلغاء',
    shortTitle: 'ملغاة / تحت الإلغاء',
    colorHex: 0xFF64748B,
  ),
  CategorySpec(
    key: 'تقرير مختبر راسب (تحتاج إعادة فحص)',
    shortTitle: 'مختبر راسب (إعادة فحص)',
    colorHex: 0xFFDC2626,
  ),
];

const List<String> kSupervisorsList = [
  'مشرف علي الجدع (مشرف الرخص والمختبر وإغلاق المعاملات)',
  'م. فهد العتيبي (مشرف معاملات خريص)',
  'م. خالد القحطاني (مشرف معاملات الشمال)',
  'م. سلطان الدوسري (مشرف معاملات الشرق)',
  'م. محمد جعفري (مشرف التطفئة والإغلاق اليومي)',
  'م. عبدالله الشهري (مشرف تصاريح MV)',
  'م. محمد جمال (مشرف فك الحظر والمواقع الخاصة)',
];

class AiAgentSpec {
  final int id;
  final String nameEn;
  final String nameAr;
  final String description;
  final String sampleQuery;

  const AiAgentSpec({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.description,
    required this.sampleQuery,
  });
}

const List<AiAgentSpec> kAiAgents15Spec = [
  AiAgentSpec(
    id: 15,
    nameEn: 'Agent 15 – Drive Sheets & Permit Images 4h Auto-Sync Agent',
    nameAr: 'وكيل تحديث شيتات الدرايف وصور الرخص وتيسير الموقع (كل 4 ساعات)',
    description:
        'يفحص ويحدث شيتات الدرايف وصور الرخص تلقائياً كل 4 ساعات ويرفقها بالمعاملات لتيسير أعمال الموقع والتنسيق التسلسلي',
    sampleQuery: 'حالة تحديث شيتات الدرايف وصور الرخص المرفقة للموقع كل 4 ساعات',
  ),
  AiAgentSpec(
    id: 14,
    nameEn: 'Agent 14 – Executive Manager Agent',
    nameAr: 'الوكيل التنفيذي الرئيسي (بإشراف: مشرف علي الجدع)',
    description: 'يستقبل الأوامر بالعربية الطبيعية ويوزع المهام على الوكلاء الـ 15',
    sampleQuery: 'ملخص شامل للـ 946 رخصة والأسئلة الـ 18',
  ),
  AiAgentSpec(
    id: 1,
    nameEn: 'Agent 1 – License Intelligence Agent',
    nameAr: 'وكيل ذكاء الرخص ومنع التكرار',
    description: 'قراءة الرخص، تصنيفها، وحذف الـ 569 سجل مكرر',
    sampleQuery: 'تقرير حذف المكرر ومقارنة الملفات بقاعدة البيانات',
  ),
  AiAgentSpec(
    id: 2,
    nameEn: 'Agent 2 – Regulatory Compliance Agent',
    nameAr: 'وكيل الامتثال والشوارع المحظورة',
    description: 'التحقق من حالة الحظر وخطابات التعهد وشركات السفلتة المؤهلة',
    sampleQuery: 'ما هي الرخص الواقعة في شوارع محظورة ومتطلباتها؟',
  ),
  AiAgentSpec(
    id: 3,
    nameEn: 'Agent 3 – Workflow Controller Agent',
    nameAr: 'وكيل ضبط دورة الحياة (17 مرحلة)',
    description: 'مراقبة انتقال الحالات ومنع تجاوز المراحل الإلزامية',
    sampleQuery: 'حالة انتقال الرخص عبر المراحل الـ 17',
  ),
  AiAgentSpec(
    id: 4,
    nameEn: 'Agent 4 – URS Laboratory Agent',
    nameAr: 'وكيل مختبر URS ومهلة 60 يوماً',
    description: 'متابعة الفحوصات، النقاط الراسبة (62)، ومهلة 60 يوماً',
    sampleQuery: 'ما الرخص التي لديها تقرير مختبر راسب؟',
  ),
  AiAgentSpec(
    id: 5,
    nameEn: 'Agent 5 – Consultant Follow-up Agent',
    nameAr: 'وكيل متابعة الاستشاريين',
    description: 'رصد الـ 186 رخصة المعادة من الاستشاري وتصعيد التأخير',
    sampleQuery: 'اعرض الرخص المعادة من الاستشاري',
  ),
  AiAgentSpec(
    id: 6,
    nameEn: 'Agent 6 – Infrastructure Center Agent',
    nameAr: 'وكيل مركز مشاريع البنية التحتية RIPC',
    description: 'متابعة الـ 295 رخصة المعادة من المركز وإعادة التقديم',
    sampleQuery: 'اعرض الرخص المعادة من المركز',
  ),
  AiAgentSpec(
    id: 7,
    nameEn: 'Agent 7 – Owner Approval Agent',
    nameAr: 'وكيل اعتماد الجهة المالكة SEC',
    description: 'متابعة موافقات الشركة السعودية للكهرباء والإغلاق النهائي',
    sampleQuery: 'اعرض الرخص المغلقة والمرفوعة للجهة المالكة',
  ),
  AiAgentSpec(
    id: 8,
    nameEn: 'Agent 8 – Work Coordination Agent',
    nameAr: 'وكيل تنسيق الأعمال (D9 / T1 / طوارئ)',
    description: 'ربط الأعمال بالرخص وفحص جاهزية التنفيذ الميداني',
    sampleQuery: 'تحليل أعمال D9 وT1 والطوارئ',
  ),
  AiAgentSpec(
    id: 9,
    nameEn: 'Agent 9 – Weekly Planning Agent',
    nameAr: 'وكيل التخطيط الأسبوعي (دورة الجمعة)',
    description: 'إعداد خطة الأسبوع وتصنيف الجاهزية في 6 مجموعات',
    sampleQuery: 'اعرض أعمال الأسبوع القادم غير الجاهزة',
  ),
  AiAgentSpec(
    id: 10,
    nameEn: 'Agent 10 – Document Intelligence Agent',
    nameAr: 'وكيل ذكاء المستندات وOCR (R6949)',
    description: 'استخراج بيانات PDF وQR ومطابقة R6949-2396761.pdf',
    sampleQuery: 'اعرض جميع الرخص المرتبطة بالأساس R6949',
  ),
  AiAgentSpec(
    id: 11,
    nameEn: 'Agent 11 – Reporting & Analytics Agent',
    nameAr: 'وكيل التقارير والتحليلات الـ 20',
    description: 'إصدار التقارير اليومية والأسبوعية والشهرية ومؤشرات الأداء',
    sampleQuery: 'قارن بين الرخص حسب الاستشاري',
  ),
  AiAgentSpec(
    id: 12,
    nameEn: 'Agent 12 – Notification & Escalation Agent',
    nameAr: 'وكيل التنبيهات وتكامل Odoo/WhatsApp',
    description: 'إرسال تنبيهات 30/15/7/3/1 يوم وإنشاء مهام Odoo',
    sampleQuery: 'ما الرخص التي تبقى لها أقل من 15 يوماً على مهلة المختبر؟',
  ),
  AiAgentSpec(
    id: 13,
    nameEn: 'Agent 13 – Security & Audit Agent',
    nameAr: 'وكيل الأمان والصلاحيات (19 دوراً)',
    description: 'مراقبة RBAC+ABAC وتوثيق سجل التدقيق ومنع التجاوز',
    sampleQuery: 'تقرير سجل التدقيق والصلاحيات',
  ),
];

const List<String> kStandardReports20 = [
  '1. تقرير جميع الرخص (946)',
  '2. تقرير الرخص السارية (96)',
  '3. تقرير الرخص المنتهية (256)',
  '4. تقرير الرخص القريبة من الانتهاء',
  '5. تقرير المعادة من الاستشاري (186)',
  '6. تقرير المعادة من المركز (295)',
  '7. تقرير الرخص المعتمدة والمرفوعة (29)',
  '8. تقرير معالجة الجهة المالكة SEC',
  '9. تقرير مهلة المختبر 60 يوماً',
  '10. تقرير المختبر الناجح والراسب (URS)',
  '11. تقرير الإغلاقات النهائية (38)',
  '12. تقرير الأعمال حسب رقم الأساس',
  '13. تقرير أعمال D9 وT1 والطوارئ',
  '14. تقرير جاهزية الأسبوع القادم',
  '15. تقرير المهام المتأخرة',
  '16. تقرير أداء المهندسين والمراقبين',
  '17. تقرير أداء المكاتب الاستشارية',
  '18. تقرير أسباب إعادة الرخص',
  '19. تقرير المستندات والشوارع المحظورة',
  '20. تقرير التحديث اليومي المؤرخ',
];

-- ==============================================================================
-- POSTGRESQL & SUPABASE COMPLETE DATABASE SCHEMA FOR SMART PERMITS SYSTEM
-- High Performance, Zero-Maintenance, Supported on GitHub CI/CD & Cloud Deployments
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Organizational Hierarchy & Roles (الهيكل التنظيمي والصلاحيات)
CREATE TYPE user_role_enum AS ENUM (
    'general_supervisor',       -- المشرف العام: مشرف علي الجدع (كامل الصلاحيات والموافقات)
    'site_engineer',           -- مهندس الموقع (تعديل، إضافة، تبديل، وإلغاء المعاملات)
    'field_monitor',           -- مراقب الميدان (استعراض الرخص، رفع الصور الميدانية)
    'lab_engineer',            -- مهندس المختبر (إغلاق فحوصات URS، وربط الدمك والسفلتة)
    'sector_supervisor',       -- مشرف القطاع (خريص، الشمال، الشرق، التطفئة، MV، فك الحظر)
    'visitor'                  -- الزائر (استعراض وتنزيل الرخص العاملة وتحت التنفيذ فقط)
);

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50),
    role user_role_enum DEFAULT 'visitor',
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by VARCHAR(255) DEFAULT 'مشرف علي الجدع',
    approval_date TIMESTAMP WITH TIME ZONE,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Master Permits Registry (السجل الشامل الموحد للرخص - 946 رخصة)
CREATE TABLE IF NOT EXISTS permits (
    id SERIAL PRIMARY KEY,
    permit_id VARCHAR(50) UNIQUE NOT NULL,
    base_no VARCHAR(50) NOT NULL,
    scheme_no VARCHAR(50),
    transaction_no VARCHAR(50),
    category VARCHAR(100) NOT NULL,
    field_status VARCHAR(100),
    permit_type VARCHAR(100) DEFAULT 'ترخيص حفر معتمد',
    dig_type VARCHAR(100) DEFAULT 'حفر مفتوح',
    consultant VARCHAR(255) DEFAULT 'شركة التصميم الفني للاستشارات الهندسية',
    lab VARCHAR(255) DEFAULT 'شركة يو أر أس العربية السعودية',
    district VARCHAR(100),
    governorate VARCHAR(100) DEFAULT 'الرياض',
    issue_date DATE,
    end_date DATE,
    assigned_supervisor VARCHAR(255),
    field_monitor VARCHAR(255),
    urs_result VARCHAR(50) DEFAULT 'ناجح',
    road_ban_status VARCHAR(100) DEFAULT 'غير محظور',
    pdf_drive_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Weekly Work Coordination (جدول تنسيق الأعمال الأسبوعي - 85 معاملة)
CREATE TABLE IF NOT EXISTS weekly_coordination (
    id SERIAL PRIMARY KEY,
    coord_id VARCHAR(50) UNIQUE NOT NULL,
    office VARCHAR(100) NOT NULL,
    step_type VARCHAR(100),
    base_no VARCHAR(50) NOT NULL,
    transaction_no VARCHAR(50) NOT NULL,
    district VARCHAR(100),
    dig_length_label VARCHAR(50),
    length_m NUMERIC(10, 2),
    expected_start VARCHAR(100),
    matched_permit_id VARCHAR(50),
    matched_permit_end_date DATE,
    assigned_supervisor VARCHAR(255),
    field_monitor VARCHAR(255),
    approval_decision VARCHAR(255),
    priority_tier VARCHAR(100),
    is_ready BOOLEAN DEFAULT TRUE,
    readiness_group VARCHAR(150),
    is_shutdown BOOLEAN DEFAULT FALSE,
    schedule_pdf_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. URS Lab Basket & Tests (فحوصات وسلة تقارير مختبر URS - 60 يوماً)
CREATE TABLE IF NOT EXISTS urs_inspections (
    id SERIAL PRIMARY KEY,
    seq INT,
    permit_id VARCHAR(50) NOT NULL,
    permit_date DATE,
    test_date DATE,
    test_type VARCHAR(100),
    passed_points INT DEFAULT 0,
    failed_points INT DEFAULT 0,
    total_points INT DEFAULT 0,
    pass_rate VARCHAR(20),
    lab_result VARCHAR(50),
    remediation_action TEXT,
    assigned_supervisor VARCHAR(255) DEFAULT 'مشرف علي الجدع',
    source_file VARCHAR(255) DEFAULT 'سلة تقرير المحتبر.xlsx',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Site Engineer Rapid Requests (تعديل / تبديل / إلغاء رخص مهندس الموقع)
CREATE TABLE IF NOT EXISTS site_engineer_requests (
    id SERIAL PRIMARY KEY,
    req_id VARCHAR(50) UNIQUE NOT NULL,
    req_type VARCHAR(100) NOT NULL,
    office VARCHAR(100),
    engineer_name VARCHAR(255),
    supervisor VARCHAR(255),
    old_base_no VARCHAR(100),
    old_tx_no VARCHAR(100),
    new_base_no VARCHAR(100),
    new_tx_no VARCHAR(100),
    permit_id VARCHAR(50),
    district VARCHAR(100),
    reason TEXT,
    status VARCHAR(100) DEFAULT 'معتمد ومحفوظ مع تحديث الـ 4 ساعات ✅',
    drive_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Technical Support Tickets & Approval Requests (الدعم الفني وموافقات الدخول)
CREATE TABLE IF NOT EXISTS support_tickets (
    id SERIAL PRIMARY KEY,
    ticket_no VARCHAR(50) UNIQUE NOT NULL,
    sender_name VARCHAR(255) NOT NULL,
    sender_email VARCHAR(255) NOT NULL,
    sender_phone VARCHAR(50),
    request_type VARCHAR(100),
    message TEXT,
    channel VARCHAR(50), -- WHATSAPP, TELEGRAM, EMAIL
    assigned_to VARCHAR(255) DEFAULT 'مشرف علي الجدع (0597778853)',
    status VARCHAR(50) DEFAULT 'قيد المتابعة والاعتماد',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Audit Trail & 4-Hour Sync Cycles (سجل التدقيق ودورات التحديث كل 4 ساعات)
CREATE TABLE IF NOT EXISTS sync_audit_log (
    id SERIAL PRIMARY KEY,
    cycle_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_source VARCHAR(255) DEFAULT 'Google Drive & Studio API Agents',
    records_checked INT DEFAULT 946,
    status_summary TEXT,
    triggered_by VARCHAR(255) DEFAULT 'Agent 15 & System Cron'
);

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE permits ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_coordination ENABLE ROW LEVEL SECURITY;

-- Policy 1: Visitors can read active & in-execution permits without login
CREATE POLICY visitor_read_active_permits ON permits
    FOR SELECT USING (
        category IN ('سارية / مفعلة (رخص PDF المعتمدة)', 'فعالة / في التنفيذ')
        OR auth.role() = 'authenticated'
    );

-- Policy 2: Authenticated & Approved users have full access
CREATE POLICY full_access_for_approved_users ON permits
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid() AND (users.is_approved = TRUE OR users.email = 'alielgada5@gmail.com')
        )
    );

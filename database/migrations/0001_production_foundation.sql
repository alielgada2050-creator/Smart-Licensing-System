CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE sectors (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE consultants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE permit_statuses (
    code text PRIMARY KEY,
    label_ar text NOT NULL UNIQUE,
    is_terminal boolean NOT NULL DEFAULT false
);

INSERT INTO permit_statuses (code, label_ar, is_terminal) VALUES
    ('draft', 'مسودة', false),
    ('pending', 'قيد المراجعة', false),
    ('active', 'سارية', false),
    ('expired', 'منتهية', false),
    ('returned', 'معادة', false),
    ('under_correction', 'قيد التصحيح', false),
    ('renewal_pending', 'بانتظار التجديد', false),
    ('ready_for_closure', 'جاهزة للإغلاق', false),
    ('closed', 'مغلقة', true),
    ('cancelled', 'ملغاة', true);

CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    external_auth_id text UNIQUE,
    email text NOT NULL UNIQUE,
    full_name text NOT NULL,
    role text NOT NULL CHECK (role IN (
        'super_admin', 'sector_manager', 'site_engineer', 'contractor', 'viewer'
    )),
    sector_id uuid REFERENCES sectors(id),
    contractor_ref text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (role <> 'sector_manager' OR sector_id IS NOT NULL),
    CHECK (role <> 'contractor' OR contractor_ref IS NOT NULL)
);

CREATE TABLE permits (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    permit_id text NOT NULL UNIQUE,
    base_no text NOT NULL,
    status text NOT NULL DEFAULT 'draft' REFERENCES permit_statuses(code),
    sector_id uuid REFERENCES sectors(id),
    consultant_id uuid REFERENCES consultants(id),
    contractor_ref text,
    issue_date date,
    end_date date,
    urs_report_approved_at timestamptz,
    compaction_result_recorded_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (end_date IS NULL OR issue_date IS NULL OR end_date >= issue_date),
    CHECK (
        status <> 'closed'
        OR (urs_report_approved_at IS NOT NULL AND compaction_result_recorded_at IS NOT NULL)
    )
);

CREATE TABLE transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_no text NOT NULL,
    permit_id uuid REFERENCES permits(id),
    transaction_type text NOT NULL CHECK (transaction_type IN ('issuance', 'renewal', 'other')),
    status text NOT NULL DEFAULT 'draft',
    sector_id uuid REFERENCES sectors(id),
    contractor_ref text,
    created_by uuid REFERENCES users(id),
    started_at timestamptz,
    completed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (started_at IS NULL OR completed_at IS NULL OR completed_at >= started_at)
);

CREATE INDEX transactions_permit_id_idx ON transactions(permit_id);
CREATE INDEX transactions_transaction_no_idx ON transactions(transaction_no);
CREATE INDEX transactions_sector_id_idx ON transactions(sector_id);

CREATE TABLE permit_site_assignments (
    permit_id uuid NOT NULL REFERENCES permits(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (permit_id, user_id)
);

CREATE TABLE transaction_site_assignments (
    transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (transaction_id, user_id)
);

CREATE TABLE permit_approvers (
    permit_id uuid NOT NULL REFERENCES permits(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (permit_id, user_id)
);

CREATE TABLE permit_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    permit_id uuid NOT NULL REFERENCES permits(id),
    event_type text NOT NULL,
    from_status text,
    to_status text,
    details jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_by uuid REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE deadlines (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    permit_id uuid NOT NULL REFERENCES permits(id),
    kind text NOT NULL CHECK (kind IN ('urs_report', 'return_correction', 'renewal')),
    start_date date NOT NULL,
    due_date date NOT NULL,
    status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'completed', 'cancelled')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (due_date >= start_date)
);

CREATE INDEX deadlines_due_date_open_idx ON deadlines(due_date) WHERE status = 'open';
CREATE INDEX deadlines_permit_kind_idx ON deadlines(permit_id, kind);
ALTER TABLE transactions ADD COLUMN deadline_id uuid REFERENCES deadlines(id);

CREATE TABLE letters (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    permit_id uuid NOT NULL REFERENCES permits(id),
    letter_type text NOT NULL,
    status text NOT NULL DEFAULT 'draft' CHECK (
        status IN ('draft', 'pending_approval', 'approved', 'issued', 'rejected')
    ),
    content jsonb NOT NULL DEFAULT '{}'::jsonb,
    approved_by uuid REFERENCES users(id),
    approved_at timestamptz,
    created_by uuid REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK ((status IN ('approved', 'issued') AND approved_by IS NOT NULL AND approved_at IS NOT NULL)
        OR status NOT IN ('approved', 'issued'))
);

CREATE TABLE attachments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    permit_id uuid NOT NULL REFERENCES permits(id),
    storage_provider text NOT NULL CHECK (storage_provider IN ('google_drive', 'supabase_storage')),
    storage_key text NOT NULL,
    original_name text NOT NULL,
    mime_type text NOT NULL,
    size_bytes bigint NOT NULL CHECK (size_bytes > 0),
    sha256 text NOT NULL CHECK (sha256 ~ '^[0-9a-f]{64}$'),
    attachment_type text NOT NULL,
    uploaded_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (storage_provider, storage_key)
);

CREATE TABLE settings (
    key text PRIMARY KEY,
    value jsonb NOT NULL,
    description text NOT NULL,
    updated_by uuid REFERENCES users(id),
    updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO settings (key, value, description) VALUES
    ('permit_duration_days', '20', 'مدة الرخصة بالأيام'),
    ('renewal_duration_days', '20', 'مدة التجديد بالأيام'),
    ('urs_report_grace_days', '60', 'مهلة تقرير URS بعد انتهاء الرخصة'),
    ('return_correction_grace_days', '60', 'مهلة تصحيح الرخصة المعادة'),
    ('closure_threshold', '10', 'حد الإغلاق للرخص المنتهية أو المعادة'),
    ('day_counting_mode', '"calendar"', 'طريقة احتساب الأيام: calendar أو business'),
    ('business_timezone', '"Asia/Riyadh"', 'المنطقة الزمنية لحساب تاريخ اليوم'),
    ('weekend_days', 'null', 'أيام عطلة نهاية الأسبوع عند استخدام أيام العمل'),
    ('official_holidays', '[]', 'العطل الرسمية عند استخدام أيام العمل'),
    ('near_deadline_days', 'null', 'عتبة التنبيه قبل الاستحقاق؛ يحددها المشرف'),
    ('minimum_kpi_sample_size', '30', 'الحد الأدنى لإظهار المؤشرات المصنفة'),
    ('attachment_max_bytes', 'null', 'الحد الأقصى لحجم المرفق؛ يحدد قبل تفعيل الرفع'),
    ('attachment_allowed_mime_types', '[]', 'أنواع الملفات المسموحة؛ يحددها المشرف قبل تفعيل الرفع')
ON CONFLICT (key) DO NOTHING;

CREATE TABLE audit_log (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_id uuid REFERENCES users(id),
    action text NOT NULL,
    table_name text NOT NULL,
    row_id text NOT NULL,
    before_values jsonb,
    after_values jsonb,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE import_runs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    source_name text NOT NULL,
    source_fingerprint text NOT NULL,
    source_rows integer NOT NULL CHECK (source_rows >= 0),
    accepted_rows integer NOT NULL CHECK (accepted_rows >= 0),
    rejected_rows integer NOT NULL CHECK (rejected_rows >= 0),
    checks jsonb NOT NULL DEFAULT '{}'::jsonb,
    status text NOT NULL CHECK (status IN ('passed', 'failed', 'pending_review')),
    started_by uuid REFERENCES users(id),
    started_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz,
    CHECK (source_rows = accepted_rows + rejected_rows)
);

CREATE TABLE kpi_definitions (
    key text PRIMARY KEY,
    title text NOT NULL,
    definition text NOT NULL,
    view_name text NOT NULL UNIQUE,
    is_active boolean NOT NULL DEFAULT true
);

INSERT INTO kpi_definitions (key, title, definition, view_name) VALUES
    ('permit_status_counts', 'الرخص حسب الحالة', 'عدد الرخص في كل حالة معيارية', 'v_kpi_permit_status'),
    ('deadline_status_counts', 'حالة المهل', 'عدد المهل المفتوحة والمكتملة والمتأخرة حسب النوع', 'v_kpi_deadline_status'),
    ('transaction_cycle_time', 'زمن دورة المعاملة', 'وسيط وP90 لزمن المعاملة بالأيام مع n', 'v_kpi_transaction_cycle_time'),
    ('on_time_completion', 'الإنجاز ضمن المهلة', 'نسبة المعاملات المكتملة ضمن المهلة مع n', 'v_kpi_on_time_completion'),
    ('consultant_cycle_time', 'زمن الدورة حسب الاستشاري', 'وسيط وP90 مع حجب العينات الأصغر من الحد المهيأ', 'v_kpi_consultant_cycle_time'),
    ('sector_cycle_time', 'زمن الدورة حسب القطاع', 'وسيط وP90 مع حجب العينات الأصغر من الحد المهيأ', 'v_kpi_sector_cycle_time');

CREATE FUNCTION app_current_user_id() RETURNS uuid
LANGUAGE sql STABLE
AS $$
    SELECT NULLIF(current_setting('app.user_id', true), '')::uuid
$$;

CREATE FUNCTION app_current_user_role() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT role FROM users WHERE id = app_current_user_id() AND is_active
$$;

CREATE FUNCTION app_can_access_permit(target_permit_id uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT COALESCE((
        SELECT CASE u.role
            WHEN 'super_admin' THEN true
            WHEN 'sector_manager' THEN p.sector_id = u.sector_id
            WHEN 'site_engineer' THEN EXISTS (
                SELECT 1 FROM permit_site_assignments a
                WHERE a.permit_id = p.id AND a.user_id = u.id
            )
            WHEN 'contractor' THEN p.contractor_ref = u.contractor_ref
            WHEN 'viewer' THEN true
            ELSE false
        END
        FROM permits p
        JOIN users u ON u.id = app_current_user_id() AND u.is_active
        WHERE p.id = target_permit_id
    ), false)
$$;

CREATE FUNCTION app_can_edit_permit(target_permit_id uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT COALESCE((
        SELECT CASE u.role
            WHEN 'super_admin' THEN true
            WHEN 'sector_manager' THEN p.sector_id = u.sector_id
            WHEN 'site_engineer' THEN EXISTS (
                SELECT 1 FROM permit_site_assignments a
                WHERE a.permit_id = p.id AND a.user_id = u.id
            )
            ELSE false
        END
        FROM permits p
        JOIN users u ON u.id = app_current_user_id() AND u.is_active
        WHERE p.id = target_permit_id
    ), false)
$$;

CREATE FUNCTION app_can_upload_for_permit(target_permit_id uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT COALESCE((
        SELECT CASE u.role
            WHEN 'super_admin' THEN true
            WHEN 'sector_manager' THEN p.sector_id = u.sector_id
            WHEN 'site_engineer' THEN EXISTS (
                SELECT 1 FROM permit_site_assignments a
                WHERE a.permit_id = p.id AND a.user_id = u.id
            )
            WHEN 'contractor' THEN p.contractor_ref = u.contractor_ref
            ELSE false
        END
        FROM permits p
        JOIN users u ON u.id = app_current_user_id() AND u.is_active
        WHERE p.id = target_permit_id
    ), false)
$$;

CREATE FUNCTION app_is_permit_approver(target_permit_id uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT app_current_user_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM permit_approvers a
            WHERE a.permit_id = target_permit_id
              AND a.user_id = app_current_user_id()
        )
$$;

CREATE FUNCTION app_validate_permit_change() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status AND NOT (
        (OLD.status = 'draft' AND NEW.status IN ('pending', 'cancelled'))
        OR (OLD.status = 'pending' AND NEW.status IN ('active', 'returned', 'cancelled'))
        OR (OLD.status = 'active' AND NEW.status IN ('expired', 'returned', 'ready_for_closure'))
        OR (OLD.status = 'expired' AND NEW.status IN ('renewal_pending', 'ready_for_closure'))
        OR (OLD.status = 'returned' AND NEW.status IN ('under_correction', 'cancelled'))
        OR (OLD.status = 'under_correction' AND NEW.status IN ('pending', 'ready_for_closure'))
        OR (OLD.status = 'renewal_pending' AND NEW.status IN ('active', 'cancelled'))
        OR (OLD.status = 'ready_for_closure' AND NEW.status = 'closed')
    ) THEN
        RAISE EXCEPTION 'Permit status transition is not allowed';
    END IF;
    IF NEW.urs_report_approved_at IS DISTINCT FROM OLD.urs_report_approved_at
       AND NOT app_is_permit_approver(NEW.id) THEN
        RAISE EXCEPTION 'Only a delegated approver may record URS approval';
    END IF;
    IF NEW.compaction_result_recorded_at IS DISTINCT FROM OLD.compaction_result_recorded_at
       AND NOT app_can_edit_permit(NEW.id) THEN
        RAISE EXCEPTION 'The user is not permitted to record the compaction result';
    END IF;
    IF NEW.status = 'closed'
       AND (NEW.urs_report_approved_at IS NULL OR NEW.compaction_result_recorded_at IS NULL) THEN
        RAISE EXCEPTION 'Closure requires approved URS and a recorded compaction result';
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER permits_validate_workflow
BEFORE UPDATE ON permits
FOR EACH ROW EXECUTE FUNCTION app_validate_permit_change();

CREATE FUNCTION app_record_permit_status_change() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO permit_events (
            permit_id, event_type, from_status, to_status, created_by
        ) VALUES (
            NEW.id, 'status_transition', OLD.status, NEW.status, app_current_user_id()
        );
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER permits_record_status_change
AFTER UPDATE ON permits
FOR EACH ROW EXECUTE FUNCTION app_record_permit_status_change();

CREATE FUNCTION app_can_access_transaction(target_transaction_id uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT COALESCE((
        SELECT CASE u.role
            WHEN 'super_admin' THEN true
            WHEN 'sector_manager' THEN t.sector_id = u.sector_id
                AND (t.permit_id IS NULL OR app_can_access_permit(t.permit_id))
            WHEN 'site_engineer' THEN
                (t.created_by = u.id OR EXISTS (
                    SELECT 1 FROM transaction_site_assignments a
                    WHERE a.transaction_id = t.id AND a.user_id = u.id
                ))
                AND (t.permit_id IS NULL OR app_can_access_permit(t.permit_id))
            WHEN 'contractor' THEN t.contractor_ref = u.contractor_ref
                AND (t.permit_id IS NULL OR app_can_access_permit(t.permit_id))
            WHEN 'viewer' THEN true
            ELSE false
        END
        FROM transactions t
        JOIN users u ON u.id = app_current_user_id() AND u.is_active
        WHERE t.id = target_transaction_id
    ), false)
$$;

CREATE FUNCTION app_can_edit_transaction(target_transaction_id uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT COALESCE((
        SELECT CASE u.role
            WHEN 'super_admin' THEN true
            WHEN 'sector_manager' THEN t.sector_id = u.sector_id
                AND (t.permit_id IS NULL OR app_can_edit_permit(t.permit_id))
            WHEN 'site_engineer' THEN
                (t.created_by = u.id OR EXISTS (
                    SELECT 1 FROM transaction_site_assignments a
                    WHERE a.transaction_id = t.id AND a.user_id = u.id
                ))
                AND (t.permit_id IS NULL OR app_can_edit_permit(t.permit_id))
            ELSE false
        END
        FROM transactions t
        JOIN users u ON u.id = app_current_user_id() AND u.is_active
        WHERE t.id = target_transaction_id
    ), false)
$$;

CREATE FUNCTION app_audit_row_change() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    old_row jsonb;
    new_row jsonb;
    row_identifier text;
BEGIN
    IF TG_OP <> 'INSERT' THEN old_row := to_jsonb(OLD); END IF;
    IF TG_OP <> 'DELETE' THEN new_row := to_jsonb(NEW); END IF;
    row_identifier := COALESCE(
        new_row->>'id',
        old_row->>'id',
        new_row->>'key',
        old_row->>'key',
        concat_ws(':', new_row->>'permit_id', new_row->>'user_id'),
        concat_ws(':', old_row->>'permit_id', old_row->>'user_id')
    );

    INSERT INTO audit_log (actor_id, action, table_name, row_id, before_values, after_values)
    VALUES (app_current_user_id(), TG_OP, TG_TABLE_NAME, COALESCE(row_identifier, 'unknown'), old_row, new_row);

    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END
$$;

CREATE FUNCTION app_reject_audit_log_mutation() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'audit_log is append-only';
END
$$;

CREATE TRIGGER audit_log_append_only
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION app_reject_audit_log_mutation();

DO $$
DECLARE
    target_table text;
BEGIN
    FOREACH target_table IN ARRAY ARRAY[
        'sectors', 'consultants', 'users', 'permits', 'transactions',
        'permit_site_assignments', 'transaction_site_assignments', 'permit_approvers',
        'permit_events', 'deadlines', 'letters',
        'attachments', 'settings', 'import_runs'
    ] LOOP
        EXECUTE format(
            'CREATE TRIGGER audit_%I AFTER INSERT OR UPDATE OR DELETE ON %I '
            'FOR EACH ROW EXECUTE FUNCTION app_audit_row_change()',
            target_table, target_table
        );
    END LOOP;
END
$$;

CREATE VIEW v_kpi_permit_status WITH (security_invoker = true) AS
SELECT status, count(*)::bigint AS n
FROM permits
GROUP BY status;

CREATE VIEW v_kpi_deadline_status WITH (security_invoker = true) AS
SELECT kind, status, count(*)::bigint AS n
FROM deadlines
GROUP BY kind, status;

CREATE VIEW v_kpi_transaction_cycle_time WITH (security_invoker = true) AS
SELECT
    count(*)::bigint AS n,
    percentile_cont(0.5) WITHIN GROUP (
        ORDER BY EXTRACT(EPOCH FROM (completed_at - started_at)) / 86400
    ) AS median_days,
    percentile_cont(0.9) WITHIN GROUP (
        ORDER BY EXTRACT(EPOCH FROM (completed_at - started_at)) / 86400
    ) AS p90_days
FROM transactions
WHERE started_at IS NOT NULL AND completed_at IS NOT NULL AND completed_at >= started_at;

CREATE VIEW v_kpi_on_time_completion WITH (security_invoker = true) AS
SELECT
    count(*)::bigint AS n,
    count(*) FILTER (WHERE t.completed_at::date <= d.due_date)::bigint AS completed_within_deadline,
    CASE WHEN count(*) = 0 THEN NULL
         ELSE round(100.0 * count(*) FILTER (WHERE t.completed_at::date <= d.due_date) / count(*), 2)
    END AS completion_rate_percent
FROM transactions t
JOIN deadlines d ON d.id = t.deadline_id AND d.status = 'completed'
WHERE t.completed_at IS NOT NULL;

CREATE VIEW v_kpi_consultant_cycle_time WITH (security_invoker = true) AS
WITH sample AS (
    SELECT
        c.id AS consultant_id,
        c.name AS consultant_name,
        count(*)::bigint AS n,
        percentile_cont(0.5) WITHIN GROUP (
            ORDER BY EXTRACT(EPOCH FROM (t.completed_at - t.started_at)) / 86400
        ) AS median_days,
        percentile_cont(0.9) WITHIN GROUP (
            ORDER BY EXTRACT(EPOCH FROM (t.completed_at - t.started_at)) / 86400
        ) AS p90_days
    FROM consultants c
    JOIN permits p ON p.consultant_id = c.id
    JOIN transactions t ON t.permit_id = p.id
    WHERE t.started_at IS NOT NULL AND t.completed_at IS NOT NULL
      AND t.completed_at >= t.started_at
    GROUP BY c.id, c.name
), threshold AS (
    SELECT (value #>> '{}')::integer AS minimum_n
    FROM settings WHERE key = 'minimum_kpi_sample_size'
)
SELECT
    consultant_id,
    CASE WHEN threshold.minimum_n IS NULL OR sample.n < threshold.minimum_n
         THEN 'عينة غير كافية' ELSE consultant_name END AS display_name,
    sample.n,
    CASE WHEN threshold.minimum_n IS NULL OR sample.n < threshold.minimum_n
         THEN NULL ELSE median_days END AS median_days,
    CASE WHEN threshold.minimum_n IS NULL OR sample.n < threshold.minimum_n
         THEN NULL ELSE p90_days END AS p90_days
FROM sample CROSS JOIN threshold;

CREATE VIEW v_kpi_sector_cycle_time WITH (security_invoker = true) AS
WITH sample AS (
    SELECT
        s.id AS sector_id,
        s.name AS sector_name,
        count(*)::bigint AS n,
        percentile_cont(0.5) WITHIN GROUP (
            ORDER BY EXTRACT(EPOCH FROM (t.completed_at - t.started_at)) / 86400
        ) AS median_days,
        percentile_cont(0.9) WITHIN GROUP (
            ORDER BY EXTRACT(EPOCH FROM (t.completed_at - t.started_at)) / 86400
        ) AS p90_days
    FROM sectors s
    JOIN permits p ON p.sector_id = s.id
    JOIN transactions t ON t.permit_id = p.id
    WHERE t.started_at IS NOT NULL AND t.completed_at IS NOT NULL
      AND t.completed_at >= t.started_at
    GROUP BY s.id, s.name
), threshold AS (
    SELECT (value #>> '{}')::integer AS minimum_n
    FROM settings WHERE key = 'minimum_kpi_sample_size'
)
SELECT
    sector_id,
    CASE WHEN threshold.minimum_n IS NULL OR sample.n < threshold.minimum_n
         THEN 'عينة غير كافية' ELSE sector_name END AS display_name,
    sample.n,
    CASE WHEN threshold.minimum_n IS NULL OR sample.n < threshold.minimum_n
         THEN NULL ELSE median_days END AS median_days,
    CASE WHEN threshold.minimum_n IS NULL OR sample.n < threshold.minimum_n
         THEN NULL ELSE p90_days END AS p90_days
FROM sample CROSS JOIN threshold;

CREATE FUNCTION app_validate_letter_change() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status IN ('approved', 'issued') THEN
        RAISE EXCEPTION 'Official letters must be approved through the approval workflow';
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF NEW.status IS DISTINCT FROM OLD.status AND NOT (
            (OLD.status = 'draft' AND NEW.status = 'pending_approval')
            OR (OLD.status = 'pending_approval' AND NEW.status IN ('approved', 'rejected'))
            OR (OLD.status = 'approved' AND NEW.status = 'issued')
            OR (OLD.status = 'rejected' AND NEW.status = 'draft')
        ) THEN
            RAISE EXCEPTION 'Letter status transition is not allowed';
        END IF;
        IF OLD.status IN ('approved', 'issued')
           AND (
               NEW.permit_id IS DISTINCT FROM OLD.permit_id
               OR NEW.content IS DISTINCT FROM OLD.content
               OR NEW.letter_type IS DISTINCT FROM OLD.letter_type
               OR NEW.approved_by IS DISTINCT FROM OLD.approved_by
               OR NEW.approved_at IS DISTINCT FROM OLD.approved_at
           ) THEN
            RAISE EXCEPTION 'Approved letter content and approval metadata are immutable';
        END IF;
        IF NEW.status = 'approved' AND OLD.status <> 'pending_approval' THEN
            RAISE EXCEPTION 'Only a pending letter can be approved';
        END IF;
        IF NEW.status = 'issued' AND OLD.status <> 'approved' THEN
            RAISE EXCEPTION 'Only an approved letter can be issued';
        END IF;
        IF NEW.status = 'approved' AND OLD.status <> 'approved' THEN
            IF NOT app_is_permit_approver(NEW.permit_id) THEN
                RAISE EXCEPTION 'Only a delegated approver may approve an official letter';
            END IF;
            IF NEW.approved_by IS DISTINCT FROM app_current_user_id() OR NEW.approved_at IS NULL THEN
                RAISE EXCEPTION 'Approval must record the delegated approver and approval time';
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER letters_validate_workflow
BEFORE INSERT OR UPDATE ON letters
FOR EACH ROW EXECUTE FUNCTION app_validate_letter_change();

ALTER TABLE sectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultants ENABLE ROW LEVEL SECURITY;
ALTER TABLE permit_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE permits ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE permit_site_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_site_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE permit_approvers ENABLE ROW LEVEL SECURITY;
ALTER TABLE permit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE deadlines ENABLE ROW LEVEL SECURITY;
ALTER TABLE letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY sectors_read ON sectors FOR SELECT USING (app_current_user_id() IS NOT NULL);
CREATE POLICY consultants_read ON consultants FOR SELECT USING (app_current_user_id() IS NOT NULL);
CREATE POLICY permit_statuses_read ON permit_statuses FOR SELECT USING (app_current_user_id() IS NOT NULL);
CREATE POLICY users_read_self_or_admin ON users FOR SELECT
    USING (id = app_current_user_id() OR app_current_user_role() = 'super_admin');
CREATE POLICY users_admin_manage ON users FOR ALL
    USING (app_current_user_role() = 'super_admin')
    WITH CHECK (app_current_user_role() = 'super_admin');

CREATE POLICY permits_read_scoped ON permits FOR SELECT USING (app_can_access_permit(id));
CREATE POLICY permits_insert_admin_or_sector ON permits FOR INSERT
    WITH CHECK (app_current_user_role() = 'super_admin'
        OR (app_current_user_role() = 'sector_manager' AND sector_id IN (
            SELECT sector_id FROM users WHERE id = app_current_user_id()
        )));
CREATE POLICY permits_update_scoped ON permits FOR UPDATE
    USING (app_can_edit_permit(id)) WITH CHECK (app_can_edit_permit(id));
CREATE POLICY permits_delete_admin ON permits FOR DELETE
    USING (app_current_user_role() = 'super_admin');

CREATE POLICY transactions_read_scoped ON transactions FOR SELECT
    USING (app_can_access_transaction(id));
CREATE POLICY transactions_insert_scoped ON transactions FOR INSERT
    WITH CHECK (
        (permit_id IS NULL OR app_can_edit_permit(permit_id))
        AND (
            app_current_user_role() = 'super_admin'
            OR (
                app_current_user_role() = 'sector_manager'
                AND sector_id IN (SELECT sector_id FROM users WHERE id = app_current_user_id())
                AND (permit_id IS NULL OR app_can_edit_permit(permit_id))
            )
            OR (
                app_current_user_role() = 'site_engineer'
                AND created_by = app_current_user_id()
                AND (permit_id IS NULL OR app_can_edit_permit(permit_id))
                )
        )
    );
CREATE POLICY transactions_update_scoped ON transactions FOR UPDATE
    USING (app_can_edit_transaction(id))
    WITH CHECK (app_can_edit_transaction(id));
CREATE POLICY transactions_delete_admin ON transactions FOR DELETE
    USING (app_current_user_role() = 'super_admin');

CREATE POLICY site_assignments_read_scoped ON permit_site_assignments FOR SELECT
    USING (user_id = app_current_user_id() OR app_current_user_role() = 'super_admin');
CREATE POLICY site_assignments_admin_manage ON permit_site_assignments FOR ALL
    USING (app_current_user_role() = 'super_admin')
    WITH CHECK (app_current_user_role() = 'super_admin');
CREATE POLICY transaction_assignments_read_scoped ON transaction_site_assignments FOR SELECT
    USING (user_id = app_current_user_id() OR app_current_user_role() = 'super_admin');
CREATE POLICY transaction_assignments_admin_manage ON transaction_site_assignments FOR ALL
    USING (app_current_user_role() = 'super_admin')
    WITH CHECK (app_current_user_role() = 'super_admin');
CREATE POLICY permit_approvers_read_scoped ON permit_approvers FOR SELECT
    USING (user_id = app_current_user_id() OR app_current_user_role() = 'super_admin');
CREATE POLICY permit_approvers_admin_manage ON permit_approvers FOR ALL
    USING (app_current_user_role() = 'super_admin')
    WITH CHECK (app_current_user_role() = 'super_admin');

CREATE POLICY events_read_scoped ON permit_events FOR SELECT USING (app_can_access_permit(permit_id));
CREATE POLICY events_insert_scoped ON permit_events FOR INSERT WITH CHECK (app_can_edit_permit(permit_id));
CREATE POLICY events_update_admin ON permit_events FOR UPDATE USING (app_current_user_role() = 'super_admin');
CREATE POLICY events_delete_admin ON permit_events FOR DELETE USING (app_current_user_role() = 'super_admin');

CREATE POLICY deadlines_read_scoped ON deadlines FOR SELECT USING (app_can_access_permit(permit_id));
CREATE POLICY deadlines_write_scoped ON deadlines FOR INSERT
    WITH CHECK (app_can_edit_permit(permit_id));
CREATE POLICY deadlines_update_scoped ON deadlines FOR UPDATE
    USING (app_can_edit_permit(permit_id)) WITH CHECK (app_can_edit_permit(permit_id));
CREATE POLICY deadlines_delete_admin ON deadlines FOR DELETE USING (app_current_user_role() = 'super_admin');

CREATE POLICY letters_read_scoped ON letters FOR SELECT USING (app_can_access_permit(permit_id));
CREATE POLICY letters_insert_scoped ON letters FOR INSERT
    WITH CHECK (app_can_edit_permit(permit_id) AND status = 'draft' AND approved_by IS NULL);
CREATE POLICY letters_update_scoped ON letters FOR UPDATE
    USING (app_can_edit_permit(permit_id) OR app_is_permit_approver(permit_id))
    WITH CHECK (
        (app_can_edit_permit(permit_id) OR app_is_permit_approver(permit_id))
        AND (status NOT IN ('approved', 'issued') OR app_is_permit_approver(permit_id))
        AND (status <> 'approved' OR approved_by = app_current_user_id())
    );
CREATE POLICY letters_delete_admin ON letters FOR DELETE USING (app_current_user_role() = 'super_admin');

CREATE POLICY attachments_read_scoped ON attachments FOR SELECT USING (app_can_access_permit(permit_id));
CREATE POLICY attachments_insert_scoped ON attachments FOR INSERT
    WITH CHECK (app_can_upload_for_permit(permit_id) AND uploaded_by = app_current_user_id());
CREATE POLICY attachments_delete_admin ON attachments FOR DELETE USING (app_current_user_role() = 'super_admin');

CREATE POLICY settings_read_authenticated ON settings FOR SELECT USING (app_current_user_id() IS NOT NULL);
CREATE POLICY settings_admin_insert ON settings FOR INSERT
    WITH CHECK (app_current_user_role() = 'super_admin');
CREATE POLICY settings_admin_update ON settings FOR UPDATE
    USING (app_current_user_role() = 'super_admin')
    WITH CHECK (app_current_user_role() = 'super_admin');

CREATE POLICY audit_read_admin ON audit_log FOR SELECT USING (app_current_user_role() = 'super_admin');
CREATE POLICY import_runs_read_scoped ON import_runs FOR SELECT
    USING (app_current_user_role() IN ('super_admin', 'sector_manager'));
CREATE POLICY import_runs_admin_insert ON import_runs FOR INSERT
    WITH CHECK (app_current_user_role() = 'super_admin');
CREATE POLICY kpi_definitions_read ON kpi_definitions FOR SELECT
    USING (app_current_user_id() IS NOT NULL);

REVOKE UPDATE, DELETE, TRUNCATE ON audit_log FROM PUBLIC;

CREATE TABLE import_run_rows (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    import_run_id uuid NOT NULL REFERENCES import_runs(id) ON DELETE CASCADE,
    source_sheet text NOT NULL,
    source_row integer NOT NULL CHECK (source_row > 0),
    permit_reference text,
    matched_permit_id uuid REFERENCES permits(id),
    disposition text NOT NULL CHECK (
        disposition IN ('new', 'changed', 'unchanged', 'rejected')
    ),
    review_status text NOT NULL DEFAULT 'pending' CHECK (
        review_status IN ('pending', 'approved', 'rejected', 'applied')
    ),
    proposed_values jsonb NOT NULL DEFAULT '{}'::jsonb,
    differences jsonb NOT NULL DEFAULT '[]'::jsonb,
    rejection_reason text,
    reviewed_by uuid REFERENCES users(id),
    reviewed_at timestamptz,
    applied_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (import_run_id, source_sheet, source_row),
    CHECK (
        (review_status IN ('approved', 'rejected', 'applied')
            AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
        OR review_status = 'pending'
    ),
    CHECK (
        (review_status = 'applied' AND applied_at IS NOT NULL)
        OR (review_status <> 'applied' AND applied_at IS NULL)
    ),
    CHECK (
        disposition <> 'rejected'
        OR rejection_reason IS NOT NULL
    )
);

CREATE INDEX import_run_rows_permit_idx
    ON import_run_rows(matched_permit_id) WHERE matched_permit_id IS NOT NULL;
CREATE INDEX import_run_rows_review_idx
    ON import_run_rows(import_run_id, review_status);
CREATE UNIQUE INDEX import_runs_source_fingerprint_idx
    ON import_runs(source_fingerprint);

CREATE TABLE permit_work_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    permit_id uuid NOT NULL REFERENCES permits(id),
    workstream text NOT NULL CHECK (
        workstream IN (
            'coordination',
            'asphalt',
            'laboratory',
            'consultant_correction',
            'center_correction'
        )
    ),
    status text NOT NULL DEFAULT 'pending' CHECK (
        status IN ('pending', 'in_progress', 'completed', 'blocked', 'cancelled')
    ),
    depends_on_item_id uuid REFERENCES permit_work_items(id),
    return_reason text,
    source_event_id uuid REFERENCES permit_events(id),
    created_by uuid REFERENCES users(id),
    completed_by uuid REFERENCES users(id),
    completed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (depends_on_item_id IS NULL OR depends_on_item_id <> id),
    CHECK (
        (workstream IN ('consultant_correction', 'center_correction')
            AND return_reason IS NOT NULL)
        OR workstream NOT IN ('consultant_correction', 'center_correction')
    ),
    CHECK (
        (status = 'completed' AND completed_by IS NOT NULL AND completed_at IS NOT NULL)
        OR status <> 'completed'
    )
);

CREATE INDEX permit_work_items_permit_status_idx
    ON permit_work_items(permit_id, status, workstream);

CREATE FUNCTION app_validate_permit_work_item() RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    dependency_permit_id uuid;
    dependency_status text;
BEGIN
    IF NEW.depends_on_item_id IS NOT NULL THEN
        SELECT permit_id, status
        INTO dependency_permit_id, dependency_status
        FROM permit_work_items
        WHERE id = NEW.depends_on_item_id;

        IF dependency_permit_id IS DISTINCT FROM NEW.permit_id THEN
            RAISE EXCEPTION 'Work item dependencies must belong to the same permit';
        END IF;
        IF NEW.status IN ('in_progress', 'completed')
           AND dependency_status <> 'completed' THEN
            RAISE EXCEPTION 'A work item cannot start before its prerequisite is completed';
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF OLD.status = 'completed'
           AND NEW.status <> 'completed'
           AND EXISTS (
               SELECT 1
               FROM permit_work_items child
               WHERE child.depends_on_item_id = OLD.id
                 AND child.status IN ('in_progress', 'completed')
           ) THEN
            RAISE EXCEPTION 'A completed prerequisite cannot be reopened while dependent work is active';
        END IF;

        IF NEW.status = 'completed'
           AND OLD.status IS DISTINCT FROM 'completed'
           AND (
               NEW.completed_by IS DISTINCT FROM app_current_user_id()
               OR NEW.completed_at IS NULL
           ) THEN
            RAISE EXCEPTION 'Work completion must record the current user and completion time';
        END IF;
    END IF;

    IF TG_OP = 'INSERT' AND NEW.status = 'completed' THEN
        IF NEW.completed_by IS DISTINCT FROM app_current_user_id()
           OR NEW.completed_at IS NULL THEN
            RAISE EXCEPTION 'Work completion must record the current user and completion time';
        END IF;
    END IF;
    RETURN NEW;
END
$$;

CREATE TRIGGER permit_work_items_validate
BEFORE INSERT OR UPDATE ON permit_work_items
FOR EACH ROW EXECUTE FUNCTION app_validate_permit_work_item();

ALTER TABLE import_run_rows ENABLE ROW LEVEL SECURITY;
ALTER TABLE permit_work_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY import_run_rows_admin_read ON import_run_rows FOR SELECT
    USING (app_current_user_role() = 'super_admin');
CREATE POLICY import_run_rows_admin_insert ON import_run_rows FOR INSERT
    WITH CHECK (app_current_user_role() = 'super_admin');
CREATE POLICY import_run_rows_admin_update ON import_run_rows FOR UPDATE
    USING (app_current_user_role() = 'super_admin')
    WITH CHECK (app_current_user_role() = 'super_admin');
CREATE POLICY import_run_rows_admin_delete ON import_run_rows FOR DELETE
    USING (app_current_user_role() = 'super_admin');

CREATE POLICY permit_work_items_read_scoped ON permit_work_items FOR SELECT
    USING (app_can_access_permit(permit_id));
CREATE POLICY permit_work_items_insert_scoped ON permit_work_items FOR INSERT
    WITH CHECK (app_can_edit_permit(permit_id));
CREATE POLICY permit_work_items_update_scoped ON permit_work_items FOR UPDATE
    USING (app_can_edit_permit(permit_id))
    WITH CHECK (app_can_edit_permit(permit_id));
CREATE POLICY permit_work_items_delete_admin ON permit_work_items FOR DELETE
    USING (app_current_user_role() = 'super_admin');

CREATE TRIGGER audit_import_run_rows
AFTER INSERT OR UPDATE OR DELETE ON import_run_rows
FOR EACH ROW EXECUTE FUNCTION app_audit_row_change();
CREATE TRIGGER audit_permit_work_items
AFTER INSERT OR UPDATE OR DELETE ON permit_work_items
FOR EACH ROW EXECUTE FUNCTION app_audit_row_change();

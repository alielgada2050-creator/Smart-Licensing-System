import unittest
from datetime import date, timedelta
from pathlib import Path

from server.domain import (
    AccessContext,
    DeadlineClass,
    DeadlineKind,
    DomainRuleError,
    KPI_DICTIONARY,
    PermitScope,
    can_export_final_letter,
    can_access_permit,
    calculate_due_date,
    check_attachment_policy,
    classify_deadline,
    configured_deadline_duration,
    resolve_permit_reference,
    should_close_batch,
    validate_import_counts,
    validate_letter_transition,
    validate_permit_transition,
)


class DeadlineEngineTests(unittest.TestCase):
    def test_deadline_kinds_read_independent_settings(self):
        settings = {
            "urs_report_grace_days": 60,
            "return_correction_grace_days": 45,
            "renewal_duration_days": 20,
        }
        self.assertEqual(
            configured_deadline_duration(DeadlineKind.URS_REPORT, settings),
            60,
        )
        self.assertEqual(
            configured_deadline_duration(DeadlineKind.RETURN_CORRECTION, settings),
            45,
        )
        self.assertEqual(
            configured_deadline_duration(DeadlineKind.RENEWAL, settings),
            20,
        )
        with self.assertRaisesRegex(DomainRuleError, "missing or invalid"):
            configured_deadline_duration(DeadlineKind.RETURN_CORRECTION, {})

    def test_closure_threshold_is_read_from_configuration(self):
        self.assertFalse(should_close_batch(9, 10))
        self.assertTrue(should_close_batch(10, 10))
        with self.assertRaises(DomainRuleError):
            should_close_batch(1, -1)

    def test_deadline_classification_uses_configured_threshold(self):
        today = date(2026, 11, 12)
        self.assertEqual(
            classify_deadline(
                today + timedelta(days=8),
                today,
                10,
                counting_mode="calendar",
            ).classification,
            DeadlineClass.NEAR,
        )
        self.assertEqual(
            classify_deadline(
                today + timedelta(days=11),
                today,
                10,
                counting_mode="calendar",
            ).classification,
            DeadlineClass.NORMAL,
        )
        self.assertEqual(
            classify_deadline(
                today - timedelta(days=1),
                today,
                10,
                counting_mode="calendar",
            ).classification,
            DeadlineClass.OVERDUE,
        )

    def test_negative_threshold_is_rejected(self):
        with self.assertRaises(DomainRuleError):
            classify_deadline(
                date.today(),
                date.today(),
                -1,
                counting_mode="calendar",
            )

    def test_business_days_use_configured_weekends_and_holidays(self):
        status = classify_deadline(
            date(2026, 11, 16),
            date(2026, 11, 12),
            2,
            counting_mode="business",
            weekend_days=frozenset({4, 5}),
            official_holidays=frozenset({date(2026, 11, 15)}),
        )
        self.assertEqual(status.days_remaining, 1)

    def test_business_day_mode_requires_weekend_settings(self):
        with self.assertRaisesRegex(DomainRuleError, "weekends"):
            classify_deadline(
                date(2026, 11, 16),
                date(2026, 11, 12),
                2,
                counting_mode="business",
            )

    def test_deadline_due_date_uses_calendar_or_business_settings(self):
        start = date(2026, 11, 12)
        self.assertEqual(
            calculate_due_date(start, 3, counting_mode="calendar"),
            date(2026, 11, 15),
        )
        self.assertEqual(
            calculate_due_date(
                start,
                2,
                counting_mode="business",
                weekend_days=frozenset({4, 5}),
                official_holidays=frozenset({date(2026, 11, 15)}),
            ),
            date(2026, 11, 17),
        )


class PermitStateMachineTests(unittest.TestCase):
    def test_closure_requires_approved_report_and_test_result(self):
        with self.assertRaisesRegex(DomainRuleError, "approved URS"):
            validate_permit_transition("ready_for_closure", "closed", {})
        with self.assertRaisesRegex(DomainRuleError, "compaction"):
            validate_permit_transition(
                "ready_for_closure",
                "closed",
                {"urs_report_approved": True},
            )
        validate_permit_transition(
            "ready_for_closure",
            "closed",
            {"urs_report_approved": True, "compaction_result_recorded": True},
        )

    def test_official_letter_requires_delegated_approval(self):
        with self.assertRaisesRegex(DomainRuleError, "delegated approver"):
            validate_letter_transition(
                "pending_approval",
                "approved",
                is_delegated_approver=False,
            )
        validate_letter_transition(
            "pending_approval",
            "approved",
            is_delegated_approver=True,
        )
        self.assertFalse(
            can_export_final_letter(
                AccessContext("sector_manager", sector_id="east"),
                PermitScope("P-1", sector_id="east"),
                "draft",
            )
        )
        self.assertFalse(
            can_export_final_letter(
                AccessContext("site_engineer", assigned_permit_ids=frozenset({"P-1"})),
                PermitScope("P-1", sector_id="east"),
                "approved",
            )
        )
        self.assertTrue(
            can_export_final_letter(
                AccessContext(
                    "sector_manager",
                    sector_id="east",
                    delegated_approval_permit_ids=frozenset({"P-1"}),
                ),
                PermitScope("P-1", sector_id="east"),
                "approved",
            )
        )

    def test_invalid_transition_is_rejected(self):
        with self.assertRaisesRegex(DomainRuleError, "not allowed"):
            validate_permit_transition("draft", "closed", {})


class PermissionPolicyTests(unittest.TestCase):
    def setUp(self):
        self.permit = PermitScope("P-1", sector_id="east", contractor_ref="C-1")

    def test_contractor_can_read_and_upload_own_permit_only(self):
        contractor = AccessContext("contractor", contractor_ref="C-1")
        other_permit = PermitScope("P-2", sector_id="east", contractor_ref="C-2")
        self.assertTrue(can_access_permit(contractor, self.permit, "read"))
        self.assertTrue(can_access_permit(contractor, self.permit, "upload"))
        self.assertFalse(can_access_permit(contractor, self.permit, "cancel"))
        self.assertFalse(can_access_permit(contractor, other_permit, "read"))

    def test_sector_manager_is_scoped_and_viewer_is_read_only(self):
        manager = AccessContext("sector_manager", sector_id="east")
        viewer = AccessContext("viewer")
        self.assertFalse(can_access_permit(manager, self.permit, "approve"))
        self.assertTrue(
            can_access_permit(
                AccessContext(
                    "sector_manager",
                    sector_id="east",
                    delegated_approval_permit_ids=frozenset({"P-1"}),
                ),
                self.permit,
                "approve",
            )
        )
        self.assertFalse(
            can_access_permit(
                AccessContext("sector_manager", sector_id="north"),
                self.permit,
                "read",
            )
        )
        self.assertTrue(can_access_permit(viewer, self.permit, "read"))
        self.assertFalse(can_access_permit(viewer, self.permit, "upload"))

    def test_site_engineer_requires_explicit_assignment(self):
        engineer = AccessContext("site_engineer", assigned_permit_ids=frozenset({"P-1"}))
        unassigned = AccessContext("site_engineer")
        self.assertTrue(can_access_permit(engineer, self.permit, "update"))
        self.assertFalse(can_access_permit(unassigned, self.permit, "update"))


class ImportAndAttachmentPolicyTests(unittest.TestCase):
    def test_import_counts_must_reconcile(self):
        validate_import_counts(10, 8, 2, 0)
        validate_import_counts(10, 8, 2, 0, {"active": 6, "expired": 4})
        with self.assertRaises(DomainRuleError):
            validate_import_counts(10, 8, 1, 0)
        with self.assertRaises(DomainRuleError):
            validate_import_counts(10, 10, 0, 1)
        with self.assertRaisesRegex(DomainRuleError, "subtotals"):
            validate_import_counts(10, 10, 0, 0, {"active": 8})

    def test_record_linking_only_uses_exact_permit_id(self):
        permits = [{"permit_id": "P-1"}, {"permit_id": "P-2"}]
        self.assertEqual(
            resolve_permit_reference({"permit_id": "P-1"}, permits),
            ("linked", "P-1"),
        )
        self.assertEqual(
            resolve_permit_reference({"permit_id": "", "base_no": "R-1"}, permits),
            ("unlinked", None),
        )

    def test_attachment_policy_must_be_configured_and_enforced(self):
        with self.assertRaisesRegex(DomainRuleError, "not configured"):
            check_attachment_policy(
                file_size=20,
                mime_type="application/pdf",
                max_bytes=None,
                allowed_mime_types=[],
            )
        check_attachment_policy(
            file_size=20,
            mime_type="application/pdf",
            max_bytes=100,
            allowed_mime_types=["application/pdf"],
        )
        with self.assertRaises(DomainRuleError):
            check_attachment_policy(
                file_size=200,
                mime_type="application/pdf",
                max_bytes=100,
                allowed_mime_types=["application/pdf"],
            )

    def test_kpi_dictionary_matches_server_view_contract(self):
        self.assertEqual(
            KPI_DICTIONARY["transaction_cycle_time"]["fields"],
            ("n", "median_days", "p90_days"),
        )
        self.assertEqual(
            KPI_DICTIONARY["transaction_cycle_time"]["view"],
            "v_kpi_transaction_cycle_time",
        )

    def test_migration_contains_kpi_views_deadline_kinds_and_audit_guards(self):
        migration = (
            Path(__file__).resolve().parents[1]
            / "database"
            / "migrations"
            / "0001_production_foundation.sql"
        ).read_text(encoding="utf-8")
        for definition in KPI_DICTIONARY.values():
            self.assertIn(f"CREATE VIEW {definition['view']}", migration)
        self.assertIn("'urs_report', 'return_correction', 'renewal'", migration)
        self.assertIn("audit_log_append_only", migration)
        self.assertIn("REVOKE UPDATE, DELETE, TRUNCATE ON audit_log", migration)
        self.assertIn("'عينة غير كافية'", migration)
        self.assertIn("permits_validate_workflow", migration)
        self.assertIn("Closure requires approved URS", migration)
        self.assertIn("ALTER TABLE permit_approvers ENABLE ROW LEVEL SECURITY", migration)
        self.assertIn("AND (t.permit_id IS NULL OR app_can_access_permit(t.permit_id))", migration)
        self.assertIn("Approval must record the delegated approver", migration)
        self.assertIn("Approved letter content and approval metadata are immutable", migration)
        workstream_migration = (
            Path(__file__).resolve().parents[1]
            / "database"
            / "migrations"
            / "0002_import_review_and_workstreams.sql"
        ).read_text(encoding="utf-8")
        self.assertIn("CREATE TABLE import_run_rows", workstream_migration)
        self.assertIn("UNIQUE (import_run_id, source_sheet, source_row)", workstream_migration)
        self.assertIn("CREATE TABLE permit_work_items", workstream_migration)
        self.assertIn("'asphalt',", workstream_migration)
        self.assertIn("'laboratory',", workstream_migration)
        self.assertIn("A work item cannot start before its prerequisite is completed", workstream_migration)
        self.assertIn("'center_correction'", workstream_migration)
        self.assertIn("'consultant_correction'", workstream_migration)


if __name__ == "__main__":
    unittest.main()

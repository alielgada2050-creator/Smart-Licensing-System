import copy
import importlib.util
import sys
import unittest
from pathlib import Path


LEGACY_APP_PATH = (
    Path(__file__).resolve().parents[1]
    / "حزمة_النشر_المتكاملة_انتغرافتى_وجيتهاب_Saudi_Energy_PDC_V3"
    / "main.py"
)
MODULE_NAME = "legacy_platform_api_under_test"
SPEC = importlib.util.spec_from_file_location(MODULE_NAME, LEGACY_APP_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Unable to load legacy API module at {LEGACY_APP_PATH}")
legacy_api = importlib.util.module_from_spec(SPEC)
sys.modules[MODULE_NAME] = legacy_api
SPEC.loader.exec_module(legacy_api)


class LegacyIntegrationGateTests(unittest.TestCase):
    def test_static_approval_code_never_creates_a_privileged_session(self):
        response = legacy_api.register_or_login(
            legacy_api.UserAuthRequest(
                full_name="Tester",
                email_or_phone="tester@example.com",
                requested_role="SUPER_ADMIN",
                approval_code="849206",
            )
        )

        self.assertEqual(response["status"], "AUTH_NOT_CONFIGURED")
        self.assertTrue(response["visitor_mode"])
        self.assertNotIn("role", response)

    def test_unauthenticated_field_action_does_not_change_permits_or_logs(self):
        permits_before = copy.deepcopy(legacy_api._DB["permits"])
        logs_before = copy.deepcopy(legacy_api._SITE_ENGINEER_LOGS)
        response = legacy_api.submit_site_engineer_action(
            legacy_api.SiteEngineerActionRequest(
                engineer_name="Tester",
                permit_no=str(permits_before[0].get("permit_id", "missing"))
                if permits_before
                else "missing",
                action_type="status_update",
                new_status="closed",
            )
        )

        self.assertEqual(response["status"], "AUTH_NOT_CONFIGURED")
        self.assertEqual(legacy_api._DB["permits"], permits_before)
        self.assertEqual(legacy_api._SITE_ENGINEER_LOGS, logs_before)

    def test_drive_sync_does_not_report_success_without_configuration(self):
        last_sync_before = legacy_api._LAST_4H_SYNC

        response = legacy_api.trigger_4hour_sync()

        self.assertEqual(response["status"], "SYNC_NOT_CONFIGURED")
        self.assertEqual(legacy_api._LAST_4H_SYNC, last_sync_before)


if __name__ == "__main__":
    unittest.main()

import unittest
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from main import (
    SiteEngineerActionRequest,
    UserAuthRequest,
    _DB,
    compute_urs_deadline,
    register_or_login,
    submit_site_engineer_action,
    trigger_4hour_sync,
)


class DeadlineApiTests(unittest.TestCase):
    def test_deadline_is_unconfigured_without_database_settings(self):
        result = compute_urs_deadline({"end_date": "2026-10-15"})
        self.assertEqual(result["status"], "UNCONFIGURED")
        self.assertIsNone(result["days_remaining"])

    def test_deadline_uses_supplied_settings_and_current_date(self):
        today = datetime.now(ZoneInfo("Asia/Riyadh")).date()
        result = compute_urs_deadline(
            {"end_date": (today - timedelta(days=5)).isoformat()},
            {
                "urs_report_grace_days": 10,
                "near_deadline_days": 6,
                "day_counting_mode": "calendar",
                "business_timezone": "Asia/Riyadh",
            },
        )
        self.assertEqual(result["status"], "NEAR")
        self.assertEqual(result["days_remaining"], 5)

    def test_invalid_settings_are_not_silently_defaulted(self):
        with self.assertRaises(ValueError):
            compute_urs_deadline(
                {"end_date": "2026-10-15"},
                {
                    "urs_report_grace_days": -1,
                    "near_deadline_days": 2,
                    "day_counting_mode": "calendar",
                    "business_timezone": "Asia/Riyadh",
                },
            )

    def test_invalid_business_timezone_fails(self):
        with self.assertRaisesRegex(ValueError, "business_timezone"):
            compute_urs_deadline(
                {"end_date": "2026-10-15"},
                {
                    "urs_report_grace_days": 10,
                    "near_deadline_days": 6,
                    "day_counting_mode": "calendar",
                    "business_timezone": "Not/A_Zone",
                },
            )

    def test_invalid_holiday_setting_fails_explicitly(self):
        with self.assertRaisesRegex(ValueError, "official_holidays"):
            compute_urs_deadline(
                {"end_date": "2026-10-15"},
                {
                    "urs_report_grace_days": 10,
                    "near_deadline_days": 6,
                    "day_counting_mode": "calendar",
                    "business_timezone": "Asia/Riyadh",
                    "official_holidays": ["not-a-date"],
                },
            )

    def test_fixed_approval_code_never_grants_access(self):
        result = register_or_login(
            UserAuthRequest(
                full_name="Test User",
                email_or_phone="test@example.com",
                requested_role="super_admin",
                approval_code="test-code",
            )
        )
        self.assertEqual(result["status"], "AUTH_PROVIDER_NOT_CONFIGURED")
        self.assertTrue(result["visitor_mode"])

    def test_unauthenticated_site_update_does_not_mutate_data(self):
        before = [dict(permit) for permit in _DB["permits"]]
        result = submit_site_engineer_action(
            SiteEngineerActionRequest(
                engineer_name="Test",
                permit_no="unknown",
                action_type="UPDATE",
                new_status="active",
            )
        )
        self.assertEqual(result["status"], "AUTH_PROVIDER_NOT_CONFIGURED")
        self.assertEqual(_DB["permits"], before)
        self.assertEqual(trigger_4hour_sync()["status"], "AUTH_PROVIDER_NOT_CONFIGURED")


if __name__ == "__main__":
    unittest.main()

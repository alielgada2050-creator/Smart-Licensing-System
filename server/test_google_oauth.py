import os
import unittest
from unittest.mock import patch

import main

try:
    from fastapi.testclient import TestClient
except ImportError:
    TestClient = None


OAUTH_ENV = {
    "GOOGLE_OAUTH_CLIENT_ID": "test-client-id",
    "GOOGLE_OAUTH_CLIENT_SECRET": "test-client-secret",
    "GOOGLE_OAUTH_REDIRECT_URI": "http://localhost:8000/api/auth/google/callback",
    "GOOGLE_MASTER_ADMIN_EMAIL": "admin@example.com",
    "SESSION_SIGNING_KEY": "test-session-signing-key-that-is-at-least-32-bytes",
    "AUTH_SESSION_TTL_SECONDS": "3600",
    "AUTH_COOKIE_SECURE": "false",
}


@unittest.skipIf(
    main.app is None or TestClient is None,
    "FastAPI and its test client are required for OAuth route tests",
)
class GoogleOAuthTests(unittest.TestCase):
    def setUp(self):
        self.environment = patch.dict(os.environ, OAUTH_ENV, clear=False)
        self.environment.start()
        self.client_context = TestClient(main.app)
        self.client = self.client_context.__enter__()

    def tearDown(self):
        self.client_context.__exit__(None, None, None)
        self.environment.stop()

    def test_oauth_start_uses_google_and_sets_state_cookie(self):
        response = self.client.get("/api/auth/google/start", follow_redirects=False)

        self.assertEqual(response.status_code, 302)
        self.assertIn("accounts.google.com/o/oauth2/v2/auth", response.headers["location"])
        self.assertIn("code_challenge_method=S256", response.headers["location"])
        self.assertIn("permit_oauth_state", response.headers["set-cookie"])

    @patch("main._google_userinfo")
    @patch("main._google_post_form")
    def test_allowlisted_google_account_receives_master_session(
        self, post_form, userinfo
    ):
        post_form.return_value = {"access_token": "temporary-test-token"}
        userinfo.return_value = {
            "sub": "google-user-123",
            "email": "ADMIN@example.com",
            "email_verified": True,
            "name": "Platform Owner",
        }
        start = self.client.get("/api/auth/google/start", follow_redirects=False)
        state = start.headers["location"].split("state=", 1)[1].split("&", 1)[0]

        callback = self.client.get(
            f"/api/auth/google/callback?code=one-time-code&state={state}",
            follow_redirects=False,
        )

        self.assertEqual(callback.status_code, 303)
        self.assertEqual(callback.headers["location"], "/app?auth=master")
        session = self.client.get("/api/auth/me")
        self.assertEqual(
            session.json(),
            {
                "oauth_configured": True,
                "authenticated": True,
                "email": "admin@example.com",
                "name": "Platform Owner",
                "role": "super_admin",
            },
        )
        self.assertEqual(
            post_form.call_args.args[1]["code_verifier"],
            main._verify_signed_payload(
                start.cookies[main.OAUTH_STATE_COOKIE]
            )["verifier"],
        )

    @patch("main._google_userinfo")
    @patch("main._google_post_form")
    def test_non_allowlisted_account_is_read_only(self, post_form, userinfo):
        post_form.return_value = {"access_token": "temporary-test-token"}
        userinfo.return_value = {
            "sub": "google-user-456",
            "email": "staff@example.com",
            "email_verified": True,
            "name": "Staff User",
        }
        start = self.client.get("/api/auth/google/start", follow_redirects=False)
        state = start.headers["location"].split("state=", 1)[1].split("&", 1)[0]

        callback = self.client.get(
            f"/api/auth/google/callback?code=one-time-code&state={state}",
            follow_redirects=False,
        )

        self.assertEqual(callback.headers["location"], "/app?auth=viewer")
        self.assertEqual(self.client.get("/api/auth/me").json()["role"], "viewer")

    def test_invalid_oauth_state_is_rejected(self):
        response = self.client.get(
            "/api/auth/google/callback?code=one-time-code&state=forged",
            follow_redirects=False,
        )

        self.assertEqual(response.status_code, 400)

    def test_tampered_session_signature_is_rejected(self):
        session = main._sign_payload(
            {
                "sub": "google-user",
                "email": "admin@example.com",
                "name": "Admin",
                "exp": 9999999999,
            }
        )
        encoded, signature = session.split(".", 1)
        tampered_signature = ("A" if signature[0] != "A" else "B") + signature[1:]
        tampered = f"{encoded}.{tampered_signature}"

        self.assertIsNone(main._user_from_session(tampered))


class GoogleOAuthSessionTests(unittest.TestCase):
    def setUp(self):
        self.environment = patch.dict(os.environ, OAUTH_ENV, clear=False)
        self.environment.start()

    def tearDown(self):
        self.environment.stop()

    def test_signed_sessions_assign_master_only_to_exact_allowlisted_email(self):
        admin_session = main._sign_payload(
            {
                "sub": "google-user",
                "email": "ADMIN@example.com",
                "name": "Admin",
                "exp": 9999999999,
            }
        )
        other_session = main._sign_payload(
            {
                "sub": "google-user-2",
                "email": "other@example.com",
                "name": "Other",
                "exp": 9999999999,
            }
        )

        self.assertEqual(main._user_from_session(admin_session)["role"], "super_admin")
        self.assertEqual(main._user_from_session(other_session)["role"], "viewer")


if __name__ == "__main__":
    unittest.main()

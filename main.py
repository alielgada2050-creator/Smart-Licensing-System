"""
منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC (الإصدار المؤسسي V3.0)
خادم الواجهة البرمجية الخلفية والمنصة (FastAPI + Zero-Dependency Built-in Server Fallback)
يخدم قاعدة البيانات الحقيقية الكاملة:
- 946 رخصة بلدية وهندسية (موزعة على 11 فئة)
- 85 عمل تنسيق أسبوعي ميداني (P0 - P3)
- 73 فحص مختبر URS + مهل يحددها المشرف من الإعدادات
- 64 رخصة PDF مستخرجة عبر OCR
- 41 مهمة أودو ERP + 12 سجل فحص SEC QA/QC
- 15 وكيلاً ذكياً + مزامنة كل 4 ساعات + إشراف عام: مشرف علي الجدع (0597778853 | alielgada5@gmail.com)
"""

from __future__ import annotations

import json
import os
import base64
import hashlib
import hmac
import secrets
import time
from dataclasses import dataclass
from datetime import date, datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import parse_qs, quote, urlencode, urlparse
from urllib.request import Request as UrlRequest, urlopen
from urllib.error import HTTPError, URLError
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
from server.domain import calculate_due_date, classify_deadline

APP_DIR = Path(__file__).resolve().parent
EXPANDED_DB_PATH = APP_DIR / "assets" / "data" / "enterprise_db_expanded.json"
INDEX_HTML_PATH = APP_DIR / "index.html"
from dotenv import load_dotenv

load_dotenv(APP_DIR / ".env")
OAUTH_STATE_COOKIE = "permit_oauth_state"
SESSION_COOKIE = "permit_session"
OAUTH_STATE_TTL_SECONDS = 600
DEFAULT_SESSION_TTL_SECONDS = 8 * 60 * 60


class OAuthConfigurationError(RuntimeError):
    pass


def _b64url_encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def _b64url_decode(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def _session_signing_key() -> bytes:
    key = os.environ.get("SESSION_SIGNING_KEY", "")
    if len(key) < 32:
        raise OAuthConfigurationError(
            "SESSION_SIGNING_KEY must contain at least 32 characters."
        )
    return key.encode("utf-8")


def _oauth_config() -> Dict[str, str]:
    config = {
        "client_id": os.environ.get("GOOGLE_OAUTH_CLIENT_ID", "").strip(),
        "client_secret": os.environ.get("GOOGLE_OAUTH_CLIENT_SECRET", "").strip(),
        "redirect_uri": os.environ.get("GOOGLE_OAUTH_REDIRECT_URI", "").strip(),
        "master_email": os.environ.get("GOOGLE_MASTER_ADMIN_EMAIL", "").strip().lower(),
    }
    if not all(config.values()):
        raise OAuthConfigurationError(
            "Google OAuth credentials, redirect URI, and master email must be configured."
        )
    parsed_redirect = urlparse(config["redirect_uri"])
    if parsed_redirect.scheme != "https" and parsed_redirect.hostname not in (
        "localhost",
        "127.0.0.1",
    ):
        raise OAuthConfigurationError(
            "Google OAuth redirect URI must use HTTPS except on localhost."
        )
    cookie_options = _cookie_options(0)
    if parsed_redirect.hostname not in ("localhost", "127.0.0.1") and not cookie_options[
        "secure"
    ]:
        raise OAuthConfigurationError(
            "AUTH_COOKIE_SECURE must be true when Google OAuth uses a public host."
        )
    _session_signing_key()
    return config


def _sign_payload(payload: Dict[str, Any]) -> str:
    encoded = _b64url_encode(
        json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
    )
    signature = hmac.new(
        _session_signing_key(), encoded.encode("ascii"), hashlib.sha256
    ).digest()
    return f"{encoded}.{_b64url_encode(signature)}"


def _verify_signed_payload(token: str) -> Optional[Dict[str, Any]]:
    try:
        encoded, supplied_signature = token.split(".", 1)
        expected_signature = hmac.new(
            _session_signing_key(), encoded.encode("ascii"), hashlib.sha256
        ).digest()
        if not hmac.compare_digest(
            expected_signature, _b64url_decode(supplied_signature)
        ):
            return None
        payload = json.loads(_b64url_decode(encoded))
        if not isinstance(payload, dict) or int(payload.get("exp", 0)) <= int(time.time()):
            return None
        return payload
    except (ValueError, TypeError, json.JSONDecodeError, OAuthConfigurationError):
        return None


def _session_ttl_seconds() -> int:
    raw_ttl = os.environ.get(
        "AUTH_SESSION_TTL_SECONDS", str(DEFAULT_SESSION_TTL_SECONDS)
    )
    try:
        ttl = int(raw_ttl)
    except ValueError as error:
        raise OAuthConfigurationError("AUTH_SESSION_TTL_SECONDS must be an integer.") from error
    if not 300 <= ttl <= 24 * 60 * 60:
        raise OAuthConfigurationError(
            "AUTH_SESSION_TTL_SECONDS must be between 300 and 86400."
        )
    return ttl


def _cookie_options(max_age: int) -> Dict[str, Any]:
    secure = os.environ.get("AUTH_COOKIE_SECURE", "true").strip().lower()
    if secure not in ("true", "false"):
        raise OAuthConfigurationError("AUTH_COOKIE_SECURE must be true or false.")
    return {
        "httponly": True,
        "secure": secure == "true",
        "samesite": "lax",
        "path": "/",
        "max_age": max_age,
    }


def _user_from_session(token: Optional[str]) -> Optional[Dict[str, str]]:
    if not token:
        return None
    payload = _verify_signed_payload(token)
    if not payload:
        return None
    email = str(payload.get("email", "")).strip().lower()
    subject = str(payload.get("sub", "")).strip()
    name = str(payload.get("name", "")).strip()
    if not email or not subject:
        return None
    master_email = os.environ.get("GOOGLE_MASTER_ADMIN_EMAIL", "").strip().lower()
    return {
        "email": email,
        "name": name or email,
        "role": "super_admin" if master_email and email == master_email else "viewer",
    }


def _google_post_form(url: str, values: Dict[str, str]) -> Dict[str, Any]:
    request = UrlRequest(
        url,
        data=urlencode(values).encode("utf-8"),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=10) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as error:
        raise OAuthConfigurationError("Google OAuth request failed.") from error
    if not isinstance(payload, dict):
        raise OAuthConfigurationError("Google OAuth returned an invalid response.")
    return payload


def _google_userinfo(access_token: str) -> Dict[str, Any]:
    request = UrlRequest(
        "https://openidconnect.googleapis.com/v1/userinfo",
        headers={"Authorization": f"Bearer {access_token}"},
        method="GET",
    )
    try:
        with urlopen(request, timeout=10) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as error:
        raise OAuthConfigurationError("Google identity verification failed.") from error
    if not isinstance(payload, dict):
        raise OAuthConfigurationError("Google returned an invalid identity response.")
    return payload

# ============================================================================
# تحميل قاعدة البيانات الحقيقية الكاملة عند بدء التشغيل
# ============================================================================
_DB: Dict[str, Any] = {
    "permits": [],
    "coordination": [],
    "urs": [],
    "pdfs": [],
    "odoo": [],
    "sec": [],
}
_SITE_ENGINEER_LOGS: List[Dict[str, Any]] = []
_SUPPORT_TICKETS: List[Dict[str, Any]] = []


def load_enterprise_database() -> None:
    global _DB
    if EXPANDED_DB_PATH.exists():
        with open(EXPANDED_DB_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            _DB["permits"] = data.get("permits", [])
            _DB["coordination"] = data.get("coordination", [])
            _DB["urs"] = data.get("urs_inspections", [])
            _DB["pdfs"] = data.get("pdf_licenses", [])
            _DB["odoo"] = data.get("odoo_tasks", [])
            _DB["sec"] = data.get("sec_qaqc", [])


load_enterprise_database()


def compute_urs_deadline(
    permit: Dict[str, Any],
    settings: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Calculate a URS deadline only when its administrator-managed settings exist."""
    cat = str(permit.get("category", "") or "")
    if cat == "مغلقة (تم الإغلاق)":
        return {
            "status": "COMPLETED",
            "badge_ar": "مغلقة نهائياً",
            "days_remaining": None,
        }
    source_settings = settings or {}
    grace_days = source_settings.get("urs_report_grace_days")
    near_days = source_settings.get("near_deadline_days")
    end_str = str(permit.get("end_date", "") or "").strip()[:10]
    counting_mode = source_settings.get("day_counting_mode")
    business_timezone = source_settings.get("business_timezone")
    if (
        not end_str
        or grace_days is None
        or near_days is None
        or counting_mode is None
        or business_timezone is None
    ):
        return {
            "status": "UNCONFIGURED",
            "badge_ar": "إعدادات المهلة أو تاريخ الانتهاء غير متاح",
            "days_remaining": None,
        }
    if (
        not isinstance(grace_days, int)
        or isinstance(grace_days, bool)
        or not isinstance(near_days, int)
        or isinstance(near_days, bool)
        or not isinstance(counting_mode, str)
        or not isinstance(business_timezone, str)
        or min(grace_days, near_days) < 0
    ):
        raise ValueError("Deadline settings must be non-negative integers")
    holiday_values = source_settings.get("official_holidays", [])
    weekend_values = source_settings.get("weekend_days")
    if not isinstance(holiday_values, list):
        raise ValueError("official_holidays setting must be a list")
    if any(not isinstance(value, str) for value in holiday_values):
        raise ValueError("official_holidays entries must be ISO dates")
    if isinstance(weekend_values, list) and any(
        not isinstance(value, int) or isinstance(value, bool) for value in weekend_values
    ):
        raise ValueError("weekend_days entries must be weekday numbers")
    try:
        holidays = frozenset(date.fromisoformat(value) for value in holiday_values)
    except ValueError as error:
        raise ValueError("official_holidays setting must contain valid ISO dates") from error
    try:
        weekends = (
            frozenset(weekend_values)
            if isinstance(weekend_values, list)
            else None
        )
        start_date = date.fromisoformat(end_str)
    except ValueError:
        return {
            "status": "INVALID_DATE",
            "badge_ar": "تاريخ انتهاء الرخصة غير صالح",
            "days_remaining": None,
        }
    deadline = calculate_due_date(
        start_date,
        grace_days,
        counting_mode=counting_mode,
        weekend_days=weekends,
        official_holidays=holidays,
    )
    try:
        business_today = datetime.now(ZoneInfo(business_timezone)).date()
    except ZoneInfoNotFoundError as error:
        raise ValueError("business_timezone setting is invalid") from error
    deadline_status = classify_deadline(
        deadline,
        business_today,
        near_days,
        counting_mode=counting_mode,
        weekend_days=weekends,
        official_holidays=holidays,
    )
    rem = deadline_status.days_remaining
    if rem < 0:
        return {
            "status": "OVERDUE",
            "badge_ar": f"متأخر {abs(rem)} يوم",
            "days_remaining": rem,
            "deadline": deadline.strftime("%Y-%m-%d"),
        }
    if rem <= near_days:
        return {
            "status": "NEAR",
            "badge_ar": f"قريب من الاستحقاق: {rem} يوم",
            "days_remaining": rem,
            "deadline": deadline.strftime("%Y-%m-%d"),
        }
    return {
        "status": "NORMAL",
        "badge_ar": f"{rem} يوم متبقي",
        "days_remaining": rem,
        "deadline": deadline.strftime("%Y-%m-%d"),
    }


# ============================================================================
# نماذج البيانات (تعمل مع Pydantic أو بدونها)
# ============================================================================
try:
    from pydantic import BaseModel

    class UserAuthRequest(BaseModel):
        full_name: str
        email_or_phone: str
        requested_role: str = "VISITOR"
        approval_code: Optional[str] = None

    class SiteEngineerActionRequest(BaseModel):
        engineer_name: str
        permit_no: str
        action_type: str
        new_status: str
        urs_status: Optional[str] = None
        notes: str = ""
        lat: float = 24.7136
        lng: float = 46.6753

    class AgentQueryRequest(BaseModel):
        prompt: str
        agent_code: str = "AG-15"

    class SupportTicketRequest(BaseModel):
        sender_name: str
        sender_phone: str
        permit_no: Optional[str] = ""
        request_type: str = "طلب صلاحية / دعم فني"
        message: str

except ImportError:

    @dataclass
    class UserAuthRequest:  # type: ignore[no-redef]
        full_name: str
        email_or_phone: str
        requested_role: str = "VISITOR"
        approval_code: Optional[str] = None

    @dataclass
    class SiteEngineerActionRequest:  # type: ignore[no-redef]
        engineer_name: str
        permit_no: str
        action_type: str
        new_status: str
        urs_status: Optional[str] = None
        notes: str = ""
        lat: float = 24.7136
        lng: float = 46.6753

    @dataclass
    class AgentQueryRequest:  # type: ignore[no-redef]
        prompt: str
        agent_code: str = "AG-15"

    @dataclass
    class SupportTicketRequest:  # type: ignore[no-redef]
        sender_name: str
        sender_phone: str
        permit_no: Optional[str] = ""
        request_type: str = "طلب صلاحية / دعم فني"
        message: str = ""


# ============================================================================
# خدمات الأعمال والمنطق الأساسي (Core Business Logic)
# ============================================================================
def read_root() -> Dict[str, Any]:
    return {
        "platform": "منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC",
        "version": "3.0.0",
        "status": "ONLINE",
        "counts": {
            "total_permits": len(_DB["permits"]),
            "weekly_coordination_works": len(_DB["coordination"]),
            "urs_lab_inspections": len(_DB["urs"]),
            "pdf_ocr_licenses": len(_DB["pdfs"]),
            "odoo_erp_tasks": len(_DB["odoo"]),
            "sec_qaqc_records": len(_DB["sec"]),
            "ai_agents": 15,
            "standard_reports": 20,
        },
        "general_supervisor": {
            "name": "مشرف علي الجدع",
            "role": "المشرف العام على الرخص ومختبر URS وإغلاق مهام أودو وتصاريح الدخول",
            "phone": "0597778853",
            "whatsapp": "https://wa.me/966597778853",
            "telegram": "https://t.me/+966597778853",
            "email": "alielgada5@gmail.com",
        },
        "external_integrations": {
            "odoo_url": "https://alasas.odoo.com/web#cids=1&action=menu",
            "sync_enabled": False,
            "last_sync": None,
        },
        "web_ui_url": "/app",
    }


def get_executive_stats() -> Dict[str, Any]:
    permits = _DB["permits"]
    categories_breakdown: Dict[str, int] = {}
    sla_counts = {"COMPLETED": 0, "OVERDUE": 0, "NEAR": 0, "NORMAL": 0, "UNCONFIGURED": 0}

    for p in permits:
        ck = str(p.get("category", "UNKNOWN"))
        categories_breakdown[ck] = categories_breakdown.get(ck, 0) + 1
        sla = compute_urs_deadline(p)
        st = sla["status"]
        sla_counts[st] = sla_counts.get(st, 0) + 1

    coord = _DB["coordination"]
    priority_breakdown: Dict[str, int] = {}
    sector_breakdown: Dict[str, int] = {}
    for c in coord:
        pr = str(c.get("priority_tier", "P2"))[:2]
        sec = str(c.get("office", "مكتب خريص"))
        priority_breakdown[pr] = priority_breakdown.get(pr, 0) + 1
        sector_breakdown[sec] = sector_breakdown.get(sec, 0) + 1

    return {
        "total_permits": len(permits),
        "categories_breakdown": categories_breakdown,
        "urs_60_day_sla": sla_counts,
        "coordination_total": len(coord),
        "coordination_by_priority": priority_breakdown,
        "coordination_by_sector": sector_breakdown,
        "urs_inspections_total": len(_DB["urs"]),
        "pdf_ocr_total": len(_DB["pdfs"]),
        "odoo_tasks_total": len(_DB["odoo"]),
        "sec_qaqc_total": len(_DB["sec"]),
        "site_engineer_logs_count": len(_SITE_ENGINEER_LOGS),
        "last_4h_sync": None,
    }


def list_permits(
    category: Optional[str] = None,
    municipality: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
) -> Dict[str, Any]:
    t0 = time.perf_counter()
    results = _DB["permits"]

    if category and category != "ALL":
        results = [p for p in results if category in str(p.get("category", ""))]

    if municipality and municipality != "ALL":
        results = [p for p in results if municipality in str(p.get("district", ""))]

    if search and search.strip():
        q = search.strip().lower()
        results = [
            p
            for p in results
            if q in str(p.get("permit_id", "")).lower()
            or q in str(p.get("base_no", "")).lower()
            or q in str(p.get("scheme_no", "")).lower()
            or q in str(p.get("transaction_no", "")).lower()
            or q in str(p.get("district", "")).lower()
            or q in str(p.get("category", "")).lower()
            or q in str(p.get("notes", "")).lower()
            or q in str(p.get("consultant", "")).lower()
        ]

    elapsed_ms = round((time.perf_counter() - t0) * 1000, 2)
    sliced = results[offset : offset + limit]
    return {
        "total_matched": len(results),
        "limit": limit,
        "offset": offset,
        "elapsed_ms": elapsed_ms,
        "items": sliced,
    }


def get_permit_13_tabs_profile(permit_id: str) -> Optional[Dict[str, Any]]:
    q = permit_id.strip()
    for p in _DB["permits"]:
        pid = str(p.get("permit_id", ""))
        base_no = str(p.get("base_no", ""))
        if pid == q or base_no == q or q in pid:
            sla = compute_urs_deadline(p)
            related_urs = [u for u in _DB["urs"] if q in str(u.get("permit_id", ""))]
            related_coord = [
                c
                for c in _DB["coordination"]
                if q in str(c.get("matched_permit_id", "")) or q in str(c.get("base_no", ""))
            ]
            related_pdfs = [d for d in _DB["pdfs"] if q in str(d.get("permit_id", ""))]
            return {
                "permit": p,
                "urs_60_day_sla": sla,
                "related_urs_inspections": related_urs,
                "related_coordination_items": related_coord,
                "related_pdf_ocr": related_pdfs,
                "supervisor": {
                    "name": "مشرف علي الجدع",
                    "phone": "0597778853",
                    "email": "alielgada5@gmail.com",
                },
            }
    return None


def list_coordination_works(
    sector: Optional[str] = None,
    priority: Optional[str] = None,
    supervisor: Optional[str] = None,
    search: Optional[str] = None,
) -> Dict[str, Any]:
    items = _DB["coordination"]
    if sector and sector != "ALL":
        items = [c for c in items if sector in str(c.get("office", ""))]
    if priority and priority != "ALL":
        items = [c for c in items if str(c.get("priority_tier", "")).startswith(priority)]
    if supervisor and supervisor != "ALL":
        items = [c for c in items if supervisor in str(c.get("assigned_supervisor", ""))]
    if search and search.strip():
        q = search.strip().lower()
        items = [
            c
            for c in items
            if q in str(c.get("matched_permit_id", "")).lower()
            or q in str(c.get("base_no", "")).lower()
            or q in str(c.get("transaction_no", "")).lower()
            or q in str(c.get("district", "")).lower()
        ]
    return {"total": len(items), "items": items}


def list_urs_inspections() -> Dict[str, Any]:
    return {"total": len(_DB["urs"]), "items": _DB["urs"]}


def list_pdf_ocr_licenses() -> Dict[str, Any]:
    return {"total": len(_DB["pdfs"]), "items": _DB["pdfs"]}


def list_odoo_tasks() -> Dict[str, Any]:
    return {
        "total": len(_DB["odoo"]),
        "odoo_portal_url": "https://alasas.odoo.com/web#cids=1&action=menu",
        "supervisor": "مشرف علي الجدع (alielgada5@gmail.com | 0597778853)",
        "items": _DB["odoo"],
    }


def trigger_4hour_sync() -> Dict[str, Any]:
    return {
        "status": "AUTH_PROVIDER_NOT_CONFIGURED",
        "message_ar": "المزامنة معطلة حتى إعداد المصادقة ومصدر البيانات الفعلي.",
    }


def query_egyptian_ai_agent(req: AgentQueryRequest) -> Dict[str, Any]:
    t0 = time.perf_counter()
    q = req.prompt.strip()
    total_p = len(_DB["permits"])
    ret_count = sum(1 for p in _DB["permits"] if "معاد" in str(p.get("category", "")))
    urs_count = len(_DB["urs"])
    coord_count = len(_DB["coordination"])

    matched_permit = None
    for p in _DB["permits"]:
        if (
            q == str(p.get("permit_id", ""))
            or q.upper() == str(p.get("base_no", "")).upper()
            or (len(q) >= 5 and q in str(p.get("permit_id", "")))
        ):
            matched_permit = p
            break

    if matched_permit:
        sla = compute_urs_deadline(matched_permit)
        reply = (
            f"يا باشمهندس، فحصت لك الرخصة رقم {matched_permit.get('permit_id')} (الأساس {matched_permit.get('base_no')}) فوراً: "
            f"الحي ({matched_permit.get('district')})، الفئة ({matched_permit.get('category')})، "
            f"الاستشاري ({matched_permit.get('consultant')})، "
            f"وحالة المختبر URS ({matched_permit.get('urs_result')} — {sla['badge_ar']}). "
            f"تحت إشراف المشرف علي الجدع (0597778853)."
        )
    else:
        reply = (
            f"أهلاً بحضرتك يا باشمهندس معاك المساعد الذكي ({req.agent_code}). "
            f"إجمالي الرخص في المنصة {total_p} رخصة حقيقية، منها {ret_count} رخصة معادة جاري معالجتها، "
            f"و{urs_count} فحص مختبر URS، بالإضافة إلى {coord_count} عمل في جدول التنسيق الأسبوعي. "
            f"لأي اعتماد أو إغلاق في أودو تواصل مع المشرف علي الجدع على 0597778853 أو alielgada5@gmail.com."
        )

    elapsed_ms = round((time.perf_counter() - t0) * 1000, 2)
    return {
        "agent_code": req.agent_code,
        "voice_profile": "ar-EG-Male (pitch=0.85)",
        "elapsed_ms": elapsed_ms,
        "reply": reply,
    }


def register_or_login(req: UserAuthRequest) -> Dict[str, Any]:
    return {
        "status": "AUTH_PROVIDER_NOT_CONFIGURED",
        "visitor_mode": True,
        "message": (
            "لم يتم إعداد مزود مصادقة؛ لم تُمنح أي صلاحية من بيانات الطلب أو رمز اعتماد."
        ),
    }


def submit_site_engineer_action(req: SiteEngineerActionRequest) -> Dict[str, Any]:
    return {
        "status": "AUTH_PROVIDER_NOT_CONFIGURED",
        "message": "لم يُحفظ التعديل؛ المصادقة ونطاق الصلاحية وسجل التدقيق غير مفعّلة.",
    }


def create_support_ticket(req: SupportTicketRequest) -> Dict[str, Any]:
    ticket = {
        "ticket_id": f"SUP-{len(_SUPPORT_TICKETS) + 1001}",
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "sender_name": req.sender_name,
        "sender_phone": req.sender_phone,
        "permit_no": req.permit_no,
        "request_type": req.request_type,
        "message": req.message,
        "assigned_to": "مشرف علي الجدع (0597778853 | alielgada5@gmail.com)",
    }
    _SUPPORT_TICKETS.insert(0, ticket)
    wa_text = quote(
        f"تحية طيبة مشرف علي الجدع،\n"
        f"تذكرة رقم: {ticket['ticket_id']}\n"
        f"المرسل: {req.sender_name} ({req.sender_phone})\n"
        f"الرخصة: {req.permit_no}\n"
        f"الطلب: {req.request_type}\n"
        f"التفاصيل: {req.message}"
    )
    return {
        "status": "CREATED",
        "ticket": ticket,
        "direct_links": {
            "whatsapp": f"https://wa.me/966597778853?text={wa_text}",
            "telegram": "https://t.me/+966597778853",
            "mailto": f"mailto:alielgada5@gmail.com?subject={quote(req.request_type)}&body={wa_text}",
        },
    }


# ============================================================================
# ربط FastAPI إن كانت المكتبة مثبتة
# ============================================================================
try:
    from fastapi import FastAPI, HTTPException, Query, Request, Response
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import FileResponse, HTMLResponse, RedirectResponse

    app = FastAPI(
        title="Saudi Energy & PDC Smart Licenses Platform API V3.0",
        description=(
            "منظومة الإدارة الذكية للرخص — الشركة السعودية للطاقة & PDC | "
            "946 رخصة | 85 عمل تنسيق | 73 مختبر URS | 15 وكيلاً ذكياً | "
            "إشراف عام: مشرف علي الجدع (alielgada5@gmail.com | 0597778853)"
        ),
        version="3.0.0",
    )

    allowed_origins = [
        origin.strip()
        for origin in os.environ.get(
            "CORS_ALLOWED_ORIGINS", "http://localhost:8000"
        ).split(",")
        if origin.strip()
    ]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type"],
    )

    app.get("/")(read_root)
    app.post("/api/support/ticket")(create_support_ticket)

    @app.get("/api/auth/google/start")
    def google_oauth_start() -> Any:
        try:
            config = _oauth_config()
            state = secrets.token_urlsafe(32)
            verifier = _b64url_encode(secrets.token_bytes(32))
            challenge = _b64url_encode(
                hashlib.sha256(verifier.encode("ascii")).digest()
            )
            now = int(time.time())
            signed_state = _sign_payload(
                {"state": state, "verifier": verifier, "exp": now + OAUTH_STATE_TTL_SECONDS}
            )
            authorization_url = "https://accounts.google.com/o/oauth2/v2/auth?" + urlencode(
                {
                    "client_id": config["client_id"],
                    "redirect_uri": config["redirect_uri"],
                    "response_type": "code",
                    "scope": "openid email profile",
                    "state": state,
                    "code_challenge": challenge,
                    "code_challenge_method": "S256",
                    "prompt": "select_account",
                }
            )
            response = RedirectResponse(authorization_url, status_code=302)
            response.set_cookie(
                OAUTH_STATE_COOKIE,
                signed_state,
                **_cookie_options(OAUTH_STATE_TTL_SECONDS),
            )
            return response
        except OAuthConfigurationError as error:
            raise HTTPException(status_code=503, detail=str(error)) from error

    @app.get("/api/auth/google/callback")
    def google_oauth_callback(request: Request) -> Any:
        config: Dict[str, str]
        try:
            config = _oauth_config()
            signed_state = request.cookies.get(OAUTH_STATE_COOKIE, "")
            state_payload = _verify_signed_payload(signed_state)
            returned_state = request.query_params.get("state", "")
            authorization_code = request.query_params.get("code", "")
            if (
                not state_payload
                or not returned_state
                or not hmac.compare_digest(
                    str(state_payload.get("state", "")), returned_state
                )
                or not authorization_code
            ):
                raise HTTPException(
                    status_code=400,
                    detail="OAuth state is missing, invalid, or expired. Please retry login.",
                )

            token_response = _google_post_form(
                "https://oauth2.googleapis.com/token",
                {
                    "client_id": config["client_id"],
                    "client_secret": config["client_secret"],
                    "code": authorization_code,
                    "code_verifier": str(state_payload["verifier"]),
                    "grant_type": "authorization_code",
                    "redirect_uri": config["redirect_uri"],
                },
            )
            access_token = token_response.get("access_token")
            if not isinstance(access_token, str) or not access_token:
                raise OAuthConfigurationError("Google did not return an access token.")
            profile = _google_userinfo(access_token)
            email = str(profile.get("email", "")).strip().lower()
            subject = str(profile.get("sub", "")).strip()
            verified = profile.get("email_verified") is True or str(
                profile.get("email_verified", "")
            ).lower() == "true"
            if not email or not subject or not verified:
                raise HTTPException(
                    status_code=403,
                    detail="Google account email is missing or not verified.",
                )

            ttl = _session_ttl_seconds()
            session = _sign_payload(
                {
                    "sub": subject,
                    "email": email,
                    "name": str(profile.get("name", "")).strip() or email,
                    "exp": int(time.time()) + ttl,
                }
            )
            role = "super_admin" if email == config["master_email"] else "viewer"
            response = RedirectResponse(
                "/app?auth=master" if role == "super_admin" else "/app?auth=viewer",
                status_code=303,
            )
            response.set_cookie(SESSION_COOKIE, session, **_cookie_options(ttl))
            response.delete_cookie(
                OAUTH_STATE_COOKIE,
                path="/",
                secure=_cookie_options(0)["secure"],
                httponly=True,
                samesite="lax",
            )
            return response
        except HTTPException:
            raise
        except OAuthConfigurationError as error:
            raise HTTPException(
                status_code=502, detail="Google sign-in could not be completed."
            ) from error

    @app.get("/api/auth/me")
    def google_oauth_session(request: Request) -> Dict[str, Any]:
        try:
            _oauth_config()
            user = _user_from_session(request.cookies.get(SESSION_COOKIE))
        except OAuthConfigurationError:
            return {"oauth_configured": False, "authenticated": False, "role": "visitor"}
        if not user:
            return {"oauth_configured": True, "authenticated": False, "role": "visitor"}
        return {"oauth_configured": True, "authenticated": True, **user}

    @app.post("/api/auth/logout")
    def google_oauth_logout() -> Response:
        response = Response(status_code=204)
        cookie_options = _cookie_options(0)
        response.delete_cookie(
            SESSION_COOKIE,
            path="/",
            secure=cookie_options["secure"],
            httponly=True,
            samesite="lax",
        )
        return response

    def api_auth_not_configured() -> Any:
        raise HTTPException(
            status_code=503,
            detail="This endpoint is unavailable until a trusted identity provider and scoped data access are configured.",
        )

    app.get("/api/stats")(api_auth_not_configured)
    app.get("/api/permits")(api_auth_not_configured)
    app.get("/api/coordination")(api_auth_not_configured)
    app.get("/api/urs")(api_auth_not_configured)
    app.get("/api/ocr")(api_auth_not_configured)
    app.get("/api/odoo")(api_auth_not_configured)
    app.post("/api/agents/query")(api_auth_not_configured)
    app.post("/api/auth/register-or-login")(api_auth_not_configured)

    @app.post("/api/sync/4h")
    def fastapi_sync_disabled() -> Dict[str, Any]:
        raise HTTPException(
            status_code=503,
            detail="Synchronization is disabled until authentication and a real data source are configured.",
        )

    @app.post("/api/site-engineer/action")
    def fastapi_site_action_disabled(req: SiteEngineerActionRequest) -> Dict[str, Any]:
        raise HTTPException(
            status_code=503,
            detail="The change was not saved; authentication, authorization, and audit storage are not configured.",
        )

    @app.get("/app", response_class=HTMLResponse)
    def serve_web_platform() -> Any:
        if INDEX_HTML_PATH.exists():
            return FileResponse(INDEX_HTML_PATH, media_type="text/html; charset=utf-8")
        raise HTTPException(status_code=404, detail="ملف المنصة index.html غير موجود")

    @app.get("/api/permits/{permit_id}")
    def fastapi_get_permit(permit_id: str) -> Any:
        return api_auth_not_configured()

except ImportError:
    app = None  # type: ignore[assignment]


# ============================================================================
# خادم HTTP مدمج بدون أي اعتماديات خارجية (يعمل فوراً بأمر python main.py)
# ============================================================================
class BuiltinEnterpriseHandler(BaseHTTPRequestHandler):
    def _send_json(self, payload: Any, status: int = 200) -> None:
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        path = parsed.path
        qs = parse_qs(parsed.query)

        if path.startswith("/api/"):
            self._send_json(
                {
                    "error": "AUTH_PROVIDER_NOT_CONFIGURED",
                    "message": "API data access is disabled until trusted authentication and row scoping are configured.",
                },
                status=503,
            )
            return

        if path in ("/app", "/index.html"):
            if INDEX_HTML_PATH.exists():
                raw = INDEX_HTML_PATH.read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(raw)))
                self.end_headers()
                self.wfile.write(raw)
                return
            self._send_json({"error": "index.html not found"}, status=404)
            return

        if path == "/":
            self._send_json(read_root())
        elif path == "/api/stats":
            self._send_json(get_executive_stats())
        elif path == "/api/permits":
            self._send_json(
                list_permits(
                    category=qs.get("category", [None])[0],
                    municipality=qs.get("municipality", [None])[0],
                    search=qs.get("search", [None])[0],
                    limit=int(qs.get("limit", ["100"])[0]),
                    offset=int(qs.get("offset", ["0"])[0]),
                )
            )
        elif path.startswith("/api/permits/"):
            pid = path.split("/api/permits/", 1)[1]
            res = get_permit_13_tabs_profile(pid)
            if res:
                self._send_json(res)
            else:
                self._send_json({"error": "Permit not found"}, status=404)
        elif path == "/api/coordination":
            self._send_json(
                list_coordination_works(
                    sector=qs.get("sector", [None])[0],
                    priority=qs.get("priority", [None])[0],
                    supervisor=qs.get("supervisor", [None])[0],
                    search=qs.get("search", [None])[0],
                )
            )
        elif path == "/api/urs":
            self._send_json(list_urs_inspections())
        elif path == "/api/ocr":
            self._send_json(list_pdf_ocr_licenses())
        elif path == "/api/odoo":
            self._send_json(list_odoo_tasks())
        else:
            self._send_json({"error": "Not found", "path": path}, status=404)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8000"))
    try:
        import uvicorn

        if app is not None:
            print(f"تشغيل خادم FastAPI/Uvicorn على المنفذ http://127.0.0.1:{port} (المنصة: /app)")
            uvicorn.run(app, host="0.0.0.0", port=port)
        else:
            raise ImportError
    except ImportError:
        print(f"تشغيل الخادم المدمج المباشر على الرابط http://127.0.0.1:{port} (المنصة: http://127.0.0.1:{port}/app)")
        server = HTTPServer(("0.0.0.0", port), BuiltinEnterpriseHandler)
        server.serve_forever()

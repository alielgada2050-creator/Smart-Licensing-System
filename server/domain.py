from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from enum import StrEnum
from typing import Any, Mapping


class DeadlineKind(StrEnum):
    URS_REPORT = "urs_report"
    RETURN_CORRECTION = "return_correction"
    RENEWAL = "renewal"


DEADLINE_SETTINGS_KEYS = {
    DeadlineKind.URS_REPORT: "urs_report_grace_days",
    DeadlineKind.RETURN_CORRECTION: "return_correction_grace_days",
    DeadlineKind.RENEWAL: "renewal_duration_days",
}


class DeadlineClass(StrEnum):
    NORMAL = "normal"
    NEAR = "near"
    OVERDUE = "overdue"


@dataclass(frozen=True)
class DeadlineStatus:
    days_remaining: int
    classification: DeadlineClass


@dataclass(frozen=True)
class AccessContext:
    role: str
    sector_id: str | None = None
    contractor_ref: str | None = None
    assigned_permit_ids: frozenset[str] = frozenset()
    delegated_approval_permit_ids: frozenset[str] = frozenset()


@dataclass(frozen=True)
class PermitScope:
    permit_id: str
    sector_id: str | None = None
    contractor_ref: str | None = None


KPI_DICTIONARY = {
    "permit_status_counts": {
        "view": "v_kpi_permit_status",
        "fields": ("status", "n"),
    },
    "deadline_status_counts": {
        "view": "v_kpi_deadline_status",
        "fields": ("kind", "status", "n"),
    },
    "transaction_cycle_time": {
        "view": "v_kpi_transaction_cycle_time",
        "fields": ("n", "median_days", "p90_days"),
    },
    "on_time_completion": {
        "view": "v_kpi_on_time_completion",
        "fields": ("n", "completed_within_deadline", "completion_rate_percent"),
    },
    "consultant_cycle_time": {
        "view": "v_kpi_consultant_cycle_time",
        "fields": ("display_name", "n", "median_days", "p90_days"),
    },
    "sector_cycle_time": {
        "view": "v_kpi_sector_cycle_time",
        "fields": ("display_name", "n", "median_days", "p90_days"),
    },
}

PERMIT_TRANSITIONS = {
    "draft": frozenset({"pending", "cancelled"}),
    "pending": frozenset({"active", "returned", "cancelled"}),
    "active": frozenset({"expired", "returned", "ready_for_closure"}),
    "expired": frozenset({"renewal_pending", "ready_for_closure"}),
    "returned": frozenset({"under_correction", "cancelled"}),
    "under_correction": frozenset({"pending", "ready_for_closure"}),
    "renewal_pending": frozenset({"active", "cancelled"}),
    "ready_for_closure": frozenset({"closed"}),
    "closed": frozenset(),
    "cancelled": frozenset(),
}
LETTER_TRANSITIONS = {
    "draft": frozenset({"pending_approval"}),
    "pending_approval": frozenset({"approved", "rejected"}),
    "approved": frozenset({"issued"}),
    "rejected": frozenset({"draft"}),
    "issued": frozenset(),
}


class DomainRuleError(ValueError):
    pass


def configured_deadline_duration(kind: DeadlineKind, settings: Mapping[str, Any]) -> int:
    key = DEADLINE_SETTINGS_KEYS[kind]
    duration = settings.get(key)
    if not isinstance(duration, int) or isinstance(duration, bool) or duration < 0:
        raise DomainRuleError(f"Administrator setting {key!r} is missing or invalid")
    return duration


def should_close_batch(expired_or_returned_count: int, closure_threshold: int) -> bool:
    if expired_or_returned_count < 0 or closure_threshold < 0:
        raise DomainRuleError("Closure counts and threshold must be non-negative")
    return expired_or_returned_count >= closure_threshold


def classify_deadline(
    due_date: date,
    today: date,
    near_deadline_days: int,
    *,
    counting_mode: str,
    weekend_days: frozenset[int] | None = None,
    official_holidays: frozenset[date] = frozenset(),
) -> DeadlineStatus:
    if near_deadline_days < 0:
        raise DomainRuleError("near_deadline_days must be non-negative")
    if counting_mode == "calendar":
        remaining = (due_date - today).days
    elif counting_mode == "business":
        if (
            weekend_days is None
            or len(weekend_days) == 7
            or any(not isinstance(day, int) or day < 0 or day > 6 for day in weekend_days)
        ):
            raise DomainRuleError("Business-day settings require valid configured weekends")
        direction = 1 if due_date >= today else -1
        current = today
        remaining = 0
        while current != due_date:
            current = date.fromordinal(current.toordinal() + direction)
            if current.weekday() not in weekend_days and current not in official_holidays:
                remaining += direction
    else:
        raise DomainRuleError(f"Unknown day-counting mode: {counting_mode}")
    if remaining < 0:
        classification = DeadlineClass.OVERDUE
    elif remaining <= near_deadline_days:
        classification = DeadlineClass.NEAR
    else:
        classification = DeadlineClass.NORMAL
    return DeadlineStatus(remaining, classification)


def calculate_due_date(
    start_date: date,
    duration_days: int,
    *,
    counting_mode: str,
    weekend_days: frozenset[int] | None = None,
    official_holidays: frozenset[date] = frozenset(),
) -> date:
    if duration_days < 0:
        raise DomainRuleError("Deadline duration must be non-negative")
    if counting_mode == "calendar":
        return date.fromordinal(start_date.toordinal() + duration_days)
    if counting_mode != "business":
        raise DomainRuleError(f"Unknown day-counting mode: {counting_mode}")
    if (
        weekend_days is None
        or len(weekend_days) == 7
        or any(not isinstance(day, int) or day < 0 or day > 6 for day in weekend_days)
    ):
        raise DomainRuleError("Business-day settings require valid configured weekends")

    due_date = start_date
    counted_days = 0
    while counted_days < duration_days:
        due_date = date.fromordinal(due_date.toordinal() + 1)
        if due_date.weekday() not in weekend_days and due_date not in official_holidays:
            counted_days += 1
    return due_date


def validate_permit_transition(
    current: str,
    target: str,
    evidence: Mapping[str, Any],
) -> None:
    if target not in PERMIT_TRANSITIONS.get(current, frozenset()):
        raise DomainRuleError(f"Transition {current!r} -> {target!r} is not allowed")
    if target == "closed":
        if evidence.get("urs_report_approved") is not True:
            raise DomainRuleError("Closing requires an approved URS report")
        if evidence.get("compaction_result_recorded") is not True:
            raise DomainRuleError("Closing requires a recorded compaction test result")


def validate_letter_transition(
    current: str,
    target: str,
    *,
    is_delegated_approver: bool,
) -> None:
    if target not in LETTER_TRANSITIONS.get(current, frozenset()):
        raise DomainRuleError(f"Letter transition {current!r} -> {target!r} is not allowed")
    if target == "approved" and not is_delegated_approver:
        raise DomainRuleError("Only a delegated approver may approve an official letter")


def can_export_final_letter(actor: AccessContext, permit: PermitScope, letter_status: str) -> bool:
    return letter_status in {"approved", "issued"} and can_access_permit(
        actor, permit, "export_final"
    )


def can_access_permit(
    actor: AccessContext,
    permit: PermitScope,
    action: str,
) -> bool:
    if action not in {"read", "update", "upload", "approve", "cancel", "export_final"}:
        return False
    if actor.role == "super_admin":
        return True
    if actor.role == "viewer":
        return action == "read"

    in_sector = actor.sector_id is not None and actor.sector_id == permit.sector_id
    assigned_to_site = permit.permit_id in actor.assigned_permit_ids
    is_contractor_permit = (
        actor.contractor_ref is not None
        and actor.contractor_ref == permit.contractor_ref
    )

    if actor.role == "sector_manager" and in_sector:
        if action in {"approve", "export_final"}:
            return permit.permit_id in actor.delegated_approval_permit_ids
        return action in {"read", "update", "upload"}
    if actor.role == "site_engineer" and assigned_to_site:
        return action in {"read", "update", "upload"}
    if actor.role == "contractor" and is_contractor_permit:
        return action in {"read", "upload"}
    return False


def validate_import_counts(
    source_rows: int,
    accepted_rows: int,
    rejected_rows: int,
    unexplained_gaps: int,
    subtotals: Mapping[str, int] | None = None,
) -> None:
    if min(source_rows, accepted_rows, rejected_rows, unexplained_gaps) < 0:
        raise DomainRuleError("Import counts cannot be negative")
    if source_rows != accepted_rows + rejected_rows:
        raise DomainRuleError("Source rows must equal accepted plus rejected rows")
    if unexplained_gaps:
        raise DomainRuleError("Import contains unexplained row-count gaps")
    if subtotals is not None:
        if any(value < 0 for value in subtotals.values()):
            raise DomainRuleError("Import subtotals cannot be negative")
        if sum(subtotals.values()) != source_rows:
            raise DomainRuleError("Import subtotals must add up to the source total")


def resolve_permit_reference(
    source_record: Mapping[str, str],
    permits: list[Mapping[str, str]],
) -> tuple[str, str | None]:
    reference = source_record.get("permit_id", "").strip()
    if not reference:
        return "unlinked", None
    exact_matches = [permit for permit in permits if permit.get("permit_id") == reference]
    if not exact_matches:
        return "unlinked", None
    if len(exact_matches) > 1:
        return "ambiguous", None
    return "linked", exact_matches[0]["permit_id"]


def check_attachment_policy(
    *,
    file_size: int,
    mime_type: str,
    max_bytes: int | None,
    allowed_mime_types: list[str] | None,
) -> None:
    if max_bytes is None or max_bytes <= 0 or not allowed_mime_types:
        raise DomainRuleError("Attachment policy is not configured by an administrator")
    if file_size <= 0:
        raise DomainRuleError("Empty attachments are not allowed")
    if file_size > max_bytes:
        raise DomainRuleError("Attachment exceeds the configured size limit")
    if mime_type not in allowed_mime_types:
        raise DomainRuleError("Attachment MIME type is not allowed by settings")

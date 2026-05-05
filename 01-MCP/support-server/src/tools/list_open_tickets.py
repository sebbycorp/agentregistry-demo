import json

from core.server import mcp

OPEN_TICKETS = [
    {
        "id": "TICK-1042",
        "subject": "Payment transactions failing with timeout errors",
        "priority": "high",
        "service": "payments",
        "status": "open",
        "created_at": "2026-05-05T12:15:00Z",
        "assigned_to": "Maria Chen",
    },
    {
        "id": "TICK-1057",
        "subject": "Payments API returning 502 gateway errors",
        "priority": "high",
        "service": "payments",
        "status": "open",
        "created_at": "2026-05-05T13:02:00Z",
        "assigned_to": "James Park",
    },
    {
        "id": "TICK-1038",
        "subject": "Order search endpoint returning slow responses",
        "priority": "medium",
        "service": "orders",
        "status": "in-progress",
        "created_at": "2026-05-04T16:45:00Z",
        "assigned_to": "Sarah Kim",
    },
    {
        "id": "TICK-1029",
        "subject": "Missing email notifications for order confirmations",
        "priority": "low",
        "service": "notifications",
        "status": "open",
        "created_at": "2026-05-03T09:30:00Z",
        "assigned_to": "Alex Rivera",
    },
    {
        "id": "TICK-1015",
        "subject": "Inventory webhook not triggering for stock updates",
        "priority": "medium",
        "service": "inventory",
        "status": "open",
        "created_at": "2026-05-02T14:20:00Z",
        "assigned_to": "Maria Chen",
    },
]


@mcp.tool()
def list_open_tickets(service: str = "") -> str:
    """List open support tickets, optionally filtered by service.

    Args:
        service: Filter tickets by service name (e.g. "payments", "orders"). Leave empty for all open tickets.

    Returns:
        JSON array of open tickets with id, subject, priority, service, status, created_at, and assigned_to.
    """
    tickets = OPEN_TICKETS
    if service:
        tickets = [t for t in tickets if t["service"] == service]
    return json.dumps(tickets, indent=2)

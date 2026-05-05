import json

from core.server import mcp

TICKETS = {
    "TICK-1042": {
        "id": "TICK-1042",
        "customer": "Acme Corp",
        "subject": "Payment transactions failing with timeout errors",
        "status": "open",
        "priority": "high",
        "service": "payments",
        "created_at": "2026-05-05T12:15:00Z",
        "assigned_to": "Maria Chen",
        "description": "Customer reports that payment transactions have been failing intermittently since ~12:00 UTC. They are seeing connection timeout errors when attempting to process orders. Affecting approximately 15% of their transaction volume.",
    },
    "TICK-1057": {
        "id": "TICK-1057",
        "customer": "GlobalTech Inc",
        "subject": "Payments API returning 502 gateway errors",
        "status": "open",
        "priority": "high",
        "service": "payments",
        "created_at": "2026-05-05T13:02:00Z",
        "assigned_to": "James Park",
        "description": "Customer integration receiving 502 Bad Gateway responses from the payments API endpoint. Started around 13:00 UTC. Their retry logic is catching some requests but overall success rate has dropped to ~85%.",
    },
    "TICK-1038": {
        "id": "TICK-1038",
        "customer": "StartupXYZ",
        "subject": "Order search endpoint returning slow responses",
        "status": "in-progress",
        "priority": "medium",
        "service": "orders",
        "created_at": "2026-05-04T16:45:00Z",
        "assigned_to": "Sarah Kim",
        "description": "Customer reports that the GET /orders/search endpoint is taking 2-3 seconds to respond, compared to the usual sub-second response time. Primarily affecting queries with large date ranges.",
    },
    "TICK-1029": {
        "id": "TICK-1029",
        "customer": "RetailMax",
        "subject": "Missing email notifications for order confirmations",
        "status": "open",
        "priority": "low",
        "service": "notifications",
        "created_at": "2026-05-03T09:30:00Z",
        "assigned_to": "Alex Rivera",
        "description": "Customer reports that some order confirmation emails are not being delivered. Appears to affect orders placed between 08:00-09:00 UTC. Push notifications are working correctly.",
    },
    "TICK-1015": {
        "id": "TICK-1015",
        "customer": "DataFlow Ltd",
        "subject": "Inventory webhook not triggering for stock updates",
        "status": "open",
        "priority": "medium",
        "service": "inventory",
        "created_at": "2026-05-02T14:20:00Z",
        "assigned_to": "Maria Chen",
        "description": "Customer's webhook endpoint is not receiving inventory update callbacks. They confirmed their endpoint is reachable and returning 200. Last successful delivery was 2 days ago.",
    },
}


@mcp.tool()
def get_ticket(ticket_id: str) -> str:
    """Retrieve details of a support ticket by its ID.

    Args:
        ticket_id: The ticket identifier (e.g. TICK-1042).

    Returns:
        JSON object with ticket details including id, customer, subject, status, priority, and description.
    """
    ticket = TICKETS.get(ticket_id)
    if ticket:
        return json.dumps(ticket, indent=2)
    return json.dumps({
        "error": f"Ticket '{ticket_id}' not found",
        "available_tickets": list(TICKETS.keys()),
    }, indent=2)

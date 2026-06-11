import json

from core.server import mcp

SERVICES = {
    "payments": {
        "status": "degraded",
        "uptime": 89.2,
        "latency_ms": 340,
        "error_rate": 12.5,
        "checked_at": "2026-05-05T14:32:00Z",
    },
    "auth": {
        "status": "healthy",
        "uptime": 99.98,
        "latency_ms": 12,
        "error_rate": 0.01,
        "checked_at": "2026-05-05T14:32:00Z",
    },
    "orders": {
        "status": "healthy",
        "uptime": 99.95,
        "latency_ms": 45,
        "error_rate": 0.03,
        "checked_at": "2026-05-05T14:32:00Z",
    },
    "inventory": {
        "status": "healthy",
        "uptime": 99.91,
        "latency_ms": 38,
        "error_rate": 0.05,
        "checked_at": "2026-05-05T14:32:00Z",
    },
    "notifications": {
        "status": "healthy",
        "uptime": 99.89,
        "latency_ms": 22,
        "error_rate": 0.02,
        "checked_at": "2026-05-05T14:32:00Z",
    },
}


@mcp.tool()
def get_service_health(service_name: str) -> str:
    """Check the health status of a service.

    Args:
        service_name: Name of the service to check (e.g. payments, auth, orders, inventory, notifications).

    Returns:
        JSON string with status, uptime, latency_ms, error_rate, and checked_at.
    """
    if service_name in SERVICES:
        return json.dumps({"service": service_name, **SERVICES[service_name]}, indent=2)
    return json.dumps({
        "service": service_name,
        "status": "unknown",
        "message": f"Service '{service_name}' not found. Known services: {', '.join(SERVICES.keys())}",
    }, indent=2)

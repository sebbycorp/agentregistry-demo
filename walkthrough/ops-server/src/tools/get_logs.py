import json

from core.server import mcp

LOGS = {
    "payments": [
        {"timestamp": "2026-05-05T14:31:58Z", "severity": "error", "message": "Connection timeout to payment gateway (attempt 3/3)"},
        {"timestamp": "2026-05-05T14:31:45Z", "severity": "error", "message": "Failed to process transaction TXN-88421: upstream connection reset"},
        {"timestamp": "2026-05-05T14:31:30Z", "severity": "warn", "message": "Payment gateway response time exceeded 500ms threshold"},
        {"timestamp": "2026-05-05T14:31:12Z", "severity": "warn", "message": "Retry queue depth at 47 — approaching capacity limit of 50"},
        {"timestamp": "2026-05-05T14:30:55Z", "severity": "info", "message": "Rolling deployment v2.4.1 in progress — 2/3 replicas updated"},
        {"timestamp": "2026-05-05T14:30:40Z", "severity": "error", "message": "Health check failed for replica payments-7f8b9c-xk2pd"},
        {"timestamp": "2026-05-05T14:30:22Z", "severity": "warn", "message": "Circuit breaker tripped for payment-gateway-west-2"},
        {"timestamp": "2026-05-05T14:30:01Z", "severity": "info", "message": "Deployment v2.4.1 initiated by ci-pipeline"},
    ],
    "auth": [
        {"timestamp": "2026-05-05T14:31:50Z", "severity": "info", "message": "Token refresh completed for 142 active sessions"},
        {"timestamp": "2026-05-05T14:31:00Z", "severity": "info", "message": "Health check passed — all 3 replicas healthy"},
        {"timestamp": "2026-05-05T14:30:15Z", "severity": "info", "message": "Rate limiter reset — 0 blocked requests in last window"},
        {"timestamp": "2026-05-05T14:29:30Z", "severity": "info", "message": "Certificate rotation completed successfully"},
        {"timestamp": "2026-05-05T14:29:00Z", "severity": "info", "message": "OAuth provider sync finished — 3 providers active"},
    ],
    "orders": [
        {"timestamp": "2026-05-05T14:31:40Z", "severity": "info", "message": "Processed 847 orders in last 5-minute window"},
        {"timestamp": "2026-05-05T14:31:00Z", "severity": "info", "message": "Health check passed — all 2 replicas healthy"},
        {"timestamp": "2026-05-05T14:30:20Z", "severity": "info", "message": "Cache hit ratio: 94.2%"},
        {"timestamp": "2026-05-05T14:29:45Z", "severity": "warn", "message": "Slow query detected: GET /orders/search took 230ms"},
        {"timestamp": "2026-05-05T14:29:00Z", "severity": "info", "message": "Database connection pool: 8/20 active connections"},
    ],
    "inventory": [
        {"timestamp": "2026-05-05T14:31:55Z", "severity": "info", "message": "Stock sync completed — 12,847 SKUs updated"},
        {"timestamp": "2026-05-05T14:31:10Z", "severity": "info", "message": "Health check passed — all 2 replicas healthy"},
        {"timestamp": "2026-05-05T14:30:30Z", "severity": "info", "message": "Webhook delivered to 3 subscribers"},
        {"timestamp": "2026-05-05T14:30:00Z", "severity": "info", "message": "Batch import job finished — 0 errors"},
        {"timestamp": "2026-05-05T14:29:15Z", "severity": "info", "message": "Low stock alert: 4 SKUs below reorder threshold"},
    ],
    "notifications": [
        {"timestamp": "2026-05-05T14:31:48Z", "severity": "info", "message": "Dispatched 2,341 email notifications in last window"},
        {"timestamp": "2026-05-05T14:31:05Z", "severity": "info", "message": "Health check passed — 1/1 replicas healthy"},
        {"timestamp": "2026-05-05T14:30:25Z", "severity": "info", "message": "SMS provider latency: 89ms average"},
        {"timestamp": "2026-05-05T14:29:50Z", "severity": "info", "message": "Push notification queue depth: 12"},
        {"timestamp": "2026-05-05T14:29:10Z", "severity": "info", "message": "Template cache refreshed — 47 templates loaded"},
    ],
}


@mcp.tool()
def get_logs(service_name: str, severity: str = "all") -> str:
    """Retrieve recent log entries for a service.

    Args:
        service_name: Name of the service (e.g. payments, auth, orders, inventory, notifications).
        severity: Filter by log severity: "info", "warn", "error", or "all" for no filter.

    Returns:
        JSON array of log entries with timestamp, severity, and message.
    """
    entries = LOGS.get(service_name, [])
    if severity != "all":
        entries = [e for e in entries if e["severity"] == severity]
    return json.dumps(entries, indent=2)

import json

from core.server import mcp

DEPLOYMENTS = {
    "default": [
        {
            "name": "payments",
            "version": "2.4.1",
            "timestamp": "2026-05-05T13:45:00Z",
            "status": "rolling",
            "replicas": "2/3",
            "namespace": "default",
        },
        {
            "name": "auth",
            "version": "1.12.0",
            "timestamp": "2026-05-04T09:20:00Z",
            "status": "running",
            "replicas": "3/3",
            "namespace": "default",
        },
        {
            "name": "orders",
            "version": "3.1.7",
            "timestamp": "2026-05-03T16:10:00Z",
            "status": "running",
            "replicas": "2/2",
            "namespace": "default",
        },
        {
            "name": "inventory",
            "version": "1.8.3",
            "timestamp": "2026-05-02T11:30:00Z",
            "status": "running",
            "replicas": "2/2",
            "namespace": "default",
        },
    ],
    "monitoring": [
        {
            "name": "notifications",
            "version": "0.9.5",
            "timestamp": "2026-05-01T08:00:00Z",
            "status": "running",
            "replicas": "1/1",
            "namespace": "monitoring",
        },
    ],
}


@mcp.tool()
def list_deployments(namespace: str = "default") -> str:
    """List recent deployments in a Kubernetes namespace.

    Args:
        namespace: Kubernetes namespace to query. Defaults to "default".

    Returns:
        JSON array of deployments with name, version, timestamp, status, and replica count.
    """
    deployments = DEPLOYMENTS.get(namespace, [])
    return json.dumps(deployments, indent=2)

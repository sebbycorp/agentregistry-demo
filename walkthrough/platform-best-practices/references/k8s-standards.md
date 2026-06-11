# Kubernetes Deployment Standards

## Namespace Conventions

| Namespace | Purpose |
|-----------|---------|
| `default` | Production application workloads |
| `monitoring` | Prometheus, Grafana, alerting infrastructure |
| `ingress` | Ingress controllers and load balancers |
| `kagent` | AgentRegistry agent and MCP server deployments |

## Labeling Standards

All deployments must include these labels:

```yaml
metadata:
  labels:
    app.kubernetes.io/name: <service-name>
    app.kubernetes.io/version: <semver>
    app.kubernetes.io/component: <api|worker|cron>
    app.kubernetes.io/part-of: <product>
    team: <owning-team>
    tier: <p0|p1|p2|p3>
```

## Health Probe Configuration

### Liveness Probe (all services)

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 15
  failureThreshold: 3
```

### Readiness Probe (all services)

```yaml
readinessProbe:
  httpGet:
    path: /readyz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 2
```

## Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: <service-name>
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <service-name>
  minReplicas: <per-tier-minimum>
  maxReplicas: <per-tier-maximum>
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

## Network Policies

- All namespaces deny ingress by default
- Explicit NetworkPolicy required for each service-to-service communication path
- Egress to external APIs must be allowlisted per service

## Secret Management

- All secrets stored in Kubernetes Secrets with encryption at rest
- Sensitive values injected via environment variables, never mounted as files
- Secret rotation: every 90 days for API keys, every 365 days for certificates
- No secrets in container images or ConfigMaps

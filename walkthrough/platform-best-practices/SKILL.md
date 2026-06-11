---
name: platform-best-practices
description: Kubernetes deployment standards, SLA tiers, health check conventions, and team ownership mappings for platform operations
---

# Platform Best Practices

Operational knowledge base for platform engineering. Use this knowledge to assess service health, classify incident severity, determine escalation paths, and recommend actions aligned with organizational standards.

## Service SLA Tiers

| Tier | Description | Response Time | Resolution Target | Examples |
|------|-------------|---------------|-------------------|----------|
| P0 — Critical | Complete service outage or data loss | 15 minutes | 1 hour | payments down, auth unavailable |
| P1 — High | Service degraded, users impacted | 30 minutes | 4 hours | payments latency > 500ms, error rate > 10% |
| P2 — Medium | Partial degradation, workaround exists | 2 hours | 24 hours | non-critical feature unavailable, elevated error rate < 5% |
| P3 — Low | Cosmetic or minor issue, no user impact | 1 business day | 1 week | dashboard rendering issue, log noise |

When assessing severity, always use measured metrics against these thresholds — never guess.

## Health Check Conventions

All services expose standard health endpoints:

| Endpoint | Purpose | Healthy Response |
|----------|---------|-----------------|
| `/healthz` | Liveness probe — is the process alive? | HTTP 200, body: `{"status": "ok"}` |
| `/readyz` | Readiness probe — can it serve traffic? | HTTP 200, body: `{"status": "ready"}` |
| `/metrics` | Prometheus metrics endpoint | HTTP 200, Prometheus text format |

### Degradation Thresholds

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Latency (p99) | < 100ms | 100ms–500ms | > 500ms |
| Error rate | < 1% | 1%–5% | > 5% |
| Uptime (30-day) | > 99.9% | 99.0%–99.9% | < 99.0% |
| CPU utilization | < 60% | 60%–85% | > 85% |
| Memory utilization | < 70% | 70%–90% | > 90% |

## Deployment Standards

### Replica Counts by Tier

| Service Tier | Min Replicas | Max Replicas | Pod Disruption Budget |
|-------------|-------------|-------------|----------------------|
| P0 (Critical) | 3 | 10 | maxUnavailable: 1 |
| P1 (High) | 2 | 8 | maxUnavailable: 1 |
| P2 (Medium) | 2 | 5 | maxUnavailable: 50% |
| P3 (Low) | 1 | 3 | none |

### Resource Limits

| Service Tier | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-------------|------------|-----------|---------------|-------------|
| P0 (Critical) | 500m | 2000m | 512Mi | 2Gi |
| P1 (High) | 250m | 1000m | 256Mi | 1Gi |
| P2 (Medium) | 100m | 500m | 128Mi | 512Mi |
| P3 (Low) | 50m | 250m | 64Mi | 256Mi |

### Rollback Policy

- **Automatic rollback** if error rate exceeds 10% within 5 minutes of deployment
- **Canary deployments** required for P0/P1 services: 10% traffic for 5 minutes before full rollout
- **Rolling updates** for P2/P3: maxSurge 25%, maxUnavailable 25%
- **Change freeze**: No P0/P1 deployments on Fridays after 14:00 UTC or during active incidents

## Team Ownership

| Service | Owner Team | Slack Channel | On-Call Rotation |
|---------|-----------|---------------|-----------------|
| payments | payments-team | #payments-eng | payments-oncall (PagerDuty) |
| auth | identity-team | #identity-eng | identity-oncall (PagerDuty) |
| orders | commerce-team | #orders-eng | commerce-oncall (PagerDuty) |
| inventory | commerce-team | #inventory-eng | commerce-oncall (PagerDuty) |
| notifications | platform-team | #notifications-eng | platform-oncall (PagerDuty) |

## Escalation Procedures

### When to Escalate

| Condition | Action |
|-----------|--------|
| P0 incident detected | Page on-call immediately, notify #incident-response, assign Incident Commander |
| P1 lasting > 30 minutes | Page on-call, notify team Slack channel |
| P2 lasting > 4 hours | Notify team Slack channel, create follow-up ticket |
| P3 | No escalation — track in backlog |

### Escalation Chain

1. **On-call engineer** — first responder, owns triage and initial mitigation
2. **Team lead** — escalated if on-call cannot resolve within response time SLA
3. **Engineering manager** — escalated for cross-team coordination or customer-facing P0
4. **VP Engineering** — escalated for extended P0 outages (> 2 hours)

### Incident Commander Responsibilities

- Owns the incident Slack thread in #incident-response
- Coordinates across teams if multiple services affected
- Publishes status updates every 15 minutes during P0, every 30 minutes during P1
- Initiates post-incident review within 48 hours of resolution

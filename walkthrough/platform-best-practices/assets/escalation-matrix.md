# Escalation Matrix

## Severity → Action Quick Reference

```
P0 (Critical)
├── Immediately page on-call via PagerDuty
├── Post in #incident-response with: service, impact, initial findings
├── Assign Incident Commander (IC)
├── IC publishes updates every 15 minutes
└── If unresolved in 1 hour → escalate to Engineering Manager

P1 (High)
├── Page on-call via PagerDuty if no response in 15 minutes
├── Post in team Slack channel with: service, symptoms, current metrics
├── IC assigned if lasting > 30 minutes
└── If unresolved in 4 hours → escalate to Team Lead

P2 (Medium)
├── Notify team Slack channel
├── Create tracking ticket with severity label
└── If unresolved in 24 hours → escalate to Team Lead

P3 (Low)
├── Create backlog ticket
└── Address in next sprint
```

## Cross-Team Incident Coordination

When multiple services are affected:

1. The team owning the **root cause service** leads the incident
2. Other affected teams join the incident Slack thread
3. IC coordinates communication and deconflicts mitigation actions
4. Each team provides a representative to the incident bridge

## Post-Incident Review Template

| Field | Description |
|-------|-------------|
| Incident ID | Auto-generated from PagerDuty |
| Duration | Time from detection to resolution |
| Severity | P0/P1/P2/P3 |
| Root Cause | Technical root cause |
| Impact | Users affected, revenue impact, SLA breach |
| Timeline | Key events with timestamps |
| Action Items | Preventive measures with owners and due dates |

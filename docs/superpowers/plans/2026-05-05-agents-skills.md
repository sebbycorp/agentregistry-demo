# Agents & Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a platform-best-practices skill (03-Skills) and a composition-focused platform-ops-agent (02-Agents) with MCP server, skill, prompt, and Kubernetes deployment, each with standalone demo scripts.

**Architecture:** The skill is a knowledge package (SKILL.md + assets) scaffolded via `arctl skill init`, containing K8s standards, SLA tiers, and team ownership mappings. The agent is scaffolded via `arctl agent init adk python`, then composed entirely through `agent.yaml` by adding the ops-server MCP (from 01-MCP), the skill, and a strict-operator prompt. No custom agent logic — the value is in composition. Each folder has a standalone demo-script.md.

**Tech Stack:** arctl CLI, Docker, Kubernetes (kind), Google ADK (Python), OpenAI (gpt-4o)

**Working directory:** `/Users/sebbycorp/Library/CloudStorage/GoogleDrive-sebastian.maniak@solo.io/My Drive/Projects/agentregistry-demo`

---

### Task 1: Create 03-Skills directory and scaffold the skill

**Files:**
- Create: `03-Skills/platform-best-practices/` (via arctl scaffold)

- [ ] **Step 1: Create the 03-Skills directory**

```bash
cd "/Users/sebbycorp/Library/CloudStorage/GoogleDrive-sebastian.maniak@solo.io/My Drive/Projects/agentregistry-demo"
mkdir -p 03-Skills
```

- [ ] **Step 2: Scaffold the skill with arctl**

```bash
cd "/Users/sebbycorp/Library/CloudStorage/GoogleDrive-sebastian.maniak@solo.io/My Drive/Projects/agentregistry-demo/03-Skills"
arctl skill init platform-best-practices
```

Expected: `platform-best-practices/` directory created with `SKILL.md`, `Dockerfile`, `LICENSE.txt`, `assets/`, `references/`, `scripts/`.

- [ ] **Step 3: Verify scaffold structure**

```bash
ls -R 03-Skills/platform-best-practices/
```

Expected: `SKILL.md`, `Dockerfile`, `LICENSE.txt`, `assets/`, `references/`, `scripts/` directories.

- [ ] **Step 4: Commit scaffold**

```bash
git add 03-Skills/
git commit -m "scaffold: init platform-best-practices skill with arctl"
```

---

### Task 2: Write the SKILL.md content

**Files:**
- Modify: `03-Skills/platform-best-practices/SKILL.md`

- [ ] **Step 1: Replace SKILL.md with platform best practices content**

Replace the entire contents of `03-Skills/platform-best-practices/SKILL.md` with:

```markdown
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
```

- [ ] **Step 2: Verify the file looks correct**

```bash
head -5 03-Skills/platform-best-practices/SKILL.md
```

Expected: YAML frontmatter with `name: platform-best-practices`.

- [ ] **Step 3: Commit SKILL.md**

```bash
git add 03-Skills/platform-best-practices/SKILL.md
git commit -m "feat(skill): add platform best practices knowledge to SKILL.md"
```

---

### Task 3: Add skill assets and references

**Files:**
- Create: `03-Skills/platform-best-practices/assets/escalation-matrix.md`
- Create: `03-Skills/platform-best-practices/references/k8s-standards.md`

- [ ] **Step 1: Create the escalation matrix asset**

Create `03-Skills/platform-best-practices/assets/escalation-matrix.md`:

```markdown
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
```

- [ ] **Step 2: Create the Kubernetes standards reference**

Create `03-Skills/platform-best-practices/references/k8s-standards.md`:

```markdown
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
```

- [ ] **Step 3: Commit assets and references**

```bash
git add 03-Skills/platform-best-practices/assets/ 03-Skills/platform-best-practices/references/
git commit -m "feat(skill): add escalation matrix and k8s standards references"
```

---

### Task 4: Write the 03-Skills demo script

**Files:**
- Create: `03-Skills/demo-script.md`

- [ ] **Step 1: Create the demo script**

Create `03-Skills/demo-script.md`:

```markdown
# Skills Demo Script — Agentregistry Conference Demo

## Prerequisites (before going on stage)

- arctl daemon running: `arctl daemon start`
- Docker running
- Clean slate: `arctl skill list` shows no existing skills
- 01-MCP ops-server already published (for context, not required)

---

## Act 1: Scaffold the Skill (~1 min)

```bash
# Scaffold
arctl skill init platform-best-practices

# Show what we got
ls platform-best-practices/
# SKILL.md  Dockerfile  LICENSE.txt  assets/  references/  scripts/

# "arctl gives us the structure — SKILL.md is the core definition"
cat platform-best-practices/SKILL.md
# Shows default frontmatter and placeholder content
```

## Act 2: Add Platform Knowledge (~2 min)

```bash
# [Copy in the pre-written SKILL.md]
# "Let's replace the placeholder with real platform knowledge"

# Show the key sections:
cat platform-best-practices/SKILL.md
# Walk through: SLA tiers, health check thresholds, team ownership, escalation

# We also added reference docs
ls platform-best-practices/assets/
# escalation-matrix.md

ls platform-best-practices/references/
# k8s-standards.md

# "Structured knowledge — SLA definitions, deployment standards, who owns what"
```

## Act 3: Build & Publish (~2 min)

```bash
# Build the skill as a Docker image
arctl skill build ./platform-best-practices \
  --image platform-best-practices:v1.0.0

# Push to registry
arctl skill build ./platform-best-practices \
  --image platform-best-practices:v1.0.0 --push

# Publish to the catalog
arctl skill publish ./platform-best-practices \
  --docker-image platform-best-practices:v1.0.0 \
  --version 1.0.0

# Verify it's in the catalog
arctl skill list
```

Then open http://localhost:12121 and show the skill in the UI.

### Punchline:

> "Structured knowledge, packaged as a skill, published to the registry — ready for any agent to use."

---

## Cleanup

```bash
arctl skill delete platform-best-practices --version 1.0.0
```
```

- [ ] **Step 2: Commit the demo script**

```bash
git add 03-Skills/demo-script.md
git commit -m "docs(skill): add standalone demo script for 03-Skills"
```

---

### Task 5: Create 02-Agents directory and scaffold the agent

**Files:**
- Create: `02-Agents/platform-ops-agent/` (via arctl scaffold)

- [ ] **Step 1: Create the 02-Agents directory**

```bash
cd "/Users/sebbycorp/Library/CloudStorage/GoogleDrive-sebastian.maniak@solo.io/My Drive/Projects/agentregistry-demo"
mkdir -p 02-Agents
```

- [ ] **Step 2: Scaffold the agent with arctl**

```bash
cd "/Users/sebbycorp/Library/CloudStorage/GoogleDrive-sebastian.maniak@solo.io/My Drive/Projects/agentregistry-demo/02-Agents"
arctl agent init adk python platform-ops-agent
```

Expected: `platform-ops-agent/` directory created with `agent.yaml`, `docker-compose.yaml`, `Dockerfile`, `platform_ops_agent/agent.py`, `pyproject.toml`, `README.md`.

- [ ] **Step 3: Verify scaffold structure**

```bash
ls -R 02-Agents/platform-ops-agent/
```

Expected: `agent.yaml`, `docker-compose.yaml`, `Dockerfile`, `platform_ops_agent/`, `pyproject.toml`, `README.md`.

- [ ] **Step 4: Commit scaffold**

```bash
git add 02-Agents/
git commit -m "scaffold: init platform-ops-agent with arctl agent init"
```

---

### Task 6: Write the strict-operator prompt

**Files:**
- Create: `02-Agents/prompts/strict-operator.txt`

- [ ] **Step 1: Create the prompts directory and prompt file**

```bash
mkdir -p 02-Agents/prompts
```

Create `02-Agents/prompts/strict-operator.txt`:

```text
You are the Platform Ops Agent. You are a formal, structured operator responsible for deployment management, incident response, and escalation.

## Behavior Rules

1. Always identify yourself as "Platform Ops Agent" when greeting users.
2. Assess severity first. Use the SLA tier definitions from your platform-best-practices skill to classify every issue as P0, P1, P2, or P3. Never skip classification.
3. Output structured incident reports using this format:

   **Severity:** P0/P1/P2/P3
   **Affected Services:** list of services
   **Impact Summary:** one-sentence description of user/business impact
   **Current Metrics:** relevant health data from MCP tools
   **Recommended Actions:** numbered list of specific actions
   **Escalation Status:** whether escalation is needed and to whom

4. Follow the escalation matrix from your platform-best-practices skill before recommending any escalation actions.
5. Never take destructive actions (rollbacks, restarts, scaling down) without explicit user confirmation.
6. Reference specific SLA targets and thresholds when reporting on service health. Do not use vague terms like "seems slow" — use measured values against defined thresholds.
7. Use formal, concise language. No speculation. Only data-backed assessments.
8. When multiple services are affected, identify the likely root cause service and lead with that assessment.
9. Always recommend checking deployment history when a service shows recent degradation.
10. End every incident assessment with a clear next-step recommendation.
```

- [ ] **Step 2: Commit the prompt**

```bash
git add 02-Agents/prompts/
git commit -m "feat(agent): add strict-operator prompt for platform ops persona"
```

---

### Task 7: Configure agent.yaml with MCP server, skill, and prompt

**Files:**
- Modify: `02-Agents/platform-ops-agent/agent.yaml`

- [ ] **Step 1: Replace agent.yaml with composed configuration**

Replace the entire contents of `02-Agents/platform-ops-agent/agent.yaml` with:

```yaml
agentName: platform-ops-agent
image: ghcr.io/platform-ops-agent:latest
language: python
framework: adk
modelProvider: openAI
modelName: gpt-4o
description: "Platform Ops Agent — deployment management, escalation, incident response"
mcpServers:
  - type: registry
    name: ops-server
    env:
      - MCP_TRANSPORT_MODE=http
      - HOST=0.0.0.0
    registryURL: http://localhost:12121
    registryServerName: sebastianmaniak/ops-server
    registryServerVersion: 0.1.0
    registryServerPreferRemote: true
skills:
  - name: platform-best-practices
    registryURL: http://localhost:12121
    registrySkillName: platform-best-practices
prompts:
  - name: strict-operator
    registryURL: http://localhost:12121
    registryPromptName: strict-operator
    registryPromptVersion: 1.0.0
```

- [ ] **Step 2: Verify the YAML is valid**

```bash
python3 -c "import yaml; yaml.safe_load(open('02-Agents/platform-ops-agent/agent.yaml')); print('Valid YAML')"
```

Expected: `Valid YAML`

- [ ] **Step 3: Commit the composed agent.yaml**

```bash
git add 02-Agents/platform-ops-agent/agent.yaml
git commit -m "feat(agent): compose agent.yaml with MCP server, skill, and prompt"
```

---

### Task 8: Write the 02-Agents demo script

**Files:**
- Create: `02-Agents/demo-script.md`

- [ ] **Step 1: Create the demo script**

Create `02-Agents/demo-script.md`:

```markdown
# Agents Demo Script — Agentregistry Conference Demo

## Prerequisites (before going on stage)

- arctl daemon running: `arctl daemon start`
- Docker running
- kind cluster ready: `kind create cluster --name agentregistry`
- kagent installed on cluster (see kagent OSS quickstart)
- 01-MCP: ops-server built and published to registry
- 03-Skills: platform-best-practices skill built and published to registry
- `OPENAI_API_KEY` env var set (for OpenAI model provider)
- Clean slate: `arctl agent list` shows no existing agents

---

## Act 1: Scaffold the Agent (~30s)

```bash
# Scaffold
arctl agent init adk python platform-ops-agent

# Show what we got
ls platform-ops-agent/
# agent.yaml  docker-compose.yaml  Dockerfile  platform_ops_agent/  pyproject.toml  README.md

cat platform-ops-agent/agent.yaml
# "Out of the box it's a bare agent — let's compose it with registry artifacts"
```

## Act 2: Add the MCP Server (~1 min)

```bash
# Add the ops-server MCP from the registry
arctl agent add-mcp --project-dir platform-ops-agent
# Interactive: select "registry", enter http://localhost:12121
# Select ops-server, set env vars:
#   MCP_TRANSPORT_MODE=http
#   HOST=0.0.0.0
# Name: ops-server

# Show the updated agent.yaml
cat platform-ops-agent/agent.yaml
# "Now the agent can check service health, view deployments, and read logs"
```

## Act 3: Add Skill & Prompt (~1.5 min)

```bash
# Add the platform-best-practices skill
arctl agent add-skill platform-best-practices \
  --project-dir platform-ops-agent \
  --registry-skill-name platform-best-practices \
  --registry-skill-version 1.0.0 \
  --image platform-best-practices:v1.0.0

# Publish the strict-operator prompt to the registry
arctl prompt publish prompts/strict-operator.txt \
  --name strict-operator \
  --version 1.0.0 \
  --description "Strict operator persona for platform ops"

# Add the prompt to the agent
arctl agent add-prompt strict-operator \
  --project-dir platform-ops-agent \
  --registry-prompt-name strict-operator

# Show the final agent.yaml — all three composed
cat platform-ops-agent/agent.yaml
# "MCP server for tools, skill for knowledge, prompt for behavior — all from the registry"
```

## Act 4: Build & Deploy to Kubernetes (~1.5 min)

```bash
# Build the agent image
arctl agent build platform-ops-agent --push --platform linux/amd64

# Load to kind cluster (for local builds)
kind load docker-image ghcr.io/platform-ops-agent:latest --name agentregistry

# Deploy to Kubernetes
arctl deployments create platform-ops-agent \
  --type agent \
  --provider-id kubernetes-default \
  --namespace default

# Verify
kubectl get pods -n kagent | grep platform-ops
arctl deployments list
```

## Act 5: Live Demo (~1 min)

```bash
# Run the agent
export OPENAI_API_KEY=<your-key>
arctl agent run platform-ops-agent
```

### Demo prompts (in order):

1. **"What's the status of the payments service?"**
   Agent calls `get_service_health` via MCP, references SLA tiers from skill, outputs structured report with severity classification.

2. **"Should we escalate this?"**
   Agent references escalation matrix from skill, identifies severity level, recommends paging payments-team via PagerDuty, posting in #payments-eng.

3. **"Generate an incident report for what's happening with payments"**
   Agent produces formal structured incident report: severity, affected services, impact, metrics, recommended actions, escalation status.

### Punchline:

> "One agent, one MCP server, one skill, one prompt — all from the registry, deployed to Kubernetes, producing structured incident reports in under 5 minutes."

---

## Cleanup

```bash
arctl deployments list
arctl deployments delete <agent-deployment-id>
arctl agent delete platform-ops-agent --version latest
arctl prompt delete strict-operator --version 1.0.0
```
```

- [ ] **Step 2: Commit the demo script**

```bash
git add 02-Agents/demo-script.md
git commit -m "docs(agent): add standalone demo script for 02-Agents"
```

---

### Task 9: Final verification

**Files:**
- None (read-only verification)

- [ ] **Step 1: Verify complete directory structure**

```bash
find 03-Skills/ -type f | sort
```

Expected:
```
03-Skills/demo-script.md
03-Skills/platform-best-practices/Dockerfile
03-Skills/platform-best-practices/LICENSE.txt
03-Skills/platform-best-practices/SKILL.md
03-Skills/platform-best-practices/assets/escalation-matrix.md
03-Skills/platform-best-practices/references/k8s-standards.md
```

- [ ] **Step 2: Verify 02-Agents directory structure**

```bash
find 02-Agents/ -type f | sort
```

Expected:
```
02-Agents/demo-script.md
02-Agents/platform-ops-agent/Dockerfile
02-Agents/platform-ops-agent/README.md
02-Agents/platform-ops-agent/agent.yaml
02-Agents/platform-ops-agent/docker-compose.yaml
02-Agents/platform-ops-agent/platform_ops_agent/agent.py
02-Agents/platform-ops-agent/pyproject.toml
02-Agents/prompts/strict-operator.txt
```

- [ ] **Step 3: Validate agent.yaml YAML syntax**

```bash
python3 -c "import yaml; data=yaml.safe_load(open('02-Agents/platform-ops-agent/agent.yaml')); print(f'Agent: {data[\"agentName\"]}'); print(f'MCP servers: {len(data.get(\"mcpServers\", []))}'); print(f'Skills: {len(data.get(\"skills\", []))}'); print(f'Prompts: {len(data.get(\"prompts\", []))}')"
```

Expected:
```
Agent: platform-ops-agent
MCP servers: 1
Skills: 1
Prompts: 1
```

- [ ] **Step 4: Validate SKILL.md frontmatter**

```bash
python3 -c "
content = open('03-Skills/platform-best-practices/SKILL.md').read()
assert content.startswith('---')
assert 'name: platform-best-practices' in content
print('SKILL.md frontmatter valid')
"
```

Expected: `SKILL.md frontmatter valid`

- [ ] **Step 5: Final commit with any remaining files**

```bash
git status
# If any unstaged files remain:
git add 02-Agents/ 03-Skills/
git commit -m "chore: ensure all agent and skill files are committed"
```

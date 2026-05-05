# Master Storyboard Design: From Zero to AI Ops Agent

## Overview

A single master storyboard (`STORYBOARD.md` at repo root) that ties the entire agentregistry-demo into one cohesive end-to-end narrative for a ~18-20 minute live conference demo. Covers: install platform (arctl, kind, kagent, agentgateway), build MCP server, build skill, compose agent with MCP + skill + prompt, publish to registry, deploy to Kubernetes, and connect to Claude Code.

**Audience:** Developers at a conference/meetup, first exposure to agentregistry.
**Format:** Live walkthrough, linear build-up, every command shown live including infrastructure install.
**Structure:** 7 acts, each with a mini-punchline and transition to the next.
**Climax:** Claude Code uses the deployed agent's MCP tools + skill knowledge + operator persona to produce a structured incident report.

**Opening line:** "What if you could go from an empty terminal to a fully deployed AI ops agent — with tools, knowledge, and a persona — in under 20 minutes?"

**Closing punchline:** "An empty terminal. Seven acts. One MCP server for tools, one skill for knowledge, one prompt for behavior, one agent to compose them all — registered, deployed to Kubernetes, and answering ops questions. That's agentregistry."

## Act Structure & Timing

| Act | Title | Time | What Happens |
|-----|-------|------|-------------|
| 1 | The Platform | ~3 min | Install arctl, kind cluster, kagent, agentgateway |
| 2 | The Tools | ~2.5 min | Scaffold ops-server MCP, add tools, build & publish |
| 3 | The Knowledge | ~2 min | Scaffold skill, add platform best practices, build & publish |
| 4 | The Registry | ~1 min | Show both artifacts in the registry UI |
| 5 | The Agent | ~3 min | Scaffold agent, compose MCP + skill + prompt, build |
| 6 | The Deployment | ~2 min | Deploy everything to Kubernetes, verify pods |
| 7 | The Magic | ~2 min | Connect to Claude Code, three demo prompts, punchline |

## Act 1: The Platform (~3 min)

Pre-stage: nothing — fresh terminal.

**Commands:**

1. `curl -fsSL https://raw.githubusercontent.com/agentregistry-dev/agentregistry/main/scripts/get-arctl | bash`
2. `arctl version`
3. `arctl daemon start`
4. `kind create cluster --name agentregistry`
5. Helm install kagent CRDs:
   ```bash
   helm install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
     --namespace kagent --create-namespace
   ```
6. Helm install kagent:
   ```bash
   export OPENAI_API_KEY="your-api-key-here"
   helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
     --namespace kagent \
     --set kmcp.enabled=true \
     --set agents.enabled=false \
     --set providers.default=openAI \
     --set providers.openAI.apiKey=$OPENAI_API_KEY
   ```
7. Helm install Gateway API CRDs:
   ```bash
   kubectl apply --server-side --force-conflicts \
     -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml
   ```
8. Helm install agentgateway CRDs + controller:
   ```bash
   helm upgrade -i agentgateway-crds oci://cr.agentgateway.dev/charts/agentgateway-crds \
     --create-namespace --namespace agentgateway-system \
     --version v1.1.0 --set controller.image.pullPolicy=Always

   helm upgrade -i agentgateway oci://cr.agentgateway.dev/charts/agentgateway \
     --namespace agentgateway-system --version v1.1.0 \
     --set controller.image.pullPolicy=Always \
     --set controller.extraEnv.KGW_ENABLE_GATEWAY_API_EXPERIMENTAL_FEATURES=true \
     --wait
   ```
9. Verify: `kubectl get pods -n kagent && kubectl get pods -n agentgateway-system`

**Transition:** "Platform's ready. Now let's give it something to run."

## Act 2: The Tools (~2.5 min)

**Commands:**

1. `arctl mcp init python ops-server`
2. Show default `echo.py` — "let's replace with real ops tools"
3. `arctl mcp add-tool get_service_health --project-dir ops-server`
4. `arctl mcp add-tool list_deployments --project-dir ops-server`
5. `arctl mcp add-tool get_logs --project-dir ops-server`
6. Copy in pre-written implementations, briefly show `get_service_health.py`
7. `arctl mcp build ops-server --image ops-server`
8. `arctl mcp publish ops-server --type oci --package-id ops-server`

**Pre-written files:** `01-MCP/ops-server/src/tools/get_service_health.py`, `list_deployments.py`, `get_logs.py` — hardcoded mock data referencing 5 canonical services (payments degraded, others healthy).

**Mini-punchline:** "Six commands — scaffold, add tools, build, publish. The MCP server is in the registry."

**Transition:** "Tools tell the agent what it can *do*. But what does it *know*?"

## Act 3: The Knowledge (~2 min)

**Commands:**

1. `arctl skill init platform-best-practices`
2. Show default SKILL.md — "let's add real platform knowledge"
3. Copy in pre-written SKILL.md (SLA tiers, health check thresholds, deployment standards, team ownership, escalation procedures)
4. Briefly walk through key sections: "P0 means 15-minute response, payments is owned by payments-team"
5. `arctl skill build ./platform-best-practices --image platform-best-practices:v1.0.0 --push`
6. `arctl skill publish ./platform-best-practices --docker-image platform-best-practices:v1.0.0 --version 1.0.0`

**Pre-written files:** `03-Skills/platform-best-practices/SKILL.md`, `assets/escalation-matrix.md`, `references/k8s-standards.md`.

**Mini-punchline:** "Structured knowledge — SLA definitions, escalation procedures, team ownership — packaged and published."

**Transition:** "Let's see what we've got in the registry."

## Act 4: The Registry (~1 min)

**Commands:**

1. `arctl mcp list` — show ops-server
2. `arctl skill list` — show platform-best-practices
3. Open http://localhost:12121 — browse both artifacts in the UI

**Transition:** "One catalog for everything. Now let's compose an agent from these building blocks."

## Act 5: The Agent (~3 min)

**Commands:**

1. `arctl agent init adk python platform-ops-agent`
2. Show bare `agent.yaml` — "empty agent, no tools, no knowledge"
3. `arctl agent add-mcp --project-dir platform-ops-agent` — interactive: select registry, point to ops-server, set env vars (MCP_TRANSPORT_MODE=http, HOST=0.0.0.0)
4. `arctl agent add-skill platform-best-practices --project-dir platform-ops-agent --registry-skill-name platform-best-practices --registry-skill-version 1.0.0 --image platform-best-practices:v1.0.0`
5. `arctl prompt publish prompts/strict-operator.txt --name strict-operator --version 1.0.0 --description "Strict operator persona for platform ops"`
6. `arctl agent add-prompt strict-operator --project-dir platform-ops-agent --registry-prompt-name strict-operator`
7. Show final `agent.yaml` — "MCP server for tools, skill for knowledge, prompt for behavior"
8. `arctl agent build platform-ops-agent --push --platform linux/amd64`

**Pre-written files:** `02-Agents/prompts/strict-operator.txt` — 10 behavior rules defining formal operator persona.

**Mini-punchline:** "One agent, three building blocks, all from the registry. No custom glue code."

**Transition:** "Let's deploy this to Kubernetes."

## Act 6: The Deployment (~2 min)

**Commands:**

1. `kind load docker-image ops-server:latest --name agentregistry`
2. `kind load docker-image ghcr.io/platform-ops-agent:latest --name agentregistry`
3. `arctl deployments create sebastianmaniak/ops-server --type mcp --provider-id kubernetes-default --namespace default --version 0.1.0`
4. `arctl deployments create platform-ops-agent --type agent --provider-id kubernetes-default --namespace default`
5. `kubectl get pods -n kagent` — show everything running
6. `arctl deployments list` — show all deployments in registry

**Transition:** "Everything's running. Let's see what this agent can do."

## Act 7: The Magic (~2 min)

**Connect to Claude Code:**

```bash
claude mcp add --transport http ops-server http://localhost:21212/mcp
```

**Demo prompts (in order):**

1. **"Check the health of the payments service"**
   Agent calls `get_service_health` via MCP → sees 89.2% uptime, 340ms latency, 12.5% error rate. References SLA tiers from skill → classifies as P1 (High: error rate > 10%).

2. **"Should we escalate this?"**
   Agent references escalation matrix from skill → P1 lasting: page on-call, notify #payments-eng. Recommends paging payments-oncall via PagerDuty.

3. **"Generate an incident report"**
   Agent produces structured report using strict-operator persona:
   - Severity: P1
   - Affected Services: payments
   - Impact: elevated error rate and latency affecting payment processing
   - Metrics: from MCP tools
   - Recommended Actions: numbered list
   - Escalation Status: payments-team notified

**Final punchline:** "An empty terminal. Seven acts. One MCP server for tools, one skill for knowledge, one prompt for behavior, one agent to compose them all — registered, deployed to Kubernetes, and answering ops questions. That's agentregistry."

## File Deliverable

Single file: `STORYBOARD.md` at the repo root.

Includes:
- Prerequisites checklist (what to have ready, what goes live)
- All 7 acts with exact commands, talking points, transitions, and punchlines
- Cleanup section at the end
- References to pre-written files in 01-MCP/, 02-Agents/, 03-Skills/ that get copied in during the demo

## Pre-Written Content Dependencies

| Act | Pre-written file | Purpose |
|-----|-----------------|---------|
| 2 | `01-MCP/ops-server/src/tools/*.py` | Tool implementations with mock data |
| 3 | `03-Skills/platform-best-practices/SKILL.md` | Platform knowledge content |
| 3 | `03-Skills/platform-best-practices/assets/escalation-matrix.md` | Escalation reference |
| 3 | `03-Skills/platform-best-practices/references/k8s-standards.md` | K8s standards |
| 5 | `02-Agents/prompts/strict-operator.txt` | Agent persona prompt |

All pre-written content already exists in the repo from previous implementation tasks.

## What This Does NOT Include

- The per-folder standalone `demo-script.md` files remain unchanged — they're still useful for presenting individual sections
- No changes to existing code in 01-MCP, 02-Agents, or 03-Skills
- No changes to 00-Install/readme.md (the raw commands there serve as a reference; the storyboard is the presentation version)

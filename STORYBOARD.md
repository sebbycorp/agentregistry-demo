# From Zero to AI Ops Agent — Agentregistry Conference Demo

> What if you could go from an empty terminal to a fully deployed AI ops agent — with tools, knowledge, and a persona — in under 20 minutes?

## Overview

A 7-act live demo showing the full agentregistry lifecycle: install the platform, build an MCP server, package a skill, compose an agent, publish everything to the registry, deploy to Kubernetes, and connect to Claude Code.

**Total time:** ~18-20 minutes
**Audience:** Developers at a conference/meetup, first exposure to agentregistry.
**Format:** Live terminal, every command run on stage.

| Act | Title | Time | What Happens |
|-----|-------|------|-------------|
| 1 | The Platform | ~3 min | Install arctl, kind cluster, kagent, agentgateway |
| 2 | The Tools | ~2.5 min | Scaffold ops-server MCP, add tools, build & publish |
| 3 | The Knowledge | ~2 min | Scaffold skill, add platform best practices, build & publish |
| 4 | The Registry | ~1 min | Show both artifacts in the registry UI |
| 5 | The Agent | ~3 min | Scaffold agent, compose MCP + skill + prompt, build |
| 6 | The Deployment | ~2 min | Deploy everything to Kubernetes, verify pods |
| 7 | The Magic | ~2 min | Connect to Claude Code, three demo prompts, punchline |

## Prerequisites

**Have ready before going on stage:**

- [ ] Docker Desktop running
- [ ] Terminal open, clean working directory
- [ ] `OPENAI_API_KEY` env var set (for kagent)
- [ ] `GOOGLE_API_KEY` env var set (for Gemini ADK agent)
- [ ] Pre-written files accessible (see [Pre-Written Content](#pre-written-content) below)
- [ ] No existing kind cluster named `agentregistry`
- [ ] No existing arctl daemon running

### Pre-Written Content

These files are copied in during the demo to save typing. Have them ready to paste:

| Act | File | What It Contains |
|-----|------|-----------------|
| 2 | `01-MCP/ops-server/src/tools/get_service_health.py` | Service health with mock data (payments degraded) |
| 2 | `01-MCP/ops-server/src/tools/list_deployments.py` | K8s deployment listing with mock data |
| 2 | `01-MCP/ops-server/src/tools/get_logs.py` | Service log retrieval with mock data |
| 3 | `03-Skills/platform-best-practices/SKILL.md` | SLA tiers, health checks, team ownership, escalation |
| 5 | `02-Agents/prompts/strict-operator.txt` | Formal operator persona with 10 behavior rules |

---

## Act 1: The Platform (~3 min)

> "Let's start from nothing. An empty terminal."

### Install arctl

```bash
curl -fsSL https://raw.githubusercontent.com/agentregistry-dev/agentregistry/main/scripts/get-arctl | bash
arctl version
```

### Start the registry

```bash
arctl daemon start
```

> "The registry is now running at localhost:12121. Let's set up the infrastructure."

### Create the Kubernetes cluster

```bash
kind create cluster --name agentregistry
```

### Install kagent

```bash
# CRDs first
helm install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --namespace kagent \
  --create-namespace

# kagent with kmcp enabled
helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --namespace kagent \
  --set kmcp.enabled=true \
  --set agents.enabled=false \
  --set providers.default=openAI \
  --set providers.openAI.apiKey=$OPENAI_API_KEY
```

### Install agentgateway

```bash
# Gateway API CRDs
kubectl apply --server-side --force-conflicts \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml

# Agentgateway CRDs
helm upgrade -i agentgateway-crds oci://cr.agentgateway.dev/charts/agentgateway-crds \
  --create-namespace --namespace agentgateway-system \
  --version v1.1.0 \
  --set controller.image.pullPolicy=Always

# Agentgateway controller
helm upgrade -i agentgateway oci://cr.agentgateway.dev/charts/agentgateway \
  --namespace agentgateway-system \
  --version v1.1.0 \
  --set controller.image.pullPolicy=Always \
  --set controller.extraEnv.KGW_ENABLE_GATEWAY_API_EXPERIMENTAL_FEATURES=true \
  --wait
```

### Verify everything is running

```bash
kubectl get pods -n kagent
kubectl get pods -n agentgateway-system
```

> "Platform's ready — arctl, kind cluster, kagent, and agentgateway. Now let's give it something to run."

---

## Act 2: The Tools (~2.5 min)

> "Every AI agent needs tools. Let's build an MCP server."

### Scaffold the MCP server

```bash
arctl mcp init python ops-server
# Description: DevOps platform engineering MCP server
# Author: Sebastian
# Email: sebastian.maniak@solo.io
```

### Show the default tool

```bash
cat ops-server/src/tools/echo.py
```

> "Here's the default echo tool. Let's replace it with real ops tools."

### Add tool stubs

```bash
arctl mcp add-tool get_service_health --project-dir ops-server
arctl mcp add-tool list_deployments --project-dir ops-server
arctl mcp add-tool get_logs --project-dir ops-server
```

### Copy in the pre-written implementations

```bash
# [Copy pre-written tool files into ops-server/src/tools/]
# Briefly show one:
cat ops-server/src/tools/get_service_health.py
```

> "Hardcoded mock data — five services, payments is degraded with 12.5% error rate. Perfect for a demo."

### Show all tools

```bash
ls ops-server/src/tools/
```

### Build and publish

```bash
arctl mcp build ops-server --image ops-server
arctl mcp publish ops-server --type oci --package-id ops-server
```

> "Six commands — scaffold, add tools, build, publish. The MCP server is in the registry."

> "Tools tell the agent what it can *do*. But what does it *know*?"

---

## Act 3: The Knowledge (~2 min)

> "An agent with tools but no knowledge is dangerous. Let's give it expertise."

### Scaffold the skill

```bash
arctl skill init platform-best-practices
```

### Show the default SKILL.md

```bash
cat platform-best-practices/SKILL.md
```

> "Empty template. Let's fill it with real platform knowledge."

### Copy in the pre-written content

```bash
# [Copy pre-written SKILL.md into platform-best-practices/]
# Walk through key sections:
cat platform-best-practices/SKILL.md
```

> "SLA tiers — P0 means 15-minute response, P1 means 30 minutes. Health check thresholds — error rate above 5% is critical. Team ownership — payments is owned by payments-team, they're on PagerDuty. Escalation procedures — P0 gets an incident commander, status updates every 15 minutes."

### Build and publish

```bash
arctl skill build ./platform-best-practices \
  --image platform-best-practices:v1.0.0 --push

arctl skill publish ./platform-best-practices \
  --docker-image platform-best-practices:v1.0.0 \
  --version 1.0.0
```

> "Structured knowledge — SLA definitions, escalation procedures, team ownership — packaged and published."

> "Let's see what we've got in the registry."

---

## Act 4: The Registry (~1 min)

> "Everything we build goes into one catalog."

```bash
arctl mcp list
arctl skill list
```

### Open the registry UI

Open http://localhost:12121 in a browser.

> "One MCP server, one skill — both in the registry, versioned, discoverable. Now let's compose an agent from these building blocks."

---

## Act 5: The Agent (~3 min)

> "Here's where it all comes together."

### Scaffold the agent

```bash
arctl agent init adk python platform-ops-agent
```

### Show the bare agent

```bash
cat platform-ops-agent/agent.yaml
```

> "Out of the box — an empty agent. No tools, no knowledge, no personality. Let's fix that."

### Add the MCP server

```bash
arctl agent add-mcp --project-dir platform-ops-agent
# Interactive prompts:
#   Source: registry
#   Registry URL: http://localhost:12121
#   Select: ops-server
#   Env vars: MCP_TRANSPORT_MODE=http, HOST=0.0.0.0
#   Name: ops-server
```

> "Now the agent can check service health, view deployments, and read logs."

### Add the skill

```bash
arctl agent add-skill platform-best-practices \
  --project-dir platform-ops-agent \
  --registry-skill-name platform-best-practices \
  --registry-skill-version 1.0.0 \
  --image platform-best-practices:v1.0.0
```

> "Now it has operational knowledge — SLA definitions, escalation procedures."

### Publish and add the prompt

```bash
# Publish the strict-operator prompt to the registry
arctl prompt publish prompts/strict-operator.txt \
  --name strict-operator \
  --version 1.0.0 \
  --description "Strict operator persona for platform ops"

# Add it to the agent
arctl agent add-prompt strict-operator \
  --project-dir platform-ops-agent \
  --registry-prompt-name strict-operator
```

### Show the composed agent

```bash
cat platform-ops-agent/agent.yaml
```

> "MCP server for tools, skill for knowledge, prompt for behavior — all composed from the registry."

### Build the agent

```bash
arctl agent build platform-ops-agent --push --platform linux/amd64
```

> "One agent, three building blocks, all from the registry. No custom glue code."

> "Let's deploy this to Kubernetes."

---

## Act 6: The Deployment (~2 min)

> "From the registry to a running cluster."

### Load images to kind

```bash
kind load docker-image ops-server:latest --name agentregistry
kind load docker-image ghcr.io/platform-ops-agent:latest --name agentregistry
```

### Deploy the MCP server

```bash
arctl deployments create sebastianmaniak/ops-server \
  --type mcp \
  --provider-id kubernetes-default \
  --namespace default \
  --version 0.1.0
```

### Deploy the agent

```bash
arctl deployments create platform-ops-agent \
  --type agent \
  --provider-id kubernetes-default \
  --namespace default
```

### Verify

```bash
kubectl get pods -n kagent
arctl deployments list
```

> "MCP server and agent — both running on Kubernetes. Everything's live."

> "Let's see what this agent can do."

---

## Act 7: The Magic (~2 min)

> "Time to connect the dots."

### Connect Claude Code to the MCP server

```bash
claude mcp add --transport http ops-server http://localhost:21212/mcp
```

> Note: The exact port depends on what agentgateway assigns. Check `arctl deployments list` for the endpoint URL.

### Demo Prompt 1: Health Check

> **"Check the health of the payments service"**

The agent calls `get_service_health` via MCP. It sees: 89.2% uptime, 340ms latency, 12.5% error rate. It references the SLA tiers from its skill — error rate > 10% is P1 (High). It outputs a structured assessment with severity classification.

### Demo Prompt 2: Escalation

> **"Should we escalate this?"**

The agent references the escalation matrix from its skill. P1 severity — page on-call, notify team Slack channel. It knows payments is owned by payments-team (#payments-eng, payments-oncall on PagerDuty). It recommends specific escalation actions.

### Demo Prompt 3: Incident Report

> **"Generate an incident report for what's happening with payments"**

The agent produces a formal structured incident report using its strict-operator persona:

- **Severity:** P1 — High
- **Affected Services:** payments
- **Impact Summary:** Elevated error rate (12.5%) and latency (340ms) affecting payment processing
- **Current Metrics:** Data from MCP tools
- **Recommended Actions:** Numbered list of specific actions
- **Escalation Status:** payments-team to be notified via PagerDuty

### The Punchline

> "An empty terminal. Seven acts. One MCP server for tools, one skill for knowledge, one prompt for behavior, one agent to compose them all — registered, deployed to Kubernetes, and answering ops questions. That's agentregistry."

---

## Cleanup

```bash
# Remove deployments
arctl deployments list
arctl deployments delete <agent-deployment-id>
arctl deployments delete <mcp-deployment-id>

# Remove registry artifacts
arctl agent delete platform-ops-agent --version latest
arctl prompt delete strict-operator --version 1.0.0
arctl skill delete platform-best-practices --version 1.0.0
arctl mcp delete ops-server --version 0.1.0

# Remove Claude Code MCP connection
claude mcp remove ops-server

# Tear down cluster
kind delete cluster --name agentregistry

# Stop daemon
arctl daemon stop
```

---

## Quick Reference: The Story Arc

```
Act 1: The Platform     → "Platform's ready. Now let's give it something to run."
Act 2: The Tools        → "Tools tell the agent what it can do. But what does it know?"
Act 3: The Knowledge    → "Structured knowledge, packaged and published."
Act 4: The Registry     → "One catalog for everything. Now let's compose an agent."
Act 5: The Agent        → "One agent, three building blocks, all from the registry."
Act 6: The Deployment   → "Everything's live. Let's see what this agent can do."
Act 7: The Magic        → "That's agentregistry."
```

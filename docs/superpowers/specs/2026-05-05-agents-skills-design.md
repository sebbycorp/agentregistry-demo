# Agents & Skills Demo Design: Platform Ops Agent with Composable Registry Artifacts

## Overview

Two standalone demos (03-Skills, 02-Agents) showing the full agentregistry lifecycle for skills and agents. The skill packages platform best-practices knowledge. The agent composes an MCP server, the skill, and a prompt from the registry, then deploys to Kubernetes.

**Audience:** Developers at a conference/meetup, familiar with 01-MCP concepts or seeing this standalone.
**Format:** Live walkthrough, CLI-driven, minimal custom code.
**Approach:** Composition-focused — the agent's power comes from composing registry artifacts, not from custom code.

## 03-Skills: Platform Best Practices Skill

### What It Is

A structured knowledge package containing Kubernetes deployment standards, health check conventions, SLA definitions, and team ownership mappings. No executable code — just documentation that an agent can reference at runtime.

### SKILL.md Content

The `SKILL.md` file uses YAML frontmatter for metadata and markdown body for the knowledge content:

```yaml
---
name: platform-best-practices
description: Kubernetes deployment standards, SLA tiers, health check conventions, and team ownership mappings for platform operations
---
```

Body sections:

| Section | Content |
|---------|---------|
| Service SLA Tiers | P0-P3 definitions with response time targets (P0: 15min response, 1hr resolution) and resolution targets |
| Health Check Conventions | Standard endpoint paths (`/healthz`, `/readyz`), expected responses, degradation thresholds (latency > 200ms, error rate > 5%) |
| Deployment Standards | Per-tier replica counts, resource limits, rollback policies, canary percentages |
| Team Ownership | Service-to-team mapping (payments → payments-team, auth → identity-team, etc.) with Slack channels and on-call rotations |
| Escalation Procedures | When to page (P0/P1), escalation channels, incident commander assignment rules |

All data is hardcoded and references the same five canonical services from 01-MCP (payments, auth, orders, inventory, notifications).

### Assets & References

- `assets/escalation-matrix.md` — visual escalation matrix with severity → action mapping
- `references/k8s-standards.md` — detailed Kubernetes deployment conventions

### Folder Structure

```
03-Skills/
├── demo-script.md
├── platform-best-practices/
│   ├── SKILL.md
│   ├── Dockerfile
│   ├── LICENSE.txt
│   ├── assets/
│   │   └── escalation-matrix.md
│   ├── references/
│   │   └── k8s-standards.md
│   └── scripts/
```

### Demo Flow (3 Acts, ~5 min)

**Act 1: Scaffold the Skill (~1 min)**
1. `arctl skill init platform-best-practices` — scaffold live
2. Show generated structure: `SKILL.md`, `Dockerfile`, `assets/`, `references/`
3. Open default `SKILL.md` — "let's replace this with real platform knowledge"

**Act 2: Add Platform Knowledge (~2 min)**
1. Replace `SKILL.md` with pre-written platform best practices content
2. Add `assets/escalation-matrix.md` and `references/k8s-standards.md`
3. Walk through key sections: SLA tiers, health check thresholds, team ownership

**Act 3: Build & Publish (~2 min)**
1. `arctl skill build ./platform-best-practices --image platform-best-practices:v1.0.0`
2. `arctl skill build ./platform-best-practices --image platform-best-practices:v1.0.0 --push`
3. `arctl skill publish ./platform-best-practices --docker-image platform-best-practices:v1.0.0 --version 1.0.0`
4. `arctl skill list` — show it in the catalog
5. Open registry UI — show skill entry with metadata

**Punchline:** "Structured knowledge, packaged as a skill, published to the registry — ready for any agent to use."

## 02-Agents: Platform Ops Agent

### What It Is

A composition-focused agent scaffolded with `arctl agent init`. Minimal custom `agent.py` — the value comes from wiring together:
- **MCP Server:** ops-server from 01-MCP (service health, deployments, logs)
- **Skill:** platform-best-practices from 03-Skills (K8s standards, SLAs, ownership)
- **Prompt:** strict-operator (formal incident response persona)

### agent.yaml Configuration

```yaml
agentName: platform-ops-agent
image: ghcr.io/platform-ops-agent:latest
language: python
framework: adk
modelProvider: gemini
modelName: gemini-2.0-flash
description: "Platform Ops Agent — deployment management, escalation, incident response"
mcpServers:
  - type: registry
    name: ops-server
    env:
      - MCP_TRANSPORT_MODE=http
      - HOST=0.0.0.0
    registryURL: http://localhost:12121
    registryServerName: user/ops-server
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

### Prompt: strict-operator.txt

Defines the agent's persona and behavior:

- Always identify yourself as "Platform Ops Agent"
- Assess severity first using SLA tier definitions from the platform-best-practices skill
- Output structured incident reports: Severity, Affected Services, Impact Summary, Recommended Actions, Escalation Status
- Follow the escalation matrix before recommending actions
- Never take destructive actions (rollbacks, restarts) without explicit confirmation
- Reference specific SLA targets when reporting on service health
- Use formal, concise language — no speculation, only data-backed assessments

### Folder Structure

```
02-Agents/
├── demo-script.md
├── platform-ops-agent/
│   ├── agent.yaml
│   ├── docker-compose.yaml
│   ├── Dockerfile
│   ├── platform_ops_agent/
│   │   └── agent.py
│   ├── pyproject.toml
│   └── README.md
├── prompts/
│   └── strict-operator.txt
```

### Demo Flow (5 Acts, ~5 min)

**Act 1: Scaffold the Agent (~30s)**
1. `arctl agent init adk python platform-ops-agent` — scaffold live
2. Show generated structure: `agent.yaml`, `agent.py`, `Dockerfile`
3. "Out of the box it's a bare agent — let's compose it with registry artifacts"

**Act 2: Add MCP Server (~1 min)**
1. `arctl agent add-mcp --project-dir platform-ops-agent`
2. Interactive: select registry source, point to ops-server, set env vars
3. Show updated `agent.yaml` with `mcpServers` section
4. "Now the agent can check service health, view deployments, and read logs"

**Act 3: Add Skill & Prompt (~1.5 min)**
1. `arctl agent add-skill platform-best-practices --project-dir platform-ops-agent --registry-skill-name platform-best-practices --registry-skill-version 1.0.0 --image platform-best-practices:v1.0.0`
2. Show updated `agent.yaml` with `skills` section
3. `arctl prompt publish prompts/strict-operator.txt --name strict-operator --version 1.0.0 --description "Strict operator persona for platform ops"`
4. `arctl agent add-prompt strict-operator --project-dir platform-ops-agent --registry-prompt-name strict-operator`
5. Show final `agent.yaml` with all three: MCP server, skill, prompt

**Act 4: Build & Deploy to Kubernetes (~1.5 min)**
1. `arctl agent build platform-ops-agent --push --platform linux/amd64`
2. `kind load docker-image ghcr.io/platform-ops-agent:latest --name agentregistry`
3. `arctl deployments create platform-ops-agent --type agent --provider-id kubernetes-default --namespace default`
4. `kubectl get pods` — show agent running alongside MCP server pods from 01-MCP
5. `arctl deployments list` — show all deployments in registry

**Act 5: Live Demo (~1 min, climax)**
1. `arctl agent run platform-ops-agent`
2. Ask: "What's the status of the payments service?"
   - Agent calls `get_service_health` via MCP, references SLA tiers from skill, outputs structured report
3. Ask: "Should we escalate this?"
   - Agent references escalation matrix from skill, identifies P1 severity, recommends paging payments-team
4. Ask: "Generate an incident report"
   - Agent produces formal incident report using strict-operator persona, data from MCP, and standards from skill

**Punchline:** "One agent, one MCP server, one skill, one prompt — all from the registry, deployed to Kubernetes, producing structured incident reports in under 5 minutes."

## Prerequisites

- 01-MCP: ops-server must be built and published to the registry
- 03-Skills: platform-best-practices must be built and published
- Docker Desktop running, `arctl daemon start` completed
- Kind cluster: `kind create cluster --name agentregistry`
- For agent run: `GOOGLE_API_KEY` env var set (Gemini ADK requirement)

## What We Reuse

- The entire `arctl agent init adk python` scaffold (agent.py, Dockerfile, docker-compose.yaml, pyproject.toml)
- The `arctl skill init` scaffold (SKILL.md, Dockerfile, assets/, references/)
- ops-server MCP from 01-MCP (already published to registry)
- The agentregistry CLI for all build/publish/deploy operations
- The existing kind cluster from 01-MCP demo

## Implementation Scope

- 1 SKILL.md with platform best practices content
- 2 reference/asset files for the skill
- 1 strict-operator.txt prompt file
- 1 agent.yaml with MCP server, skill, and prompt composition
- 2 demo-script.md files (standalone, one per folder)
- Minimal agent.py — scaffold default with model config only

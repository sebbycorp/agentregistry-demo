# Agents Demo Script — Agentregistry Conference Demo

## Prerequisites (before going on stage)

- arctl daemon running: `arctl daemon start`
- Docker running
- kind cluster ready: `kind create cluster --name agentregistry`
- kagent installed on cluster (see kagent OSS quickstart)
- 01-MCP: ops-server built and published to registry
- 03-Skills: platform-best-practices skill built and published to registry
- `GOOGLE_API_KEY` env var set (Gemini ADK requirement)
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
export GOOGLE_API_KEY=<your-key>
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

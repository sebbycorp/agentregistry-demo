# MCP Demo Script — Agentregistry Conference Demo

## Prerequisites (before going on stage)

- arctl daemon running: `arctl daemon start`
- Docker running
- kind cluster ready: `kind create cluster --name agentregistry`
- kagent installed on cluster (see kagent OSS quickstart)
- Clean slate: `arctl mcp list` shows no existing servers
- Claude Code installed and open

---

## Act 1: Build the Ops Server (~1.5 min)

```bash
# Scaffold
arctl mcp init python ops-server
# Description: DevOps platform engineering MCP server
# Author: Sebastian Maniak
# Email: sebastian.maniak@solo.io

# Show the default tool
cat ops-server/src/tools/echo.py
# "Here's the default echo tool — let's replace it with something useful"

# Add our tools
arctl mcp add-tool get_service_health --project-dir ops-server
arctl mcp add-tool list_deployments --project-dir ops-server
arctl mcp add-tool get_logs --project-dir ops-server

# [Copy in the pre-written tool implementations]
# Show the tool code briefly:
cat ops-server/src/tools/get_service_health.py

# Show all tools
ls ops-server/src/tools/

# Build and publish
arctl mcp build ops-server --image ops-server
arctl mcp publish ops-server --type oci --package-id ops-server
```

## Act 2: Build the Support Server (~1 min)

```bash
arctl mcp init python support-server
# Description: Customer support and knowledge base MCP server

arctl mcp add-tool search_docs --project-dir support-server
arctl mcp add-tool get_ticket --project-dir support-server
arctl mcp add-tool list_open_tickets --project-dir support-server

# [Copy in the pre-written tool implementations]

arctl mcp build support-server --image support-server
arctl mcp publish support-server --type oci --package-id support-server
```

## Act 3: The Registry (~30s)

```bash
arctl mcp list
```

Then open http://localhost:12121 and show both servers in the UI.

## Act 4: Deploy to Kubernetes (~1 min)

```bash
# Load images to kind (since we built locally)
kind load docker-image ops-server:0.1.0 --name agentregistry
kind load docker-image support-server:0.1.0 --name agentregistry

# Deploy
arctl deployments create ops-server \
  --type mcp \
  --provider-id kubernetes-default \
  --namespace default \
  --version 0.1.0

arctl deployments create support-server \
  --type mcp \
  --provider-id kubernetes-default \
  --namespace default \
  --version 0.1.0

# Verify
kubectl get pods | grep -E "ops-server|support-server"
```

## Act 5: The AI Agent (~1 min)

Open Claude Code. Add both MCP servers:

```bash
claude mcp add ops-server --transport http --url http://localhost:21212/mcp
claude mcp add support-server --transport http --url http://localhost:21213/mcp
```

### Demo prompts (in order):

1. **"Check the health of the payments service"**
   Claude calls `get_service_health` -> sees degraded (89.2% uptime, 12.5% error rate)

2. **"Are there any support tickets related to payments?"**
   Claude calls `list_open_tickets` -> finds TICK-1042 (timeout errors) and TICK-1057 (502 gateway errors)

3. **"Summarize what's going on with payments and what our customers are experiencing"**
   Claude synthesizes both -> incident summary connecting infra issues with customer impact

### Punchline:

> "Two teams, two MCP servers, one registry, one AI agent connecting the dots — built in under 5 minutes."

---

## Cleanup

```bash
arctl deployments list
arctl deployments delete <ops-deployment-id>
arctl deployments delete <support-deployment-id>
arctl mcp delete ops-server --version 0.1.0
arctl mcp delete support-server --version 0.1.0
```

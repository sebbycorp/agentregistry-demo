# MCP Demo Design: Two-Server Agentregistry Walkthrough

## Overview

A 5-minute conference demo showing the full agentregistry MCP lifecycle: scaffold, add tools, build, publish, deploy to Kubernetes, and connect to Claude Code. Two MCP servers from two different domains demonstrate multi-team catalog value and cross-server AI orchestration.

**Audience:** Developers at a conference/meetup, first exposure to agentregistry.
**Format:** Live walkthrough, linear build-up, every `arctl` command shown.
**Climax:** Claude Code queries both deployed servers to correlate an infrastructure incident with customer support tickets.

## MCP Server #1: ops-server (DevOps/Platform Engineering)

### Tools

| Tool | Signature | Description |
|------|-----------|-------------|
| `get_service_health` | `(service_name: str) -> str` | Returns JSON with status (healthy/degraded/down), uptime, latency_ms, error_rate, and checked_at for a named service. |
| `list_deployments` | `(namespace: str = "default") -> str` | Returns a JSON list of 3-4 mock deployments with name, version, timestamp, status (running/rolling/failed), and replica count. |
| `get_logs` | `(service_name: str, severity: str = "all") -> str` | Returns 5-8 mock log lines with timestamp, severity, and message. Filterable by severity (info/warn/error). |

### Mock Data

Five canonical services: `payments`, `auth`, `orders`, `inventory`, `notifications`.

- `payments` is always degraded: 89.2% uptime, 340ms latency, 12.5% error rate.
- `auth`, `orders`, `inventory`, `notifications` are healthy with normal metrics.
- Deployments include a recent `payments` deploy that is in `rolling` state.
- Logs for `payments` include connection timeout and retry messages.

All data is hardcoded in the tool functions. No randomness, no external dependencies.

## MCP Server #2: support-server (Customer Support / Knowledge Base)

### Tools

| Tool | Signature | Description |
|------|-----------|-------------|
| `search_docs` | `(query: str) -> str` | Returns JSON list of 2-3 matching KB articles with title, snippet, relevance_score, and article_id. |
| `get_ticket` | `(ticket_id: str) -> str` | Returns a single mock support ticket with id, customer, subject, status, priority, created_at, and description. |
| `list_open_tickets` | `(service: str = "") -> str` | Returns JSON list of 3-5 open tickets. Filterable by service/category name. |

### Mock Data

KB articles and tickets reference the same five services from ops-server.

- Two open tickets specifically about `payments` timeouts (TICK-1042, TICK-1057).
- KB articles cover "Payment processing timeouts", "Auth token refresh guide", "Order API rate limits".
- Ticket subjects and descriptions use language that correlates with ops-server log messages (e.g., "connection timeouts", "gateway errors").

This deliberate cross-referencing ensures the Claude Code finale always produces a correlated narrative.

## Demo Flow (5 Acts)

### Act 1: Build the Ops Server (~1.5 min)

1. `arctl mcp init python ops-server` -- scaffold live
2. Briefly show default `echo.py` -- "let's replace this with real tools"
3. `arctl mcp add-tool get_service_health --project-dir ops-server`
4. Show the implemented tool code (pre-written, paste in)
5. Mention "we also added list_deployments and get_logs" -- `ls ops-server/src/tools/`
6. `arctl mcp build ops-server --image ops-server`
7. `arctl mcp publish ops-server --type oci --package-id ops-server`

### Act 2: Build the Support Server (~1 min)

Same flow, faster. Audience already knows the pattern.

1. `arctl mcp init python support-server`
2. Add tools: `search_docs`, `get_ticket`, `list_open_tickets`
3. `arctl mcp build support-server --image support-server`
4. `arctl mcp publish support-server --type oci --package-id support-server`

### Act 3: The Registry (~30s)

1. `arctl mcp list` -- show both servers in the catalog
2. Open agentregistry UI -- visually show both entries with version, type, metadata

### Act 4: Deploy to Kubernetes (~1 min)

1. `arctl deployments create ops-server --type mcp --provider-id kubernetes-default --namespace default --version 0.1.0`
2. `arctl deployments create support-server --type mcp --provider-id kubernetes-default --namespace default --version 0.1.0`
3. `kubectl get pods` -- show both running
4. Note the Agent Gateway endpoints

### Act 5: The AI Agent (~1 min, climax)

1. Open Claude Code with both MCP servers configured as remote endpoints
2. Ask: "Check the health of the payments service" -- Claude calls `get_service_health`, sees degraded status
3. Ask: "Are there any support tickets related to payments?" -- Claude calls `list_open_tickets`, finds 2 tickets about payment timeouts
4. Ask: "Summarize what's going on with payments and what our customers are experiencing" -- Claude synthesizes data from both servers

**Punchline:** "Two teams, two MCP servers, one registry, one AI agent connecting the dots -- built in under 5 minutes."

## Project Structure

Both servers use the standard `arctl mcp init python` scaffold:

```
ops-server/
  Dockerfile
  mcp.yaml
  pyproject.toml
  src/
    main.py
    core/
      server.py
      utils.py
    tools/
      get_service_health.py
      list_deployments.py
      get_logs.py
  tests/

support-server/
  Dockerfile
  mcp.yaml
  pyproject.toml
  src/
    main.py
    core/
      server.py
      utils.py
    tools/
      search_docs.py
      get_ticket.py
      list_open_tickets.py
  tests/
```

The `core/`, `main.py`, `Dockerfile`, and `pyproject.toml` come from the scaffold template and are used as-is. Only the tool files are custom -- 3 per server, 6 total. The default `echo.py` is deleted from both.

## Claude Code Configuration

After deployment, both servers are configured in Claude Code's MCP settings pointing at the Agent Gateway URLs. Add to `.claude.json` (or via `claude mcp add`):

```json
{
  "mcpServers": {
    "ops-server": {
      "type": "url",
      "url": "http://localhost:21212/mcp"
    },
    "support-server": {
      "type": "url",
      "url": "http://localhost:21213/mcp"
    }
  }
}
```

The exact ports depend on what the Agent Gateway assigns during deployment. These can be pre-staged with placeholder ports and updated after `arctl deployments create` outputs the endpoints, or added live via `claude mcp add --transport http` during the demo.

## Implementation Scope

- 6 tool files with hardcoded mock data (the core deliverable)
- 2 `mcp.yaml` configs with correct server metadata
- Pre-staged Claude Code MCP config for the finale
- Optional: a demo script/cheat-sheet with exact commands and talking points

## What We Reuse

- The entire `arctl mcp init python` scaffold (server.py, utils.py, main.py, Dockerfile, pyproject.toml)
- The agentregistry CLI for build/publish/deploy
- The existing kind cluster setup for k8s deployment

# Walkthrough — self-contained agentregistry demo

An interactive, educational run through the full agentregistry lifecycle:
install the platform, build + publish three artifacts, deploy to Kubernetes,
and connect to the Claude Code CLI. Every step prints an explanation, shows
the exact command, waits for **Enter** so you can narrate, then runs it live.

This folder is **self-contained** — it bundles its own copies of the three
artifacts, so you can run the demo without the rest of the repo. (The copies
were taken from `01-MCP/`, `02-Agents/`, and `03-Skills/`; `agent.yaml`
references everything by registry name, so nothing here depends on those
original paths.)

## Contents

| Path | What it is |
|------|------------|
| `walkthrough.sh` | The interactive deploy walkthrough (Phases 1–8) |
| `walkthrough-cleanup.sh` | Interactive teardown, reverses the walkthrough |
| `walkthrough.mmd` | Mermaid source of the build diagram (for slides) |
| `ops-server/` | MCP server — tools: `get_service_health`, `list_deployments`, `get_logs` |
| `platform-best-practices/` | Skill — SLA tiers, health thresholds, team ownership, escalation |
| `platform-ops-agent/` | Agent — ADK + gpt-4o, composes the MCP + skill + prompt |
| `prompts/strict-operator.txt` | The `strict-operator` operator-persona prompt |

## Run it

```bash
export OPENAI_API_KEY=sk-...        # required
cd walkthrough
./walkthrough.sh                    # full interactive walkthrough
./walkthrough.sh --no-pause         # rehearsal — no Enter prompts
./walkthrough.sh --skip-platform    # platform already installed
./walkthrough.sh --from 3           # resume from a phase (1–8)
```

Tear it back down:

```bash
./walkthrough-cleanup.sh            # confirms once
./walkthrough-cleanup.sh --yes      # no prompts
./walkthrough-cleanup.sh --keep-cluster
```

**Prereqs:** Docker Desktop, `OPENAI_API_KEY`, and `arctl`, `kind`, `kubectl`,
`helm` on your `PATH` (plus the `claude` CLI for the final connect step).

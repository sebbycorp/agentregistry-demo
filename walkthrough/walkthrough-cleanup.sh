#!/usr/bin/env bash
# walkthrough-cleanup.sh — Interactive teardown that mirrors walkthrough.sh.
#
# Reverses the walkthrough, in order, with the same show-then-run rhythm:
# each step explains what it removes, shows the command, waits for Enter, runs.
#
# Usage:
#   ./walkthrough-cleanup.sh             # interactive teardown (confirm once)
#   ./walkthrough-cleanup.sh --yes       # confirm + skip all Enter prompts
#   ./walkthrough-cleanup.sh --no-pause  # confirm once, then no Enter prompts
#   ./walkthrough-cleanup.sh --keep-cluster  # everything except deleting the kind cluster
#
# Best-effort: keeps going even if individual steps fail.

set -uo pipefail   # no -e: cleanup continues on errors.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# ─── Config (mirrors walkthrough.sh) ─────────────────────────────────
CLUSTER_NAME="agentregistry"
MCP_NAME="ops-server"
MCP_VERSION="0.1.0"
SKILL_NAME="platform-best-practices"
SKILL_VERSION="1.0.0"
PROMPT_NAME="strict-operator"
PROMPT_VERSION="1.0.0"
AGENT_NAME="platformopsagent"
KIND_REGISTRY_HOST="localhost:5001"

IMAGES=(
  "ops-server:latest"
  "ghcr.io/platform-ops-agent:latest"
  "platform-best-practices:v${SKILL_VERSION}"
  "${KIND_REGISTRY_HOST}/platform-best-practices:v${SKILL_VERSION}"
)

# ─── UI ──────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; CYAN=$'\033[36m'; GREEN=$'\033[32m'
  YELLOW=$'\033[33m'; RED=$'\033[31m'; MAGENTA=$'\033[35m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; CYAN=""; GREEN=""; YELLOW=""; RED=""; MAGENTA=""; RESET=""
fi

ok()      { echo -e "${GREEN}✔${RESET} $*"; }
warn()    { echo -e "${YELLOW}!${RESET} $*"; }
explain() { echo -e "${YELLOW}ℹ${RESET} $*"; }
phase()   { echo; echo -e "${BOLD}${MAGENTA}▎ $* ${RESET}"; echo -e "${MAGENTA}$(printf '─%.0s' {1..60})${RESET}"; }

NO_PAUSE=0
have()      { command -v "$1" >/dev/null 2>&1; }
daemon_up() { curl -fsS http://localhost:12121/v0/version >/dev/null 2>&1; }

pause() {
  (( NO_PAUSE )) && return 0
  printf "\n${DIM}  ▶ press Enter to run…${RESET}"
  read -r _ || true
  echo
}
show() { echo; echo -e "    ${BOLD}${GREEN}❯${RESET} ${BOLD}${YELLOW}$*${RESET}"; }
out_open()  { echo -e "    ${DIM}╭─ output ${DIM}$(printf '─%.0s' {1..48})${RESET}"; }
out_close() { echo -e "    ${DIM}╰$(printf '─%.0s' {1..57})${RESET}"; echo; }
runc() { show "$1"; pause; out_open; eval "$1"; out_close; }

# ─── Step 1 — disconnect Claude Code + stop the port-forward ─────────
clean_claude() {
  phase "Step 1 — Disconnect the Claude Code CLI"
  explain "Remove the MCP registration and kill the background port-forward."

  if have claude; then
    runc "claude mcp remove ops-server || true"
  else
    warn "claude CLI not found — skipping (run 'claude mcp remove ops-server' yourself)"
  fi

  if [[ -f /tmp/walkthrough-pf.pid ]]; then
    local pid; pid=$(cat /tmp/walkthrough-pf.pid 2>/dev/null || true)
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      runc "kill $pid"
      ok "port-forward (pid $pid) stopped"
    else
      warn "recorded port-forward pid not running"
    fi
    rm -f /tmp/walkthrough-pf.pid
  else
    # Fall back to killing any port-forward on :3000
    pkill -f "port-forward.*3000:3000" 2>/dev/null && ok "killed stray port-forward on :3000" || warn "no port-forward pid recorded"
  fi
}

# ─── Step 2 — delete arctl/k8s deployments ───────────────────────────
clean_deployments() {
  phase "Step 2 — Delete the Kubernetes deployments"
  explain "Remove the agent + MCP deployments arctl created on the cluster."
  if have arctl && daemon_up; then
    local id
    while read -r id; do
      [[ -z "$id" ]] && continue
      runc "arctl deployments delete $id || true"
    done < <(arctl deployments list 2>/dev/null | awk 'NR>1 {print $1}')
  else
    warn "arctl daemon not reachable — skipping arctl deployment cleanup"
  fi
  if have kubectl && kubectl config get-contexts "kind-${CLUSTER_NAME}" >/dev/null 2>&1; then
    runc "kubectl --context kind-${CLUSTER_NAME} delete agent --all -n default --ignore-not-found || true"
    runc "kubectl --context kind-${CLUSTER_NAME} delete deploy,svc,cm -n default -l 'aregistry.ai/deployment-id' --ignore-not-found || true"
  fi
}

# ─── Step 3 — delete published registry artifacts ───────────────────
clean_registry() {
  phase "Step 3 — Delete the published registry artifacts"
  explain "Remove the three artifacts we published: agent, MCP server, skill, prompt."
  if ! have arctl; then warn "arctl not in PATH — skipping registry cleanup"; return; fi
  if ! daemon_up; then
    warn "arctl daemon not reachable — starting it to delete artifacts"
    arctl daemon start >/dev/null 2>&1 || { warn "could not start daemon — skipping"; return; }
    for _ in {1..15}; do daemon_up && break; sleep 1; done
  fi
  runc "arctl agent  delete $AGENT_NAME || true"
  runc "arctl mcp    delete $MCP_NAME --version $MCP_VERSION || true"
  runc "arctl skill  delete $SKILL_NAME --version $SKILL_VERSION || true"
  runc "arctl prompt delete $PROMPT_NAME --version $PROMPT_VERSION || true"
}

# ─── Step 4 — delete the kind cluster ────────────────────────────────
clean_cluster() {
  phase "Step 4 — Delete the kind cluster"
  if (( KEEP_CLUSTER )); then warn "--keep-cluster set — leaving '$CLUSTER_NAME' intact"; return; fi
  explain "Deleting the cluster removes every remaining in-cluster resource at once."
  if ! have kind; then warn "kind not in PATH — skipping"; return; fi
  if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
    runc "kind delete cluster --name $CLUSTER_NAME"
  else
    warn "kind cluster '$CLUSTER_NAME' not present"
  fi
}

# ─── Step 5 — stop the arctl daemon ──────────────────────────────────
clean_daemon() {
  phase "Step 5 — Stop the arctl daemon"
  if ! have arctl; then warn "arctl not in PATH — skipping"; return; fi
  if daemon_up; then
    runc "arctl daemon stop || true"
  else
    warn "arctl daemon not running"
  fi
}

# ─── Step 6 — remove kind-registry container ─────────────────────────
clean_kind_registry() {
  phase "Step 6 — Remove the kind-registry container"
  if ! have docker; then warn "docker not in PATH — skipping"; return; fi
  if docker ps -a --format '{{.Names}}' | grep -qx kind-registry; then
    runc "docker rm -f kind-registry"
  else
    warn "kind-registry container not present"
  fi
}

# ─── Step 7 — remove demo docker images ──────────────────────────────
clean_images() {
  phase "Step 7 — Remove the demo docker images"
  if ! have docker; then warn "docker not in PATH — skipping"; return; fi
  local img
  for img in "${IMAGES[@]}"; do
    if docker image inspect "$img" >/dev/null 2>&1; then
      runc "docker rmi -f $img || true"
    else
      echo "  · $img not present"
    fi
  done
}

# ─── CLI parsing ─────────────────────────────────────────────────────
KEEP_CLUSTER=0
ASSUME_YES=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)       ASSUME_YES=1; NO_PAUSE=1; shift ;;
    --no-pause)     NO_PAUSE=1; shift ;;
    --keep-cluster) KEEP_CLUSTER=1; shift ;;
    -h|--help)      sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

# ─── Main ────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}══ Tear down the agentregistry walkthrough ══${RESET}"
echo "  • disconnect Claude Code + stop the port-forward"
echo "  • delete the Kubernetes deployments"
echo "  • delete the published registry artifacts"
(( KEEP_CLUSTER )) && echo "  • (keeping the kind cluster)" || echo "  • delete the kind cluster '$CLUSTER_NAME'"
echo "  • stop the arctl daemon"
echo "  • remove the kind-registry container + demo images"
echo
if (( ! ASSUME_YES )); then
  printf "${YELLOW}Proceed? [y/N] ${RESET}"
  read -r ans || true
  [[ "${ans:-}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

clean_claude
clean_deployments
clean_registry
clean_cluster
clean_daemon
clean_kind_registry
clean_images

phase "Teardown complete"
echo "  Everything from the walkthrough has been removed (best-effort)."
echo "  Re-run ./walkthrough.sh to start fresh."

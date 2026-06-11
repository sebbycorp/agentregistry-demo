#!/usr/bin/env bash
# walkthrough.sh — Interactive, educational walkthrough of the agentregistry
# lifecycle (STORYBOARD.md, Acts 1-7).
#
# Unlike deploy-all.sh (one-shot, hands-off), this script is built for talking
# to an audience. Every step:
#   1. prints a short plain-English explanation of WHAT we're about to do,
#   2. shows the exact command(s) we'll run,
#   3. waits for you to press Enter (so you can narrate),
#   4. runs them live and prints the result.
#
# It builds + publishes all three AI artifacts (MCP server, skill, agent),
# pushes them to the registry, deploys them to Kubernetes, and finishes by
# printing the exact commands to wire the MCP server into the Claude Code CLI.
#
# Usage:
#   ./walkthrough.sh                 # full interactive walkthrough
#   ./walkthrough.sh --no-pause      # run unattended (no Enter prompts) — rehearsal
#   ./walkthrough.sh --skip-platform # skip Phase 1 (platform already installed)
#   ./walkthrough.sh --from <phase>  # resume from phase 2|3|4|5|6|7
#
# Prereqs: Docker Desktop, OPENAI_API_KEY, arctl, kind, kubectl, helm,
#          and (for the final step) the `claude` CLI.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# ─── Config ──────────────────────────────────────────────────────────
CLUSTER_NAME="agentregistry"
MCP_NAME="ops-server"
MCP_VERSION="0.1.0"
SKILL_NAME="platform-best-practices"
SKILL_VERSION="1.0.0"
PROMPT_NAME="strict-operator"
PROMPT_VERSION="1.0.0"
AGENT_NAME="platformopsagent"
AGENT_IMAGE="ghcr.io/platform-ops-agent:latest"
KIND_REGISTRY_HOST="localhost:5001"
IN_CLUSTER_REGISTRY="kind-registry:5000"
REGISTRY_UI="http://localhost:12121"
MCP_LOCAL_URL="http://localhost:3000/mcp"

# Host CPU arch → docker platform
case "$(uname -m)" in
  arm64|aarch64) PLATFORM="linux/arm64" ;;
  x86_64|amd64)  PLATFORM="linux/amd64" ;;
  *) echo "Unsupported arch: $(uname -m)"; exit 1 ;;
esac

# ─── UI ──────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; CYAN=$'\033[36m'; GREEN=$'\033[32m'
  YELLOW=$'\033[33m'; RED=$'\033[31m'; MAGENTA=$'\033[35m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; CYAN=""; GREEN=""; YELLOW=""; RED=""; MAGENTA=""; RESET=""
fi

ok()      { echo -e "${GREEN}✔${RESET} $*"; }
warn()    { echo -e "${YELLOW}!${RESET} $*"; }
fail()    { echo -e "${RED}✘${RESET} $*"; exit 1; }
explain() { echo -e "${YELLOW}ℹ${RESET} $*"; }
banner()  { echo; echo -e "${BOLD}${CYAN}══ $* ══${RESET}"; }
phase()   { echo; echo; echo -e "${BOLD}${MAGENTA}▎ $* ${RESET}"; echo -e "${MAGENTA}$(printf '─%.0s' {1..60})${RESET}"; }

NO_PAUSE=0
# Wait for the presenter to press Enter so they can talk through the step.
pause() {
  (( NO_PAUSE )) && return 0
  printf "\n${DIM}  ▶ press Enter to run…${RESET}"
  read -r _ || true
  echo
}

# Print a command so it POPS — bright, bold, on its own line.
show() {
  echo
  echo -e "    ${BOLD}${GREEN}❯${RESET} ${BOLD}${YELLOW}$*${RESET}"
}

# Frame live command output so the audience sees where it starts/ends.
out_open()  { echo -e "    ${DIM}╭─ output ${DIM}$(printf '─%.0s' {1..48})${RESET}"; }
out_close() { echo -e "    ${DIM}╰$(printf '─%.0s' {1..57})${RESET}"; echo; }

# show + pause + run a single command string (so what you see is what runs),
# with its output framed.
runc() {
  local cmd="$1"
  show "$cmd"
  pause
  out_open
  eval "$cmd"
  out_close
}

# ─── Intro: the diagram + the plan ───────────────────────────────────
intro() {
  clear 2>/dev/null || true
  echo -e "${BOLD}${CYAN}"
  echo "  ┌──────────────────────────────────────────────────────────────┐"
  echo "  │   From Zero to AI Ops Agent — agentregistry walkthrough        │"
  echo "  └──────────────────────────────────────────────────────────────┘"
  echo -e "${RESET}"
  echo "  Three artifacts (tools, knowledge, persona) → one registry →"
  echo "  one agent that composes them → deployed to Kubernetes →"
  echo "  consumed by the Claude Code CLI."
  echo

  echo -e "${BOLD}What we're going to build${RESET}"
  echo
  local rule;  rule="$(printf '━%.0s' {1..60})"
  local arrow; arrow="                            ${DIM}│${RESET}"
  local tip;   tip="                            ${DIM}▼${RESET}"

  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "  ${BOLD}${CYAN} PHASE 2 · PLATFORM${RESET}"
  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "   arctl daemon ${DIM}:12121${RESET}  ·  kind cluster  ·  kagent + agentgateway"
  echo -e "$arrow"; echo -e "$tip"
  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "  ${BOLD}${CYAN} PHASES 3-5 · BUILD + PUBLISH THREE ARTIFACTS${RESET}"
  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "   ${GREEN}[1]${RESET} MCP server  ${BOLD}ops-server${RESET}              health · deployments · logs"
  echo -e "   ${GREEN}[2]${RESET} Skill       ${BOLD}platform-best-practices${RESET}  SLAs · escalation · owners"
  echo -e "   ${GREEN}[3]${RESET} Prompt      ${BOLD}strict-operator${RESET}          operator persona"
  echo -e "$arrow   ${DIM}composed into${RESET}"; echo -e "$tip"
  echo -e "   ${MAGENTA}Agent${RESET}  ${BOLD}platformopsagent${RESET}  ${DIM}(ADK + gpt-4o)${RESET}"
  echo -e "$arrow"; echo -e "$tip"
  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "  ${BOLD}${CYAN} PHASE 6 · REGISTRY @ :12121${RESET}"
  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "   all three artifacts catalogued and pullable"
  echo -e "$arrow"; echo -e "$tip"
  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "  ${BOLD}${CYAN} PHASE 7 · KUBERNETES${RESET}"
  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "   ops-server pod  ${DIM}+${RESET}  agent pod   ${DIM}(running)${RESET}"
  echo -e "$arrow"; echo -e "$tip"
  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "  ${BOLD}${CYAN} PHASE 8 · CLAUDE CODE CLI${RESET}"
  echo -e "  ${BOLD}${CYAN}${rule}${RESET}"
  echo -e "   port-forward ${DIM}:3000${RESET}  +  ${GREEN}claude mcp add${RESET}  →  use the tools live"
  echo
  echo -e "  ${DIM}Mermaid source for slides: walkthrough.mmd (paste into mermaid.live)${RESET}"
  echo

  echo -e "${BOLD}The plan${RESET}"
  echo "    1. Preflight ............ verify Docker, keys, and CLIs"
  echo "    2. Platform ............ kind cluster + arctl daemon + kagent + agentgateway"
  echo "    3. MCP server .......... build the tools, publish to the registry"
  echo "    4. Skill ............... build the knowledge pack, publish to the registry"
  echo "    5. Agent ............... compose MCP + skill + prompt, build, publish"
  echo "    6. Registry ............ confirm all three artifacts are catalogued"
  echo "    7. Deploy .............. run the agent + MCP server on Kubernetes"
  echo "    8. Connect ............. wire the MCP server into the Claude Code CLI"
  echo
  (( NO_PAUSE )) && { ok "Running unattended (--no-pause)"; return; }
  printf "${DIM}  ▶ press Enter to begin…${RESET}"
  read -r _ || true
}

# ─── Phase 1 — Preflight ─────────────────────────────────────────────
phase1_preflight() {
  phase "Phase 1 — Preflight"
  explain "Before we build anything, make sure the toolbelt is present and Docker is up."
  pause
  docker info >/dev/null 2>&1 || fail "Docker is not running"
  [[ -n "${OPENAI_API_KEY:-}" ]] || fail "OPENAI_API_KEY not set"
  for c in arctl kind kubectl helm; do
    command -v "$c" >/dev/null 2>&1 || fail "$c not in PATH"
  done
  command -v claude >/dev/null 2>&1 || warn "claude CLI not found — Phase 8 will print the commands for you to run manually"
  ok "Docker, OPENAI_API_KEY, arctl, kind, kubectl, helm all present"
  ok "Target platform: $PLATFORM"
}

# ─── Phase 2 — Platform ──────────────────────────────────────────────
phase2_platform() {
  phase "Phase 2 — The Platform"
  explain "We stand up everything the artifacts will run on: a local Kubernetes"
  explain "cluster (kind), the arctl registry daemon, a container registry for"
  explain "skill images, kagent (runs agents + MCP servers), and agentgateway."

  banner "kind cluster"
  if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
    warn "kind cluster '$CLUSTER_NAME' already exists — skipping create"
  else
    runc "kind create cluster --name $CLUSTER_NAME"
  fi
  kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null

  banner "arctl daemon (the registry @ :12121)"
  runc "arctl daemon start || true"
  for _ in {1..30}; do
    curl -fsS http://localhost:12121/v0/version >/dev/null 2>&1 && break
    sleep 1
  done
  curl -fsS http://localhost:12121/v0/version >/dev/null 2>&1 \
    || fail "arctl daemon did not become ready on :12121"
  ok "Registry daemon ready"

  banner "local kind-registry (so the cluster can pull skill images)"
  if docker ps --format '{{.Names}}' | grep -qx kind-registry; then
    warn "kind-registry already running — skipping"
  else
    runc "docker run -d --restart=always --name kind-registry --network kind -p 127.0.0.1:5001:5000 registry:2"
  fi

  banner "kagent (+ CRDs)"
  runc "helm upgrade --install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds --namespace kagent --create-namespace"
  runc 'helm upgrade --install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --namespace kagent \
  --set kmcp.enabled=true \
  --set agents.enabled=false \
  --set helm-agent.enabled=false \
  --set istio-agent.enabled=false \
  --set promql-agent.enabled=false \
  --set observability-agent.enabled=false \
  --set argo-rollouts-agent.enabled=false \
  --set cilium-debug-agent.enabled=false \
  --set cilium-manager-agent.enabled=false \
  --set cilium-policy-agent.enabled=false \
  --set kgateway-agent.enabled=false \
  --set grafana-mcp.enabled=false \
  --set querydoc.enabled=false \
  --set providers.default=openAI \
  --set providers.openAI.apiKey="$OPENAI_API_KEY"'

  banner "agentgateway (+ Gateway API CRDs)"
  runc "kubectl apply --server-side --force-conflicts -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml"
  runc "helm upgrade -i agentgateway-crds oci://cr.agentgateway.dev/charts/agentgateway-crds --create-namespace --namespace agentgateway-system --version v1.1.0 --set controller.image.pullPolicy=Always"
  runc "helm upgrade -i agentgateway oci://cr.agentgateway.dev/charts/agentgateway --namespace agentgateway-system --version v1.1.0 --set controller.image.pullPolicy=Always --set controller.extraEnv.KGW_ENABLE_GATEWAY_API_EXPERIMENTAL_FEATURES=true --wait || true"

  banner "wait for kagent"
  kubectl wait --for=condition=Ready pod --all -n kagent --timeout=180s \
    || warn "some kagent pods not ready yet"
  ok "Platform installed — arctl, kind, kagent, agentgateway"
}

# ─── Phase 3 — MCP server ────────────────────────────────────────────
phase3_mcp() {
  phase "Phase 3 — The Tools (MCP server)"
  explain "First artifact: the ops-server MCP server. It exposes the tools the"
  explain "agent can *do* — get_service_health, list_deployments, get_logs."
  explain "We containerize it and publish it to the registry as an OCI artifact."

  banner "build the MCP server image"
  runc "(cd ops-server && arctl mcp build . --image ops-server)"

  banner "publish to the registry"
  show   "(cd ops-server && arctl mcp publish . --type oci --package-id ops-server)"
  pause
  out_open
  (cd ops-server && arctl mcp publish . --type oci --package-id ops-server) \
    || warn "publish may have already happened — continuing"
  out_close
  ok "MCP server built & published  →  $MCP_NAME@$MCP_VERSION"
}

# ─── Phase 4 — Skill ─────────────────────────────────────────────────
phase4_skill() {
  phase "Phase 4 — The Knowledge (skill)"
  explain "Second artifact: the platform-best-practices skill — SLA tiers,"
  explain "escalation procedures, team ownership. Skills are pulled at runtime"
  explain "over the network, so we push the image to the local kind-registry"
  explain "and register it under the in-cluster hostname ($IN_CLUSTER_REGISTRY)."

  banner "what's in the skill"
  explain "Before we package it — here's the knowledge itself: metadata + outline."
  runc "sed -n '1,8p' platform-best-practices/SKILL.md; echo; echo '   ── sections ──'; grep '^## ' platform-best-practices/SKILL.md | sed 's/^## /   • /'"

  explain "And the SLA tiers — this is what drives the escalation demo later:"
  runc "sed -n '10,18p' platform-best-practices/SKILL.md"

  banner "build the skill image"
  runc "arctl skill build ./platform-best-practices --image platform-best-practices:v${SKILL_VERSION}"

  banner "tag + push to the kind-registry"
  runc "docker tag platform-best-practices:v${SKILL_VERSION} ${KIND_REGISTRY_HOST}/platform-best-practices:v${SKILL_VERSION}"
  runc "docker push ${KIND_REGISTRY_HOST}/platform-best-practices:v${SKILL_VERSION}"

  banner "publish to the registry"
  show   "arctl skill publish ./platform-best-practices --docker-image ${IN_CLUSTER_REGISTRY}/platform-best-practices:v${SKILL_VERSION} --version ${SKILL_VERSION}"
  pause
  out_open
  arctl skill publish ./platform-best-practices \
    --docker-image ${IN_CLUSTER_REGISTRY}/platform-best-practices:v${SKILL_VERSION} \
    --version ${SKILL_VERSION} \
    || warn "skill publish may have already happened — continuing"
  out_close
  ok "Skill built & published  →  $SKILL_NAME@$SKILL_VERSION"
}

# ─── Phase 5 — Agent ─────────────────────────────────────────────────
phase5_agent() {
  phase "Phase 5 — The Agent (compose + build)"
  explain "Third artifact: the agent itself. agent.yaml already composes the"
  explain "MCP server + skill + prompt. We publish the strict-operator prompt,"
  explain "then build and publish the agent image."

  banner "publish the strict-operator prompt"
  show   "arctl prompt publish prompts/strict-operator.txt --name $PROMPT_NAME --version $PROMPT_VERSION --description \"Strict operator persona for platform ops\""
  pause
  out_open
  arctl prompt publish prompts/strict-operator.txt \
    --name "$PROMPT_NAME" --version "$PROMPT_VERSION" \
    --description "Strict operator persona for platform ops" \
    || warn "prompt publish may have already happened — continuing"
  out_close

  banner "build the agent image"
  runc "(cd platform-ops-agent && arctl agent build . --platform $PLATFORM)"

  banner "publish to the registry"
  show   "(cd platform-ops-agent && arctl agent publish .)"
  pause
  out_open
  (cd platform-ops-agent && arctl agent publish .) \
    || warn "agent publish may have already happened — continuing"
  out_close
  ok "Agent built & published  →  $AGENT_NAME"
}

# ─── Phase 6 — Registry listing ──────────────────────────────────────
phase6_registry() {
  phase "Phase 6 — The Registry"
  explain "All three artifacts are now catalogued. Let's see them in the registry."
  banner "what's in the registry"
  runc "arctl mcp list || true"
  runc "arctl skill list || true"
  runc "arctl prompt list 2>/dev/null || true"
  runc "arctl agent list 2>/dev/null || true"
  ok "Tools, knowledge, and persona — all in the registry"
  echo -e "  ${DIM}Browse the UI at ${RESET}${BOLD}${REGISTRY_UI}${RESET}"
}

# ─── Phase 7 — Deploy to Kubernetes ──────────────────────────────────
phase7_deploy() {
  phase "Phase 7 — Deploy to Kubernetes"
  explain "Now we pull the artifacts back out of the registry and run them on the"
  explain "cluster. Creating the agent deployment auto-creates a companion MCP"
  explain "server pod. A few CRD/configmap patches wire them together for the"
  explain "local HTTP registry."

  banner "load images into kind"
  runc "kind load docker-image ops-server:latest --name $CLUSTER_NAME"
  runc "kind load docker-image $AGENT_IMAGE --name $CLUSTER_NAME"

  banner "create the agent deployment (auto-creates the MCP pod)"
  show   "arctl deployments create $AGENT_NAME --type agent --provider-id kubernetes-default --namespace default"
  pause
  out_open
  arctl deployments create "$AGENT_NAME" \
    --type agent --provider-id kubernetes-default --namespace default
  out_close

  banner "wire it up (3 patches)"
  explain "Waiting for the agent CRD to appear…"
  local AGENT=""
  for _ in {1..30}; do
    AGENT=$(kubectl get agent -n default -o name 2>/dev/null | head -1 || true)
    [[ -n "$AGENT" ]] && break
    sleep 2
  done
  [[ -n "$AGENT" ]] || fail "agent CRD did not appear in 'default' namespace"
  ok "Agent CRD: $AGENT"

  explain "Patch 1/3 — allow the insecure (HTTP) local skill registry"
  runc "kubectl patch $AGENT --type=merge -p '{\"spec\":{\"skills\":{\"insecureSkipVerify\":true}}}'"

  explain "Patch 2/3 — point the agent at the real MCP Service name"
  local DEP_ID DID MCP_SVC CM
  DEP_ID=$(kubectl get "$AGENT" -o jsonpath='{.metadata.labels.aregistry\.ai/deployment-id}')
  DID=${DEP_ID:0:8}
  echo -e "  ${DIM}deployment-id: $DEP_ID (short: $DID)${RESET}"
  for _ in {1..30}; do
    MCP_SVC=$(kubectl get svc -n default -o name 2>/dev/null \
      | grep "ops-server-${DID}" | head -1 | sed 's|.*/||' || true)
    [[ -n "$MCP_SVC" ]] && break
    sleep 2
  done
  [[ -n "${MCP_SVC:-}" ]] || fail "MCP Service for deployment $DID never appeared"
  ok "MCP Service: $MCP_SVC"
  CM=$(kubectl get cm -n default -l "aregistry.ai/deployment-id=$DEP_ID" -o name | head -1)
  [[ -n "$CM" ]] || fail "no configmap found for deployment $DEP_ID"
  kubectl patch -n default "$CM" --type=merge \
    -p "{\"data\":{\"mcp-servers.json\":\"[\\n  {\\n    \\\"name\\\": \\\"${MCP_SVC}\\\",\\n    \\\"type\\\": \\\"command\\\"\\n  }\\n]\"}}"
  ok "configmap patched"

  explain "Patch 3/3 — restart the agent so it picks up the configmap"
  runc "kubectl rollout restart deploy -n default ${AGENT_NAME}-latest-${DID} || true"
  kubectl rollout status deploy -n default "${AGENT_NAME}-latest-${DID}" --timeout=180s \
    || warn "agent rollout still in progress"

  banner "final state"
  runc "kubectl get pods,svc,agent -n default"
  runc "arctl deployments list"
  ok "Deployment complete — agent + MCP server running on Kubernetes"
}

# ─── Phase 8 — Connect Claude Code ───────────────────────────────────
phase8_connect() {
  phase "Phase 8 — Connect the Claude Code CLI"
  explain "The deployed agent is one consumer of these artifacts. Claude Code is"
  explain "another — same MCP server, same tools, its own model. The MCP server"
  explain "runs on a ClusterIP Service, so we port-forward it to localhost and"
  explain "register it with the Claude Code CLI."

  banner "find the MCP Service + start a port-forward"
  local MCP_SVC
  MCP_SVC=$(kubectl get svc -n default -o name 2>/dev/null \
    | grep ops-server | head -1 | sed 's|.*/||' || true)
  [[ -n "$MCP_SVC" ]] || { warn "no ops-server Service found — is Phase 7 done?"; MCP_SVC="<ops-server-svc>"; }

  show "kubectl port-forward -n default svc/$MCP_SVC 3000:3000 &"
  pause
  if [[ "$MCP_SVC" != "<ops-server-svc>" ]]; then
    kubectl port-forward -n default "svc/$MCP_SVC" 3000:3000 >/tmp/walkthrough-pf.log 2>&1 &
    PF_PID=$!
    echo "$PF_PID" > /tmp/walkthrough-pf.pid
    sleep 2
    ok "port-forward running (pid $PF_PID) → localhost:3000  [log: /tmp/walkthrough-pf.log]"
  else
    warn "skipping live port-forward — fill in the Service name yourself"
  fi

  banner "register the MCP server with Claude Code"
  local box; box="$(printf '━%.0s' {1..62})"
  echo
  echo -e "  ${BOLD}${CYAN}┏${box}┓${RESET}"
  echo -e "  ${BOLD}${CYAN}┃${RESET}  ${BOLD}Add the MCP server to your Claude Code CLI:${RESET}"
  echo -e "  ${BOLD}${CYAN}┃${RESET}"
  echo -e "  ${BOLD}${CYAN}┃${RESET}    ${BOLD}${GREEN}❯${RESET} ${BOLD}${YELLOW}claude mcp add --transport http ops-server $MCP_LOCAL_URL${RESET}"
  echo -e "  ${BOLD}${CYAN}┃${RESET}    ${BOLD}${GREEN}❯${RESET} ${BOLD}${YELLOW}claude mcp list | grep ops-server${RESET}"
  echo -e "  ${BOLD}${CYAN}┃${RESET}"
  echo -e "  ${BOLD}${CYAN}┃${RESET}    ${DIM}# Expect: ops-server: $MCP_LOCAL_URL (HTTP) - ✓ Connected${RESET}"
  echo -e "  ${BOLD}${CYAN}┗${box}┛${RESET}"
  echo

  if command -v claude >/dev/null 2>&1; then
    runc "claude mcp add --transport http ops-server $MCP_LOCAL_URL || true"
    runc "claude mcp list | grep ops-server || true"
  else
    warn "claude CLI not installed — copy the commands above into your terminal"
  fi

  banner "try it from Claude Code"
  cat <<EOF
  Open Claude Code and try the three demo prompts:

    1. "Check the health of the payments service"
    2. "Should we escalate this?"
    3. "Generate an incident report for what's happening with payments"

EOF
}

# ─── Outro ───────────────────────────────────────────────────────────
outro() {
  phase "Done — from zero to a deployed AI ops agent"
  echo "  ✔ Platform installed (kind + arctl + kagent + agentgateway)"
  echo "  ✔ MCP server, skill, and agent built & published to the registry"
  echo "  ✔ Agent + MCP server deployed to Kubernetes"
  echo "  ✔ MCP server connected to the Claude Code CLI"
  echo
  echo -e "  ${BOLD}Next steps${RESET}"
  echo "    • Browse the registry UI ......... $REGISTRY_UI"
  echo "    • Inspect the cluster ............ kubectl get pods,svc,agent -n default"
  echo "    • List deployments ............... arctl deployments list"
  echo "    • Tear it all down ............... ./walkthrough-cleanup.sh"
  echo
  echo -e "  ${DIM}The port-forward keeps running in the background. Stop it with:${RESET}"
  echo -e "  ${DIM}  kill \$(cat /tmp/walkthrough-pf.pid 2>/dev/null) 2>/dev/null${RESET}"
  echo
}

# ─── CLI parsing ─────────────────────────────────────────────────────
SKIP_PLATFORM=0
FROM_PHASE=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pause)      NO_PAUSE=1; shift ;;
    --skip-platform) SKIP_PLATFORM=1; shift ;;
    --from)          FROM_PHASE="$2"; shift 2 ;;
    -h|--help)       sed -n '2,23p' "$0"; exit 0 ;;
    *) fail "unknown arg: $1" ;;
  esac
done

# ─── Main ────────────────────────────────────────────────────────────
intro
(( FROM_PHASE <= 1 )) && phase1_preflight
(( FROM_PHASE <= 2 )) && [[ $SKIP_PLATFORM -eq 0 ]] && phase2_platform
(( FROM_PHASE <= 3 )) && phase3_mcp
(( FROM_PHASE <= 4 )) && phase4_skill
(( FROM_PHASE <= 5 )) && phase5_agent
(( FROM_PHASE <= 6 )) && phase6_registry
(( FROM_PHASE <= 7 )) && phase7_deploy
(( FROM_PHASE <= 8 )) && phase8_connect
outro

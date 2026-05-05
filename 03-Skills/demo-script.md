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

# `docs/agents/` — task-specific runbooks for AI coding assistants

[`AGENTS.md`](../../AGENTS.md) at the repo root covers *general* repo
conventions that any agent should load on every interaction (build
commands, proto rules, DCO, etc.). The files in this directory are
*playbooks for recurring narrow tasks* — long enough to be load-bearing
in their own right, narrow enough that inlining them in `AGENTS.md`
would drown out the basics.

## Intent

- **Vendor-neutral.** Plain markdown with prose + numbered steps. No
  Claude-specific frontmatter, no Cursor-specific rule syntax, no
  Codex-specific extensions. A human can follow them; so can any
  agent.
- **Reproducible.** Each runbook captures the steps a senior
  contributor would take to handle a class of task (e.g. a CVE alert,
  a proto field deprecation, a release cut). Codifying them keeps
  agent output consistent regardless of which tool or which model is
  driving.
- **Lightweight.** No new tooling required. They live in the repo so
  every contributor (human or agent) sees the same instructions
  pinned at the same commit.
- **Discoverable.** [`AGENTS.md`](../../AGENTS.md) links here, and
  this `README.md` indexes the runbooks. Adding a new runbook is just
  a new file plus one index line.

## Conventions for runbook files

- **One file per task.** Name it for what the task accomplishes
  (`triage-cve.md`, not `cve-triage-skill.md`).
- **Structure.** *When to use → Inputs → Steps → Things to NOT do →
  Worked example.* The worked example is the most valuable section —
  it grounds the prompt in a real artifact someone can compare
  against.
- **Capabilities, not tools.** If a runbook needs the agent to call
  something, name the *capability* (`shell`, `read GitHub issues`)
  rather than a specific MCP server or CLI binary. That keeps the
  runbook portable across agents.
- **Length cap.** ~200 lines. If a runbook outgrows that, split it.

## Index

- [`triage-cve.md`](./triage-cve.md) — triage a Mend / Dependabot
  dependency-vulnerability issue and prepare a remediation PR.

## How to invoke a runbook

| Tool | How |
|------|-----|
| Claude Code | `read docs/agents/<name>.md and follow it`, or register it as a skill in your personal `~/.claude/skills/` for auto-dispatch |
| Codex / Cursor / Aider / Cline | `read docs/agents/<name>.md and follow it` |
| Human contributor | open the file and read it; it's a checklist |

## Adding a new runbook

1. Pick a task you've already done at least twice in this repo.
2. Write down what you did. Steps you skipped because you "just know"
   them are exactly the steps an agent will get wrong — write those
   down too.
3. Add a worked example pointing at a real PR or issue.
4. Drop a one-line entry in the **Index** above.
5. Open a PR.

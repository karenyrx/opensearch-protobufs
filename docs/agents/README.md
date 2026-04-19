# `docs/agents/`

This directory holds task-specific playbooks for AI coding assistants
(and humans) — for example, triaging a CVE alert, generating proto
libraries locally, or cutting a release. It is currently a placeholder;
playbooks will be added here as we extract them from real workflows
rather than written speculatively.

Each playbook will be plain markdown with no tool-specific frontmatter
so that any agent (Claude, Codex, Cursor, Aider, Cline, …) or human
contributor can follow the same instructions.

[`AGENTS.md`](../../AGENTS.md) at the repo root covers general repo
conventions; the files here cover narrow recurring tasks.

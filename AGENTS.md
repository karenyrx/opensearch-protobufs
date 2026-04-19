# AGENTS.md

Guidance for AI coding assistants (Claude Code, Codex, Cursor, Aider,
Cline, etc.) working in this repository. Human contributors should
start with [`README.md`](./README.md) and
[`DEVELOPER_GUIDE.md`](./DEVELOPER_GUIDE.md). This file follows the
[agents.md](https://agents.md) cross-tool convention so a single
document serves every assistant.

## Repository overview

`opensearch-protobufs` holds the Protocol Buffer schemas and gRPC
service definitions for the OpenSearch client ↔ server gRPC API,
along with generated client libraries for Java, Python, and Go.

- **Source of truth for the API shape**: the
  [`opensearch-api-specification`](https://github.com/opensearch-project/opensearch-api-specification)
  repo. This repo is a *downstream consumer* — proto changes typically
  follow spec changes, not the other way around.
- **License**: Apache-2.0.

For build commands and packaging recipes see
[`DEVELOPER_GUIDE.md`](./DEVELOPER_GUIDE.md).

## Conventions

### Proto changes

- **Check the spec first.** If you are adding or renaming a field, look
  in `opensearch-api-specification` before editing `.proto` files
  directly.
- **Backward compatibility is non-negotiable.** Generated clients in
  the wild depend on field numbers and names. Never reuse or renumber a
  field. If a field is going away, mark it `reserved`. Run
  `npm run backward-compat` before opening a PR.
- **proto3 optional is enabled** (`--experimental_allow_proto3_optional`
  in `.bazelrc`). Use `optional` explicitly when presence matters.
- **Naming**: snake_case for fields, PascalCase for messages and
  services; match the casing used in the corresponding spec entity.
- **Don't hand-edit generated code** under `generated/` — it is rebuilt
  from `.proto` files.

### Bazel

- New proto files go in the appropriate `protos/<dir>/BUILD.bazel` and
  must be wired into the language aggregates in the top-level
  `BUILD.bazel` (`java_protos_all`, `python_protos_all`,
  `go_protos_all`).
- `bzlmod` is disabled (`common --noenable_bzlmod`). Add dependencies
  through `WORKSPACE`, not `MODULE.bazel`.

### Python packaging gotcha

`protoc` does not emit a `package` option for Python, so import paths
must be fixed up post-generation. See the comment in `BUILD.bazel` and
the `generate_pyi_files` genrule before changing Python proto
generation.

## Contribution workflow

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the full process. The
agent-relevant deltas:

- **DCO sign-off is required on every commit** (`git commit -s`), and
  it must use the contributor's real name — not a GitHub handle.
- **Keep PRs scoped** to one logical change. Don't bundle drive-by
  cleanup with a security or schema change.

## What agents should NOT do without explicit human direction

- Do not bump the version in `version.properties` or cut a release.
- Do not modify `WORKSPACE` to pull in new external repositories
  without flagging the supply-chain implication in the PR description.
- Do not commit anything under `generated/`, `bazel-*/`, or
  `node_modules/`.
- Do not modify `LICENSE.txt`, `NOTICE.txt`, `MAINTAINERS.md`, or
  `CODE_OF_CONDUCT.md`.
- Do not skip DCO sign-off, and do not add co-author trailers that
  imply authorship by an account that did not actually sign the DCO.
- Do not introduce dependencies on internal or proprietary systems —
  this is a public Apache-2.0 project; everything must build from a
  clean clone with only public dependencies.

## Task-specific runbooks

For recurring narrow tasks (CVE triage, generating protos locally,
release cuts, etc.) see [`docs/agents/`](./docs/agents/). The directory
is currently a placeholder; runbooks will be added there as we extract
them from real workflows.

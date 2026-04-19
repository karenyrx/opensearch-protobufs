# AGENTS.md

## Repository overview

`opensearch-protobufs` holds the Protocol Buffer schemas and gRPC
service definitions for the OpenSearch client ↔ server gRPC API,
along with generated client libraries for Java, Python, and Go.

The [`opensearch-api-specification`](https://github.com/opensearch-project/opensearch-api-specification)
repo is the source of truth for the API shape; this repo is a
*downstream consumer*. Proto changes typically follow spec changes,
not the other way around.

License: Apache-2.0.

## Build

Bazel version is pinned in `.bazelversion` — install that exact
version. Generate proto libraries:

```
bazel build //:java_protos_all
bazel build //:python_protos_all
bazel build //:go_protos_all
bazel build //:java_protos_all //:python_protos_all //:go_protos_all   # all three
```

Package the Java Maven JAR:

```
rm -rf generated && bazel build //:java_protos_all && ./tools/java/package_proto_jar.sh
```

Hermetic Docker builds are also available — see
[`DEVELOPER_GUIDE.md`](./DEVELOPER_GUIDE.md) for `build-bazel-{java,python,go}`
and `test-bazel-{java,python,go}` targets.

## Testing

```
npm install
npm test                       # jest tests for the TypeScript tooling
npm run backward-compat        # checks generated protos remain backward-compatible
npm run postprocessing         # backward-compat + cleanup-unused passes
```

For Bazel proto code, run the relevant `bazel build` target — proto
generation failures show up at build time, not in a separate test
phase.

## Proto changes

- **Check the spec first.** If you are adding or renaming a field,
  look in `opensearch-api-specification` before editing `.proto`
  files directly.
- **Never reuse or renumber a field.** Generated clients in the wild
  depend on field numbers and names. If a field is going away, mark
  it `reserved`.
- **Always run `npm run backward-compat`** before opening a PR; review
  its output.
- **proto3 optional is enabled** (`--experimental_allow_proto3_optional`
  in `.bazelrc`). Use `optional` explicitly when presence matters.
- **Naming**: snake_case for fields, PascalCase for messages and
  services. Match the casing used in the corresponding spec entity.
- **Don't hand-edit generated code** under `generated/` — it is
  rebuilt from `.proto` files.

When adding a new `.proto` file, wire it into the appropriate
`protos/<dir>/BUILD.bazel` *and* into the language aggregates in the
top-level `BUILD.bazel` (`java_protos_all`, `python_protos_all`,
`go_protos_all`). Forgetting the second step is a common mistake — the
file will compile in isolation but never reach the published artifact.

## Bazel

`bzlmod` is disabled (`common --noenable_bzlmod` in `.bazelrc`). Add
dependencies through `WORKSPACE`, not `MODULE.bazel`.

## Python packaging gotcha

`protoc` does not emit a `package` option for Python, so import paths
must be fixed up post-generation. See the comment in `BUILD.bazel`
and the `generate_pyi_files` genrule before changing Python proto
generation.

## Commits

DCO sign-off is required on every commit (`git commit -s`) and must
use the contributor's real name — not a GitHub handle. Commit titles
should focus on user impact, not implementation:

- Good: `Bump axios to 1.15.0 (CVE-2026-40175)`
- Bad: `Update package.json deps and lockfile`

Wrap titles at ~50 chars and bodies at ~72.

## Pull Requests

Always push to your fork. Never push directly to
`opensearch-project/opensearch-protobufs`. Open the PR with:

```
gh pr create --repo opensearch-project/opensearch-protobufs \
  --head <your-fork-user>:<branch> --base main \
  --title "<title>" --body "<body>"
```

Keep PRs scoped to one logical change. Don't bundle drive-by cleanup
with a security or schema change. Update `CHANGELOG.md` for any
user-visible change.

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

## Runbooks

Task-specific playbooks (CVE triage, generating protos locally,
release cuts, etc.) live in [`docs/agents/`](./docs/agents/) as
they're extracted from real workflows.

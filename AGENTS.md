# AGENTS.md

Guidance for AI coding assistants (Claude Code, Codex, Cursor, Aider, Cline, etc.)
working in this repository. Human contributors should start with
[`README.md`](./README.md) and [`DEVELOPER_GUIDE.md`](./DEVELOPER_GUIDE.md).

This file follows the [agents.md](https://agents.md) cross-tool convention so a
single document serves every assistant.

## Repository overview

`opensearch-protobufs` holds the Protocol Buffer schemas and gRPC service
definitions for the OpenSearch client ↔ server gRPC API, along with generated
client libraries for Java, Python, and Go.

- **Source of truth for the API shape**: the
  [`opensearch-api-specification`](https://github.com/opensearch-project/opensearch-api-specification)
  repo. This repo is a *downstream consumer* — proto changes typically follow
  spec changes, not the other way around.
- **License**: Apache-2.0.
- **Releases**: a Maven JAR (`opensearch-protobufs-java.tar.gz`) and a raw
  `.zip` of `.proto` files for generating clients in any language.

## Project layout

```
.
├── protos/
│   ├── schemas/        # common.proto — shared message types
│   └── services/       # search_service.proto, document_service.proto
├── tools/
│   ├── proto-convert/  # TypeScript: converts opensearch-api-spec -> .proto
│   ├── java/           # package_proto_jar.sh — builds Maven JAR
│   ├── python/         # python packaging helpers
│   └── go/             # go packaging helpers
├── jenkins/            # CI pipelines
├── BUILD.bazel         # top-level bazel targets (java/python/go _protos_all)
├── WORKSPACE           # bazel workspace
├── build.gradle        # Java publishing (Maven/Gradle)
├── package.json        # JS/TS tooling deps (proto-convert, jest)
└── version.properties  # release version
```

## Build and test

This repo uses **Bazel** for proto compilation (version is pinned in
`.bazelversion` — install that exact version) and **Gradle** for Java
publishing. TypeScript tooling under `tools/proto-convert/` uses **npm + jest**.

### Generate proto libraries

```bash
# Per language
bazel build //:java_protos_all
bazel build //:python_protos_all
bazel build //:go_protos_all

# All at once
bazel build //:java_protos_all //:python_protos_all //:go_protos_all
```

### Package the Java Maven JAR

```bash
rm -rf generated && bazel build //:java_protos_all && ./tools/java/package_proto_jar.sh
```

The resulting JAR is installed to your local Maven repo and to
`generated/maven/publish/`.

### Docker (hermetic build/test)

Each language has `build-bazel-*`, `package-bazel-*`, and `test-bazel-*`
targets:

```bash
docker build --target build-bazel-java .
docker build --target test-bazel-java .
# (repeat for python / go)
```

### TypeScript tooling tests

```bash
npm install
npm test                 # runs jest
npm run preprocessing    # OpenAPI -> proto preprocessing
npm run postprocessing   # backward-compat + cleanup passes
```

## Conventions

### Proto changes

- **Check the spec first.** This repo follows
  `opensearch-api-specification`. If you are adding or renaming a field, look
  there before editing `.proto` files directly.
- **Backward compatibility is non-negotiable.** Generated clients in the wild
  depend on field numbers and names. Never reuse or renumber a field. If a
  field is going away, mark it `reserved`. Run
  `npm run backward-compat` (and review its output) before opening a PR.
- **proto3 optional is enabled** (`--experimental_allow_proto3_optional` in
  `.bazelrc`). Use `optional` explicitly rather than relying on default-value
  semantics where presence matters.
- **Naming**: snake_case for fields, PascalCase for messages and services,
  matching the rest of the proto tree. Match the casing used in the
  corresponding spec entity.
- **Don't hand-edit generated code** under `generated/` — it is rebuilt from
  `.proto` files.

### Bazel

- Add new proto files to the appropriate `protos/<dir>/BUILD.bazel` and wire
  them into the language-specific aggregates in the top-level `BUILD.bazel`
  (`java_protos_all`, `python_protos_all`, `go_protos_all`).
- `bzlmod` is disabled (`common --noenable_bzlmod`). Add dependencies through
  `WORKSPACE`, not `MODULE.bazel`.

### Python packaging gotcha

`protoc` does not emit a `package` option for Python, so import paths must be
fixed up post-generation. See the comment in `BUILD.bazel` and the
`generate_pyi_files` genrule before changing Python proto generation.

## Contribution workflow

1. **Open an issue first.** Even small changes — see `CONTRIBUTING.md`. This
   prevents duplicate work and surfaces design questions early.
2. **Sign your commits (DCO required).** Every commit must include a
   `Signed-off-by: Your Name <email>` line. Use `git commit -s`. PRs without
   DCO sign-off will not be merged.
3. **Use your real name** in commits — anonymous contributions and pseudonyms
   are not accepted.
4. **Update `CHANGELOG.md`** under the appropriate section for any
   user-visible change.
5. **Keep PRs focused.** A schema change, the regenerated code, and the
   tooling change to support it can land together; unrelated cleanup should
   not.
6. **Run the relevant build target locally** before pushing — CI is slow and
   proto generation failures are easier to debug locally.

## What agents should NOT do without explicit human direction

- Do not bump the version in `version.properties` or cut a release.
- Do not modify `WORKSPACE` to pull in new external repositories without
  flagging the supply-chain implication in the PR description.
- Do not commit anything under `generated/`, `bazel-*`, or `node_modules/`.
- Do not modify `LICENSE.txt`, `NOTICE.txt`, `MAINTAINERS.md`, or
  `CODE_OF_CONDUCT.md`.
- Do not skip DCO sign-off, and do not add co-author trailers that imply
  authorship by an account that did not actually sign the DCO.
- Do not introduce dependencies on internal or proprietary systems — this is
  a public Apache-2.0 project; everything must build from a clean clone with
  only public dependencies.

## Useful references

- [README.md](./README.md) — user-facing intro and language usage examples
- [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) — full build recipes
- [CONTRIBUTING.md](./CONTRIBUTING.md) — contribution policy and DCO details
- [COMPATIBILITY.md](./COMPATIBILITY.md) — backward-compatibility policy
- [RELEASING.md](./RELEASING.md) — release process (humans only)
- [opensearch-api-specification](https://github.com/opensearch-project/opensearch-api-specification) — upstream spec

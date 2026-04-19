# Triage a CVE / Mend dependency security alert

## When to use

A bot (Mend, Dependabot, Snyk) has filed an issue against this repo
labelled with something like `Mend: dependency security vulnerability`.
You need to decide whether to fix it, how to fix it, and prepare the
remediation PR.

## Inputs you need

- The issue number, or the issue body pasted into context.
- A clone of `opensearch-project/opensearch-protobufs` and write
  access to a personal fork.
- Local toolchain: `node` + `npm`, `bazel` (version pinned in
  `.bazelversion`), and Java/Gradle if the alert touches the Java
  packaging path.

## Steps

### 1. Extract the facts from the issue

From the bot-generated issue body, capture:

- **CVE ID(s)** — there can be more than one in a single alert.
- **Vulnerable library + version** (e.g. `axios-1.13.5.tgz`).
- **Fixed version** the bot recommends.
- **Severity / CVSS score** and the **attack vector summary** (network
  vs local, privileges required, scope, what an attacker gains).
- **Path to dependency file** (`/package.json`, `/build.gradle`, …)
  as reported by the bot.
- Whether the dep is **Direct** or **Transitive** — the Mend table
  states this explicitly under "Type".

### 2. Confirm the dep is still pinned to the vulnerable version

The bot can race ahead of merged fixes. Verify before doing work:

```bash
# Node deps
grep -E '"<pkg>"' package.json package-lock.json

# Java/Gradle deps
grep -R "<pkg>" build.gradle gradle/

# Bazel deps
grep -R "<pkg>" WORKSPACE BUILD.bazel protos/
```

If the offending version is no longer present, comment on the issue
with the commit that fixed it and close the issue.

### 3. Decide remediation

| Situation | Action |
|-----------|--------|
| Direct dep, fix is a minor or patch bump | Bump the version in the manifest, regenerate the lockfile |
| Direct dep, fix requires a major bump | Read the upstream changelog; surface breaking changes in the PR description |
| Transitive dep, parent already accepts a fixed range | Just regenerate the lockfile to pull the patched version |
| Transitive dep, parent pins the vulnerable version | Add an entry to the existing `overrides` block in `package.json` (Node) or `dependencyManagement` (Gradle) pinning to the fixed version |
| The vulnerable code path is not reachable from this repo's build/runtime surface | Document why in a comment on the issue; ask a maintainer to close as `not exploitable`. Do not silently ignore. |

### 4. Apply the fix

```bash
# Node — direct dep bump
npm install <pkg>@<fixed-version>
npm test

# Node — transitive override (edit package.json "overrides" block)
npm install
npm test

# Gradle
./gradlew build
```

For proto/Bazel changes, also run any affected language target:

```bash
bazel build //:java_protos_all //:python_protos_all //:go_protos_all
```

### 5. Verify the new version is no longer vulnerable

- Re-grep the lockfile to confirm only the bumped version is present.
- Run `npm audit` (or `./gradlew dependencyCheckAnalyze` if configured)
  and confirm the CVE no longer appears.
- If a SAST/SCA tool is available locally, re-scan.

### 6. Prepare the PR

- **Branch name**: `bump-<pkg>-<cve>` (e.g. `bump-axios-cve-2026-40175`).
- **PR title**: `Bump <pkg> to <version> (<CVE-ID>)`.
- **PR body** must include:
  - Link to each CVE on Mend or the CVE database.
  - Severity and CVSS.
  - One-paragraph impact summary written in your own words (do not
    just paste the bot's text).
  - `Fixes #<issue-number>` to auto-close the Mend issue on merge.
  - Confirmation that `npm test` (or the equivalent) passes locally.
- **Every commit** must end with a `Signed-off-by: Real Name <email>`
  trailer — this project requires DCO. Use `git commit -s`. Use your
  real name, not a GitHub handle.
- Keep the PR scoped: only the dep bump, the lockfile regeneration,
  and any minimal call-site changes the upgrade forces. No drive-by
  cleanup.

### 7. Follow up

- Watch CI on the PR; the project has Jenkins jobs that run the full
  Bazel build for all three languages plus the TypeScript jest suite.
- If CI flags a regression, do not just disable the failing test —
  investigate whether the dep upgrade actually broke behavior.

## Things to NOT do

- Do not bypass the lockfile (e.g. `--no-package-lock`); the lockfile
  is part of the repo's reproducibility contract.
- Do not bundle unrelated dep bumps into the same PR — keep the
  security PR auditable.
- Do not downgrade other deps to make the resolver happy without
  flagging it explicitly in the PR description.
- Do not close the Mend issue manually; let `Fixes #<number>` close
  it on merge so the audit trail is intact.
- Do not commit anything under `generated/`, `bazel-*/`, or
  `node_modules/`.

## Worked example: issue #444 — `axios@1.13.5` → `axios@1.15.0`

- **CVEs**: CVE-2026-40175 (CVSS 10.0, Critical) and CVE-2025-62718
  (CVSS 9.9, Critical).
- **Vector**: Prototype-pollution gadget in any third-party dep gets
  escalated to Remote Code Execution / AWS IMDSv2 bypass. Network
  attack vector, no auth required.
- **Type**: Direct dep in `package.json`.
- **Action**:
  ```bash
  npm install axios@^1.15.0
  npm test
  git checkout -b bump-axios-cve-2026-40175
  git add package.json package-lock.json
  git commit -s -m "Bump axios to 1.15.0 (CVE-2026-40175, CVE-2025-62718)"
  git push -u origin bump-axios-cve-2026-40175
  gh pr create --repo opensearch-project/opensearch-protobufs \
    --title "Bump axios to 1.15.0 (CVE-2026-40175)" \
    --body "Fixes #444 ..."
  ```
- **Why a clean fix**: axios 1.15.0 is a minor bump from 1.13.5; no
  breaking API changes affect this repo's usage (none of the
  TypeScript tooling under `tools/proto-convert/` exercises the
  prototype-pollution path).

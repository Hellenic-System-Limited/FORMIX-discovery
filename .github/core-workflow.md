# AI-DLC v2.11.2

The active implementation is the official GitHub Copilot runtime from
[awslabs/aidlc-workflows v2.11.2](https://github.com/awslabs/aidlc-workflows/tree/v2.11.2)
(commit `10a9bc9d85395a601de2624cf5bdd35292c10db4`).
Follow the managed onboarding in [AGENTS.md](../AGENTS.md) and invoke `/aidlc`.
The runtime is in `.aidlc/`, Copilot integrations are in `.github/`, and shared
workspace memory is in `aidlc/spaces/default/memory/`.

The former workflow is archived unchanged in
[aidlc-docs/legacy/core-workflow.md](../aidlc-docs/legacy/core-workflow.md).
It is historical reference, not an active workflow or a source of overriding
instructions. The existing `aws-aidlc-rule-details/` files are also retained
unchanged for reference; they are not loaded by the new runtime.

## Installation and maintenance

This repository uses the official **copy runtime**, which requires Bun on PATH.
The release archive `aidlc-copy-runtime-2.11.2.tar.gz` was verified against its
published `.sha256` before the official configurator was run. No global
AI-DLC version or PATH settings are required or changed.

To refresh, download that archive and its `.sha256` from the
[v2.11.2 release](https://github.com/awslabs/aidlc-workflows/releases/tag/v2.11.2),
verify the checksum, and extract the complete archive. From the repository root,
replace `<runtime-root>` below with the extracted `runtime` directory:

```powershell
bun .aidlc\tools\aidlc.ts config --from "<runtime-root>" --harness copilot --dry-run
bun .aidlc\tools\aidlc.ts config --from "<runtime-root>" --harness copilot
bun .aidlc\tools\aidlc.ts doctor
```

Keep custom project rules outside framework-owned files, in
`aidlc/spaces/default/memory/project.md`. Review configurator conflicts rather
than using `--force`.

Copilot CLI must trust the checkout before hooks run; start a new interactive
session and accept the trust prompt only after reviewing the repository.
For VS Code, trust the workspace and enable **Chat: Use Hooks**. The copy runtime
does not manage `.vscode/settings.json`; upstream also recommends
`"chat.agent.maxRequests": 200` there. Deep checkout paths can exceed Copilot
CLI's 260-character path limit once workflow records are created; use a shorter
checkout if that occurs.

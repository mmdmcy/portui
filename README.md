# PortUI

PortUI is a zero-dependency cross-platform terminal engine for project-local TUIs.

The intended model is:

- define one `portui/` app inside a repo
- install the PortUI runtime into that repo
- run PortUI from that repo as the repo's main TUI on macOS, Linux, and Windows

That lets you reuse one standardized portable TUI base instead of rebuilding shell scripts, batch files, and terminal UI glue for every project.

## What PortUI Does

PortUI gives you one declarative place to define:

- project actions
- working directories
- environment overrides
- per-OS command differences
- shared built-in variables like project and workspace paths

It is not a package manager and not a terminal emulator. It is a portable project-local TUI base with a manifest-driven runtime.

## Project-Local Model

Put a PortUI app inside a project using either:

```text
repo-name/
  portui/
    manifest.env
    actions/
```

or:

```text
repo-name/
  .portui/
    manifest.env
    actions/
```

Then install the runtime into that project from the central `portui` repo.

## Quick Start

Install PortUI into a project that already has `portui/manifest.env` or `.portui/manifest.env`.

Linux or macOS:

```bash
sh ./portui.sh --install-project ../GUITboard
```

Windows PowerShell:

```powershell
.\portui.ps1 -InstallProject ..\GUITboard
```

That creates project-local runtime files in the target repo:

```text
repo-name/
  .portui-runtime/
  portui.sh
  portui.ps1
  portui.cmd
  portui/
```

After that, run PortUI from inside the target project.

Linux or macOS:

```bash
sh ./portui.sh --list
sh ./portui.sh --run test
```

Windows PowerShell:

```powershell
.\portui.ps1 -List
.\portui.ps1 -Run test
```

Windows Command Prompt:

```cmd
portui.cmd --list
portui.cmd --run test
```

## Common Commands

Install or update PortUI in a repo:

```bash
sh ./portui.sh --install-project ../smaLLMs
```

Run the vendored PortUI inside that repo:

```bash
(cd ../smaLLMs && sh ./portui.sh --run doctor)
```

Manifest-direct mode still exists for debugging:

```bash
sh ./portui.sh --manifest-dir ./examples/demo --list
sh ./portui.sh --manifest-dir ./examples/demo --run git-version
```

Workspace mode also still exists as a secondary convenience feature:

- `--workspace`
- `--project`
- `--list-projects`

## Manifest Example

`manifest.env`:

```text
NAME=My Project
DESCRIPTION=Portable actions for one project.
VARIABLE_repo={{projectDir}}
```

`actions/01-doctor.env`:

```text
ID=doctor
TITLE=Doctor
DESCRIPTION=Print workspace-aware project info.
TIMEOUT_SECONDS=20
CWD={{projectDir}}
POSIX_PROGRAM=sh
POSIX_ARGS=-c|printf '%s\n' 'project={{projectId}}' 'workspace={{workspaceDir}}'
WINDOWS_PROGRAM=powershell
WINDOWS_ARGS=-NoProfile|-Command|Write-Output 'project={{projectId}}'; Write-Output 'workspace={{workspaceDir}}'
```

See [docs/manifest-spec.md](./docs/manifest-spec.md) for the full format.

## Built-In Variables

- `{{home}}`
- `{{cwd}}`
- `{{os}}`
- `{{manifestDir}}`
- `{{projectDir}}`
- `{{projectId}}`
- `{{workspaceDir}}`
- `{{pathSep}}`
- `{{listSep}}`
- `{{exeSuffix}}`

Manifest-defined variables can reference built-ins and each other.

## Why This Shape

PortUI is meant to reduce duplicated per-repo terminal glue.

Instead of each repo growing its own shell scripts, batch files, and one-off TUIs, PortUI standardizes:

- the TUI surface
- process launching
- cross-platform command resolution
- preview, confirmation, logs, and timeouts

That keeps repo-specific code focused on actual project logic while PortUI owns the portable terminal layer.

## Repository Layout

```text
.
├── portui.sh
├── portui.ps1
├── portui.cmd
├── docs/
├── ci/
└── examples/
```

The workspace examples live in:

- [examples/workspace/alpha](./examples/workspace/alpha)
- [examples/workspace/beta](./examples/workspace/beta)

## Verification

The repository includes smoke tests for supported flows:

- project-local runtime install
- project-local wrapper execution
- single-manifest mode
- workspace project discovery
- per-project action dispatch on POSIX
- PowerShell workspace behavior in CI

Files:

- [ci/test-posix.sh](./ci/test-posix.sh)
- [ci/test-powershell.ps1](./ci/test-powershell.ps1)
- [GitHub Actions CI](./.github/workflows/ci.yml)

Linux or macOS:

```bash
sh -n ./portui.sh
sh ./ci/test-posix.sh
```

Windows:

```powershell
.\ci\test-powershell.ps1
```

## Project Status

PortUI is evolving from a manifest runner into a reusable project-local terminal engine. The current implementation is still intentionally small and explicit, but it now supports vendoring the runtime into repos and running them through project-local PortUI entrypoints.

## Open Source

- License: [MIT](./LICENSE)
- Contributing: [CONTRIBUTING.md](./CONTRIBUTING.md)
- Security: [SECURITY.md](./SECURITY.md)
- Changelog: [CHANGELOG.md](./CHANGELOG.md)

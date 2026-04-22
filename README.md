# PortUI

PortUI is a zero-dependency, manifest-driven command runner for cross-platform terminal workflows.

It gives you one declarative place to define developer actions, variables, working directories, and per-OS command overrides, then resolves those actions into native commands on:

- Linux with `sh`
- macOS with `sh`
- Windows with built-in `PowerShell`

PortUI is not a terminal emulator and not a package manager. It is a small runtime for portable command surfaces.

## Why PortUI

Cross-platform developer tooling usually breaks down in one of two ways:

- every repo grows a pile of shell-specific wrapper scripts
- a simple command runner turns into a full application stack with its own dependencies

PortUI is aimed at the gap between those two extremes:

- no third-party runtime dependencies
- no JSON or YAML parser dependency
- no language-specific bootstrap requirement
- one logical action can still map to different native commands on each OS

## What It Is

PortUI is best described as a small framework or runtime for manifest-driven terminal commands.

Each PortUI app is just:

```text
my-portui-app/
  manifest.env
  actions/
    01-doctor.env
    02-build.env
    03-dev.env
```

The runtime is provided by:

- [portui.sh](./portui.sh)
- [portui.ps1](./portui.ps1)
- [portui.cmd](./portui.cmd)

The demo app lives in:

- [examples/demo](./examples/demo)

## Quick Start

Linux or macOS:

```bash
sh ./portui.sh
```

Windows:

```powershell
.\portui.ps1
```

Or:

```cmd
portui.cmd
```

The default manifest directory is `./examples/demo`.

## Non-Interactive Usage

Linux or macOS:

```bash
sh ./portui.sh --list
sh ./portui.sh --run git-version
sh ./portui.sh --manifest-dir ./examples/demo --run list-workspace
```

Windows:

```powershell
.\portui.ps1 -List
.\portui.ps1 -Run git-version
.\portui.ps1 -ManifestDir .\examples\demo -Run list-workspace
```

## Manifest Example

`manifest.env`:

```text
NAME=My Repo Tools
DESCRIPTION=Portable local commands for one repository.
VARIABLE_workspace={{home}}/Documents/github
VARIABLE_repo={{workspace}}/my-repo
```

`actions/01-list-workspace.env`:

```text
ID=list-workspace
TITLE=List Workspace
DESCRIPTION=Demonstrate per-platform command translation.
TIMEOUT_SECONDS=20
CWD={{workspace}}
POSIX_PROGRAM=ls
POSIX_ARGS=-la|.
WINDOWS_PROGRAM=powershell
WINDOWS_ARGS=-NoProfile|-Command|Get-ChildItem -Force .
```

See [docs/manifest-spec.md](./docs/manifest-spec.md) for the full format.

## Resolution Model

PortUI resolves actions in a simple order:

1. base keys
2. `POSIX_*` overrides on Linux and macOS
3. OS-specific overrides for the current host

That lets you share the common shape of an action while only overriding the parts that are truly platform-specific.

## Built-In Variables

- `{{home}}`
- `{{cwd}}`
- `{{os}}`
- `{{manifestDir}}`
- `{{pathSep}}`
- `{{listSep}}`
- `{{exeSuffix}}`

Manifest variables can reference built-ins and each other.

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

## Verification

The repository includes smoke tests for all supported platforms:

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

PortUI `0.1.0` is the first public release. The current scope is intentionally narrow:

- stable enough for local developer workflows
- small enough to audit quickly
- opinionated toward explicit commands over shell magic

## Open Source

- License: [MIT](./LICENSE)
- Contributing: [CONTRIBUTING.md](./CONTRIBUTING.md)
- Security: [SECURITY.md](./SECURITY.md)
- Changelog: [CHANGELOG.md](./CHANGELOG.md)

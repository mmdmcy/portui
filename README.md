# PortUI

PortUI is a zero-dependency cross-platform terminal runtime for project-local TUIs.

The simple mental model:

- `portui/` or `.portui/` is your app: a manifest plus action files.
- `portui.sh`, `portui.ps1`, and `portui.cmd` are tiny launchers for Linux/macOS, PowerShell, and Command Prompt.
- `.portui-runtime/` is the vendored engine that those launchers call.

That is the whole shape. PortUI is not a GUI toolkit, package manager, global install, or executable builder. A repo should be cloneable on Linux, macOS, or Windows and then runnable from its own local launcher scripts.

## What It Feels Like To Use

From inside any project that has PortUI installed:

Linux or macOS:

```bash
sh ./portui.sh
```

Windows PowerShell:

```powershell
.\portui.ps1
```

Command Prompt:

```cmd
portui.cmd
```

That opens a terminal menu. You can also skip the menu for scripts and CI:

```bash
sh ./portui.sh --list
sh ./portui.sh --run doctor
```

```powershell
.\portui.ps1 -List
.\portui.ps1 -Run doctor
```

If an action runs a compiled program, that compiled program is your project logic, not PortUI itself. The built-in `{{exeSuffix}}` variable only exists so an action can say `mytool{{exeSuffix}}` when it really does need `mytool.exe` on Windows.

## New Idea Workflow

You can clone `portui` into a new folder and use it right away because this repo ships with a starter app in [`.portui/`](./.portui).

Linux or macOS:

```bash
git clone https://github.com/mmdmcy/portui.git my-idea
cd my-idea
sh ./portui.sh --list
```

Windows PowerShell:

```powershell
git clone https://github.com/mmdmcy/portui.git my-idea
cd my-idea
.\portui.ps1 -List
```

That starter app is only a base. Edit `.portui/manifest.env` and `.portui/actions/` to turn the clone into your actual project.

## Existing Project Workflow

If a repo does not have a PortUI app yet, initialize one and vendor the runtime:

Linux or macOS:

```bash
git clone https://github.com/mmdmcy/portui.git .portui-src
sh ./.portui-src/portui.sh --init-project .
```

Windows PowerShell:

```powershell
git clone https://github.com/mmdmcy/portui.git .portui-src
.\.portui-src\portui.ps1 -InitProject .
```

If a repo already has `portui/manifest.env` or `.portui/manifest.env`, just vendor or refresh the runtime:

Linux or macOS:

```bash
sh ./.portui-src/portui.sh --install-project .
```

Windows PowerShell:

```powershell
.\.portui-src\portui.ps1 -InstallProject .
```

After either command, the target repo gets:

```text
repo-name/
  .portui-runtime/
  portui.sh
  portui.ps1
  portui.cmd
  portui/ or .portui/
```

At that point the target repo is self-contained. You can delete the temporary PortUI source clone if you want.

## Using PortUI Inside A Repo

Once a repo has vendored PortUI, use the repo-local launchers:

Linux or macOS:

```bash
sh ./portui.sh --list
sh ./portui.sh --run doctor
```

Windows PowerShell:

```powershell
.\portui.ps1 -List
.\portui.ps1 -Run doctor
```

Command Prompt:

```cmd
portui.cmd --list
portui.cmd --run doctor
```

## What PortUI Owns

PortUI gives you one declarative place to define:

- project actions
- working directories
- environment overrides
- per-OS command differences
- preview, confirmation, logs, direct interactive mode, and timeouts
- built-in path and project variables

It does not replace your project logic. It standardizes the terminal menu layer around that logic.

## Project Layout

A PortUI app inside a repo can use either:

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

## Built-In Starter App

This repo contains a built-in starter app in [`.portui/`](./.portui) so a plain clone is immediately usable.

Starter actions:

- `doctor`
- `list-files`
- `git-status`

If you want a clean project base, edit or replace those files after cloning.

## Maintainer Commands

Main commands:

- `--init-project DIR`
  Creates a starter `portui/` app in a repo, then vendors the runtime.
- `--install-project DIR`
  Vendors or refreshes the runtime for a repo that already has a PortUI app.
- `--manifest-dir DIR`
  Runs one manifest directly.

Workspace mode still exists, but it is secondary:

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
DESCRIPTION=Print the current project, workspace, and OS values.
TIMEOUT_SECONDS=20
CWD={{projectDir}}
POSIX_PROGRAM=sh
POSIX_ARGS=-c|printf '%s\n' 'project={{projectId}}' 'workspace={{workspaceDir}}' 'os={{os}}'
WINDOWS_PROGRAM=powershell
WINDOWS_ARGS=-NoProfile|-Command|Write-Output 'project={{projectId}}'; Write-Output 'workspace={{workspaceDir}}'; Write-Output 'os={{os}}'
```

For a nested terminal dashboard or full-screen TUI, add:

```text
INTERACTIVE=true
TIMEOUT_SECONDS=0
```

That tells PortUI to hand the terminal directly to the action instead of capturing its output.

See [docs/manifest-spec.md](./docs/manifest-spec.md) for the full format.

## Verification

The repository includes smoke tests for:

- starter-app default behavior
- project-local runtime install
- project-local wrapper execution
- project initialization
- single-manifest mode
- workspace discovery and dispatch

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

## Open Source

- License: [MIT](./LICENSE)
- Contributing: [CONTRIBUTING.md](./CONTRIBUTING.md)
- Security: [SECURITY.md](./SECURITY.md)
- Changelog: [CHANGELOG.md](./CHANGELOG.md)

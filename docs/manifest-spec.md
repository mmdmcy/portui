# Manifest Spec

PortUI is built around project-local terminal apps. A PortUI app is just a manifest plus action files; the repo-local launcher scripts load those files and run the selected action.

PortUI does not build executables. If your own project action runs a compiled binary, that binary is part of your project logic. The PortUI runtime only resolves variables, chooses the right per-OS command, previews it, and executes it.

Main modes:

- starter repo mode
- initialized repo mode
- direct manifest mode
- workspace mode

The first two are the primary intended workflows.

## App Layout

Inside a repo, a PortUI app can live in either:

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

## Starter Repo Mode

This `portui` repo includes a built-in starter app under `.portui/`.

That means a plain clone is already runnable:

```bash
sh ./portui.sh --list
```

This is meant to support the “clone PortUI into a new idea folder and start editing there” workflow.

## Initializing An Existing Repo

Create a starter app in an existing repo and vendor the runtime:

```bash
sh ./portui.sh --init-project ../my-repo
```

This creates:

```text
my-repo/
  portui/
    manifest.env
    actions/
  .portui-runtime/
  portui.sh
  portui.ps1
  portui.cmd
```

## Installing Or Refreshing The Runtime

If a repo already has `portui/manifest.env` or `.portui/manifest.env`, vendor or refresh the runtime:

```bash
sh ./portui.sh --install-project ../my-repo
```

This updates the repo-local runtime files:

```text
my-repo/
  .portui-runtime/
  portui.sh
  portui.ps1
  portui.cmd
```

## `manifest.env`

Recognized keys:

- `NAME`
- `DESCRIPTION`
- `VARIABLE_<name>`

Example:

```text
NAME=My Repo Tools
DESCRIPTION=Portable local commands for one repository.
VARIABLE_repo={{projectDir}}
VARIABLE_buildDir={{projectDir}}{{pathSep}}dist
```

## Action Files

Each file under `actions/` defines one runnable action using `KEY=value` lines.

Core keys:

- `ID`
- `TITLE`
- `DESCRIPTION`
- `TIMEOUT_SECONDS`
- `INTERACTIVE`
- `PROGRAM`
- `ARGS`
- `CWD`
- `ENV_<NAME>`

Platform override keys:

- `POSIX_PROGRAM`, `POSIX_ARGS`, `POSIX_CWD`, `POSIX_ENV_<NAME>`
- `LINUX_PROGRAM`, `LINUX_ARGS`, `LINUX_CWD`, `LINUX_ENV_<NAME>`
- `MACOS_PROGRAM`, `MACOS_ARGS`, `MACOS_CWD`, `MACOS_ENV_<NAME>`
- `WINDOWS_PROGRAM`, `WINDOWS_ARGS`, `WINDOWS_CWD`, `WINDOWS_ENV_<NAME>`

## Argument Encoding

`ARGS` values are `|`-separated.

Example:

```text
PROGRAM=git
ARGS=status|--short|--branch
```

## Interactive Actions

Most actions are captured: PortUI runs the command, collects stdout/stderr, and prints a status block when it exits.

Set `INTERACTIVE=true` for terminal apps that need direct stdin/stdout, such as a nested dashboard, REPL, editor, or full-screen TUI:

```text
ID=dashboard
TITLE=Dashboard
INTERACTIVE=true
TIMEOUT_SECONDS=0
CWD={{projectDir}}
PROGRAM=go
ARGS=run|./cmd/dashboard
```

When `INTERACTIVE=true`, the command inherits the terminal directly. `TIMEOUT_SECONDS=0` means no timeout.

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

Behavior:

- `projectDir` resolves to the repository root when the manifest lives in `repo/portui` or `repo/.portui`
- `projectId` defaults to the repository directory name
- `workspaceDir` resolves to the active workspace root in workspace mode, or the parent of the project in project-local mode

## Resolution Order

PortUI resolves actions in this order:

1. base keys
2. `POSIX_*` overrides on Linux and macOS
3. OS-specific overrides for the current host

Later layers replace earlier `PROGRAM`, `ARGS`, and `CWD` values. Environment overrides merge by key.

## Execution Model

- Linux and macOS run through `portui.sh`
- Windows runs through `portui.ps1` or `portui.cmd`
- repos can vendor the runtime under `.portui-runtime/`
- repo-local `portui.sh`, `portui.ps1`, and `portui.cmd` wrappers call that vendored runtime
- the runtime executes the resolved program directly with explicit argument arrays
- the runtime changes into the resolved working directory before launch

The wrappers are source files meant to be committed with your repo. They are not generated build artifacts and they are not replacements for your app code.

## Secondary Modes

Direct manifest mode:

```bash
sh ./portui.sh --manifest-dir ./examples/demo --list
```

Workspace mode:

```bash
sh ./portui.sh --workspace ../github --project smaLLMs --list
```

These are supported, but they are not the main point of PortUI.

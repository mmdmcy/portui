# Manifest Spec

PortUI supports two operating modes:

- single-manifest mode
- workspace mode

The main intended model is project-local PortUI:

- each repo keeps one `portui/` or `.portui/` app definition
- the PortUI runtime is installed into that repo
- the repo then runs PortUI through local wrappers like `./portui.sh`

Workspace mode and single-manifest mode are secondary tools built on the same runtime.

## Project Layout

PortUI app definitions can live in either of these layouts:

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

## Single-Manifest Layout

PortUI can also run a manifest directly:

```text
my-portui-app/
  manifest.env
  actions/
    01-doctor.env
    02-build.env
    03-dev.env
```

## Installing PortUI Into A Repo

From the source `portui` repo:

```bash
sh ./portui.sh --install-project ../my-repo
```

This installs:

```text
my-repo/
  .portui-runtime/
  portui.sh
  portui.ps1
  portui.cmd
  portui/
```

The project-local wrappers call the vendored runtime with the repo's own manifest directory. That is the intended way to make PortUI the repo's main TUI without depending on the central `portui` repo at runtime.

## `manifest.env`

Recognized keys:

- `NAME`: display name for the project
- `DESCRIPTION`: short description shown in listings
- `VARIABLE_<name>`: reusable variable definition

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

This avoids shell-splitting ambiguity while keeping manifests easy to author by hand.

## Resolution Order

PortUI resolves actions in this order:

1. base keys
2. `POSIX_*` overrides on Linux and macOS
3. OS-specific overrides for the current host: `LINUX_*`, `MACOS_*`, or `WINDOWS_*`

Later layers replace earlier `PROGRAM`, `ARGS`, and `CWD` values. Environment overrides merge by key, with later layers winning.

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
- `workspaceDir` resolves to the active workspace root in workspace mode
- manifest-defined variables can reference built-ins and each other
- expansion is repeated for a small fixed number of passes

## Execution Model

- Linux and macOS run through `portui.sh`
- Windows runs through `portui.ps1` or `portui.cmd`
- repos can vendor the runtime under `.portui-runtime/` and expose local `portui.sh`, `portui.ps1`, and `portui.cmd` wrappers
- the runtime executes the resolved program directly with explicit argument arrays
- the runtime changes into the resolved working directory before launch
- timeouts are enforced by the host launcher

## CLI Modes

Project-local mode after vendoring:

```bash
(cd ../my-repo && sh ./portui.sh --list)
(cd ../my-repo && sh ./portui.sh --run doctor)
```

Workspace mode examples:

```bash
sh ./portui.sh --list-projects
sh ./portui.sh --project smaLLMs --list
sh ./portui.sh --project GUITboard --run test
```

Single-manifest mode examples:

```bash
sh ./portui.sh --manifest-dir ./examples/demo --list
sh ./portui.sh --manifest-dir ./examples/demo --run git-version
```

## Intended Use

PortUI is for trusted local project workflows where one standardized terminal interface should be reused across many repos instead of rebuilt from scratch for each one.

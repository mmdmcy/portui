# Manifest Spec

PortUI applications are directory-based manifests.

## Layout

```text
my-portui-app/
  manifest.env
  actions/
    01-doctor.env
    02-build.env
    03-dev.env
```

## `manifest.env`

Recognized keys:

- `NAME`: display name for the manifest
- `DESCRIPTION`: short description shown in listings
- `VARIABLE_<name>`: reusable variable definition

Example:

```text
NAME=My Repo Tools
DESCRIPTION=Portable local commands for one repository.
VARIABLE_workspace={{home}}/Documents/github
VARIABLE_repo={{workspace}}/my-repo
```

## Action files

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

## Argument encoding

`ARGS` values are `|`-separated.

Example:

```text
PROGRAM=git
ARGS=status|--short|--branch
```

This avoids ambiguous shell splitting in the manifest format while keeping the files easy to author by hand.

## Resolution order

PortUI resolves actions in this order:

1. base keys
2. `POSIX_*` overrides on Linux and macOS
3. OS-specific overrides for the current host: `LINUX_*`, `MACOS_*`, or `WINDOWS_*`

Later layers replace earlier `PROGRAM`, `ARGS`, and `CWD` values. Environment overrides merge by key, with later layers winning.

## Built-in variables

- `{{home}}`
- `{{cwd}}`
- `{{os}}`
- `{{manifestDir}}`
- `{{pathSep}}`
- `{{listSep}}`
- `{{exeSuffix}}`

Manifest-defined variables can reference built-ins and other manifest variables. Expansion is repeated for a small fixed number of passes so chained variables can resolve without introducing unbounded recursion.

## Execution model

- Linux and macOS run through `portui.sh`
- Windows runs through `portui.ps1` or `portui.cmd`
- the runtime executes the resolved program directly with explicit argument arrays
- the runtime changes into the resolved working directory before launch
- timeouts are enforced by the host launcher, not by an external process manager

## Intended use

PortUI is for trusted local developer workflows where one logical action may need different native commands on different operating systems.


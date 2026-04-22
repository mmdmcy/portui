# Contributing

PortUI is small on purpose. Contributions should preserve that.

## Principles

- keep the runtime dependency-free
- prefer portable shell behavior over clever shell tricks
- treat manifest compatibility as a public interface
- document behavior changes in `README.md`, `docs/manifest-spec.md`, and `CHANGELOG.md`

## Development

Linux or macOS:

```bash
sh -n ./portui.sh
sh ./ci/test-posix.sh
```

Windows:

```powershell
.\ci\test-powershell.ps1
```

## Change scope

Good contributions usually fit one of these categories:

- bug fixes in action resolution, variable expansion, or process execution
- manifest format improvements with backward-compatible defaults
- clearer documentation and examples
- CI coverage that increases confidence without adding runtime dependencies

Changes that add third-party runtime dependencies or turn PortUI into a shell-specific tool are usually out of scope.

## Pull requests

- keep PRs focused
- explain the behavioral change, not just the code diff
- note any portability tradeoffs explicitly
- update examples or docs when user-facing behavior changes


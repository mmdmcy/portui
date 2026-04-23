# Changelog

All notable changes to this project will be documented in this file.

The format is intentionally lightweight and follows semantic versioning in practice.

## [Unreleased]

- added `--install-project` and `-InstallProject` to vendor the PortUI runtime into existing repos
- added project-local wrapper generation for `portui.sh`, `portui.ps1`, and `portui.cmd`
- expanded smoke tests to cover project-local install and project-local execution
- added workspace mode that discovers project manifests under direct child repositories
- added `--workspace`, `--project`, and `--list-projects` support to the POSIX and PowerShell runtimes
- added new built-in variables: `projectDir`, `projectId`, and `workspaceDir`
- changed the default startup behavior to prefer workspace mode when sibling PortUI projects are present
- added workspace example projects and expanded smoke tests to cover discovery and per-project dispatch

## [0.1.0] - 2026-04-22

Initial public release.

- introduced a zero-dependency PortUI runtime for Linux, macOS, and Windows
- added `portui.sh`, `portui.ps1`, and `portui.cmd`
- added manifest-driven action selection with per-platform overrides
- added built-in variable expansion for paths and host metadata
- added demo manifests and smoke-test scripts
- added GitHub Actions CI across Ubuntu, macOS, and Windows

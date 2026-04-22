# Security Policy

PortUI is an early-stage developer tool. It executes commands defined in trusted local manifests and is not designed as a sandbox.

## Supported versions

Only the latest release line is considered supported for security fixes.

## Reporting

Do not open a public issue for a suspected vulnerability.

Instead, use GitHub's private vulnerability reporting for this repository if it is enabled. If that path is unavailable, contact the maintainer through the repository owner profile on GitHub and avoid public disclosure until the issue has been reviewed.

## Threat model notes

- PortUI assumes manifests are trusted by the local user
- PortUI does not attempt to sanitize arbitrary shell commands into safe commands
- PortUI is intended for local developer workflows, not hostile multi-tenant execution


#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

cd "$ROOT_DIR"

list_output=$(sh ./portui.sh --list)
printf '%s\n' "$list_output" | grep 'PortUI Demo' >/dev/null
printf '%s\n' "$list_output" | grep 'Git Version' >/dev/null

git_output=$(sh ./portui.sh --run git-version)
printf '%s\n' "$git_output" | grep 'git version' >/dev/null

doctor_output=$(sh ./portui.sh --run doctor)
printf '%s\n' "$doctor_output" | grep 'shell=sh' >/dev/null

home_output=$(sh ./portui.sh --run show-home)
printf '%s\n' "$home_output" | grep 'pathSep=' >/dev/null

workspace_output=$(sh ./portui.sh --run list-workspace)
printf '%s\n' "$workspace_output" | grep 'Status: exit code 0' >/dev/null

printf '%s\n' 'POSIX smoke tests passed.'


#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

cd "$ROOT_DIR"

starter_output=$(sh ./portui.sh --list)
printf '%s\n' "$starter_output" | grep 'PortUI Starter' >/dev/null
printf '%s\n' "$starter_output" | grep 'Doctor \[doctor\]' >/dev/null

list_output=$(sh ./portui.sh --manifest-dir ./examples/demo --list)
printf '%s\n' "$list_output" | grep 'PortUI Demo' >/dev/null
printf '%s\n' "$list_output" | grep 'Git Version' >/dev/null

git_output=$(sh ./portui.sh --manifest-dir ./examples/demo --run git-version)
printf '%s\n' "$git_output" | grep 'git version' >/dev/null

doctor_output=$(sh ./portui.sh --manifest-dir ./examples/demo --run doctor)
printf '%s\n' "$doctor_output" | grep 'shell=sh' >/dev/null

home_output=$(sh ./portui.sh --manifest-dir ./examples/demo --run show-home)
printf '%s\n' "$home_output" | grep 'pathSep=' >/dev/null

workspace_output=$(sh ./portui.sh --manifest-dir ./examples/demo --run list-workspace)
printf '%s\n' "$workspace_output" | grep 'Status: exit code 0' >/dev/null

projects_output=$(sh ./portui.sh --workspace ./examples/workspace --list-projects)
printf '%s\n' "$projects_output" | grep 'Alpha Workspace App \[alpha\]' >/dev/null
printf '%s\n' "$projects_output" | grep 'Beta Hidden App \[beta\]' >/dev/null

alpha_list_output=$(sh ./portui.sh --workspace ./examples/workspace --project alpha --list)
printf '%s\n' "$alpha_list_output" | grep 'Alpha Doctor \[doctor\]' >/dev/null

alpha_doctor_output=$(sh ./portui.sh --workspace ./examples/workspace --project alpha --run doctor)
printf '%s\n' "$alpha_doctor_output" | grep 'alpha=alpha' >/dev/null
printf '%s\n' "$alpha_doctor_output" | grep 'workspace=' >/dev/null

beta_ping_output=$(sh ./portui.sh --workspace ./examples/workspace --project beta --run ping)
printf '%s\n' "$beta_ping_output" | grep 'beta=beta' >/dev/null

temp_project_root=$(mktemp -d)
mkdir -p "$temp_project_root/engine-demo/portui/actions"
cp ./examples/workspace/alpha/portui/manifest.env "$temp_project_root/engine-demo/portui/manifest.env"
cp ./examples/workspace/alpha/portui/actions/01-doctor.env "$temp_project_root/engine-demo/portui/actions/01-doctor.env"

install_output=$(sh ./portui.sh --install-project "$temp_project_root/engine-demo")
printf '%s\n' "$install_output" | grep 'Installed PortUI runtime into' >/dev/null

grep '%~dp0portui' "$temp_project_root/engine-demo/portui.cmd" >/dev/null

embedded_output=$(sh "$temp_project_root/engine-demo/portui.sh" --run doctor)
printf '%s\n' "$embedded_output" | grep 'alpha=engine-demo' >/dev/null

init_project_root=$(mktemp -d)
mkdir -p "$init_project_root/idea"

init_output=$(sh ./portui.sh --init-project "$init_project_root/idea")
printf '%s\n' "$init_output" | grep 'Created starter PortUI app in' >/dev/null
test -f "$init_project_root/idea/portui/manifest.env"
test -f "$init_project_root/idea/portui/actions/01-doctor.env"
test -f "$init_project_root/idea/.portui-runtime/portui.sh"

init_embedded_output=$(sh "$init_project_root/idea/portui.sh" --run doctor)
printf '%s\n' "$init_embedded_output" | grep 'project=idea' >/dev/null

rm -rf "$temp_project_root" "$init_project_root"

printf '%s\n' 'POSIX smoke tests passed.'

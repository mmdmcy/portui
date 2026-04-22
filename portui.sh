#!/bin/sh

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MANIFEST_DIR="$SCRIPT_DIR/examples/demo"
LIST_ONLY=0
RUN_ACTION_ID=""

PORTUI_OS=""
PORTUI_VAR_KEYS=""
PORTUI_ACTION_LIST_FILE=""

usage() {
    cat <<'EOF'
Usage: sh ./portui.sh [--manifest-dir DIR] [--list] [--run ACTION_ID]

Options:
  --manifest-dir DIR   Path to a PortUI manifest directory.
  --list               Print actions and exit.
  --run ACTION_ID      Run a specific action non-interactively.
  --help               Show this help.
EOF
}

quote_single() {
    printf "%s" "$1" | sed "s/'/'\\\\''/g"
}

set_named_var() {
    key=$1
    value=$2
    case "$key" in
        ''|*[!A-Za-z0-9_]*)
            return 1
            ;;
    esac

    escaped=$(quote_single "$value")
    eval "PORTUI_VAR_$key='$escaped'"

    case " $PORTUI_VAR_KEYS " in
        *" $key "*) ;;
        *) PORTUI_VAR_KEYS="$PORTUI_VAR_KEYS $key" ;;
    esac
}

get_named_var() {
    key=$1
    case "$key" in
        ''|*[!A-Za-z0-9_]*)
            printf '%s' ""
            return
            ;;
    esac

    eval "printf '%s' \"\${PORTUI_VAR_$key-}\""
}

escape_sed_replacement() {
    printf "%s" "$1" | sed 's/[&|]/\\&/g'
}

expand_text() {
    text=$1
    pass=0

    while [ "$pass" -lt 8 ]; do
        changed=0
        for key in $PORTUI_VAR_KEYS; do
            token="{{$key}}"
            value=$(get_named_var "$key")
            safe_value=$(escape_sed_replacement "$value")
            updated=$(printf "%s" "$text" | sed "s|$token|$safe_value|g")
            if [ "$updated" != "$text" ]; then
                changed=1
                text=$updated
            fi
        done

        if [ "$changed" -eq 0 ]; then
            break
        fi

        pass=$((pass + 1))
    done

    printf "%s" "$text"
}

append_pipe_value() {
    var_name=$1
    next_value=$2
    eval "current_value=\${$var_name-}"
    if [ -n "$current_value" ]; then
        merged="$current_value|$next_value"
    else
        merged="$next_value"
    fi
    escaped=$(quote_single "$merged")
    eval "$var_name='$escaped'"
}

detect_os() {
    uname_value=$(uname -s 2>/dev/null || printf '%s' "unknown")
    case "$uname_value" in
        Linux) PORTUI_OS="linux" ;;
        Darwin) PORTUI_OS="macos" ;;
        *) PORTUI_OS="unknown" ;;
    esac
}

init_builtin_variables() {
    home_dir=${HOME-}
    current_dir=$(pwd)

    set_named_var "home" "$home_dir" || exit 1
    set_named_var "cwd" "$current_dir" || exit 1
    set_named_var "os" "$PORTUI_OS" || exit 1
    set_named_var "manifestDir" "$MANIFEST_DIR" || exit 1

    if [ "$PORTUI_OS" = "windows" ]; then
        set_named_var "pathSep" "\\" || exit 1
        set_named_var "listSep" ";" || exit 1
        set_named_var "exeSuffix" ".exe" || exit 1
    else
        set_named_var "pathSep" "/" || exit 1
        set_named_var "listSep" ":" || exit 1
        set_named_var "exeSuffix" "" || exit 1
    fi
}

parse_manifest_line() {
    line=$1
    case "$line" in
        ''|'#'*)
            return
            ;;
    esac

    key=${line%%=*}
    value=${line#*=}

    case "$key" in
        NAME) PORTUI_MANIFEST_NAME=$value ;;
        DESCRIPTION) PORTUI_MANIFEST_DESCRIPTION=$value ;;
        VARIABLE_*)
            variable_name=${key#VARIABLE_}
            set_named_var "$variable_name" "$value" || {
                printf '%s\n' "Invalid variable name in manifest: $variable_name" >&2
                exit 1
            }
            ;;
    esac
}

load_manifest() {
    manifest_file="$MANIFEST_DIR/manifest.env"
    if [ ! -f "$manifest_file" ]; then
        printf '%s\n' "Missing manifest file: $manifest_file" >&2
        exit 1
    fi

    PORTUI_MANIFEST_NAME="PortUI"
    PORTUI_MANIFEST_DESCRIPTION=""

    while IFS= read -r raw_line || [ -n "$raw_line" ]; do
        line=$(printf "%s" "$raw_line" | tr -d '\r')
        parse_manifest_line "$line"
    done < "$manifest_file"

    for key in $PORTUI_VAR_KEYS; do
        value=$(get_named_var "$key")
        expanded=$(expand_text "$value")
        set_named_var "$key" "$expanded" || exit 1
    done
}

build_action_list() {
    actions_dir="$MANIFEST_DIR/actions"
    if [ ! -d "$actions_dir" ]; then
        printf '%s\n' "Missing actions directory: $actions_dir" >&2
        exit 1
    fi

    PORTUI_ACTION_LIST_FILE=$(mktemp)
    find "$actions_dir" -type f -name '*.env' | sort > "$PORTUI_ACTION_LIST_FILE"
}

cleanup() {
    if [ -n "${PORTUI_ACTION_LIST_FILE-}" ] && [ -f "$PORTUI_ACTION_LIST_FILE" ]; then
        rm -f "$PORTUI_ACTION_LIST_FILE"
    fi
}

trap cleanup EXIT INT TERM

reset_action_state() {
    ACTION_ID=""
    ACTION_TITLE=""
    ACTION_DESCRIPTION=""
    ACTION_TIMEOUT_SECONDS="30"
    ACTION_PROGRAM=""
    ACTION_ARGS=""
    ACTION_CWD=""
    ACTION_ENV=""
    ACTION_POSIX_PROGRAM=""
    ACTION_POSIX_ARGS=""
    ACTION_POSIX_CWD=""
    ACTION_POSIX_ENV=""
    ACTION_LINUX_PROGRAM=""
    ACTION_LINUX_ARGS=""
    ACTION_LINUX_CWD=""
    ACTION_LINUX_ENV=""
    ACTION_MACOS_PROGRAM=""
    ACTION_MACOS_ARGS=""
    ACTION_MACOS_CWD=""
    ACTION_MACOS_ENV=""
    ACTION_WINDOWS_PROGRAM=""
    ACTION_WINDOWS_ARGS=""
    ACTION_WINDOWS_CWD=""
    ACTION_WINDOWS_ENV=""
}

parse_action_line() {
    line=$1
    case "$line" in
        ''|'#'*)
            return
            ;;
    esac

    key=${line%%=*}
    value=${line#*=}

    case "$key" in
        ID) ACTION_ID=$value ;;
        TITLE) ACTION_TITLE=$value ;;
        DESCRIPTION) ACTION_DESCRIPTION=$value ;;
        TIMEOUT_SECONDS) ACTION_TIMEOUT_SECONDS=$value ;;
        PROGRAM) ACTION_PROGRAM=$value ;;
        ARGS) ACTION_ARGS=$value ;;
        CWD) ACTION_CWD=$value ;;
        ENV_*) append_pipe_value "ACTION_ENV" "${key#ENV_}=$value" ;;
        POSIX_PROGRAM) ACTION_POSIX_PROGRAM=$value ;;
        POSIX_ARGS) ACTION_POSIX_ARGS=$value ;;
        POSIX_CWD) ACTION_POSIX_CWD=$value ;;
        POSIX_ENV_*) append_pipe_value "ACTION_POSIX_ENV" "${key#POSIX_ENV_}=$value" ;;
        LINUX_PROGRAM) ACTION_LINUX_PROGRAM=$value ;;
        LINUX_ARGS) ACTION_LINUX_ARGS=$value ;;
        LINUX_CWD) ACTION_LINUX_CWD=$value ;;
        LINUX_ENV_*) append_pipe_value "ACTION_LINUX_ENV" "${key#LINUX_ENV_}=$value" ;;
        MACOS_PROGRAM) ACTION_MACOS_PROGRAM=$value ;;
        MACOS_ARGS) ACTION_MACOS_ARGS=$value ;;
        MACOS_CWD) ACTION_MACOS_CWD=$value ;;
        MACOS_ENV_*) append_pipe_value "ACTION_MACOS_ENV" "${key#MACOS_ENV_}=$value" ;;
        WINDOWS_PROGRAM) ACTION_WINDOWS_PROGRAM=$value ;;
        WINDOWS_ARGS) ACTION_WINDOWS_ARGS=$value ;;
        WINDOWS_CWD) ACTION_WINDOWS_CWD=$value ;;
        WINDOWS_ENV_*) append_pipe_value "ACTION_WINDOWS_ENV" "${key#WINDOWS_ENV_}=$value" ;;
    esac
}

load_action() {
    action_file=$1
    reset_action_state

    while IFS= read -r raw_line || [ -n "$raw_line" ]; do
        line=$(printf "%s" "$raw_line" | tr -d '\r')
        parse_action_line "$line"
    done < "$action_file"

    if [ -z "$ACTION_ID" ]; then
        printf '%s\n' "Action file is missing ID: $action_file" >&2
        exit 1
    fi

    if [ -z "$ACTION_TITLE" ]; then
        ACTION_TITLE=$ACTION_ID
    fi
}

apply_variant() {
    prefix=$1
    label=$2

    eval "variant_program=\${ACTION_${prefix}_PROGRAM-}"
    eval "variant_args=\${ACTION_${prefix}_ARGS-}"
    eval "variant_cwd=\${ACTION_${prefix}_CWD-}"
    eval "variant_env=\${ACTION_${prefix}_ENV-}"

    if [ -n "$variant_program" ]; then
        RESOLVED_PROGRAM=$variant_program
    fi
    if [ -n "$variant_args" ]; then
        RESOLVED_ARGS=$variant_args
    fi
    if [ -n "$variant_cwd" ]; then
        RESOLVED_CWD=$variant_cwd
    fi
    if [ -n "$variant_env" ]; then
        if [ -n "$RESOLVED_ENV" ]; then
            RESOLVED_ENV="$RESOLVED_ENV|$variant_env"
        else
            RESOLVED_ENV=$variant_env
        fi
    fi

    if [ -n "$variant_program$variant_args$variant_cwd$variant_env" ]; then
        RESOLUTION_SOURCE="$RESOLUTION_SOURCE -> $label"
    fi
}

expand_env_pairs() {
    raw_pairs=$1
    expanded_pairs=""

    if [ -z "$raw_pairs" ]; then
        printf '%s' ""
        return
    fi

    old_ifs=$IFS
    IFS='|'
    set -- $raw_pairs
    IFS=$old_ifs

    for pair in "$@"; do
        env_key=${pair%%=*}
        env_value=${pair#*=}
        env_value=$(expand_text "$env_value")
        if [ -n "$expanded_pairs" ]; then
            expanded_pairs="$expanded_pairs|$env_key=$env_value"
        else
            expanded_pairs="$env_key=$env_value"
        fi
    done

    printf '%s' "$expanded_pairs"
}

resolve_action() {
    RESOLVED_PROGRAM=$ACTION_PROGRAM
    RESOLVED_ARGS=$ACTION_ARGS
    RESOLVED_CWD=$ACTION_CWD
    RESOLVED_ENV=$ACTION_ENV
    RESOLUTION_SOURCE="base"

    if [ "$PORTUI_OS" != "windows" ]; then
        apply_variant "POSIX" "posix"
    fi

    case "$PORTUI_OS" in
        linux) apply_variant "LINUX" "linux" ;;
        macos) apply_variant "MACOS" "macos" ;;
        windows) apply_variant "WINDOWS" "windows" ;;
    esac

    if [ -z "$RESOLVED_PROGRAM" ]; then
        printf '%s\n' "Action $ACTION_ID does not resolve to a runnable program on $PORTUI_OS" >&2
        exit 1
    fi

    RESOLVED_PROGRAM=$(expand_text "$RESOLVED_PROGRAM")
    RESOLVED_ARGS=$(expand_text "$RESOLVED_ARGS")

    if [ -n "$RESOLVED_CWD" ]; then
        RESOLVED_CWD=$(expand_text "$RESOLVED_CWD")
    else
        RESOLVED_CWD=$(pwd)
    fi

    RESOLVED_ENV=$(expand_env_pairs "$RESOLVED_ENV")
}

quote_display_part() {
    value=$1
    case "$value" in
        ''|*[!A-Za-z0-9_./:=+-]*)
            escaped=$(printf "%s" "$value" | sed 's/"/\\"/g')
            printf '"%s"' "$escaped"
            ;;
        *)
            printf '%s' "$value"
            ;;
    esac
}

display_command() {
    quote_display_part "$RESOLVED_PROGRAM"
    old_ifs=$IFS
    IFS='|'
    if [ -n "$RESOLVED_ARGS" ]; then
        set -- $RESOLVED_ARGS
    else
        set --
    fi
    IFS=$old_ifs

    for arg in "$@"; do
        printf ' '
        quote_display_part "$arg"
    done
}

run_resolved_action() {
    output_file=$(mktemp)
    timeout_flag_file=$(mktemp)
    start_epoch=$(date +%s)

    (
        cd "$RESOLVED_CWD" || exit 1

        old_ifs=$IFS
        IFS='|'
        if [ -n "$RESOLVED_ENV" ]; then
            set -- $RESOLVED_ENV
        else
            set --
        fi
        IFS=$old_ifs

        for pair in "$@"; do
            env_key=${pair%%=*}
            env_value=${pair#*=}
            export "$env_key=$env_value"
        done

        old_ifs=$IFS
        IFS='|'
        if [ -n "$RESOLVED_ARGS" ]; then
            set -- $RESOLVED_ARGS
        else
            set --
        fi
        IFS=$old_ifs

        exec "$RESOLVED_PROGRAM" "$@"
    ) >"$output_file" 2>&1 &
    command_pid=$!

    timed_out=0
    if [ -n "$ACTION_TIMEOUT_SECONDS" ] && [ "$ACTION_TIMEOUT_SECONDS" -gt 0 ] 2>/dev/null; then
        (
            sleep "$ACTION_TIMEOUT_SECONDS"
            if kill -0 "$command_pid" 2>/dev/null; then
                printf '%s' "1" > "$timeout_flag_file"
                kill "$command_pid" 2>/dev/null
                sleep 1
                kill -9 "$command_pid" 2>/dev/null
            fi
        ) >/dev/null 2>&1 </dev/null &
        watchdog_pid=$!
    else
        watchdog_pid=""
    fi

    wait "$command_pid"
    exit_code=$?

    if [ -n "$watchdog_pid" ]; then
        if [ -s "$timeout_flag_file" ]; then
            timed_out=1
        elif kill -0 "$watchdog_pid" 2>/dev/null; then
            kill "$watchdog_pid" 2>/dev/null
        fi
    fi

    end_epoch=$(date +%s)
    duration=$((end_epoch - start_epoch))

    printf '\n'
    if [ "$timed_out" -eq 1 ]; then
        printf '%s\n' "Status: timed out after ${ACTION_TIMEOUT_SECONDS}s"
    else
        printf '%s\n' "Status: exit code $exit_code"
    fi
    printf '%s\n' "Duration: ${duration}s"
    printf '\n'
    cat "$output_file"
    printf '\n'

    rm -f "$output_file" "$timeout_flag_file"

    if [ "$timed_out" -eq 1 ]; then
        return 124
    fi

    return "$exit_code"
}

list_actions() {
    count=0
    printf '%s\n' "$PORTUI_MANIFEST_NAME"
    if [ -n "$PORTUI_MANIFEST_DESCRIPTION" ]; then
        printf '%s\n' "$PORTUI_MANIFEST_DESCRIPTION"
    fi
    printf '\n'

    while IFS= read -r action_file || [ -n "$action_file" ]; do
        [ -n "$action_file" ] || continue
        load_action "$action_file"
        count=$((count + 1))
        printf '%2d. %s [%s]\n' "$count" "$ACTION_TITLE" "$ACTION_ID"
        if [ -n "$ACTION_DESCRIPTION" ]; then
            printf '    %s\n' "$ACTION_DESCRIPTION"
        fi
    done < "$PORTUI_ACTION_LIST_FILE"
}

run_action_by_id() {
    target_id=$1
    matched_file=""

    while IFS= read -r action_file || [ -n "$action_file" ]; do
        [ -n "$action_file" ] || continue
        load_action "$action_file"
        if [ "$ACTION_ID" = "$target_id" ]; then
            matched_file=$action_file
            break
        fi
    done < "$PORTUI_ACTION_LIST_FILE"

    if [ -z "$matched_file" ]; then
        printf '%s\n' "No action with id: $target_id" >&2
        exit 1
    fi

    load_action "$matched_file"
    resolve_action

    printf '%s\n' "$ACTION_TITLE"
    if [ -n "$ACTION_DESCRIPTION" ]; then
        printf '%s\n' "$ACTION_DESCRIPTION"
    fi
    printf '%s\n' "Working directory: $RESOLVED_CWD"
    printf '%s\n' "Resolution: $RESOLUTION_SOURCE"
    printf '%s' "Command: "
    display_command
    printf '\n'

    if [ -n "$RESOLVED_ENV" ]; then
        printf '%s\n' "Environment overrides:"
        old_ifs=$IFS
        IFS='|'
        set -- $RESOLVED_ENV
        IFS=$old_ifs
        for pair in "$@"; do
            printf '  %s\n' "$pair"
        done
    fi

    run_resolved_action
}

interactive_menu() {
    while :; do
        printf '\n%s\n' "$PORTUI_MANIFEST_NAME"
        if [ -n "$PORTUI_MANIFEST_DESCRIPTION" ]; then
            printf '%s\n' "$PORTUI_MANIFEST_DESCRIPTION"
        fi
        printf '%s\n' "OS: $PORTUI_OS"
        printf '%s\n\n' "Manifest: $MANIFEST_DIR"

        count=0
        while IFS= read -r action_file || [ -n "$action_file" ]; do
            [ -n "$action_file" ] || continue
            load_action "$action_file"
            count=$((count + 1))
            printf '%2d. %s [%s]\n' "$count" "$ACTION_TITLE" "$ACTION_ID"
            if [ -n "$ACTION_DESCRIPTION" ]; then
                printf '    %s\n' "$ACTION_DESCRIPTION"
            fi
        done < "$PORTUI_ACTION_LIST_FILE"

        if [ "$count" -eq 0 ]; then
            printf '%s\n' "No actions found."
            exit 1
        fi

        printf '\n%s' "Select an action number, or q to quit: "
        IFS= read -r selection

        case "$selection" in
            q|Q|quit|exit)
                exit 0
                ;;
        esac

        case "$selection" in
            ''|*[!0-9]*)
                printf '%s\n' "Invalid selection."
                continue
                ;;
        esac

        if [ "$selection" -lt 1 ] || [ "$selection" -gt "$count" ]; then
            printf '%s\n' "Selection out of range."
            continue
        fi

        current_index=0
        selected_file=""
        while IFS= read -r action_file || [ -n "$action_file" ]; do
            [ -n "$action_file" ] || continue
            current_index=$((current_index + 1))
            if [ "$current_index" -eq "$selection" ]; then
                selected_file=$action_file
                break
            fi
        done < "$PORTUI_ACTION_LIST_FILE"

        if [ -z "$selected_file" ]; then
            printf '%s\n' "Unable to resolve selection."
            continue
        fi

        load_action "$selected_file"
        resolve_action

        printf '\n%s\n' "$ACTION_TITLE"
        if [ -n "$ACTION_DESCRIPTION" ]; then
            printf '%s\n' "$ACTION_DESCRIPTION"
        fi
        printf '%s\n' "Working directory: $RESOLVED_CWD"
        printf '%s\n' "Resolution: $RESOLUTION_SOURCE"
        printf '%s' "Command: "
        display_command
        printf '\n'

        if [ -n "$RESOLVED_ENV" ]; then
            printf '%s\n' "Environment overrides:"
            old_ifs=$IFS
            IFS='|'
            set -- $RESOLVED_ENV
            IFS=$old_ifs
            for pair in "$@"; do
                printf '  %s\n' "$pair"
            done
        fi

        printf '\n%s' "Run this action? [Y/n]: "
        IFS= read -r confirmation
        case "$confirmation" in
            n|N|no|NO)
                continue
                ;;
        esac

        run_resolved_action
        printf '\n%s' "Press Enter to return to the menu."
        IFS= read -r _
    done
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --manifest-dir)
            shift
            if [ "$#" -eq 0 ]; then
                printf '%s\n' "--manifest-dir requires a value" >&2
                exit 1
            fi
            MANIFEST_DIR=$1
            ;;
        --list)
            LIST_ONLY=1
            ;;
        --run)
            shift
            if [ "$#" -eq 0 ]; then
                printf '%s\n' "--run requires an action id" >&2
                exit 1
            fi
            RUN_ACTION_ID=$1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf '%s\n' "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

detect_os
if [ ! -d "$MANIFEST_DIR" ]; then
    printf '%s\n' "Missing manifest directory: $MANIFEST_DIR" >&2
    exit 1
fi
MANIFEST_DIR=$(CDPATH= cd -- "$MANIFEST_DIR" && pwd)
init_builtin_variables
load_manifest
build_action_list

if [ "$LIST_ONLY" -eq 1 ]; then
    list_actions
    exit 0
fi

if [ -n "$RUN_ACTION_ID" ]; then
    run_action_by_id "$RUN_ACTION_ID"
    exit $?
fi

interactive_menu

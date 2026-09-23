#!/bin/bash

# ============================================================
# devstartv2 - Manifest
# ============================================================

# ------------------------------------------------------------
# Manifest Path
# ------------------------------------------------------------

manifest_path() {
    local project_dir="$1"

    printf '%s/.project-env.txt\n' "${project_dir%/}"
}

# ------------------------------------------------------------
# Manifest Validation
# ------------------------------------------------------------

manifest_exists() {
    local project_dir="$1"
    local manifest

    manifest="$(manifest_path "$project_dir")"

    [[ -f "$manifest" ]]
}

manifest_require() {
    local project_dir="$1"
    local manifest

    manifest="$(manifest_path "$project_dir")"

    if [[ ! -f "$manifest" ]]; then
        devstart_die "Manifest missing: $manifest"
    fi
}

# ------------------------------------------------------------
# Load Manifest
# ------------------------------------------------------------

manifest_load() {
    local project_dir="$1"
    local manifest
    local line
    local key
    local value
    local pane_index

    manifest="$(manifest_path "$project_dir")"

    # Reset manifest state every time we load.
    MANIFEST_PROJECT_NAME=""

    declare -gA MANIFEST_PANES=()
    declare -ga MANIFEST_PANE_INDICES=()

    if [[ ! -f "$manifest" ]]; then
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do

        # Remove possible CR character.
        line="${line%$'\r'}"

        # Ignore empty lines.
        [[ -z "$line" ]] && continue

        # ----------------------------------------------------
        # PROJECT_NAME
        # ----------------------------------------------------

        if [[ "$line" == PROJECT_NAME=* ]]; then

            value="${line#PROJECT_NAME=}"

            # Remove surrounding quotes.
            value="${value#\"}"
            value="${value%\"}"

            MANIFEST_PROJECT_NAME="$value"

            continue
        fi

        # ----------------------------------------------------
        # Everything else must have an equals sign.
        # ----------------------------------------------------

        [[ "$line" == *=* ]] || continue

        key="${line%%=*}"
        value="${line#*=}"

        # ----------------------------------------------------
        # PANE_<number>
        # ----------------------------------------------------

        if [[ "$key" =~ ^PANE_[0-9]+$ ]]; then

            pane_index="${key#PANE_}"

            # Remove surrounding quotes.
            value="${value#\"}"
            value="${value%\"}"

            MANIFEST_PANES["$pane_index"]="$value"
            MANIFEST_PANE_INDICES+=("$pane_index")

        fi

    done < "$manifest"

    return 0
}

# ------------------------------------------------------------
# Pane Count
# ------------------------------------------------------------

manifest_pane_count() {
    local count=0
    local i

    for i in "${!MANIFEST_PANES[@]}"; do
        [[ -n "${MANIFEST_PANES[$i]}" ]] || continue
        ((count++))
    done

    printf '%s\n' "$count"
}

# ------------------------------------------------------------
# Get Pane
# ------------------------------------------------------------

manifest_get_pane() {
    local pane_index="$1"

    printf '%s\n' "${MANIFEST_PANES[$pane_index]}"
}

# ------------------------------------------------------------
# Parse Pane
# ------------------------------------------------------------

manifest_parse_pane() {
    local pane_index="$1"
    local pane_value

    pane_value="${MANIFEST_PANES[$pane_index]}"

    MANIFEST_PANE_PATH=""
    MANIFEST_PANE_COMMAND=""

    [[ -z "$pane_value" ]] && return 1

    if [[ "$pane_value" == *"|"* ]]; then

        MANIFEST_PANE_PATH="${pane_value%%|*}"
        MANIFEST_PANE_COMMAND="${pane_value#*|}"

        # Trim whitespace
        MANIFEST_PANE_PATH="${MANIFEST_PANE_PATH#"${MANIFEST_PANE_PATH%%[![:space:]]*}"}"
        MANIFEST_PANE_PATH="${MANIFEST_PANE_PATH%"${MANIFEST_PANE_PATH##*[![:space:]]}"}"

        MANIFEST_PANE_COMMAND="${MANIFEST_PANE_COMMAND#"${MANIFEST_PANE_COMMAND%%[![:space:]]*}"}"
        MANIFEST_PANE_COMMAND="${MANIFEST_PANE_COMMAND%"${MANIFEST_PANE_COMMAND##*[![:space:]]}"}"

    else

        MANIFEST_PANE_PATH="$pane_value"

    fi

    return 0
}
# ------------------------------------------------------------
# Get Pane Directory
# ------------------------------------------------------------

manifest_get_pane_path() {
    local pane_index="$1"

    manifest_parse_pane "$pane_index" || return 1

    printf '%s\n' "$MANIFEST_PANE_PATH"
}

# ------------------------------------------------------------
# Get Pane Command
# ------------------------------------------------------------

manifest_get_pane_command() {
    local pane_index="$1"

    manifest_parse_pane "$pane_index" || return 1

    printf '%s\n' "$MANIFEST_PANE_COMMAND"
}


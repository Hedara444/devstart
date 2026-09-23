#!/bin/bash

# ============================================================
# devstartv2 - Registry
# ============================================================

# ------------------------------------------------------------
# Registry Initialization
# ------------------------------------------------------------

registry_init() {
    devstart_init_config

    if [[ ! -f "$DEVSTART_REGISTRY" ]]; then
        touch "$DEVSTART_REGISTRY"
    fi
}

# ------------------------------------------------------------
# Load Registry
# ------------------------------------------------------------

registry_load() {
    registry_init

    REGISTRY_PROJECT_NAMES=()
    REGISTRY_PROJECT_PATHS=()

    local project_name
    local project_path

    while IFS='|' read -r project_name project_path; do

        [[ -z "$project_name" ]] && continue
        [[ -z "$project_path" ]] && continue

        REGISTRY_PROJECT_NAMES+=("$project_name")
        REGISTRY_PROJECT_PATHS+=("$project_path")

    done < "$DEVSTART_REGISTRY"
}

# ------------------------------------------------------------
# Add Project
# ------------------------------------------------------------

registry_add() {
    local project_name="$1"
    local project_path="$2"

    if [[ -z "$project_name" ]]; then
        devstart_warning "Registry: project name is empty."
        return 1
    fi

    if [[ -z "$project_path" ]]; then
        devstart_warning "Registry: project path is empty."
        return 1
    fi

    registry_init

    # Normalize the path.
    project_path="$(cd "$project_path" 2>/dev/null && pwd)" || {
        devstart_warning "Registry: project path does not exist:"
        echo "  $project_path"
        return 1
    }

    # Remove an existing registration for this path.
    registry_remove_path "$project_path"

    # Add the new registration.
    printf '%s|%s\n' \
        "$project_name" \
        "$project_path" >> "$DEVSTART_REGISTRY"
}

# ------------------------------------------------------------
# Remove Project By Path
# ------------------------------------------------------------

registry_remove_path() {
    local project_path="$1"
    local temp_file
    local project_name
    local registered_path

    registry_init

    [[ ! -s "$DEVSTART_REGISTRY" ]] && return 0

    temp_file="$(mktemp)" || return 1

    while IFS='|' read -r project_name registered_path; do

        # Skip completely empty lines.
        [[ -z "$project_name" && -z "$registered_path" ]] && continue

        # Skip malformed registry entries.
        [[ -z "$project_name" ]] && continue
        [[ -z "$registered_path" ]] && continue

        # Remove the requested project path.
        if [[ "$registered_path" == "$project_path" ]]; then
            continue
        fi

        printf '%s|%s\n' \
            "$project_name" \
            "$registered_path" >> "$temp_file"

    done < "$DEVSTART_REGISTRY"

    mv "$temp_file" "$DEVSTART_REGISTRY"
}
# ------------------------------------------------------------
# Find Project
# ------------------------------------------------------------

registry_find_project() {
    local project_name="$1"
    local index

    registry_load

    for index in "${!REGISTRY_PROJECT_NAMES[@]}"; do

        if [[ "${REGISTRY_PROJECT_NAMES[$index]}" == "$project_name" ]]; then

            printf '%s\n' \
                "${REGISTRY_PROJECT_PATHS[$index]}"

            return 0
        fi

    done

    return 1
}

# ------------------------------------------------------------
# Rename Project
# ------------------------------------------------------------

registry_rename() {
    local old_name="$1"
    local new_name="$2"
    local temp_file

    [[ -z "$old_name" ]] && return 1
    [[ -z "$new_name" ]] && return 1

    registry_init

    temp_file="$(mktemp)" || return 1

    while IFS='|' read -r project_name project_path; do

        [[ -z "$project_name" ]] && continue
        [[ -z "$project_path" ]] && continue

        if [[ "$project_name" == "$old_name" ]]; then

            printf '%s|%s\n' \
                "$new_name" \
                "$project_path" >> "$temp_file"

        else

            printf '%s|%s\n' \
                "$project_name" \
                "$project_path" >> "$temp_file"

        fi

    done < "$DEVSTART_REGISTRY"

    mv "$temp_file" "$DEVSTART_REGISTRY"
}

# ------------------------------------------------------------
# Registry Empty?
# ------------------------------------------------------------

registry_is_empty() {
    registry_init

    [[ ! -s "$DEVSTART_REGISTRY" ]]
}

# ------------------------------------------------------------
# Registry Count
# ------------------------------------------------------------

registry_count() {
    registry_load

    printf '%s\n' \
        "${#REGISTRY_PROJECT_NAMES[@]}"
}
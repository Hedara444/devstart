#!/bin/bash

# ============================================================
# devstartv2 - Initializer
# ============================================================


# ------------------------------------------------------------
# Directory Discovery
# ------------------------------------------------------------

initializer_discover_directories() {
    local project_dir="$1"
    local entry
    local name
    local directory

    INITIALIZER_DIRECTORIES=()

    # --------------------------------------------------------
    # First: configured pods
    # --------------------------------------------------------

    for directory in "${INITIALIZER_ORDER[@]}"; do

        [[ -v "INITIALIZER_PODS[$directory]" ]] || continue

        INITIALIZER_DIRECTORIES+=("$directory")

    done

    # --------------------------------------------------------
    # Second: discover new directories
    # --------------------------------------------------------

    while IFS= read -r entry; do

        name="${entry#"$project_dir"/}"

        [[ -z "$name" ]] && continue
        [[ "$name" == .* ]] && continue

        # Skip directories already present in the manifest.
        if [[ -v "INITIALIZER_PODS[$name]" ]]; then
            continue
        fi

        INITIALIZER_DIRECTORIES+=("$name")

    done < <(
        find "$project_dir" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -not -name '.*' \
            -print |
        sort
    )
}

# ------------------------------------------------------------
# Load Existing Manifest
# ------------------------------------------------------------

initializer_load_existing() {
    local project_dir="$1"
    local pane_index
    local pane_path
    local pane_command

    # Reset initializer state.
    declare -gA INITIALIZER_PODS=()
    declare -ga INITIALIZER_ORDER=()

    # Load the project's manifest.
    if ! manifest_load "$project_dir"; then
        return 1
    fi

    # Read panes in the same order they appeared
    # inside .project-env.txt.
    for pane_index in "${MANIFEST_PANE_INDICES[@]}"; do

        if ! manifest_parse_pane "$pane_index"; then
            continue
        fi

        pane_path="$MANIFEST_PANE_PATH"
        pane_command="$MANIFEST_PANE_COMMAND"

        [[ -z "$pane_path" ]] && continue

        # Store pod configuration.
        INITIALIZER_PODS["$pane_path"]="$pane_command"

        # Preserve manifest ordering.
        INITIALIZER_ORDER+=("$pane_path")

    done

    return 0
}


# ------------------------------------------------------------
# Draw Initializer
# ------------------------------------------------------------

initializer_draw() {
    local project_dir="$1"
    local index
    local directory
    local status

    clear

    draw_line

    echo "📂 Pod Configuration"
    echo "Project: $project_dir"

    draw_line

    if [[ "${#INITIALIZER_DIRECTORIES[@]}" -eq 0 ]]; then

        echo "No directories found."
        echo

    else

        for index in "${!INITIALIZER_DIRECTORIES[@]}"; do

            directory="${INITIALIZER_DIRECTORIES[$index]}"

            if [[ -v "INITIALIZER_PODS[$directory]" ]]; then

                if [[ -n "${INITIALIZER_PODS[$directory]}" ]]; then
                    status="${INITIALIZER_PODS[$directory]}"
                else
                    status="Idle"
                fi

            else

                status="Unconfigured"

            fi

            echo "[$index] $directory ($status)"

        done

        echo
    fi

    echo "[S] Save & Confirm"
    echo "[Q] Exit"
    echo

    draw_line
}


# ------------------------------------------------------------
# Configure Directory
# ------------------------------------------------------------

initializer_configure_directory() {
    local directory="$1"
    local type_choice
    local boot_command

    echo
    echo "Configure: $directory"
    echo
    echo "(a) Idle"
    echo "(b) Active"
    echo "(r) Remove"
    echo

    read -r -p "Choice: " type_choice

    case "${type_choice,,}" in

        a)
            INITIALIZER_PODS["$directory"]=""

            if [[ ! " ${INITIALIZER_ORDER[*]} " =~ " ${directory} " ]]; then
                INITIALIZER_ORDER+=("$directory")
            fi
            ;;

        b)
            read -r -p "Enter boot command: " boot_command

            INITIALIZER_PODS["$directory"]="$boot_command"

            if [[ ! " ${INITIALIZER_ORDER[*]} " =~ " ${directory} " ]]; then
                INITIALIZER_ORDER+=("$directory")
            fi
            ;;

        r)
            unset 'INITIALIZER_PODS[$directory]'

            local new_order=()
            local item

            for item in "${INITIALIZER_ORDER[@]}"; do
                [[ "$item" == "$directory" ]] && continue
                new_order+=("$item")
            done

            INITIALIZER_ORDER=("${new_order[@]}")
            ;;

    esac
}

# ------------------------------------------------------------
# Confirm Pods
# ------------------------------------------------------------

initializer_confirm() {
    local directory
    local command

    echo
    echo "Configured pods:"
    echo

    # Use INITIALIZER_ORDER so confirmation follows
    # the same order as the manifest.
    for directory in "${INITIALIZER_ORDER[@]}"; do

        [[ -v "INITIALIZER_PODS[$directory]" ]] || continue

        command="${INITIALIZER_PODS[$directory]}"

        if [[ -n "$command" ]]; then
            echo "Pod: $directory | Cmd: $command"
        else
            echo "Pod: $directory | Cmd: [idle]"
        fi

    done

    echo
}


# ------------------------------------------------------------
# Generate Manifest
# ------------------------------------------------------------

initializer_generate_manifest() {
    local project_dir="$1"
    local project_name="$2"
    local manifest
    local directory
    local command
    local index=1

    manifest="$(manifest_path "$project_dir")"

    {
        printf 'PROJECT_NAME="%s"\n' "$project_name"
        printf '\n'

        # Preserve pod order.
        for directory in "${INITIALIZER_ORDER[@]}"; do

            [[ -v "INITIALIZER_PODS[$directory]" ]] || continue

            command="${INITIALIZER_PODS[$directory]}"

            printf 'PANE_%s="%s | %s"\n' \
                "$index" \
                "$directory" \
                "$command"

            ((index++))

        done

    } > "$manifest"

    printf '%s\n' "$manifest"
}


# ------------------------------------------------------------
# Save Project
# ------------------------------------------------------------

initializer_save() {
    local project_dir="$1"
    local project_name
    local final_confirm

    echo
    initializer_confirm

    read -r -p "Confirm? (y/n): " final_confirm

    [[ "${final_confirm,,}" != "y" ]] && return 1

    echo

    # When modifying an existing project, preserve
    # its existing project name.
    if [[ -n "$MANIFEST_PROJECT_NAME" ]]; then

        project_name="$MANIFEST_PROJECT_NAME"

    else

        read -r -p "Enter PROJECT_NAME: " project_name

        if [[ -z "$project_name" ]]; then
            project_name="$(basename "$project_dir")"
        fi

    fi

    project_name="$(devstart_sanitize_name "$project_name")"

    if [[ -z "$project_name" ]]; then
        devstart_die "Project name cannot be empty."
    fi

    initializer_generate_manifest \
        "$project_dir" \
        "$project_name"

    registry_add \
        "$project_name" \
        "$project_dir"

    echo
    devstart_success "Project registered: $project_name"

    echo
    echo "Manifest:"
    echo "  $(manifest_path "$project_dir")"

    echo

    return 0
}


# ------------------------------------------------------------
# Main Initializer
# ------------------------------------------------------------

initializer_run() {
    local current_dir
    local manifest
    local confirm
    local choice
    local selected_directory

    current_dir="$(pwd)"
    manifest="$(manifest_path "$current_dir")"

    # --------------------------------------------------------
    # Existing manifest?
    # --------------------------------------------------------

    if [[ -f "$manifest" ]]; then

        echo "⚠️  .project-env.txt already exists."

        read -r -p "Modify it? (y/n): " confirm

        [[ "${confirm,,}" != "y" ]] && return 0

    fi

    # --------------------------------------------------------
    # Discover directories
    # --------------------------------------------------------

    # --------------------------------------------------------
    # Initialize state
    # --------------------------------------------------------

    declare -gA INITIALIZER_PODS=()
    declare -ga INITIALIZER_ORDER=()

    # --------------------------------------------------------
    # Load existing manifest
    # --------------------------------------------------------

    if [[ -f "$manifest" ]]; then

        if ! initializer_load_existing "$current_dir"; then
            devstart_warning "Could not read existing manifest."
        fi

    fi

    # --------------------------------------------------------
    # Discover directories
    # --------------------------------------------------------

    initializer_discover_directories "$current_dir"

    # --------------------------------------------------------
    # Configuration loop
    # --------------------------------------------------------

    while true; do

        initializer_draw "$current_dir"

        read -r -p "Select index or action: " choice

        case "${choice,,}" in

            q)
                return 0
                ;;

            s)

                if [[ "${#INITIALIZER_PODS[@]}" -eq 0 ]]; then
                    echo
                    echo "No pods configured!"
                    sleep 1
                    continue
                fi

                if initializer_save "$current_dir"; then
                    return 0
                fi

                ;;

            *)

                if [[ "$choice" =~ ^[0-9]+$ ]] &&
                   (( choice < ${#INITIALIZER_DIRECTORIES[@]} )); then

                    selected_directory="${INITIALIZER_DIRECTORIES[$choice]}"

                    initializer_configure_directory \
                        "$selected_directory"

                fi

                ;;

        esac

    done
}
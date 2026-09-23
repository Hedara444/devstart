#!/bin/bash

# ============================================================
# devstartv2 - Launcher
# ============================================================

# ------------------------------------------------------------
# Load Projects
# ------------------------------------------------------------

launcher_load_projects() {

    registry_load

    LAUNCHER_PROJECT_NAMES=()
    LAUNCHER_PROJECT_PATHS=()

    local index

    for index in "${!REGISTRY_PROJECT_NAMES[@]}"; do

        LAUNCHER_PROJECT_NAMES+=(
            "${REGISTRY_PROJECT_NAMES[$index]}"
        )

        LAUNCHER_PROJECT_PATHS+=(
            "${REGISTRY_PROJECT_PATHS[$index]}"
        )

    done
}

# ------------------------------------------------------------
# Draw
# ------------------------------------------------------------

launcher_draw() {

    local index

    clear

    draw_line
    echo "🚀 devstartv2 - Project Launcher"
    draw_line

    if [[ "${#LAUNCHER_PROJECT_NAMES[@]}" -eq 0 ]]; then

        echo
        echo "📭 Registry empty."
        echo
        echo "Use:"
        echo "  devstartv2 --init"
        echo

        return

    fi

    echo

    for index in "${!LAUNCHER_PROJECT_NAMES[@]}"; do

        echo "[$index] ${LAUNCHER_PROJECT_NAMES[$index]}"

    done

    echo
    echo "[R] Rename Project"
    echo "[Q] Quit"

    draw_line
}

# ------------------------------------------------------------
# Rename
# ------------------------------------------------------------

launcher_rename_project() {

    local index
    local old_name
    local new_name

    echo

    read -r -p "Index to rename: " index

    if [[ ! "$index" =~ ^[0-9]+$ ]] ||
       (( index >= ${#LAUNCHER_PROJECT_NAMES[@]} )); then

        devstart_warning "Invalid project index."
        sleep 1
        return
    fi

    old_name="${LAUNCHER_PROJECT_NAMES[$index]}"

    echo
    echo "Current name: $old_name"
    echo

    read -r -p "New name: " new_name

    if [[ -z "$new_name" ]]; then
        devstart_warning "Project name cannot be empty."
        sleep 1
        return
    fi

    new_name="$(devstart_sanitize_name "$new_name")"

    if [[ -z "$new_name" ]]; then
        devstart_warning "Invalid project name."
        sleep 1
        return
    fi

    registry_rename \
        "$old_name" \
        "$new_name"

    devstart_success "Project renamed."

    sleep 1
}

# ------------------------------------------------------------
# Select Project
# ------------------------------------------------------------

launcher_select_project() {

    local choice

    while true; do

        launcher_load_projects
        launcher_draw

        if [[ "${#LAUNCHER_PROJECT_NAMES[@]}" -eq 0 ]]; then
            return 1
        fi

        echo

        read -r -p "Select index or action: " choice

        case "${choice,,}" in

            q)
                return 1
                ;;

            r)
                launcher_rename_project
                ;;

            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] &&
                   (( choice < ${#LAUNCHER_PROJECT_NAMES[@]} )); then

                    LAUNCHER_SELECTED_NAME="${LAUNCHER_PROJECT_NAMES[$choice]}"
                    LAUNCHER_SELECTED_PATH="${LAUNCHER_PROJECT_PATHS[$choice]}"

                    return 0
                fi

                devstart_warning "Invalid selection."
                sleep 1
                ;;

        esac

    done
}

# ------------------------------------------------------------
# Launch
# ------------------------------------------------------------

launcher_launch_selected() {
    local project_name="$1"
    local project_path="$2"
    local manifest
    local workspace_name

    manifest="$(manifest_path "$project_path")"

    if [[ ! -f "$manifest" ]]; then
        devstart_die "Manifest missing: $manifest"
    fi

    workspace_name="$(
        workspace_assign \
            "$project_name" \
            "$project_path"
    )"

    if [[ -z "$workspace_name" ]]; then
        devstart_die "Failed to assign workspace."
    fi

    devstart_info "Workspace: $workspace_name"

    tmux_launch_project \
        "$workspace_name" \
        "$project_path"
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

launcher_run() {
    if registry_is_empty; then

        clear

        draw_line
        echo "🚀 devstartv2"
        draw_line

        echo
        echo "📭 Registry empty."
        echo
        echo "Initialize a project with:"
        echo
        echo "    devstartv2 --init"
        echo

        return 1
    fi

    ui_workspace_menu
}
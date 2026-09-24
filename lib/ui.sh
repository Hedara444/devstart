#!/usr/bin/env bash

# ============================================================
# devstartv2 - User Interface
# ============================================================

ui_clear() {
    clear
}

ui_header() {
    local title="$1"

    echo
    echo "========================================"
    echo "  $title"
    echo "========================================"
    echo
}

ui_workspace_list() {
    workspace_load

    local count="${#WORKSPACE_NAMES_LOADED[@]}"
    local i

    if [[ "$count" -eq 0 ]]; then
        echo "No workspaces found."
        return 0
    fi

    for ((i = 0; i < count; i++)); do
        printf '%2d) %-12s %s\n' \
            "$((i + 1))" \
            "${WORKSPACE_NAMES_LOADED[$i]}" \
            "${WORKSPACE_PROJECT_NAMES[$i]}"
    done

    echo
}

ui_select_workspace() {
    local selection
    local index

    workspace_load

    if [[ "${#WORKSPACE_NAMES_LOADED[@]}" -eq 0 ]]; then
        return 1
    fi

    read -r -p "Select workspace: " selection

    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
        echo "Invalid selection."
        return 1
    fi

    index=$((selection - 1))

    if (( index < 0 || index >= ${#WORKSPACE_NAMES_LOADED[@]} )); then
        echo "Invalid selection."
        return 1
    fi

    UI_SELECTED_WORKSPACE_NAME="${WORKSPACE_NAMES_LOADED[$index]}"
    UI_SELECTED_PROJECT_NAME="${WORKSPACE_PROJECT_NAMES[$index]}"
    UI_SELECTED_PROJECT_PATH="${WORKSPACE_PROJECT_PATHS[$index]}"

    return 0
}

ui_remove_workspace() {
    local selection
    local index
    local project_name
    local project_path
    local workspace_name
    local confirmation

    workspace_load

    if [[ "${#WORKSPACE_NAMES_LOADED[@]}" -eq 0 ]]; then
        echo "No workspaces found."
        return 1
    fi

    echo
    read -r -p "Select workspace to remove: " selection

    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
        echo "Invalid selection."
        return 1
    fi

    index=$((selection - 1))

    if (( index < 0 || index >= ${#WORKSPACE_NAMES_LOADED[@]} )); then
        echo "Invalid selection."
        return 1
    fi

    workspace_name="${WORKSPACE_NAMES_LOADED[$index]}"
    project_name="${WORKSPACE_PROJECT_NAMES[$index]}"
    project_path="${WORKSPACE_PROJECT_PATHS[$index]}"

    echo
    echo "You are about to unregister:"
    echo
    echo "  Workspace: $workspace_name"
    echo "  Project:   $project_name"
    echo "  Path:      $project_path"
    echo
    echo "The project directory and .project-env.txt will NOT be deleted."
    echo

    read -r -p "Remove this project from devstartv2? [y/N]: " confirmation

    case "${confirmation,,}" in
        y|yes)
            registry_remove_path "$project_path"
            workspace_remove_path "$project_path"

            echo
            echo "Project removed from devstartv2."
            ;;

        *)
            echo
            echo "Removal cancelled."
            ;;
    esac

    echo
    read -r -p "Press Enter to continue..." _
}

ui_workspace_menu() {
    while true; do
        ui_clear
        ui_header "devstartv2 - Workspaces"

        workspace_sync

        ui_workspace_list

        echo "[R] Remove Project | [Q] Quit"
        echo

        read -r -p "Select workspace or action: " selection

        case "${selection,,}" in

            q)
                return 0
                ;;

            r)
                ui_remove_workspace
                ;;

            *)
                if [[ "$selection" =~ ^[0-9]+$ ]]; then

                    local index
                    index=$((selection - 1))

                    workspace_load

                    if (( index < 0 || index >= ${#WORKSPACE_NAMES_LOADED[@]} )); then
                        echo
                        echo "Invalid selection."
                        read -r -p "Press Enter to continue..." _
                        continue
                    fi

                    UI_SELECTED_WORKSPACE_NAME="${WORKSPACE_NAMES_LOADED[$index]}"
                    UI_SELECTED_PROJECT_NAME="${WORKSPACE_PROJECT_NAMES[$index]}"
                    UI_SELECTED_PROJECT_PATH="${WORKSPACE_PROJECT_PATHS[$index]}"

                    echo
                    echo "Launching workspace: $UI_SELECTED_WORKSPACE_NAME"
                    echo

                    workspace_launch_selected \
                        "$UI_SELECTED_WORKSPACE_NAME" \
                        "$UI_SELECTED_PROJECT_PATH"

                    return $?
                fi

                echo
                echo "Invalid selection."
                read -r -p "Press Enter to continue..."
                ;;
        esac
    done
}
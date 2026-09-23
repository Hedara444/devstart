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

ui_workspace_menu() {
    while true; do
        ui_clear
        ui_header "devstartv2 - Workspaces"

        workspace_sync

        ui_workspace_list

        if ! ui_select_workspace; then
            echo
            read -r -p "Press Enter to continue..." _
            continue
        fi

        echo
        echo "Launching workspace: $UI_SELECTED_WORKSPACE_NAME"
        echo

        workspace_launch_selected \
            "$UI_SELECTED_WORKSPACE_NAME" \
            "$UI_SELECTED_PROJECT_PATH"

        return $?
    done
}
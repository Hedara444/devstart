#!/bin/bash

# ============================================================
# devstartv2 - Tmux
# ============================================================

# ------------------------------------------------------------
# Session Helpers
# ------------------------------------------------------------

tmux_session_exists() {
    local session_name="$1"

    tmux has-session -t "$session_name" 2>/dev/null
}

# ------------------------------------------------------------
# Create Session
# ------------------------------------------------------------

tmux_create_session() {
    local session_name="$1"

    if tmux_session_exists "$session_name"; then
        return 0
    fi

    tmux new-session \
        -d \
        -s "$session_name" \
        -n "Workspace"
}

# ------------------------------------------------------------
# Get Current Pane
# ------------------------------------------------------------

tmux_current_pane() {
    local session_name="$1"

    tmux display-message \
        -p \
        -t "$session_name" \
        '#{pane_id}'
}

# ------------------------------------------------------------
# Create Pane
# ------------------------------------------------------------

tmux_create_pane() {
    local session_name="$1"

    tmux split-window \
        -t "$session_name"
}

# ------------------------------------------------------------
# Run Command In Pane
# ------------------------------------------------------------

tmux_run_in_pane() {
    local target="$1"
    local working_dir="$2"
    local command="$3"

    # Navigate to the working directory.
    tmux send-keys \
        -t "$target" \
        "cd -- \"$working_dir\"" \
        C-m

    # Execute configured command if one exists.
    if [[ -n "$command" ]]; then
        tmux send-keys \
            -t "$target" \
            "$command" \
            C-m
    fi
}

# ------------------------------------------------------------
# Set Pane Title
# ------------------------------------------------------------

tmux_set_pane_title() {
    local target="$1"
    local title="$2"

    tmux select-pane \
        -t "$target" \
        -T "$title"
}

# ------------------------------------------------------------
# Apply Layout
# ------------------------------------------------------------

tmux_apply_layout() {
    local session_name="$1"
    local layout="${2:-tiled}"

    tmux select-layout \
        -t "$session_name" \
        "$layout"
}

# ------------------------------------------------------------
# Attach Session
# ------------------------------------------------------------

tmux_attach() {
    local session_name="$1"

    tmux attach-session \
        -t "$session_name"
}

# ------------------------------------------------------------
# Kill Session
# ------------------------------------------------------------

tmux_kill_session() {
    local session_name="$1"

    if tmux_session_exists "$session_name"; then
        tmux kill-session \
            -t "$session_name"
    fi
}

# ------------------------------------------------------------
# Launch Project
# ------------------------------------------------------------

tmux_launch_project() {
    local session_name="$1"
    local project_dir="$2"

    manifest_load "$project_dir"

    local pane_index
    local pane_value
    local pane_path
    local pane_command
    local full_path

    # --------------------------------------------------------
    # Existing session
    # --------------------------------------------------------

    if tmux_session_exists "$session_name"; then
        devstart_info "Tmux session already exists: $session_name"
        tmux_attach "$session_name"
        return 0
    fi

    # --------------------------------------------------------
    # Create session
    # --------------------------------------------------------

    devstart_info "Creating tmux session: $session_name"

    tmux_create_session "$session_name"

    # --------------------------------------------------------
    # First pane
    # --------------------------------------------------------

    local first_pane

    first_pane="$(tmux_current_pane "$session_name")"

    # --------------------------------------------------------
    # Process configured panes
    # --------------------------------------------------------

    local first_configured_pane=true

    for pane_index in "${MANIFEST_PANE_INDICES[@]}"; do

        pane_value="${MANIFEST_PANES[$pane_index]}"

        [[ -z "$pane_value" ]] && continue

        manifest_parse_pane "$pane_index"

        pane_path="$MANIFEST_PANE_PATH"
        pane_command="$MANIFEST_PANE_COMMAND"

        full_path="$project_dir/$pane_path"

        if [[ ! -d "$full_path" ]]; then
            devstart_warning "Directory does not exist: $full_path"
            continue
        fi

        # ----------------------------------------------------
        # First configured pane uses the original pane.
        # ----------------------------------------------------

        if [[ "$first_configured_pane" == true ]]; then

            tmux_run_in_pane \
                "$first_pane" \
                "$full_path" \
                "$pane_command"

            tmux_set_pane_title \
                "$first_pane" \
                "$pane_path"

            first_configured_pane=false

        else

            # ------------------------------------------------
            # Additional panes
            # ------------------------------------------------

            tmux_create_pane "$session_name"

            local new_pane

            new_pane="$(tmux_current_pane "$session_name")"

            tmux_run_in_pane \
                "$new_pane" \
                "$full_path" \
                "$pane_command"

            tmux_set_pane_title \
                "$new_pane" \
                "$pane_path"

        fi

    done

    # --------------------------------------------------------
    # Apply default layout
    # --------------------------------------------------------

    tmux_apply_layout \
        "$session_name" \
        "$DEVSTART_DEFAULT_LAYOUT"

    # --------------------------------------------------------
    # Attach
    # --------------------------------------------------------

    tmux_attach "$session_name"
}
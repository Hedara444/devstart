#!/bin/bash

# ============================================================
# devstartv2 - Core
# ============================================================

# Resolve the directory containing the main devstartv2 executable.
DEVSTART_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

DEVSTART_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/devstart"

DEVSTART_REGISTRY="${DEVSTART_CONFIG_DIR}/registry.txt"
DEVSTART_CONFIG_FILE="$DEVSTART_CONFIG_DIR/config.env"
DEVSTART_WORKSPACES="$DEVSTART_CONFIG_DIR/workspaces.txt"

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------

DEVSTART_VERSION="2.0.0"

# ------------------------------------------------------------
# Initialization
# ------------------------------------------------------------

devstart_init_config() {
    mkdir -p "$DEVSTART_CONFIG_DIR"

    if [[ ! -f "$DEVSTART_REGISTRY" ]]; then
        touch "$DEVSTART_REGISTRY"
    fi
}

# ------------------------------------------------------------
# Utility functions
# ------------------------------------------------------------

devstart_die() {
    echo "❌ $*" >&2
    exit 1
}

devstart_info() {
    echo "ℹ️  $*"
}

devstart_success() {
    echo "✅ $*"
}

devstart_warning() {
    echo "⚠️  $*"
}

devstart_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

devstart_require_command() {
    local command_name="$1"

    if ! devstart_command_exists "$command_name"; then
        devstart_die "Required command not found: $command_name"
    fi
}

# ------------------------------------------------------------
# Project / Session Helpers
# ------------------------------------------------------------

devstart_sanitize_name() {
    local name="$1"

    # Keep only characters that are safe for tmux session names
    name="$(printf '%s' "$name" | tr -cd '[:alnum:]_-')"

    printf '%s\n' "$name"
}

draw_line() {
    printf '%s\n' \
        '--------------------------------------------------------------------------------'
}
#!/usr/bin/env bash

# ============================================================
# devstartv2 - Global Configuration
# ============================================================

config_init() {
    mkdir -p "$DEVSTART_CONFIG_DIR"

    if [[ ! -f "$DEVSTART_CONFIG_FILE" ]]; then
        cat > "$DEVSTART_CONFIG_FILE" <<'EOF'
# devstartv2 global configuration

DEVSTART_COMMAND="devstartv2"
DEVSTART_SESSION_PREFIX="devstart"
DEVSTART_DEFAULT_LAYOUT="tiled"
EOF
    fi
}


config_load() {
    config_init

    # Load user configuration.
    #
    # shellcheck disable=SC1090
    source "$DEVSTART_CONFIG_FILE"

    # Apply defaults if values are missing.
    DEVSTART_COMMAND="${DEVSTART_COMMAND:-devstartv2}"
    DEVSTART_SESSION_PREFIX="${DEVSTART_SESSION_PREFIX:-devstart}"
    DEVSTART_DEFAULT_LAYOUT="${DEVSTART_DEFAULT_LAYOUT:-tiled}"
}
#!/usr/bin/env bash

# ============================================================
# devstartv2 - Workspace Management
# ============================================================

WORKSPACE_NAMES=(
    "Bob"
    "Jeff"
    "Alex"
    "Mike"
    "Sam"
    "Jack"
    "Tom"
    "Ben"
    "Dan"
    "Max"
    "Leo"
    "Luke"
    "Nick"
    "Ryan"
    "Adam"
    "Chris"
    "Dave"
    "Matt"
    "John"
    "Mark"
    "Paul"
    "Steve"
    "Joe"
    "Kevin"
)

  workspace_init() {
      mkdir -p "$DEVSTART_CONFIG_DIR"

      if [[ ! -f "$DEVSTART_WORKSPACES" ]]; then
          touch "$DEVSTART_WORKSPACES"
      fi
  }

  workspace_load() {
      workspace_init

      WORKSPACE_NAMES_LOADED=()
      WORKSPACE_PROJECT_NAMES=()
      WORKSPACE_PROJECT_PATHS=()

      local workspace_name
      local project_name
      local project_path

      while IFS='|' read -r workspace_name project_name project_path; do
          [[ -z "$workspace_name" ]] && continue
          [[ -z "$project_name" ]] && continue
          [[ -z "$project_path" ]] && continue

          WORKSPACE_NAMES_LOADED+=("$workspace_name")
          WORKSPACE_PROJECT_NAMES+=("$project_name")
          WORKSPACE_PROJECT_PATHS+=("$project_path")
      done < "$DEVSTART_WORKSPACES"
  }

  workspace_name_exists() {
      local workspace_name="$1"
      local existing_name

      workspace_init

      while IFS='|' read -r existing_name _; do
          [[ "$existing_name" == "$workspace_name" ]] && return 0
      done < "$DEVSTART_WORKSPACES"

      return 1
  }

  workspace_find_by_path() {
      local project_path="$1"

      local workspace_name
      local project_name
      local registered_path

      workspace_init

      while IFS='|' read -r workspace_name project_name registered_path; do
          [[ -z "$workspace_name" ]] && continue
          [[ -z "$registered_path" ]] && continue

          if [[ "$registered_path" == "$project_path" ]]; then
              echo "$workspace_name"
              return 0
          fi
      done < "$DEVSTART_WORKSPACES"

      return 1
  }

  workspace_assign() {
      local project_name="$1"
      local project_path="$2"

      local workspace_name
      local name
      local suffix

      workspace_init

      # Check whether this project already has a workspace.
      while IFS='|' read -r name existing_project existing_path; do
          if [[ "$existing_path" == "$project_path" ]]; then
              echo "$name"
              return 0
          fi
      done < "$DEVSTART_WORKSPACES"

      # Try the predefined names first.
      for workspace_name in "${WORKSPACE_NAMES[@]}"; do
          if ! workspace_name_exists "$workspace_name"; then
              printf '%s|%s|%s\n' \
                  "$workspace_name" \
                  "$project_name" \
                  "$project_path" \
                  >> "$DEVSTART_WORKSPACES"

              echo "$workspace_name"
              return 0
          fi
      done

      # All predefined names are occupied.
      # Generate a unique fallback name using:
      #   friendly-name + 3 letters + 3 digits

# All predefined names are occupied.
# Generate a unique fallback name.

      while true; do
          local base_name
          local suffix

          base_name="${WORKSPACE_NAMES[$((RANDOM % ${#WORKSPACE_NAMES[@]}))]}"
          suffix="$(workspace_generate_suffix)"

          workspace_name="${base_name}-${suffix}"

          if ! workspace_name_exists "$workspace_name"; then
              printf '%s|%s|%s\n' \
                  "$workspace_name" \
                  "$project_name" \
                  "$project_path" \
                  >> "$DEVSTART_WORKSPACES"

              echo "$workspace_name"
              return 0
          fi
      done
  }

workspace_sync() {
    registry_load

    local i
    local project_name
    local project_path

    for ((i = 0; i < ${#REGISTRY_PROJECT_NAMES[@]}; i++)); do
        project_name="${REGISTRY_PROJECT_NAMES[$i]}"
        project_path="${REGISTRY_PROJECT_PATHS[$i]}"

        if ! workspace_find_by_path "$project_path" >/dev/null; then
            workspace_assign \
                "$project_name" \
                "$project_path" \
                >/dev/null
        fi
    done
}

  workspace_generate_suffix() {
      local letters
      local numbers

      letters="$(
          tr -dc 'a-z' < /dev/urandom |
          head -c 3
      )"

      numbers="$(
          tr -dc '0-9' < /dev/urandom |
          head -c 3
      )"

      printf '%s%s\n' "$letters" "$numbers"
  }

  workspace_launch_selected() {
      local workspace_name="$1"
      local project_path="$2"

      if [[ -z "$workspace_name" ]]; then
          devstart_warning "Workspace name is empty."
          return 1
      fi

      if [[ -z "$project_path" ]]; then
          devstart_warning "Project path is empty."
          return 1
      fi

      tmux_launch_project \
          "$workspace_name" \
          "$project_path"
  }

#!/bin/bash

# ============================================================
# devstartv2 - Update Checker
# ============================================================

update_check() {
    local repo_dir="$1"
    local upstream
    local counts
    local ahead
    local behind
    local choice

    # --------------------------------------------------------
    # Verify Git repository
    # --------------------------------------------------------

    if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Update check skipped: installation is not a Git repository."
        return 0
    fi

    # --------------------------------------------------------
    # Find upstream branch
    # --------------------------------------------------------

    upstream="$(git -C "$repo_dir" rev-parse \
        --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || {
        echo "Update check skipped: no upstream branch is configured."
        return 0
    }

    # --------------------------------------------------------
    # Protect local tracked changes
    # --------------------------------------------------------

    if ! git -C "$repo_dir" diff --quiet HEAD --; then
        echo
        echo "Local tracked changes detected."
        echo "Automatic updates are disabled to protect your work."
        echo
        read -r -p "Continue without updating? [Y/n]: " choice

        case "${choice,,}" in
            n|no)
                return 1
                ;;
            *)
                return 0
                ;;
        esac
    fi

    # --------------------------------------------------------
    # Fetch remote changes
    # --------------------------------------------------------

    echo "Checking for devstartv2 updates..."

    if ! git -C "$repo_dir" fetch --quiet; then
        echo
        echo "Could not reach GitHub or fetch updates."
        read -r -p "Continue without updating? [Y/n]: " choice

        case "${choice,,}" in
            n|no)
                return 1
                ;;
            *)
                return 0
                ;;
        esac
    fi

    # --------------------------------------------------------
    # Compare local and remote commits
    # --------------------------------------------------------

    counts="$(git -C "$repo_dir" rev-list \
        --left-right --count "HEAD...$upstream")" || {
        echo "Could not compare local and remote versions."
        return 0
    }

    read -r ahead behind <<< "$counts"

    # Already up to date
    if (( behind == 0 )); then
        echo "devstartv2 is up to date."
        return 0
    fi

    # Local and remote branches have diverged
    if (( ahead > 0 )); then
        echo
        echo "Local and remote branches have diverged."
        echo "Please resolve this manually before updating."
        return 0
    fi

    # --------------------------------------------------------
    # Update available
    # --------------------------------------------------------

    echo
    echo "An update is available."
    echo "Local commits ahead:  $ahead"
    echo "Remote commits ahead: $behind"
    echo
    echo "[U] Update now"
    echo "[R] Resume without updating"
    echo "[Q] Quit"
    echo

    read -r -p "Choose an option: " choice

    case "${choice,,}" in
        u)
            echo
            echo "Applying update..."

            if git -C "$repo_dir" merge --ff-only "$upstream"; then
                echo
                echo "Update completed successfully."
                return 2
            else
                echo
                echo "Update failed. No forced changes were made."
                return 0
            fi
            ;;

        r)
            echo "Resuming without updating."
            return 0
            ;;

        q)
            return 1
            ;;

        *)
            echo "Invalid choice. Resuming without updating."
            return 0
            ;;
    esac
}
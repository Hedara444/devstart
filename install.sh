#!/bin/bash

# ============================================================
# devstartv2 - Installer
# ============================================================

set -o pipefail

# ------------------------------------------------------------
# Locate devstart repository
# ------------------------------------------------------------

INSTALLER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------
# Verify required commands
# ------------------------------------------------------------

if ! command -v git >/dev/null 2>&1; then
    echo "Error: Git is required to install devstartv2."
    exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
    echo "Error: tmux is required to run devstartv2."
    echo "Please install tmux and run this installer again."
    exit 1
fi

# ------------------------------------------------------------
# Verify repository structure
# ------------------------------------------------------------

if [[ ! -f "$INSTALLER_ROOT/bin/devstartv2" ]]; then
    echo "Error: bin/devstartv2 was not found."
    echo "Please run this script from a valid devstart repository."
    exit 1
fi

if [[ ! -f "$INSTALLER_ROOT/update.sh" ]]; then
    echo "Error: update.sh was not found."
    echo "Please ensure the repository is complete."
    exit 1
fi

# ------------------------------------------------------------
# Verify Git remote
# ------------------------------------------------------------

EXPECTED_REMOTE="${DEVSTART_REMOTE:-https://github.com/Hedara444/devstart.git}"
CURRENT_REMOTE="$(git -C "$INSTALLER_ROOT" remote get-url origin 2>/dev/null || true)"

if [[ -z "$CURRENT_REMOTE" ]]; then
    echo "Error: Git remote 'origin' is not configured."
    exit 1
fi

if [[ "$CURRENT_REMOTE" != "$EXPECTED_REMOTE" ]]; then
    echo "Error: Unexpected Git remote."
    echo "Expected: $EXPECTED_REMOTE"
    echo "Found:    $CURRENT_REMOTE"
    exit 1
fi

CURRENT_BRANCH="$(git -C "$INSTALLER_ROOT" branch --show-current)"

if [[ "$CURRENT_BRANCH" != "master" ]]; then
    echo "Error: devstartv2 must be installed from the master branch."
    echo "Current branch: $CURRENT_BRANCH"
    exit 1
fi

echo "Git repository verified."
echo "Remote: $CURRENT_REMOTE"
echo "Branch: $CURRENT_BRANCH"

# ------------------------------------------------------------
# Check remote status
# ------------------------------------------------------------

echo "Checking GitHub for updates..."

if ! git -C "$INSTALLER_ROOT" fetch --quiet origin master; then
    echo
    echo "Error: Could not reach GitHub."
    echo "The local repository was not modified."
    echo "Please check your network connection and run the installer again."
    exit 1
fi

COUNTS="$(git -C "$INSTALLER_ROOT" rev-list \
    --left-right --count HEAD...origin/master)" || {
    echo "Error: Could not compare local and remote versions."
    exit 1
}

read -r AHEAD BEHIND <<< "$COUNTS"

if (( AHEAD > 0 && BEHIND > 0 )); then
    echo
    echo "Error: Local and remote branches have diverged."
    echo "Local commits ahead:  $AHEAD"
    echo "Remote commits ahead: $BEHIND"
    echo
    echo "Please resolve the Git divergence manually before installing."
    exit 1
fi

if (( AHEAD > 0 )); then
    echo
    echo "Error: Local commits are ahead of GitHub."
    echo "Local commits ahead: $AHEAD"
    echo
    echo "Please push or resolve the local commits before installing."
    exit 1
fi

if (( BEHIND > 0 )); then
    echo
    echo "The repository is behind GitHub."
    echo "Remote commits available: $BEHIND"
    echo

    if ! git -C "$INSTALLER_ROOT" diff --quiet HEAD --; then
        echo "Error: Local tracked changes were detected."
        echo "The installer will not modify a working tree with local changes."
        echo
        echo "Please commit or stash your changes, then run the installer again."
        exit 1
    fi

    read -r -p "Update the repository before installing? [Y/n]: " UPDATE_CHOICE

    case "${UPDATE_CHOICE,,}" in
        n|no)
            echo
            echo "Installation cancelled."
            echo "The repository was not changed."
            exit 0
            ;;

        *)
            echo
            echo "Updating repository..."

            if ! git -C "$INSTALLER_ROOT" merge --ff-only origin/master; then
                echo
                echo "Error: Repository update failed."
                echo "No forced changes were made."
                exit 1
            fi

            echo
            echo "Repository updated successfully."
            ;;
    esac
else
    echo "Repository is up to date."
fi


# ------------------------------------------------------------
# Install devstartv2
# ------------------------------------------------------------

INSTALL_BIN="$HOME/.local/bin/devstartv2"

echo
echo "Installing devstartv2..."

mkdir -p "$HOME/.local/bin" || {
    echo "Error: Could not create $HOME/.local/bin."
    exit 1
}

ln -sfn "$INSTALLER_ROOT/bin/devstartv2" "$INSTALL_BIN" || {
    echo "Error: Could not create installation symlink."
    exit 1
}

chmod +x "$INSTALLER_ROOT/bin/devstartv2"

echo "Installation completed."
echo "Command: $INSTALL_BIN"
echo "Target:  $INSTALLER_ROOT/bin/devstartv2"

# ------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------

if [[ "$(readlink -f "$INSTALL_BIN")" != "$INSTALLER_ROOT/bin/devstartv2" ]]; then
    echo "Error: Installation verification failed."
    exit 1
fi

echo "Installation verified successfully."

# ------------------------------------------------------------
# Check installed command
# ------------------------------------------------------------

if [[ -x "$INSTALL_BIN" ]]; then
    echo
    echo "devstartv2 is ready."
    "$INSTALL_BIN" --version
fi



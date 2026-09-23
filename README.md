You're right — I only described it instead of actually giving you the Markdown content. Here it is in full.

Save this manually as:

`DEVSTARTV2_PROGRESS.md`

# devstartv2 — Project Progress & Architecture

## 1. Project Overview

`devstartv2` is a Linux-native terminal workflow tool designed to make launching and managing development projects from the terminal simple and repeatable.

The intended workflow is:

```text
devstartv2
    ↓
Workspace navigation
    ↓
Select a workspace
    ↓
Resolve workspace → project
    ↓
Launch / attach tmux session
    ↓
Project panes start in their configured directories
    ↓
Optional commands run inside each pane
```

The project evolved from a v1 Bash script into a modular Bash application.

The main design principles are:

* Linux-native.
* Bash/shell based.
* No Python dependency.
* No `fzf` dependency.
* No external TUI framework.
* `tmux` is the runtime engine.
* Configuration is stored in simple text files.
* Project configuration remains inside `.project-env.txt`.
* Global project registration is handled separately from project manifests.
* Workspace identity is handled separately from both.

---

# 2. Current Repository

Source repository:

```text
/home/hedara/E/Projects/Personal-Projects/devstart
```

Main structure:

```text
devstart/
├── bin/
│   └── devstartv2
│
└── lib/
    ├── core.sh
    ├── config.sh
    ├── registry.sh
    ├── manifest.sh
    ├── initializer.sh
    ├── launcher.sh
    ├── tmux.sh
    ├── workspace.sh
    └── ui.sh
```

The application is deliberately split into modules so that each part has one primary responsibility.

---

# 3. Main Entry Point

The main executable is:

```text
bin/devstartv2
```

It acts as the application orchestrator.

It loads the project root and then sources the required modules:

```bash
source "$DEVSTART_ROOT/lib/core.sh"
source "$DEVSTART_ROOT/lib/config.sh"
source "$DEVSTART_ROOT/lib/workspace.sh"
source "$DEVSTART_ROOT/lib/registry.sh"
source "$DEVSTART_ROOT/lib/manifest.sh"
source "$DEVSTART_ROOT/lib/ui.sh"
source "$DEVSTART_ROOT/lib/tmux.sh"
source "$DEVSTART_ROOT/lib/launcher.sh"
source "$DEVSTART_ROOT/lib/initializer.sh"
```

The configuration is initialized through:

```bash
config_load
```

Supported top-level operations currently include:

```text
devstartv2
devstartv2 --help
devstartv2 --version
devstartv2 --init
```

Current version:

```text
devstartv2 2.0.0
```

---

# 4. Important Global Paths

`core.sh` defines the main application paths.

Current project root:

```bash
DEVSTART_ROOT="/home/hedara/E/Projects/Personal-Projects/devstart"
```

Global configuration directory:

```bash
DEVSTART_CONFIG_DIR="$HOME/.config/devstart"
```

Project registry:

```bash
DEVSTART_REGISTRY="$DEVSTART_CONFIG_DIR/registry.txt"
```

Global configuration:

```bash
DEVSTART_CONFIG_FILE="$DEVSTART_CONFIG_DIR/config.env"
```

Workspace registry:

```bash
DEVSTART_WORKSPACES="$DEVSTART_CONFIG_DIR/workspaces.txt"
```

Therefore the persistent application state currently lives under:

```text
~/.config/devstart/
├── config.env
├── registry.txt
└── workspaces.txt
```

---

# 5. Global Installation

The executable is globally available through:

```text
~/.local/bin/devstartv2
```

The installation uses a symbolic link:

```text
~/.local/bin/devstartv2
    ↓
/home/hedara/E/Projects/Personal-Projects/devstart/bin/devstartv2
```

The user's `PATH` already contains:

```text
~/.local/bin
```

Therefore the command works from anywhere:

```bash
devstartv2
```

The entrypoint had to account for symbolic-link execution.

The final root detection uses:

```bash
DEVSTART_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
DEVSTART_ROOT="$(cd "$(dirname "$DEVSTART_SCRIPT")/.." && pwd)"
```

This is important because:

```bash
dirname "${BASH_SOURCE[0]}"
```

would resolve to:

```text
~/.local/bin
```

when the application is started through the symlink.

Using `readlink -f` resolves the actual script location first.

---

# 6. Global Configuration

Global configuration is handled by:

```text
lib/config.sh
```

The configuration file is:

```text
~/.config/devstart/config.env
```

Current contents:

```bash
# devstartv2 global configuration

DEVSTART_COMMAND="devstartv2"
DEVSTART_SESSION_PREFIX="devstart"
DEVSTART_DEFAULT_LAYOUT="tiled"
```

The configuration module provides:

```bash
config_init()
config_load()
```

`config_init()` creates the configuration directory and configuration file if they don't exist.

`config_load()` sources the configuration and applies defaults when necessary.

For example:

```bash
DEVSTART_DEFAULT_LAYOUT="${DEVSTART_DEFAULT_LAYOUT:-tiled}"
```

The tmux layer therefore does not need to hardcode the layout.

Current layout:

```text
tiled
```

The configuration was tested by temporarily changing the layout to:

```text
main-horizontal
```

and confirming that the configuration was actually being loaded.

It was then restored to:

```text
tiled
```

---

# 7. Project Registry

The project registry is persistent application memory.

File:

```text
~/.config/devstart/registry.txt
```

Format:

```text
project-name|absolute/path
```

Example:

```text
devstart-test|/home/hedara/devstart-test
devstart-final-test|/home/hedara/devstart-final-test
```

The registry is responsible for remembering:

```text
Project name
    +
Project filesystem location
```

The registry module owns all registry CRUD operations.

Other modules should not directly edit `registry.txt`.

Important functions include:

```bash
registry_add()
registry_count()
registry_find_project()
registry_init()
registry_is_empty()
registry_load()
registry_remove_path()
registry_rename()
```

`registry_load()` loads project names and paths into arrays:

```bash
REGISTRY_PROJECT_NAMES
REGISTRY_PROJECT_PATHS
```

This separation keeps project registration independent from the workspace system.

---

# 8. Project Manifest

Each registered project contains:

```text
.project-env.txt
```

This file describes the project's configured tmux panes.

The format is intentionally unchanged.

Example:

```text
id="enp8kj"
id="ubf0ck"
id="frhwdx"
id="sgpb6f"
PROJECT_NAME="devstart-final-test"

PANE_1="frontend | echo Frontend-running; sleep 1000"
PANE_2="worker | "
PANE_3="backend | echo Backend-running; sleep 1000"
```

The format is considered established and should not be redesigned casually.

The manifest module is:

```text
lib/manifest.sh
```

It handles reading and parsing this file.

Important functions include:

```bash
manifest_path()
manifest_load()
manifest_parse_pane()
```

`manifest_load()` reads:

```text
PROJECT_NAME
PANE_1
PANE_2
PANE_3
...
```

into internal Bash structures.

Pane information is stored in:

```bash
MANIFEST_PANES
MANIFEST_PANE_INDICES
```

The pane value:

```text
frontend | echo Frontend-running; sleep 1000
```

is interpreted as:

```text
path:
frontend

command:
echo Frontend-running; sleep 1000
```

An empty command:

```text
worker |
```

represents an idle pane.

---

# 9. Project Initializer

The initializer is responsible for:

```text
devstartv2 --init
```

Its implementation lives in:

```text
lib/initializer.sh
```

The initializer currently supports:

```bash
initializer_discover_directories()
initializer_load_existing()
initializer_draw()
initializer_configure_directory()
initializer_confirm()
initializer_generate_manifest()
initializer_save()
initializer_run()
```

The initializer starts from a project root and discovers top-level directories.

The user can configure discovered directories as:

```text
(a) Idle
(b) Active
(r) Remove
```

For an active directory, the user provides a boot command.

Example:

```text
frontend
    ↓
Active
    ↓
npm run dev
```

For an idle directory:

```text
worker
    ↓
Idle
```

The initializer preserves existing project configuration where appropriate.

Existing configured panes appear first.

Newly discovered directories are then added.

New directories are ordered alphabetically.

The initializer also preserves:

```text
MANIFEST_PROJECT_NAME
```

when modifying an existing manifest instead of unnecessarily prompting for a new project name.

---

# 10. Tmux Layer

Tmux functionality is isolated in:

```text
lib/tmux.sh
```

The launcher does not need to know the details of tmux pane creation.

The current project launch function is:

```bash
tmux_launch_project()
```

Its responsibilities are:

1. Load the project manifest.
2. Determine whether the requested tmux session already exists.
3. Attach to an existing session if necessary.
4. Otherwise create a new session.
5. Configure panes.
6. Set pane working directories.
7. Run configured commands.
8. Set pane titles.
9. Apply the configured tmux layout.
10. Attach to the session.

The layout currently uses:

```bash
tmux_apply_layout \
    "$session_name" \
    "$DEVSTART_DEFAULT_LAYOUT"
```

The default is:

```text
tiled
```

The current layout is intentionally accepted for now.

No layout redesign is currently required.

---

# 11. Project → Tmux Relationship

Originally, the project name was being used as the tmux session name.

That approach worked, but it mixed two different concepts.

The architecture was therefore changed to introduce a separate workspace identity.

The new conceptual model is:

```text
Project
    =
filesystem identity

Workspace
    =
runtime identity

Tmux session
    =
workspace implementation
```

This distinction is important.

A project may have a human-friendly runtime identity without changing the project's filesystem name or its `.project-env.txt`.

---

# 12. Workspace System

Workspace management lives in:

```text
lib/workspace.sh
```

Workspace state is stored in:

```text
~/.config/devstart/workspaces.txt
```

Format:

```text
workspace-name|project-name|absolute-project-path
```

Example:

```text
Bob|devstart-test|/home/hedara/devstart-test
Jeff|devstart-final-test|/home/hedara/devstart-final-test
```

The workspace registry is separate from:

```text
registry.txt
```

and separate from:

```text
.project-env.txt
```

This means workspace identity does not pollute project configuration.

---

# 13. Friendly Workspace Names

The workspace system has a predefined list of 24 friendly names:

```text
Bob
Jeff
Alex
Mike
Sam
Jack
Tom
Ben
Dan
Max
Leo
Luke
Nick
Ryan
Adam
Chris
Dave
Matt
John
Mark
Paul
Steve
Joe
Kevin
```

These names are tried first.

The goal is to make tmux session names easier to remember and navigate.

For example:

```text
Bob
Jeff
Alex
```

are easier to refer to than long project names or generated identifiers.

---

# 14. Workspace Assignment

The main assignment function is:

```bash
workspace_assign()
```

Its behavior is:

```text
Project already has workspace?
        ↓
       YES
        ↓
Return existing workspace
```

Otherwise:

```text
Find first available friendly name
        ↓
Assign it
        ↓
Persist it
        ↓
Return name
```

This guarantees that repeatedly launching the same project does not create a new workspace.

Example:

```bash
workspace_assign \
    "devstart-test" \
    "/home/hedara/devstart-test"
```

returns:

```text
Bob
```

Calling it again for the same project/path returns:

```text
Bob
```

rather than allocating another name.

---

# 15. Workspace Name Uniqueness

The function:

```bash
workspace_name_exists()
```

checks whether a workspace name is already present in:

```text
~/.config/devstart/workspaces.txt
```

This prevents duplicate workspace names.

The normal assignment process therefore guarantees:

```text
One workspace name
    ↓
One project/path mapping
```

---

# 16. Workspace Fallback Names

After all 24 predefined names are occupied, the system generates a fallback.

The suffix generator is:

```bash
workspace_generate_suffix()
```

It generates:

```text
3 lowercase letters
+
3 digits
```

Examples tested successfully:

```text
weu223
aop375
eij630
pze679
```

When all friendly names are occupied, the fallback format becomes:

```text
<BaseName>-<suffix>
```

Examples:

```text
Bob-weu223
Alex-aop375
Steve-pze679
```

The base name is selected from the predefined friendly-name list.

The fallback name is checked with:

```bash
workspace_name_exists()
```

before it is persisted.

Therefore the fallback also remains unique.

---

# 17. Workspace Lookup

The function:

```bash
workspace_find_by_path()
```

was added so that other parts of the application can ask:

```text
Which workspace belongs to this project path?
```

Example:

```bash
workspace_find_by_path "/home/hedara/devstart-test"
```

returns:

```text
Bob
```

If the path is not registered as a workspace, the function returns failure without producing a workspace name.

This will become useful for future workspace navigation and status functionality.

---

# 18. Workspace Loading

The function:

```bash
workspace_load()
```

loads persistent workspace information into arrays:

```bash
WORKSPACE_NAMES_LOADED
WORKSPACE_PROJECT_NAMES
WORKSPACE_PROJECT_PATHS
```

For example:

```text
WORKSPACE_NAMES_LOADED
    ├── Bob
    └── Jeff

WORKSPACE_PROJECT_NAMES
    ├── devstart-test
    └── devstart-final-test

WORKSPACE_PROJECT_PATHS
    ├── /home/hedara/devstart-test
    └── /home/hedara/devstart-final-test
```

The indexes correspond.

For example:

```text
index 0:
    Bob
    devstart-test
    /home/hedara/devstart-test
```

and:

```text
index 1:
    Jeff
    devstart-final-test
    /home/hedara/devstart-final-test
```

---

# 19. UI Layer

The UI module is:

```text
lib/ui.sh
```

It was intentionally left empty until the workspace architecture was ready.

The first UI primitives have now been implemented.

Current functions include:

```bash
ui_clear()
ui_header()
ui_workspace_list()
ui_select_workspace()
ui_workspace_menu()
```

The UI is deliberately simple and Bash-native.

There is no:

```text
fzf
Python
external TUI library
```

---

# 20. UI Header

The basic header function is:

```bash
ui_header()
```

Example:

```text
========================================
  devstartv2
========================================
```

This provides the basic visual foundation for the terminal interface.

---

# 21. Workspace List

The function:

```bash
ui_workspace_list()
```

loads workspace data and displays it.

Example:

```text
========================================
  Workspaces
========================================

 1) Bob          devstart-test
 2) Jeff         devstart-final-test
```

The UI intentionally separates display from selection.

---

# 22. Workspace Selection

The function:

```bash
ui_select_workspace()
```

accepts a numeric selection.

For example:

```text
Select workspace: 1
```

The selected information is stored in:

```bash
UI_SELECTED_WORKSPACE_NAME
UI_SELECTED_PROJECT_NAME
UI_SELECTED_PROJECT_PATH
```

For example:

```text
UI_SELECTED_WORKSPACE_NAME="Bob"
UI_SELECTED_PROJECT_NAME="devstart-test"
UI_SELECTED_PROJECT_PATH="/home/hedara/devstart-test"
```

Invalid input is rejected.

This creates a clean separation between:

```text
UI selection
```

and:

```text
workspace launching
```

---

# 23. Workspace Menu

The main workspace menu is:

```bash
ui_workspace_menu()
```

Its current flow is:

```text
Clear screen
    ↓
Draw header
    ↓
Display workspaces
    ↓
Ask for selection
    ↓
Resolve selected workspace
    ↓
Launch selected workspace
```

The current menu is intentionally minimal.

More sophisticated navigation and actions can be added later.

---

# 24. Workspace Launch

The function:

```bash
workspace_launch_selected()
```

connects workspace selection to the existing tmux layer.

It receives:

```text
workspace name
project path
```

and calls:

```bash
tmux_launch_project \
    "$workspace_name" \
    "$project_path"
```

This means the tmux session is now identified by the workspace name.

Example:

```text
Workspace:
    Bob

Project:
    /home/hedara/devstart-test

Tmux session:
    Bob
```

---

# 25. Launcher Layer

The launcher module is:

```text
lib/launcher.sh
```

The previous project-selection flow has now been replaced at the top level by the workspace menu.

Current conceptual `launcher_run()` behavior:

```text
Is registry empty?
    ↓
   YES → Show initialization instructions
    ↓
   NO
    ↓
ui_workspace_menu()
```

The empty-registry behavior remains:

```text
📭 Registry empty.

Initialize a project with:

    devstartv2 --init
```

The normal path now enters the workspace UI directly.

---

# 26. Current Complete Runtime Flow

The application now works approximately like this:

```text
User runs:

    devstartv2
        │
        ▼
bin/devstartv2
        │
        ├── core.sh
        ├── config.sh
        ├── workspace.sh
        ├── registry.sh
        ├── manifest.sh
        ├── ui.sh
        ├── tmux.sh
        ├── launcher.sh
        └── initializer.sh
        │
        ▼
config_load()
        │
        ▼
launcher_run()
        │
        ▼
Check project registry
        │
        ▼
ui_workspace_menu()
        │
        ▼
workspace_load()
        │
        ▼
Display workspaces
        │
        ▼
User selects workspace
        │
        ▼
UI_SELECTED_WORKSPACE_*
        │
        ▼
workspace_launch_selected()
        │
        ▼
tmux_launch_project()
        │
        ▼
manifest_load()
        │
        ▼
Create / attach tmux session
        │
        ▼
Configure project panes
        │
        ▼
Apply configured tmux layout
        │
        ▼
Attach to workspace
```

---

# 27. Current Real Workspace State

At the point where development stopped, the real workspace registry was restored and confirmed.

Expected current entries are:

```text
Bob|devstart-test|/home/hedara/devstart-test
Jeff|devstart-final-test|/home/hedara/devstart-final-test
```

Temporary test workspace entries were removed.

---

# 28. Testing Completed

The following areas have been tested successfully.

## Version

```bash
./bin/devstartv2 --version
```

Expected:

```text
devstartv2 2.0.0
```

Also confirmed globally through:

```bash
devstartv2 --version
```

---

## Global invocation

Confirmed that:

```bash
cd ~
devstartv2
```

works.

The symbolic-link installation correctly resolves the actual project root.

---

## Global configuration

Confirmed that changing:

```text
DEVSTART_DEFAULT_LAYOUT
```

in:

```text
~/.config/devstart/config.env
```

changes the value used by the application.

The setting was then restored to:

```text
tiled
```

---

## Workspace assignment

Confirmed:

```text
devstart-test → Bob
```

Repeated assignment returns:

```text
Bob
```

instead of creating another workspace.

---

## Multiple workspace assignment

Confirmed that another project receives another available name.

Example:

```text
devstart-test → Bob
another-project → Jeff
```

---

## Workspace suffix generation

Confirmed the generator produces:

```text
3 lowercase letters + 3 digits
```

Examples:

```text
weu223
aop375
eij630
pze679
```

---

## Workspace fallback

All 24 predefined names were temporarily occupied.

The fallback mechanism successfully produced names matching:

```text
<BaseName>-<3 lowercase letters><3 digits>
```

The temporary test data was subsequently restored.

---

## Workspace lookup

Confirmed:

```bash
workspace_find_by_path "/home/hedara/devstart-test"
```

returns:

```text
Bob
```

Unknown paths correctly return no workspace.

---

## Workspace loading

Confirmed that:

```bash
workspace_load
```

correctly loads workspace names, project names, and project paths into arrays.

---

## UI

Confirmed:

```bash
ui_header
ui_workspace_list
ui_select_workspace
ui_workspace_menu
```

all work as expected.

---

## Full workspace launch

Confirmed that selecting a workspace from the UI launches/attaches the corresponding tmux session.

The normal `devstartv2` command now uses the workspace-driven flow.

---

# 29. Things Deliberately NOT Changed

Several decisions are currently considered stable.

## `.project-env.txt`

The format is **not being changed**.

Current example:

```text
id="enp8kj"
id="ubf0ck"
id="frhwdx"
id="sgpb6f"
PROJECT_NAME="devstart-final-test"

PANE_1="frontend | echo Frontend-running; sleep 1000"
PANE_2="worker | "
PANE_3="backend | echo Backend-running; sleep 1000"
```

Workspace information does not belong in this file.

---

## Tmux layout

The current:

```text
tiled
```

layout is accepted.

Layout redesign is deferred.

---

## External dependencies

The project remains intentionally native to Linux/Bash.

No dependency on:

```text
Python
fzf
external TUI frameworks
```

has been introduced.

---

# 30. Architectural Separation

The current architecture can be summarized as:

```text
                  devstartv2
                      │
                      ▼
                 launcher.sh
                      │
                      ▼
                    ui.sh
                      │
                      ▼
                workspace.sh
                      │
             ┌────────┴────────┐
             ▼                 ▼
       registry.sh        workspace state
             │
             ▼
        project path
             │
             ▼
        manifest.sh
             │
             ▼
          tmux.sh
             │
             ▼
       tmux workspace
```

More precisely:

### `core.sh`

Application-wide paths and core definitions.

### `config.sh`

Global configuration.

### `registry.sh`

Persistent project registration.

### `manifest.sh`

Project-specific pane configuration.

### `initializer.sh`

Creation and modification of project manifests.

### `workspace.sh`

Runtime workspace identity and persistence.

### `ui.sh`

Terminal presentation and user selection.

### `launcher.sh`

High-level application launch orchestration.

### `tmux.sh`

Actual tmux session and pane management.

This separation should be preserved as the project grows.

---

# 31. Important Conceptual Model

The most important architectural distinction established so far is:

```text
PROJECT
```

is not the same thing as:

```text
WORKSPACE
```

and neither should be confused with:

```text
TMUX SESSION
```

The intended model is:

```text
Project
│
├── filesystem path
├── project name
└── .project-env.txt
        │
        ▼
Workspace
│
├── human-friendly runtime name
└── project association
        │
        ▼
Tmux Session
│
├── panes
├── working directories
├── commands
└── runtime state
```

This gives the application room to evolve without forcing workspace concepts into the project manifest.

---

# 32. Current State of Development

The project has moved beyond the basic project launcher.

The following foundation is now working:

```text
✓ Modular Bash architecture
✓ Global configuration
✓ Project registry
✓ Project manifest parsing
✓ Project initialization
✓ Tmux project launching
✓ Global command installation
✓ Workspace persistence
✓ Friendly workspace names
✓ Unique fallback workspace names
✓ Workspace lookup
✓ Workspace loading
✓ Workspace selection UI
✓ Workspace-driven tmux launch
✓ Global devstartv2 workspace navigation
```

The application is now effectively **workspace-driven at the main UI level**.

---

# 33. Next Development Direction

The next major phase should be building the workspace experience into a more useful terminal application.

Potential progression:

```text
Current:
    Workspace list
        ↓
    Select
        ↓
    Launch
```

Then evolve toward:

```text
Workspace list
        │
        ├── Enter / Launch
        ├── Attach
        ├── View status
        ├── Stop
        ├── Restart
        ├── Rename
        ├── Remove workspace
        └── Open project
```

The exact interaction model should be designed incrementally.

The preferred development style remains:

```text
one feature
    ↓
implement
    ↓
syntax check
    ↓
manual test
    ↓
confirm
    ↓
next feature
```

This has worked well during the current development session and should continue.

---

# 34. Likely Future Improvements

Possible future work includes:

## Workspace status

Determine whether a workspace's tmux session is:

```text
Running
Not running
```

and display that in the workspace list.

Example concept:

```text
1) Bob       devstart-test        Running
2) Jeff      devstart-final-test  Stopped
```

---

## Attach versus launch

If a workspace already has a tmux session:

```text
Attach
```

If it doesn't:

```text
Create + launch
```

The existing tmux layer already has the basic behavior for this.

---

## Workspace actions

Eventually the selected workspace could provide actions such as:

```text
Enter
Stop
Restart
Rename
Remove
Back
```

These should be added incrementally rather than all at once.

---

## Better navigation

The current numeric selection works and is intentionally simple.

Later, the UI could evolve toward more keyboard-oriented navigation while remaining Bash/system-native.

No external UI dependency is required.

---

# 35. Development Philosophy

The project should remain:

```text
Small
Modular
Predictable
Native
Scriptable
Readable
```

Avoid introducing abstraction merely for abstraction's sake.

Each module should have a clear responsibility.

Avoid making:

```text
ui.sh
```

responsible for tmux internals.

Avoid making:

```text
tmux.sh
```

responsible for project registration.

Avoid putting workspace state into:

```text
.project-env.txt
```

Avoid making the project registry responsible for runtime workspace identity.

The separation established so far should remain the foundation.

---

# 36. Current Milestone

The current milestone can be considered:

## Workspace Foundation Complete

The application has successfully transitioned from:

```text
Project selector
    ↓
Project name
    ↓
Tmux session
```

to:

```text
Workspace selector
    ↓
Workspace identity
    ↓
Associated project
    ↓
Tmux session
```

This is the foundation for turning `devstartv2` from a simple project launcher into a persistent terminal workspace manager.

---

# 37. Resume Point

When development resumes, start from:

```text
Workspace navigation UI
```

The next feature should be chosen and implemented as a small isolated step.

Current working command:

```bash
devstartv2
```

Current real workspaces:

```text
Bob → devstart-test
Jeff → devstart-final-test
```

Current tmux layout:

```text
tiled
```

Current project manifest format:

```text
unchanged
```

Current global installation:

```text
~/.local/bin/devstartv2
```

Current persistent configuration:

```text
~/.config/devstart/
```

The workspace foundation is working and confirmed.

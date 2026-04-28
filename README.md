# tmux-ide

A tmux plugin that creates a 3-pane IDE layout with a single keybinding. Turns any tmux window into a development workspace with your editor, an AI coding agent, and a terminal.

```
+----------------------------------------+-------------------+
|                                        |                   |
|   editor (nvim)                        |   agent (opencode)|
|   (top-left)                           |   (right)         |
|                                        |   (full height)   |
|                                        |                   |
|----------------------------------------|                   |
|   terminal (bash)                      |                   |
|   (bottom-left)                        |                   |
+----------------------------------------+-------------------+
```

Defaults to **nvim** as the editor and **[OpenCode](https://opencode.ai)** as the right-side AI agent, but both are fully configurable. Works with any editor and any terminal-based tool.

## Quick Start

```bash
git clone https://github.com/guysoft/tmux-ide ~/.tmux/plugins/tmux-ide
~/.tmux/plugins/tmux-ide/install.sh
```

Then inside tmux, press `prefix + e` to create the IDE layout.

## Requirements

- [tmux](https://github.com/tmux/tmux) >= 2.0
- An editor (default: [Neovim](https://neovim.io/))
- An AI agent or tool for the right pane (default: [OpenCode](https://opencode.ai))

## Installation

### One-Line Install

```bash
git clone https://github.com/guysoft/tmux-ide ~/.tmux/plugins/tmux-ide && ~/.tmux/plugins/tmux-ide/install.sh
```

This will:
1. Symlink the plugin into `~/.tmux/plugins/tmux-ide/`
2. Create an `ide` command in `~/.local/bin/` for command-line usage
3. Add the plugin to `~/.tmux.conf` (before tpack/TPM init if present)
4. Reload your tmux config

### With [tpack](https://github.com/tmuxpack/tpack) (Recommended)

[tpack](https://github.com/tmuxpack/tpack) is a modern drop-in replacement for TPM with a TUI, written in Go. Install it via Homebrew (`brew install tmuxpack/tpack/tpack`) or see the [tpack installation guide](https://github.com/tmuxpack/tpack#installation).

Add this line to your `~/.tmux.conf`, before the tpack init line:

```tmux
set -g @plugin 'guysoft/tmux-ide'

# Initialize tpack (keep at the very bottom)
run 'tpack init'
```

Then press `prefix + I` to install.

### With [TPM](https://github.com/tmux-plugins/tpm)

Add this line to your `~/.tmux.conf`, before the TPM init line:

```tmux
set -g @plugin 'guysoft/tmux-ide'

# Initialize TPM (keep at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
```

Then press `prefix + I` to install.

To also get the `ide` CLI command, run:

```bash
~/.tmux/plugins/tmux-ide/install.sh
```

### Manual

Clone the repo and source the plugin:

```bash
git clone https://github.com/guysoft/tmux-ide ~/.tmux/plugins/tmux-ide
```

Add to `~/.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-ide/tmux-ide.tmux
```

### Uninstall

```bash
~/.tmux/plugins/tmux-ide/install.sh --remove
```

## Usage

### Keybinding (inside tmux)

Press `prefix + e` to transform the current tmux window into an IDE layout.

The layout uses the current pane's working directory as the project root:
- **Editor** opens in the project directory (nvim with your session auto-loaded if using a session plugin)
- **Agent** opens in the project directory (opencode continues the last session for that directory)
- **Terminal** opens in the project directory
- **Window** is renamed to the project directory name

If the window already has multiple panes, they are replaced.

### Command Line

The `ide` command (installed by `install.sh`) can be used directly:

```bash
# Create IDE layout in current directory
ide

# Create IDE layout for a specific project
ide ~/workspace/myproject

# Skip confirmation when replacing existing panes
ide --force ~/workspace/myproject
```

### Workflow Example

```bash
# Open a new tmux window
# Ctrl+a c

# Navigate to your project
cd ~/workspace/myproject

# Press prefix + e to create IDE layout
# Ctrl+a e

# Or from command line:
ide ~/workspace/myproject
```

## Configuration

All options are set in `~/.tmux.conf`:

| Option | Default | Description |
|--------|---------|-------------|
| `@ide-key` | `e` | Keybinding to trigger the IDE layout |
| `@ide-editor` | `nvim` | Editor command to run in the top-left pane |
| `@ide-agent` | `opencode -c` | Command to run in the right pane |
| `@ide-terminal` | *(empty)* | Command to run in the bottom-left pane (empty = plain shell) |
| `@ide-right-width` | `30` | Right pane width as a percentage |
| `@ide-bottom-height` | `30` | Bottom pane height as a percentage |

### Example Configurations

#### Neovim + OpenCode (default)

```tmux
set -g @plugin 'guysoft/tmux-ide'
# No extra config needed, these are the defaults
```

#### Neovim + Claude Code

```tmux
set -g @plugin 'guysoft/tmux-ide'
set -g @ide-agent "claude"
```

#### Vim + Aider

```tmux
set -g @plugin 'guysoft/tmux-ide'
set -g @ide-editor "vim"
set -g @ide-agent "aider"
```

#### Helix + Goose

```tmux
set -g @plugin 'guysoft/tmux-ide'
set -g @ide-editor "hx"
set -g @ide-agent "goose"
```

#### Wider Agent Pane

```tmux
set -g @plugin 'guysoft/tmux-ide'
set -g @ide-right-width "40"
set -g @ide-bottom-height "25"
```

## Session Restoration

This plugin works well with [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) and [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum). After a tmux restart, the full IDE layout is restored:

| Component | How It's Restored |
|-----------|-------------------|
| **Layout** | tmux-resurrect saves and restores pane geometry |
| **Editor** | tmux-resurrect restores nvim (in default process list). Use a session plugin like [possession.nvim](https://github.com/jedrzejboczar/possession.nvim) with `autoload = 'auto_cwd'` to auto-restore editor sessions |
| **Agent** | For OpenCode, use [tmux-resurrect-opencode-sessions](https://github.com/guysoft/tmux-resurrect-opencode-sessions) to restore the exact agent session |
| **Terminal** | tmux-resurrect restores the shell in the correct directory |

### Recommended tmux.conf for Full Restoration

```tmux
# Plugins
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'guysoft/tmux-resurrect-opencode-sessions'
set -g @plugin 'guysoft/tmux-ide'

# Auto-save and restore
set -g @continuum-restore 'on'

# Initialize tpack (keep at the very bottom)
run 'tpack init'
```

> **Note:** If using TPM instead of tpack, replace `run 'tpack init'` with `run '~/.tmux/plugins/tpm/tpm'` and add `set -g @plugin 'tmux-plugins/tpm'` to the plugins list.

## Related Plugins

- [tmux-resurrect-opencode-sessions](https://github.com/guysoft/tmux-resurrect-opencode-sessions) - Preserves OpenCode sessions across tmux restarts
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) - Save and restore tmux sessions
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) - Automatic save and restore

## License

GPL-3.0. See [LICENSE](LICENSE) for details.

# tmux-ide

A tmux plugin that creates a 3-pane IDE layout with a single keybinding.

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

Defaults to **nvim** as the editor and **opencode** as the right-side agent, but both are configurable.

## Requirements

- [tmux](https://github.com/tmux/tmux) >= 2.0
- An editor (default: [Neovim](https://neovim.io/))
- An AI agent or tool for the right pane (default: [OpenCode](https://opencode.ai))

## Installation

### With [TPM](https://github.com/tmux-plugins/tpm) (recommended)

Add this line to your `~/.tmux.conf`:

```tmux
set -g @plugin 'guysoft/tmux-ide'

# Initialize TPM (keep at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
```

Then press `prefix + I` to install.

### Manual

Clone the repo:

```bash
git clone https://github.com/guysoft/tmux-ide ~/.tmux/plugins/tmux-ide
```

Add to `~/.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-ide/tmux-ide.tmux
```

## Usage

### Keybinding

Press `prefix + e` to transform the current tmux window into an IDE layout using the current pane's working directory.

- If the window has multiple panes, they are replaced with the IDE layout.
- The window is renamed to the project directory name.
- Focus is set to the editor pane.

### Command Line

You can also run the script directly:

```bash
# Use current directory
~/.tmux/plugins/tmux-ide/scripts/ide.sh

# Specify a directory
~/.tmux/plugins/tmux-ide/scripts/ide.sh ~/workspace/myproject

# Skip confirmation (used by keybinding)
~/.tmux/plugins/tmux-ide/scripts/ide.sh --force ~/workspace/myproject
```

## Configuration

All options are set in `~/.tmux.conf` via tmux options:

```tmux
# Change the keybinding (default: "e")
set -g @ide-key "e"

# Change the editor command (default: "nvim")
set -g @ide-editor "nvim"

# Change the right pane command (default: "opencode -c")
set -g @ide-agent "opencode -c"

# Change the terminal command (default: "" = plain bash)
set -g @ide-terminal ""

# Change the right pane width percentage (default: 30)
set -g @ide-right-width "30"

# Change the bottom pane height percentage (default: 30)
set -g @ide-bottom-height "30"
```

### Examples

#### Vim + GitHub Copilot CLI

```tmux
set -g @ide-editor "vim"
set -g @ide-agent "gh copilot"
```

#### Neovim + Claude Code

```tmux
set -g @ide-editor "nvim"
set -g @ide-agent "claude"
```

#### Helix + Aider

```tmux
set -g @ide-editor "hx"
set -g @ide-agent "aider"
```

## Session Restoration

This plugin works well with [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) and [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum). After a tmux restart:

- **Layout**: Restored by tmux-resurrect (saves pane geometry).
- **Editor**: Restored by tmux-resurrect (nvim is in the default process list). If using a session plugin like [possession.nvim](https://github.com/jedrzejboczar/possession.nvim) with `autoload = 'auto_cwd'`, the editor session is restored automatically.
- **Agent**: For OpenCode, use [tmux-resurrect-opencode-sessions](https://github.com/guysoft/tmux-resurrect-opencode-sessions) to restore the exact agent session.
- **Terminal**: Restored by tmux-resurrect in the correct directory.

## License

GPL-3.0. See [LICENSE](LICENSE) for details.

#!/usr/bin/env bash
#
# ide.sh - Create a 3-pane tmux IDE layout
#
# Layout:
#   +----------------------------------------+-------------------+
#   |                                        |                   |
#   |   editor (nvim)                        |   agent (opencode)|
#   |   (top-left, 70% width, 70% height)    |   (right, 30%)    |
#   |                                        |   (full height)   |
#   |                                        |                   |
#   |----------------------------------------|                   |
#   |   terminal (bash)                      |                   |
#   |   (bottom-left, 70% width, 30% height) |                   |
#   +----------------------------------------+-------------------+
#
# Usage:
#   ide.sh [--force] [directory]
#
# Options:
#   --force   Skip confirmation prompt when replacing existing panes
#             (used by the tmux keybinding)
#
# Configurable via tmux options:
#   @ide-editor          Editor command (default: "nvim")
#   @ide-agent           Right pane command (default: "opencode -c")
#   @ide-terminal        Terminal command (default: "")
#   @ide-right-width     Right pane width percentage (default: 30)
#   @ide-bottom-height   Bottom pane height percentage (default: 30)
#
# License: GPL-3.0

set -euo pipefail

get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value
	option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

# --- Parse arguments ---

FORCE=0
DIR=""

for arg in "$@"; do
	if [ "$arg" = "--force" ]; then
		FORCE=1
	else
		DIR="$arg"
	fi
done

DIR="${DIR:-$(pwd)}"
DIR="$(realpath "$DIR")"
PROJECT_NAME="$(basename "$DIR")"

# --- Read configuration ---

EDITOR_CMD=$(get_tmux_option "@ide-editor" "nvim")
AGENT_CMD=$(get_tmux_option "@ide-agent" "opencode -c")
TERMINAL_CMD=$(get_tmux_option "@ide-terminal" "")
RIGHT_WIDTH=$(get_tmux_option "@ide-right-width" "30")
BOTTOM_HEIGHT=$(get_tmux_option "@ide-bottom-height" "30")

# --- Validation ---

if [ -z "${TMUX:-}" ]; then
	echo "Error: must be run inside tmux"
	exit 1
fi

# --- Handle existing panes ---

PANE_COUNT=$(tmux list-panes | wc -l)
if [ "$PANE_COUNT" -gt 1 ] && [ "$FORCE" -eq 0 ]; then
	read -p "Window has $PANE_COUNT panes. Replace with IDE layout? (y/n) " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "Aborted."
		exit 0
	fi
fi

if [ "$PANE_COUNT" -gt 1 ]; then
	CURRENT_PANE=$(tmux display-message -p '#{pane_id}')
	tmux kill-pane -a -t "$CURRENT_PANE"
fi

# --- Create layout ---

# Rename window to project name
tmux rename-window "$PROJECT_NAME"

# 1. Split right for agent pane
tmux split-window -h -l "${RIGHT_WIDTH}%" -c "$DIR"

# 2. Go back to left pane, split bottom for terminal
tmux select-pane -L
tmux split-window -v -l "${BOTTOM_HEIGHT}%" -c "$DIR"

# After splits, pane layout is:
#   Pane 0: top-left (original)
#   Pane 1: bottom-left (vertical split)
#   Pane 2: right (horizontal split)

# 3. Launch agent in right pane
tmux send-keys -t 2 "cd '$DIR' && $AGENT_CMD" C-m

# 4. Launch editor in top-left pane with RPC socket for external tool access
SESSION_NAME=$(tmux display-message -p '#{session_name}')
WINDOW_INDEX=$(tmux display-message -p '#{window_index}')
NVIM_IDE_SOCK="/tmp/nvim-ide-${SESSION_NAME}-${WINDOW_INDEX}.sock"
# Remove stale socket if it exists
rm -f "$NVIM_IDE_SOCK"
tmux set-environment NVIM_IDE_SOCK "$NVIM_IDE_SOCK"
# Export as env var so nvim can self-heal the socket on restart
tmux send-keys -t 0 "cd '$DIR' && NVIM_IDE_SOCK='$NVIM_IDE_SOCK' $EDITOR_CMD --listen '$NVIM_IDE_SOCK'" C-m

# 5. Set up terminal in bottom-left pane
if [ -n "$TERMINAL_CMD" ]; then
	tmux send-keys -t 1 "cd '$DIR' && $TERMINAL_CMD" C-m
else
	tmux send-keys -t 1 "cd '$DIR'" C-m
fi

# 6. Focus the editor pane
tmux select-pane -t 0

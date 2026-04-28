#!/usr/bin/env bash
#
# install.sh - Install tmux-ide plugin
#
# This script:
#   1. Installs the plugin to ~/.tmux/plugins/tmux-ide/
#   2. Creates an 'ide' command symlink in ~/.local/bin/
#   3. Adds the plugin to ~/.tmux.conf if not already present (before tpack/TPM init if present)
#   4. Reloads tmux config if tmux is running
#
# Usage:
#   ./install.sh           # Install from local clone
#   ./install.sh --remove  # Uninstall
#
# License: GPL-3.0

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGIN_DIR="$HOME/.tmux/plugins/tmux-ide"
BIN_DIR="$HOME/.local/bin"
TMUX_CONF="$HOME/.tmux.conf"
PLUGIN_LINE="set -g @plugin 'guysoft/tmux-ide'"

# --- Colors ---

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }

# --- Cross-platform sed -i (macOS BSD sed vs GNU sed) ---

sed_inplace() {
	if [[ "$OSTYPE" == "darwin"* ]]; then
		sed -i '' "$@"
	else
		sed -i "$@"
	fi
}

# --- Uninstall ---

uninstall() {
	info "Uninstalling tmux-ide..."

	if [ -L "$PLUGIN_DIR" ] || [ -d "$PLUGIN_DIR" ]; then
		rm -rf "$PLUGIN_DIR"
		info "Removed $PLUGIN_DIR"
	fi

	if [ -L "$BIN_DIR/ide" ]; then
		rm "$BIN_DIR/ide"
		info "Removed $BIN_DIR/ide symlink"
	fi

	if [ -f "$TMUX_CONF" ] && grep -qF "$PLUGIN_LINE" "$TMUX_CONF"; then
		sed_inplace "\|${PLUGIN_LINE}|d" "$TMUX_CONF"
		info "Removed plugin line from $TMUX_CONF"
	fi

	if [ -n "${TMUX:-}" ]; then
		tmux source-file "$TMUX_CONF" 2>/dev/null || true
		info "Reloaded tmux config"
	fi

	info "Uninstall complete."
	exit 0
}

# --- Install ---

install() {
	info "Installing tmux-ide..."

	# 1. Install plugin directory
	mkdir -p "$(dirname "$PLUGIN_DIR")"

	if [ "$SCRIPT_DIR" = "$PLUGIN_DIR" ]; then
		info "Already installed at $PLUGIN_DIR"
	elif [ -d "$PLUGIN_DIR" ] || [ -L "$PLUGIN_DIR" ]; then
		warn "Existing installation found at $PLUGIN_DIR, replacing..."
		rm -rf "$PLUGIN_DIR"
		ln -sfn "$SCRIPT_DIR" "$PLUGIN_DIR"
		info "Symlinked $SCRIPT_DIR -> $PLUGIN_DIR"
	else
		ln -sfn "$SCRIPT_DIR" "$PLUGIN_DIR"
		info "Symlinked $SCRIPT_DIR -> $PLUGIN_DIR"
	fi

	# 2. Create 'ide' CLI command symlink
	mkdir -p "$BIN_DIR"
	ln -sfn "$SCRIPT_DIR/scripts/ide.sh" "$BIN_DIR/ide"
	info "Created 'ide' command at $BIN_DIR/ide"

	# Check if ~/.local/bin is in PATH
	if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
		warn "$BIN_DIR is not in your PATH. Add it to your shell profile:"
		warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
	fi

	# 3. Add plugin to tmux.conf
	if [ ! -f "$TMUX_CONF" ]; then
		warn "$TMUX_CONF not found. Creating it..."
		echo "$PLUGIN_LINE" > "$TMUX_CONF"
		info "Created $TMUX_CONF with plugin line"
	elif grep -qF "tmux-ide" "$TMUX_CONF"; then
		info "Plugin already in $TMUX_CONF"
	else
		# Insert before plugin manager init line if it exists, otherwise append
		# Supports both tpack (run 'tpack init') and TPM (run '~/.tmux/plugins/tpm/tpm')
		if grep -qE "run.*(tpack init|tpm/tpm)" "$TMUX_CONF"; then
			# Use awk to insert before the init line (portable across macOS and Linux)
			awk -v line="$PLUGIN_LINE" '/run.*(tpack init|tpm\/tpm)/{print line}{print}' "$TMUX_CONF" > "$TMUX_CONF.tmp" && mv "$TMUX_CONF.tmp" "$TMUX_CONF"
			info "Added plugin to $TMUX_CONF (before plugin manager init)"
		else
			echo "$PLUGIN_LINE" >> "$TMUX_CONF"
			info "Appended plugin to $TMUX_CONF"
		fi
	fi

	# 4. Reload tmux config if inside tmux
	if [ -n "${TMUX:-}" ]; then
		tmux source-file "$TMUX_CONF" 2>/dev/null || true
		info "Reloaded tmux config"
	else
		warn "Not inside tmux. Reload config manually: tmux source-file $TMUX_CONF"
	fi

	echo ""
	info "Installation complete!"
	echo ""
	echo "  Usage:"
	echo "    Inside tmux:  prefix + e  (creates IDE layout in current window)"
	echo "    Command line: ide [directory]"
	echo ""
	echo "  Configuration (add to $TMUX_CONF):"
	echo "    set -g @ide-editor \"nvim\"        # editor command"
	echo "    set -g @ide-agent \"opencode -c\"  # right pane command"
	echo "    set -g @ide-right-width \"30\"     # right pane width %"
	echo "    set -g @ide-bottom-height \"30\"   # bottom pane height %"
	echo ""
}

# --- Main ---

if [ "${1:-}" = "--remove" ] || [ "${1:-}" = "uninstall" ]; then
	uninstall
else
	install
fi

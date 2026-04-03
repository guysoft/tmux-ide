#!/usr/bin/env bash
#
# tmux-ide
#
# A tmux plugin that creates a 3-pane IDE layout:
#   editor (top-left) + terminal (bottom-left) + agent/tool (right)
#
# Defaults: nvim + bash + opencode
# Configurable via tmux options.
#
# License: GPL-3.0

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

main() {
	local key
	key=$(get_tmux_option "@ide-key" "e")

	tmux bind-key "$key" run-shell "'${CURRENT_DIR}/scripts/ide.sh' --force '#{pane_current_path}'"
}

main

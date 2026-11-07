#!/usr/bin/env bash
# Installs claude-tmux-media for the current user. Safe to rerun.
set -euo pipefail

src=$(cd "$(dirname "$0")" && pwd)
bin=$HOME/.local/bin
tmux_dir=${XDG_CONFIG_HOME:-$HOME/.config}/tmux
settings=$HOME/.claude/settings.json
claude_md=$HOME/.claude/CLAUDE.md
rule='To show me an image or video, run `show-media <path>`; when I ask to see a specific file, run `show-media --focus <path>`. Never try to render images in Bash output.'

mkdir -p "$bin" "$tmux_dir" "$HOME/.claude"
install -m 755 "$src"/bin/{show-media,media-pane,media-toggle} "$bin/"
install -m 644 "$src/claude-media.tmux.conf" "$tmux_dir/claude-media.conf"

source_line="source-file $tmux_dir/claude-media.conf"
grep -qxF "$source_line" "$tmux_dir/tmux.conf" 2>/dev/null || echo "$source_line" >>"$tmux_dir/tmux.conf"

# Claude Code: PostToolUse hook on Read/Write/Edit, merged into existing settings (rerun replaces it).
[ -f "$settings" ] || echo '{}' >"$settings"
jq '.hooks.PostToolUse = ([.hooks.PostToolUse[]? | select(any(.hooks[]?; (.command // "") | contains("show-media")) | not)]
  + [{"matcher": "Read|Write|Edit", "hooks": [{"type": "command", "command": "\"$HOME/.local/bin/show-media\" --hook", "async": true}]}])' \
	"$settings" >"$settings.tmp" && mv "$settings.tmp" "$settings"

# Replace an earlier version of the rule (any line starting "To show me an image or video") with the current one.
touch "$claude_md"
{ grep -v '^To show me an image or video' "$claude_md"; echo "$rule"; } >"$claude_md.tmp" && mv "$claude_md.tmp" "$claude_md"

tmux source-file "$tmux_dir/tmux.conf" 2>/dev/null || true
echo "Installed. In tmux press prefix+M (default Ctrl+b, then Shift+m) to open the media pane."

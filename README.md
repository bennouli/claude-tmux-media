# claude-tmux-media

A tmux side pane that shows every image Claude Code reads, writes or wants to show you, rendered inline with the Kitty graphics protocol.

- `prefix+M` (default `Ctrl+b`, then `Shift+m`) opens or hides the media pane next to the current pane. Hiding parks it in a window named `_media`; it keeps running and keeps its history.
- A Claude Code `PostToolUse` hook on `Read|Write|Edit` sends image and video files to the pane automatically.
- `show-media <file...>` sends files by hand; `show-media --focus <file...>` also switches the pane to their tab. Through `~/.claude/CLAUDE.md`, Claude uses the plain form when it wants to show you something and `--focus` when you ask to see a specific file.
- One tab per repo + branch, taken from where the Claude session works (the hook's `cwd`), so every worktree gets its own tab. Sessions outside git share an `other` tab. Each item is labelled with its session's name.
- Only `--focus` switches tabs; any other new image marks its tab with `•` until you look at it. Within the current tab, a new image comes to the front if you were looking at the newest one.
- Tabs close themselves within a minute once their branch is deleted (e.g. after a merge) or their repo is gone.
- In the pane: `h`/`l` or `Tab` previous/next tab, `p`/`n` older/newer, `r` redraw, `x` close tab, `q` quit. Each tab keeps its last 50 items in `$XDG_RUNTIME_DIR/claude-media/<tab>/`, which is cleared on reboot.

Images travel through the pty (direct transmission with unicode placeholders), so they also render when you attach to the tmux session over SSH from another machine.

## Requirements

Linux host with GNU coreutils (tested on Arch Linux, Ghostty, tmux 3.8).

| Package         | Why                                        |
| --------------- | ------------------------------------------ |
| `tmux` ≥ 3.3    | `allow-passthrough`                        |
| `kitty`         | provides `kitten icat`                     |
| `inotify-tools` | the pane watches the queue                 |
| `jq`            | hook input, settings merge                 |
| `ffmpeg`        | still frame for GIF and video              |
| `librsvg`       | SVG to PNG                                 |
| `chafa`         | optional text fallback when `icat` fails   |

The terminal must support Kitty graphics with unicode placeholders (Ghostty, kitty).

## Install

```sh
git clone https://github.com/bennouli/claude-tmux-media.git
./claude-tmux-media/install.sh
```

The installer copies the scripts to `~/.local/bin`, adds a `source-file` line to `~/.config/tmux/tmux.conf`, merges the hook into `~/.claude/settings.json` and adds one line to `~/.claude/CLAUDE.md`. Running it again changes nothing. New Claude sessions pick up the `CLAUDE.md` line.

### tmux setup

The pane needs these tmux settings. `install.sh` puts them in `~/.config/tmux/claude-media.conf` and sources that file; if you manage your tmux config yourself, add them to it instead:

```tmux
# prefix+M shows/hides the media pane next to the current pane (hidden keeps it running).
bind M run-shell -b '$HOME/.local/bin/media-toggle #{pane_id}'

# Image data only reaches a terminal while the pane is visible, and a newly attached client
# (e.g. over SSH) has none, so panes re-send it whenever what a client shows changes.
set-hook -g client-attached 'run-shell -b "$HOME/.local/bin/media-pane --refresh"'
set-hook -g client-session-changed 'run-shell -b "$HOME/.local/bin/media-pane --refresh"'
set-hook -g after-select-window 'run-shell -b "$HOME/.local/bin/media-pane --refresh"'
```

Then reload with `tmux source-file ~/.config/tmux/tmux.conf` (or `~/.tmux.conf`).

- Without the `bind` line there is no way to open the pane except running `media-pane` in a pane yourself.
- Without the hooks, images go blank after switching windows or sessions or attaching from another machine until you press `r` in the pane.
- `allow-passthrough` is not needed in your config: the media pane turns it on for itself only and turns it off again when it exits.

## Limits

- GIF, video and SVG show a single still frame: Ghostty does not play Kitty animation frames, and video players cannot draw through tmux passthrough.
- Session names come from `~/.claude/sessions/*.json`, which is not a documented Claude Code interface; when that lookup fails the label falls back to the first 8 characters of the session id.
- `show-media` only queues; it does not open a hidden pane. With no media pane at all it does nothing and exits 0.
- `prefix+M` replaces tmux's default "clear marked pane" binding.

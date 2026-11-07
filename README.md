# claude-tmux-media

A tmux side pane that shows every image Claude Code reads, writes or wants to show you, rendered inline with the Kitty graphics protocol.

- `prefix+M` (default `Ctrl+b`, then `Shift+m`) opens or hides the media pane next to the current pane. Hiding parks it in a window named `_media`; it keeps running and keeps its history.
- A Claude Code `PostToolUse` hook on `Read|Write|Edit` sends image and video files to the pane automatically.
- `show-media <file...>` sends files by hand. Claude is told to use it through `~/.claude/CLAUDE.md`.
- In the pane: `p` older, `n` newer, `r` redraw, `q` quit. New items jump to the front. The last 50 items are kept in `$XDG_RUNTIME_DIR/claude-media/`.
- One feed for all Claude sessions; each item is labelled with its session's name.

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

## Limits

- GIF, video and SVG show a single still frame: Ghostty does not play Kitty animation frames, and video players cannot draw through tmux passthrough.
- Session names come from `~/.claude/sessions/*.json`, which is not a documented Claude Code interface; when that lookup fails the label falls back to the first 8 characters of the session id.
- `show-media` only queues; it does not open a hidden pane. With no media pane at all it does nothing and exits 0.
- `prefix+M` replaces tmux's default "clear marked pane" binding.

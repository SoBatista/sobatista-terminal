# Customization

## Black Ice palette

The palette has a narrow role for every color:

| Role | Hex | Use |
| --- | --- | --- |
| Background | `#070B0D` | Terminal canvas. |
| Elevated surface | `#111820` | Identity segment of the prompt bar. |
| Secondary surface | `#18222C` | Directory, Git, runtime bar and pane separators. |
| Terminal green | `#00E68A` | Success, identity, staged and ahead Git state. |
| Ice cyan | `#5EEBFF` | Directory and restrained runtime highlights. |
| Teal | `#22C7A9` | Containers and secondary accents. |
| Main text | `#D6E7E9` | Primary readable content and the project version. |
| Muted text | `#64748B` | Duration, untracked, stashed, behind, inactive UI. |
| Warning amber | `#F5C451` | Modified and read-only (dirty) state. |
| Error red | `#FF4D5A` | Failed commands, conflicts, divergence, deletions. |

Do not add pink, peach, mauve, lavender, or pastel rainbow sequences. Accent
colors should remain text/icons on dark surfaces rather than luminous blocks.

## Starship prompt

The prompt is one connected Powerline bar written as a single `format` line.
The identity segment sits on the elevated surface, a single rounded transition
hands off to the secondary surface, and directory, Git, and every language or
container module share that secondary surface. Because the conditional modules
share one background, any of them can be absent without leaving a gap, an
orphaned separator, or a placeholder capsule — the bar simply closes after the
last segment that rendered. The clock is intentionally removed and `[time]` is
disabled; do not re-enable it.

To keep this property when editing:

- Leave `directory` unconditional; it is the anchor that always closes the bar.
- Give any new segment `bg:secondary` and place it before the closing `` glyph.
- Never give a middle segment its own background shade or its own closing glyph.

Conditional state renders only when meaningful: `git_status` counters appear
only when non-zero, `cmd_duration` only past `min_time` (2s), and the exit code
only after a failing command. Keep `git_status` styling within the palette:
amber for modified, green for staged/ahead, muted for untracked/stashed/behind,
and red for conflicts, divergence, and deletions.

The `package` module shows `v<version>` in neutral main text, read from the
project manifest by Starship — it never runs project code, a package manager, or
the network. `version_format = "v${raw}"` adds the `v` prefix; there is no label
or icon so it stays compact. It shares `bg:secondary` and vanishes outside a
versioned project, so the connected bar stays intact. Language and runtime
version modules (`python`, `nodejs`, `rust`, …) are intentionally left out of
the top-level `format` so the project version is the prompt's only version-like
value; the runtimes themselves are untouched and reported by `python3 --version`
and friends.

Validate after editing:

```bash
python3 -c 'import tomllib; tomllib.load(open("config/starship/starship.toml", "rb"))'
STARSHIP_CONFIG="$PWD/config/starship/starship.toml" starship prompt
```

## Safe screenshot identity

The prompt shows `$SOBATISTA_PROMPT_IDENTITY`, which `config/bash/bashrc` sets to
your real `user@host` normally and to a deterministic `sobatista@blackice` when
`SOBATISTA_SCREENSHOT_MODE=1`. Start a safe shell for captures without `eval`:

```bash
SOBATISTA_SCREENSHOT_MODE=1 exec bash
```

Leave that shell (`exec bash`, or open a new one) to return to your real
identity. Screenshot mode changes only the displayed identity, nothing else.

## Terminator

The default profile uses a solid Black Ice background and the exact font family
`JetBrainsMono Nerd Font Mono`. Change `font` size without changing the family
name so Nerd Font glyphs continue to render.

The `AI-Workbench` hierarchy is:

```text
window0
└── main_split (horizontal; 70/30)
    ├── terminal_main
    └── right_split (vertical; 50/50)
        ├── terminal_ai
        └── terminal_logs
```

Terminator stores split positions in pixels as well as ratios. Adjust positions
for a preferred monitor, then review the entire config before contributing the
change; Terminator may rewrite unrelated preferences.

### Pane separators

Terminator draws the split handle with the GTK theme, which on a light desktop
theme renders an almost-white divider. `config/terminator/config` sets a thin
`handle_size = 1`, and `config/terminator/gtk.css` repaints only Terminator's
separators in muted Black Ice slate (`#18222C`). It is opt-in so it never
clobbers an existing GTK stylesheet — import it from your own:

```bash
mkdir -p ~/.config/gtk-3.0
printf '@import url("file://%s/.config/terminator/gtk.css");\n' "$HOME" \
    >> ~/.config/gtk-3.0/gtk.css
```

Restart Terminator to apply it. Remove that single `@import` line to revert. The
rule is scoped to Terminator windows and does not affect other applications.

### Background opacity and the solid profile

The shipped `default` profile is **subtly transparent** — near-black Black Ice
with a faint hint of the desktop behind it:

```ini
    background_type = transparent
    background_darkness = 0.90
    background_color = "#070B0D"
```

`background_darkness = 0.90` keeps the terminal 90% opaque, so the `#070B0D`
appearance and text contrast are preserved while the background is gently
see-through. Lower it for more transparency; raise it toward `1.0` for less.
Restart Terminator to apply a change.

A second profile, **`BlackIce-Solid`**, is fully opaque (`background_darkness =
1.0`) for when transparency is a liability:

```ini
    background_type = solid
    background_darkness = 1.0
    background_color = "#070B0D"
```

Prefer `BlackIce-Solid` for screenshots, livestreaming, screen sharing,
presentations, and any time sensitive desktop content sits behind the terminal —
a transparent background can leak whatever is behind the window. The `privacy`
command opens a new solid window in the current directory:

```bash
privacy   # terminator --no-dbus --profile=BlackIce-Solid --working-directory="$PWD"
```

It never changes the current terminal or its panes. `termhelp privacy` documents
it.

Terminal background opacity is a Terminator profile setting and is unrelated to
the shell's `SOBATISTA_SCREENSHOT_MODE`, which only changes the displayed prompt
identity. They are separate concerns. Note too that full-screen applications
which paint their own background — Codex, Claude, editors, pagers such as
`less` — can appear opaque even while the Terminator profile is transparent.

The `AI-Workbench` layout uses the transparent `default` profile and keeps the
muted slate pane separators.

## Local shell overrides

The installed files are deliberately complete and replacement-based so rollback
is deterministic. For private machine aliases, source a non-repository file from
the end of `~/.bash_aliases`, for example:

```bash
if [[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/sobatista-terminal/local.bash ]]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/sobatista-terminal/local.bash"
fi
```

That hook is not enabled by default because private files and their behavior
cannot be tested by the project. Never contribute private hostnames, credentials,
target addresses, client names, or machine-specific paths.

## Model selection state

Set `XDG_CONFIG_HOME` before Bash starts to relocate the model-selection state.
Do not edit the file to an arbitrary string; model names are validated and must
match an installed Ollama name. Prefer `qmodel MODEL` or `qm`.

The default can be changed in `LOCAL_LLM_MODEL_DEFAULT` in
`config/bash/bash_aliases`. Update tests, help text, README examples, and release
notes in the same pull request.

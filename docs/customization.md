# Customization

## Black Ice palette

The palette has a narrow role for every color:

| Role | Hex | Use |
| --- | --- | --- |
| Background | `#070B0D` | Terminal canvas. |
| Elevated surface | `#111820` | Identity, Git, runtime, and time capsules. |
| Secondary surface | `#18222C` | Directory and focused UI states. |
| Terminal green | `#00E68A` | Success, identity, clean Git state. |
| Ice cyan | `#5EEBFF` | Directory and restrained runtime highlights. |
| Teal | `#22C7A9` | Containers and secondary accents. |
| Main text | `#D6E7E9` | Primary readable content. |
| Muted text | `#64748B` | Time, duration, inactive UI. |
| Warning amber | `#F5C451` | Modified/untracked/read-only state. |
| Error red | `#FF4D5A` | Failed commands, conflicts, deletions. |

Do not add pink, peach, mauve, lavender, or pastel rainbow sequences. Accent
colors should remain text/icons on dark surfaces rather than luminous blocks.

## Starship modules

The identity and directory form one always-present powerline group. Every
optional Git, runtime, container, environment, or time module includes both its
own opening and closing glyph. Removing an optional module from `format` or
disabling it therefore cannot expose a duplicated arrow.

Validate TOML after editing:

```bash
python3 -c 'import tomllib; tomllib.load(open("config/starship/starship.toml", "rb"))'
STARSHIP_CONFIG="$PWD/config/starship/starship.toml" starship prompt
```

Keep `git_status` symbols individually styled: amber for modified/untracked,
green for staged/ahead, and red for conflicts/deletions/divergence.

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

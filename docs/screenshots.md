# Screenshot workflow

Screenshots must come from the actual configured Terminator environment. A
generated mockup, composited terminal, or text rendered into an image is not an
acceptable substitute.

No screenshot is committed until it is individually reviewed for credentials,
tokens, private paths, hostnames, IP addresses, client names, engagement data,
neighboring-window content, and unrelated personal information. If meaningful
sanitization would damage the evidence, recapture it with safe content.

## Shared capture settings

- Configuration: install the shipped configs first so the Black Ice palette and
  connected prompt are active: `bash install.sh --configs-only`.
- Profile: capture on the solid **`BlackIce-Solid`** profile, not the subtly
  transparent `default` — a transparent background would leak whatever is behind
  the window. Launch an isolated process on the solid profile:

  ```bash
  terminator --no-dbus --profile=BlackIce-Solid
  ```

- Font: JetBrainsMono Nerd Font Mono 11.
- Window: 1600 × 900 pixels where possible; use 1920 × 1080 only if 1600 × 900
  makes the three-pane layout unreadable.
- Identity: start every capture shell in screenshot mode so the prompt shows the
  safe `sobatista@blackice` identity instead of the real username and hostname
  (no `eval`):

  ```bash
  SOBATISTA_SCREENSHOT_MODE=1 exec bash
  ```

- Working directory: repository root, with the prompt configured to show only
  the shortened `sobatista-terminal` directory.
- Browser tabs, desktop notifications, other windows, and personal terminal tabs
  must be closed or outside the frame.
- Use PNG. Do not apply filters, fake glow, or color replacement.
- Crop to consistent outer terminal bounds without hiding the title/tab context
  needed to identify the layout.
- Optimize losslessly with `oxipng -o 4 FILE` or an equivalent reviewed tool.

The prompt has no clock; a time value must never appear in any capture.

Run `scripts/capture-demo.sh diagnostics` before every capture.

## 1. Main hero terminal

Open a single-pane window on the solid `BlackIce-Solid` profile at 1600 × 900 in
the repository root, then start screenshot mode and run the demo:

```bash
SOBATISTA_SCREENSHOT_MODE=1 exec bash
clear
scripts/capture-demo.sh hero
git status --short --branch
```

Compose so the connected prompt bar and the demo output fill the upper-left of
the frame with little blank space. Visible: the single connected Black Ice bar
(`sobatista@blackice` identity, shortened `sobatista-terminal` directory, Git
branch, and any meaningful Git state), the deterministic project summary, and
the green success prompt character. Hidden/absent: the clock (removed), the real
username and hostname (replaced by screenshot mode), absolute paths, credentialed
remotes, notifications, IP addresses, and unrelated files.

Filename: `docs/assets/screenshots/hero-black-ice.png`.

Alt text: “SoBatista Terminal Black Ice connected prompt in Terminator with a safe
sobatista@blackice identity, Git status, and a deterministic project summary.”

> [!NOTE]
> Captured and in the repository. It was reviewed for secrets and private data,
> cropped to a single pane (the safe identity only), and shown at full opacity
> for README text contrast. It is wired into the README hero.

## 2. AI help

Use the same solid profile and dimensions in the repository root. Run:

```bash
clear
termhelp ai
```

Visible: the entire local Ollama, cloud Codex, and local Codex help output. Hide
the prompt line if it exposes an unsuitable host name; recapture with a safe host
rather than painting over it.

Filename: `docs/assets/screenshots/termhelp-ai.png`.

Alt text: “Built-in AI help listing direct Ollama and separate cloud and local
Codex commands.”

> [!NOTE]
> Captured and in the repository. Reviewed for private data, captured in
> screenshot mode (safe identity), and cropped to the content. Wired into the
> README "Discover shortcuts" section.

## 3. Model selection menu

Ensure only non-sensitive model names appear in `ollama list`. Use the solid
profile at 1600 × 900 in the repository root — `privacy` opens one in the current
directory. Run:

```bash
clear
qm
```

Visible: the fzf menu with the supported installed model names and the Black Ice
selection style. Hide hardware telemetry, model paths, unrelated custom model
names, and terminal history.

Desired filename: `docs/assets/screenshots/qm-model-selector.png`.

Suggested alt text: “Black Ice fzf menu selecting among installed Qwen coder
models.”

## 4. AI-Workbench layout

Open `terminator -l AI-Workbench` at 1600 × 900 or 1920 × 1080. All panes must be
in the repository root.

This is the one capture that cannot use the solid profile: the `AI-Workbench`
layout sets `profile = default` on each of its three terminals, and `-p` does not
override a layout's per-terminal profile. The capture is therefore made on the
subtly transparent profile, so clear the desktop behind the window first — a
transparent background shows whatever is behind it. Start Terminator itself in
screenshot mode so every pane inherits the safe identity, then confirm the
identity in all three panes before sending the file:

```bash
SOBATISTA_SCREENSHOT_MODE=1 terminator --no-dbus -l AI-Workbench
```

Prepare:

```bash
# Left pane
scripts/capture-demo.sh hero

# Upper-right pane
termhelp ai

# Lower-right pane
git status --short --branch
```

Visible: one large left pane and two stacked right panes, pane separators, font,
and readable prompts. Hidden: AI conversation history, real logs, system process
lists, environment variables, target data, and shell history.

Desired filename: `docs/assets/screenshots/ai-workbench.png`.

Suggested alt text: “SoBatista AI-Workbench Terminator layout with one main pane
and two stacked side panes.”

## 5. Optional diagnostics/update view

Use the solid profile at 1600 × 900 in the repository root. Prefer the
deterministic, non-mutating diagnostics output:

```bash
clear
scripts/capture-demo.sh diagnostics
termhelp updates
```

Do not capture `llm_check` if it reveals hardware, custom model names, process
arguments, usernames, or service details. Do not run live system updates solely
for a screenshot.

Desired filename: `docs/assets/screenshots/update-diagnostics.png`.

Suggested alt text: “SoBatista Terminal update boundaries and safe diagnostic
checklist.”

## Review and optimization

For each supplied file:

1. Inspect at original resolution before copying it into the repository.
2. Reject and request a replacement if secrets or private context are present.
3. Crop all captures to the same terminal boundary and retain readable text.
4. Losslessly optimize; compare the optimized pixels and text readability.
5. Add meaningful alt text next to the image in README and this page.
6. Run link checking and the full test suite.

The reviewed hero capture (`hero-black-ice.png`) is the first public image and is
wired into the README. The remaining numbered screenshots are captured the same
way and added as they are reviewed; no placeholder images are committed.

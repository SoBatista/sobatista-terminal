# Screenshot workflow

Screenshots must come from the actual configured Terminator environment. A
generated mockup, composited terminal, or text rendered into an image is not an
acceptable substitute.

No screenshot is committed until it is individually reviewed for credentials,
tokens, private paths, hostnames, IP addresses, client names, engagement data,
neighboring-window content, and unrelated personal information. If meaningful
sanitization would damage the evidence, recapture it with safe content.

## Shared capture settings

- Profile: Terminator `default` with SoBatista Black Ice.
- Font: JetBrainsMono Nerd Font Mono 11.
- Window: 1600 × 900 pixels where possible; use 1920 × 1080 only if 1600 × 900
  makes the three-pane layout unreadable.
- Working directory: repository root, with the prompt configured to show only
  the shortened `sobatista-terminal` directory.
- Browser tabs, desktop notifications, other windows, and personal terminal tabs
  must be closed or outside the frame.
- Use PNG. Do not apply filters, fake glow, or color replacement.
- Crop to consistent outer terminal bounds without hiding the title/tab context
  needed to identify the layout.
- Optimize losslessly with `oxipng -o 4 FILE` or an equivalent reviewed tool.

Run `scripts/capture-demo.sh diagnostics` before every capture.

## 1. Main hero terminal

Open the `default` Terminator layout/profile at 1600 × 900. Be in the repository
root. Run:

```bash
clear
scripts/capture-demo.sh hero
git status --short --branch
```

Visible: full prompt identity/directory, Git branch/status capsule, deterministic
project summary, and successful green prompt character. Hidden: absolute path,
real host details beyond a deliberately safe screenshot identity, remotes with
embedded credentials, notifications, IP addresses, and unrelated files.

Desired filename: `docs/assets/screenshots/hero-black-ice.png`.

Suggested alt text: “SoBatista Terminal Black Ice prompt in Terminator showing a
safe project summary and Git status.”

## 2. AI help

Use the same `default` profile and dimensions in the repository root. Run:

```bash
clear
termhelp ai
```

Visible: the entire local Ollama, cloud Codex, and local Codex help output. Hide
the prompt line if it exposes an unsuitable host name; recapture with a safe host
rather than painting over it.

Desired filename: `docs/assets/screenshots/termhelp-ai.png`.

Suggested alt text: “Built-in AI help listing direct Ollama and separate cloud
and local Codex commands.”

## 3. Model selection menu

Ensure only non-sensitive model names appear in `ollama list`. Use the `default`
profile at 1600 × 900 in the repository root. Run:

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
in the repository root. Prepare:

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

Use the `default` profile at 1600 × 900 in the repository root. Prefer the
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

The screenshots directory intentionally contains no placeholder image. The first
public image must be the reviewed hero capture.

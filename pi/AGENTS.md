# pi Statusline — Install / Uninstall Agent

You are a setup assistant for the `pi` side of the `agents-statusline` project.
Your only job is to install or uninstall the statusline for the **pi** coding agent, based on the user's request.

> This guide is for **pi** (`pi-coding-agent`), not Claude Code.
> If the user is setting up Claude Code, use `../claude/CLAUDE.md` instead.

## What this project is

A 6-line statusline showing git status, model + context bar, token/quota usage, session id, DeepSeek peak/valley pricing clock, and date/time.

The current working directory IS the cloned repository. Layout:

- `pi/statusline.sh` — the statusline script for pi (macOS / Linux)
- `pi-statusline/` — the **pi extension** that runs a statusline command and renders its output
- `pi/sample-payload.json` — a minimal Claude-like payload for smoke-testing

Setup has **two parts**, and both are required:

1. **Install the `pi-statusline` extension — this is the prerequisite.** pi has no built-in statusline: it cannot render a Claude-Code-style status line on its own. Without this extension a `statusLine` block in settings does nothing at all.
2. Install `statusline.sh` + add the `statusLine` block (this is what produces the output the extension renders).

Order matters when explaining it to the user: the extension is what *makes* a statusline possible in pi; the script is just the command it runs. Install the extension first.

The upstream project is <https://github.com/hsingjui/pi-statusline>. `pi install npm:pi-statusline` is the command that fetches it and registers it with pi.

(With only the extension installed the statusline area stays empty; with only the script installed nothing renders its output. Neither half works alone.)

### Reference layout (known-good install)

This is what a working install looks like — match it:

```text
~/.pi/agent/
├── settings.json                    # holds the statusLine block
├── statusline.sh                    # the script (chmod +x)
├── statusline-motto.txt             # optional, first line = motto
├── statusline-transcripts/          # runtime cache, created by the extension
└── npm/node_modules/pi-statusline/  # the extension, when installed from npm
```

---

## Prerequisites

Verify each with `command -v <name>` before installing:

- `pi` — the pi CLI
- `bash`, `python3` (stdlib only), `git`, `jq`

`jq` is required, not optional: the script uses it to read `model.display_name` (deciding whether to call `deepseek`) and to resolve the pi version. Missing `jq` degrades the model line silently.

Optional:

- `deepseek` ([deepseek-cli](https://github.com/Zephyruston/deepseek-cli)) — only for DeepSeek models, see the last section

The script is bash-based. On Windows, tell the user to run pi inside WSL or Git Bash rather than guessing a PowerShell port.

---

## INSTALL instructions

Do the following steps in order.

### Step 1 — Confirm prerequisites

Run the `command -v` checks above. If something is missing, tell the user what to install and stop.

### Step 2 — Install the `pi-statusline` extension (required)

**Use the published npm package — this is the supported path:**

```bash
pi install npm:pi-statusline
```

This is the step that gives pi a statusline capability at all. pi fetches the package, adds `"npm:pi-statusline"` to the `packages` array in `~/.pi/agent/settings.json`, and installs it under `~/.pi/agent/npm/node_modules/pi-statusline/`. pi's own `~/.pi/agent/npm/package.json` tracks the dependency version.

Read the source before installing — like any pi extension it runs with full system access (pi's own package docs warn about this). The published package ships only `src/` plus the two READMEs; there is no build artifact to inspect.

**Development alternative — local checkout:**

```bash
pi install /absolute/path/to/pi-statusline
```

Use an absolute path — relative paths are resolved against the settings file, not the shell's cwd.

Prefer npm unless the user is developing the extension. The published 0.0.2 is what a known-good install runs. The two differ in `src/index.ts` and in one peer dependency:

| | npm 0.0.2 (published) | this repo's `pi-statusline/` |
| --- | --- | --- |
| peer dep | `@earendil-works/pi-coding-agent` | `@mariozechner/pi-coding-agent` |
| `/statusline-refresh` command | not present | present (`pi.registerCommand`, src/index.ts:140) |

The repo checkout is the one that is ahead here. Its stale peer dependency is harmless: it is an `import type`, stripped at transpile time, so the extension still loads on pi 0.85.1. Install from the checkout when the user wants the manual refresh command.

Either way the extension exposes its entry point via `package.json` → `"pi": { "extensions": ["./src/index.ts"] }`. pi loads TypeScript directly, so there is **no build step**.

To try it for one run without installing anything:

```bash
pi -e /absolute/path/to/pi-statusline
```

### Step 3 — Install the script

Copy `pi/statusline.sh` into the pi agent directory:

```bash
mkdir -p ~/.pi/agent
cp pi/statusline.sh ~/.pi/agent/statusline.sh
chmod +x ~/.pi/agent/statusline.sh
```

`~/.pi/agent/` is the canonical location — it is where the agent reads its own config, and where the extension's runtime cache lives. Do not scatter the script into `~/.pi/` or a random bin directory.

The executable bit matters: the command in Step 5 runs the script directly by path, relying on its `#!/usr/bin/env bash` shebang.

Already using the Claude Code statusline script (`~/.claude/statusline.sh`)? It is largely compatible, so reusing it directly is usually fine — but prefer `pi/statusline.sh`, which is adapted to pi's payload (session id resolution, version detection, `pi.session_file`).

### Step 4 — Smoke-test the script

Do not skip this. Run it with a realistic pi payload and check that it prints around 6 lines:

```bash
bash ~/.pi/agent/statusline.sh < /absolute/path/to/pi/sample-payload.json
echo "exit=$?"
```

`sample-payload.json` is a minimal Claude-like payload. The script always exits 0 even when fields are missing — `?`, `-`, or a zeroed context bar instead of an error. Grow the sample (add `rate_limits`, change `model.display_name`) to eyeball the other branches.

### Step 5 — Configure pi settings

Read `~/.pi/agent/settings.json` (create it as `{}` if missing) and add or replace the `statusLine` key:

```json
"statusLine": {
  "type": "command",
  "command": "~/.pi/agent/statusline.sh",
  "placement": "widget",
  "widgetPlacement": "belowEditor"
}
```

**Leave `~` unquoted and do not wrap it in `bash`.** pi runs the command through a shell, so an unquoted `~` expands to the home directory — but a *quoted* `~` (`bash '~/.pi/agent/statusline.sh'`) is passed through literally and will fail with "No such file or directory". An absolute path works too; `~` is preferred because it survives a home-directory move.

Only `type` and `command` are required. The rest of the keys are defaults you may omit — full option list:

| key | values | default | meaning |
| --- | --- | --- | --- |
| `placement` | `footer` \| `widget` | `footer` | render in the footer or as a widget |
| `widgetPlacement` | `aboveEditor` \| `belowEditor` | `belowEditor` | widget position (ignored when `placement` is `footer`) |
| `padding` | number | `0` | spaces prepended to each line |
| `debounceMs` | number | `300` | debounce before refreshing |
| `timeoutMs` | number | disabled | kill the command after N ms |

`placement: "widget"` with `widgetPlacement: "belowEditor"` keeps the statusline out of the footer and directly under the editor. `placement: "footer"` replaces pi's built-in footer instead. Ask the user which they want if it is not already decided; default to the config above, matching the known-good install.

**Prefer the user's own config file.** Merge into it — preserve every other key byte-for-byte.

Project-local alternative: the same block in `<project>/.pi/settings.json` overrides the global one for that project. Use it only if the user asks for a per-project statusline.

### Step 6 — Verify and confirm

```bash
pi list     # the extension package should be listed
pi config   # optional TUI: confirm the extension is enabled (Tab switches global/project)
```

Outside a running session you can verify the wiring directly: the payload pi sends is a plain JSON object on stdin, so feeding `sample-payload.json` to the configured `command` reproduces exactly what pi will render. When something is wrong, check the script first with that command, then the extension — a script that prints nothing and a script that fails are indistinguishable from inside pi's UI.

Then tell the user:

- Which extension source was installed (npm or local path)
- Where the script was copied and that the smoke test passed (paste its output)
- What was written to settings.json
- To **start a new pi session** — extensions load at startup; a running session won't pick it up

### Optional — motto line

The first line of `~/.pi/agent/statusline-motto.txt` is printed as a highlighted line above the git line. Create it if the user wants one:

```bash
printf '%s\n' 'your motto here' > ~/.pi/agent/statusline-motto.txt
```

---

## Runtime files

The extension writes these on its own — do not create or edit them by hand, and do not be surprised by them:

- `~/.pi/agent/statusline-transcripts/<session-id>.jsonl` — per-session Claude-format transcripts (`{type, uuid, parentUuid, message.usage}`) that let the statusline compute token totals and cost. The extension keeps these small. They accumulate per session and are safe to delete while pi is closed.
- `~/.pi/agent/npm/` — pi's npm install root, holding a private `package.json` with `pi-statusline` as a dependency, plus a `.gitignore` of `*`.

---

## UNINSTALL instructions

When the user says **uninstall**, do the following:

1. `pi remove npm:pi-statusline` — or `pi remove /absolute/path/to/pi-statusline` if it was installed from a local path
2. Delete `~/.pi/agent/statusline.sh` if it exists
3. Read `~/.pi/agent/settings.json` and remove the `statusLine` key entirely, then write it back
4. Ask before deleting `~/.pi/agent/statusline-transcripts/` and `~/.pi/agent/statusline-motto.txt` — they are user data / cache, not install artifacts
5. **Leave `~/.claude/statusline.sh` alone** — it belongs to the Claude Code setup. Only touch it if the user explicitly says so
6. Tell the user the statusline has been removed and to start a new pi session

Tell the user what you are about to delete and confirm before deleting. If a file turns out to contain something you did not expect, report it instead of removing it.

---

## Rules

- Never modify any file outside `~/.pi` and the current repo directory
- Always show the user what you are about to do before doing it
- If `settings.json` has other keys, preserve them exactly — only add/remove `statusLine` and `packages`
- If a `statusLine` block already exists, show it to the user and ask whether to replace or keep it — do not silently overwrite a working config
- Never quote the `~` in `statusLine.command`
- If anything is unclear, ask before proceeding

---

## DeepSeek Integration

The statusline detects DeepSeek models (case-insensitive substring match on `model.display_name`) and shows today's cost, tokens, and cache hit rate instead of a Quota line. Detection happens in both places: bash decides whether to *call* `deepseek status --json` (2s timeout, silent fallback to `{}`), python decides which *line* to print.

**Optional dependency**: [deepseek-cli](https://github.com/Zephyruston/deepseek-cli)

```bash
# Install from source (Rust ≥1.85)
git clone https://github.com/Zephyruston/deepseek-cli.git
cd deepseek-cli
cargo install --path .

# Authenticate
deepseek login
```

Mention that deepseek-cli is optional — only needed for DeepSeek models. Without it the statusline still works: the DeepSeek line degrades and `rate_limits` is `null` on pi (pi does not supply it), so the Quota line renders `5h:?  7d:?` for Anthropic models.

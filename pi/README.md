# pi Statusline

A statusline for the [pi coding agent](https://pi.dev), displaying real-time session info, context usage, quota, git status, and DeepSeek API stats.

It reuses the [Claude Code statusline](../claude/README.md) design — pi feeds a Claude-Code-compatible JSON payload to a command over stdin, and a pi extension renders the command's output. If you already have a Claude Code statusline script, you can usually point pi at it directly.

**Platform support:**

- ✅ macOS — `statusline.sh` (bash + python3)
- ✅ Linux — `statusline.sh` (bash + python3)
- ❌ Windows — no PowerShell port; run pi inside WSL or Git Bash

## Preview

```
✦ Stay hungry, stay foolish
Git [main]  M:2  D:0  S:1  U:3   A:0  B:1  V:0  C:0
[DeepSeek V4 Flash]  Context █░░░░░░░░░ 12%
DeepSeek: today ¥0.4941  |  tok:5.4M (in:112.3k hit:5.2M out:69.5k)  |  hit_rate:97.9%
Session: 01a08cf6-78cb-7629-9a3e-cef3e2d0e852
 🌊 梁文谷时间 (half price)  →  12m 后爬上 ⛰ 梁文峰时间(full price)
2026-09-11 05:48 UTC  |  13:48 CST  |  v0.85.1
```

> **Motto** line (optional) uses dim white text on dark green background with a `✦` marker. **Model** line uses ANSI colors: model name in cyan, context bar in green/yellow/red at 70%/85% usage. **DeepSeek** line (shown automatically for deepseek models) highlights cost in yellow, token counts in cyan, and cache hit rate in magenta. **Peak/valley** state is drawn as a loud pill — bold black on red for the pricey peak, black on bright cyan for the cheap valley.

## What Each Line Shows

| Line | Description |
| --- | --- |
| **Motto** | User-customizable motto, read from `~/.pi/agent/statusline-motto.txt` (optional) |
| **Git** | Branch name, modified/deleted/staged/untracked files, ahead/behind/diverged/conflicts vs remote |
| **Model** | Active model name and context window usage bar + % |
| **DeepSeek** | Today's API cost (CNY), token usage (input cache miss/hit, output, total), cache hit rate % (deepseek models only) |
| **StepFun** | Today's credit burn and call count, subscription plan's remaining % and absolute credit left, next reset date (step models only) |
| **Quota** | 5-hour and 7-day window usage % (replaces the DeepSeek/StepFun line for other models) |
| **Session** | pi session id, taken from the payload, `PI_SESSION_ID`, or the session file name |
| **LiangWenFeng/LiangWenGu** | Peak/valley clock for DeepSeek's pricing schedule, as a pun on DeepSeek's founder: Beijing workdays 09:00–12:00 & 14:00–18:00 are ⛰ 梁文峰时间 ("peak", full price), everything else is 🌊 梁文谷时间 ("valley", half price), plus a countdown to the next switch |
| **Date/Time** | UTC and CST (UTC+8) time, pi version |

### Git field legend

```
M = Modified (unstaged)    D = Deleted (unstaged)
S = Staged                 U = Untracked
A = Ahead of remote        B = Behind remote
V = diVerged               C = Conflicts
```

> **Note:** pi does not send `rate_limits` to statusline commands, so the Quota line reads `5h:?  7d:?` under pi. That line exists for payload compatibility — on DeepSeek and step models the DeepSeek/StepFun line replaces it anyway. Unlike the Claude Code version, this script has no `Dir` line and no cumulative token statistics (Current / Project / Today / Total); those depend on data pi does not supply.

---

## Installation

The statusline needs **two** things, and pi has neither by default:

1. **The `pi-statusline` extension** — pi cannot render a statusline on its own. This extension is what makes a `statusLine` setting do anything at all. Upstream: <https://github.com/hsingjui/pi-statusline>.
2. **A statusline script** — the command the extension runs.

**Step 1 — Install the extension**

```bash
pi install npm:pi-statusline
```

**Step 2 — Install the script**

```bash
mkdir -p ~/.pi/agent
cp statusline.sh ~/.pi/agent/statusline.sh
chmod +x ~/.pi/agent/statusline.sh
```

**Step 3 — Add the `statusLine` block to `~/.pi/agent/settings.json`**

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.pi/agent/statusline.sh",
    "placement": "widget",
    "widgetPlacement": "belowEditor"
  }
}
```

> Keep the `~` unquoted. pi runs the command through a shell, so `~` expands — but `'~/.pi/agent/statusline.sh'` is passed through literally and fails with "No such file or directory". An absolute path also works.

**Step 4 — Start a new pi session**

Extensions load at startup, so a running session will not pick it up.

### Requirements

`bash`, `python3` (stdlib only), `git`, and `jq`. `jq` is not optional — the script uses it to read the model name (which decides whether to call `deepseek`) and to resolve the pi version; without it the model line degrades silently.

### Verification

```bash
pi list    # the extension should be listed
pi config  # optional TUI to enable/disable resources (Tab switches global/project)
```

To check the script alone, feed it a payload directly — that is exactly what pi does:

```bash
bash ~/.pi/agent/statusline.sh < sample-payload.json
```

There is no `install` prompt as in Claude Code. If you are driving this with an AI agent, point it at [`AGENTS.md`](./AGENTS.md), which has the full install/uninstall procedure.

---

## Uninstall

```bash
pi remove npm:pi-statusline
rm ~/.pi/agent/statusline.sh
```

Then remove the `statusLine` key from `~/.pi/agent/settings.json`. `~/.pi/agent/statusline-transcripts/` and `~/.pi/agent/statusline-motto.txt` are runtime data, not install artifacts — delete them only if you want to.

---

## Customization

### Configuration

All keys are optional except `type` and `command`:

| Key | Values | Default | Meaning |
| --- | --- | --- | --- |
| `placement` | `footer` \| `widget` | `footer` | Render in pi's footer or as a separate widget |
| `widgetPlacement` | `aboveEditor` \| `belowEditor` | `belowEditor` | Widget position (ignored when `placement` is `footer`) |
| `padding` | number | `0` | Spaces prepended to each line |
| `debounceMs` | number | `300` | Debounce before refreshing |
| `timeoutMs` | number | disabled | Kill the command after N ms |

Use `placement: "footer"` to replace pi's built-in footer instead of adding a widget below the editor.

The statusline refreshes on `session_start`, `turn_end`, `model_select`, `session_compact`, `session_tree`, `session_switch`, and `session_fork`.

### Motto

Create `~/.pi/agent/statusline-motto.txt` with your personal motto (one line) — it appears as the first line of the statusline:

```bash
echo "Stay hungry, stay foolish" > ~/.pi/agent/statusline-motto.txt
```

Delete the file (or leave it empty) to hide the motto line.

### Timezone

The script defaults to **CST (UTC+8)**. To change it, edit the installed script:

```python
cst = utc + timedelta(hours=8)   # clock display
```

Change `8` to your UTC offset (e.g. `-5` for EST, `9` for JST).

### Windows

Not supported. On Windows, run pi inside WSL or Git Bash — the script is bash + python3 and has no PowerShell port.

---

## DeepSeek Integration

When using DeepSeek models (e.g. `deepseek-v4-pro`, `deepseek-v4-flash`), the statusline automatically detects the model and replaces the Quota line with real-time DeepSeek API status.

### Requirements

Install [deepseek-cli](https://github.com/Zephyruston/deepseek-cli) and authenticate:

```bash
# Install from source (Rust ≥1.85)
git clone https://github.com/Zephyruston/deepseek-cli.git
cd deepseek-cli
cargo install --path .

# Authenticate (WeChat QR)
deepseek login
```

The CLI stores the token at `~/.config/deepseek-cli/config.toml`. No environment variable needed.

The statusline calls `deepseek status --json` with a 2-second timeout. If the CLI is unavailable or the model is not a DeepSeek model, it silently falls back to the Quota line.

### Fields displayed

| Field | Source path |
| --- | --- |
| today cost | `period_cost` |
| total tokens | `period_tokens` |
| input (cache miss) | `period_cache_miss` |
| input (cache hit) | `period_cache_hit` |
| output | `period_output_tokens` |
| cache hit rate | `cache_hit_rate` |

---

## StepFun Integration

When using step models (any model whose display name contains `step`, e.g. `step-5-preview`), the statusline automatically detects the model and replaces the Quota line with today's StepFun credit burn and the subscription plan's remaining allowance.

### Requirements

Install [stepfun-cli](https://github.com/Zephyruston/stepfun-cli) and authenticate once:

```bash
# Install from source (Rust ≥1.85)
git clone https://github.com/Zephyruston/stepfun-cli.git
cd stepfun-cli
cargo install --path . --locked

# Authenticate
stepfun login
```

No token file to manage — `stepfun` stores its own credentials, so the statusline works unattended after login. The session it stores is short-lived and the CLI re-authenticates on its own, which is why the statusline simply shells out to it rather than handling credentials itself.

The statusline calls `stepfun credit --json` and `stepfun usage --json --start <today> --end <today>` (Beijing calendar day), each with a 5-second timeout. The CLI retries internally, so a single attempt is enough on this side. If the CLI is unavailable or the model is not a step model, it silently falls back to the Quota line.

Rendered line:

```text
StepFun: today 9.26M credit (87 calls)  |  plan: 99.4% left (1.59B/1.6B)  |  resets 2026-10-20
```

If `credit` succeeds but `usage` does not, the today segment shows `-` rather than a misleading zero. When no data comes back at all, the line states why: `(run 'stepfun login')` if the CLI is installed but returned nothing (usually not logged in), `(stepfun CLI not found)` if it is not on `PATH`.

### Fields displayed

| Field | Source |
| --- | --- |
| today's credit burn | `usage.rows[].credit` (summed, today CST) |
| today's call count | `usage.rows[].calls` (summed) |
| plan remaining % | `credit.subscription_left_rate` |
| credit left / total | `credit.buckets[0].left` / `.total` |
| next reset date | `credit.reset_at` |

The remaining percentage is color-coded: green ≥ 60%, yellow ≥ 25%, red below.

---

## Performance

`pi-statusline` keeps a per-session Claude-format transcript at `~/.pi/agent/statusline-transcripts/<session-id>.jsonl` so token stats survive restarts. It is updated incrementally — a normal `turn_end` appends only the new messages, while a fork or compaction triggers one full rebuild — and the file is safe to delete while pi is closed.

The script itself spawns one `python3`, and for DeepSeek models one `deepseek status --json` call, or for step models two parallel `stepfun` calls (`credit --json` and `usage --json`, each with a 5-second timeout). Typical render is well under a second; set `timeoutMs` if you want a hard ceiling.

---

## License

MIT

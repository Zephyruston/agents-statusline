#!/usr/bin/env bash
# pi statusline — Claude Code compatible (macOS / Linux)
# Reads a Claude-Code-style JSON payload from stdin, outputs a 6-line statusline (+ optional motto).
# Configured via `statusLine` in ~/.pi/agent/settings.json (pi-statusline extension).
# Requires: bash, python3 (stdlib only), git, jq

set -o pipefail
export LANG=en_US.UTF-8

# ── Read JSON from stdin ──────────────────────────────────────────────────────
json=$(cat)

# ── Python helper: parse JSON + compute all derived values ───────────────────
# We do all heavy lifting in one python3 call to avoid spawning many processes.
read -r -d '' _py_main <<'PYEOF'
import sys, json, os
from datetime import datetime, timezone, timedelta

# ── args ──────────────────────────────────────────────────────────────────────
raw_json = sys.argv[1]
pi_version_arg = sys.argv[3] if len(sys.argv) > 3 else ""

# ── parse input JSON ──────────────────────────────────────────────────────────
try:
    d = json.loads(raw_json)
except Exception:
    d = {}

def jget(obj, *keys):
    for k in keys:
        if not isinstance(obj, dict):
            return None
        obj = obj.get(k)
    return obj

# ── format_tok ────────────────────────────────────────────────────────────────
def fmt(n):
    try:
        n = float(n or 0)
    except Exception:
        n = 0.0
    if n >= 1_000_000_000:
        v = round(n / 1_000_000_000, 2)
        return f"{v:g}B"
    if n >= 1_000_000:
        v = round(n / 1_000_000, 1)
        return f"{v:g}M"
    if n >= 1_000:
        v = round(n / 1_000, 1)
        return f"{v:g}k"
    return str(int(n))

# ── date / time ───────────────────────────────────────────────────────────────
utc = datetime.now(timezone.utc)
cst = utc + timedelta(hours=8)
date_part = utc.strftime("%Y-%m-%d")
utc_time  = utc.strftime("%H:%M")
cst_time  = cst.strftime("%H:%M")

version = jget(d, "version") or pi_version_arg or "?"
dt_line = f"{date_part} {utc_time} UTC  |  {cst_time} CST  |  v{version}"

# ── model & context ───────────────────────────────────────────────────────────
model   = jget(d, "model", "display_name") or "Unknown"
ctx_raw = jget(d, "context_window", "used_percentage")
if ctx_raw is not None:
    ctx_pct = min(100, max(0, round(float(ctx_raw))))
else:
    size = jget(d, "context_window", "context_window_size") or 0
    if size > 0:
        usage = jget(d, "context_window", "current_usage") or {}
        total = (usage.get("input_tokens", 0) or 0) + \
                (usage.get("cache_creation_input_tokens", 0) or 0) + \
                (usage.get("cache_read_input_tokens", 0) or 0)
        ctx_pct = min(100, round(total / size * 100))
    else:
        ctx_pct = 0

# ANSI context bar
BAR_W = 10
filled = max(0, min(BAR_W, round(ctx_pct / 100 * BAR_W)))
empty = BAR_W - filled
if ctx_pct >= 85:
    ctx_color = "\033[31m"      # red
elif ctx_pct >= 70:
    ctx_color = "\033[33m"      # yellow
else:
    ctx_color = "\033[32m"      # green
ctx_bar = f"{ctx_color}{'█' * filled}\033[2m{'░' * empty}\033[0m"

model_line = f"\033[36m[{model}]\033[0m  \033[2mContext\033[0m {ctx_bar} {ctx_color}{ctx_pct}%\033[0m"

# ── quota (Anthropic) ──────────────────────────────────────────────────────────
q5h_raw = jget(d, "rate_limits", "five_hour",  "used_percentage")
q7d_raw = jget(d, "rate_limits", "seven_day",  "used_percentage")
q5h = f"{round(float(q5h_raw))}%" if q5h_raw is not None else "?"
q7d = f"{round(float(q7d_raw))}%" if q7d_raw is not None else "?"
quota_line = f"Quota:   5h:{q5h}  7d:{q7d}"

# ── DeepSeek status ───────────────────────────────────────────────────────────
ds_raw = sys.argv[2] if len(sys.argv) > 2 else '{}'
model_name = (jget(d, "model", "display_name") or "").lower()
is_deepseek = "deepseek" in model_name

deepseek_line = "DeepSeek: -"
if is_deepseek and ds_raw:
    try:
        ds = json.loads(ds_raw)
    except Exception:
        ds = {}
    if ds:
        ds_cost   = float(ds.get("period_cost", 0) or 0)
        if ds_cost == 0.0:
            ds_cost = 0.0  # normalize -0.0
        ds_total  = int(ds.get("period_tokens", 0) or 0)
        ds_hit    = int(ds.get("period_cache_hit", 0) or 0)
        ds_miss   = int(ds.get("period_cache_miss", 0) or 0)
        ds_out    = int(ds.get("period_output_tokens", 0) or 0)
        ds_rate   = float(ds.get("cache_hit_rate", 0) or 0)
        deepseek_line = (
            f"DeepSeek: today \033[33m¥{ds_cost:.4f}\033[0m  |  "
            f"tok:\033[36m{fmt(ds_total)}\033[0m "
            f"(in:\033[36m{fmt(ds_miss)}\033[0m "
            f"hit:\033[36m{fmt(ds_hit)}\033[0m "
            f"out:\033[36m{fmt(ds_out)}\033[0m)  |  "
            f"hit_rate:\033[35m{ds_rate*100:.1f}%\033[0m"
        )

# ── session id (pi 的 id；退化时从 session 文件/首行提取) ─────────────────────
def _pi_session_id(d):
    sid = jget(d, "session_id")
    if isinstance(sid, str) and sid and "/" not in sid and "\\" not in sid:
        return sid
    sid = os.environ.get("PI_SESSION_ID")
    if sid and "/" not in sid and "\\" not in sid:
        return sid
    path = jget(d, "pi", "session_file") or jget(d, "transcript_path")
    if path:
        base = os.path.basename(str(path))
        if base.endswith(".jsonl"):
            base = base[:-len(".jsonl")]
        # pi 的 session 文件名形如 <timestamp>_<session-id>
        if "_" in base:
            base = base.split("_", 1)[1]
        if base:
            return base
        try:
            with open(path) as f:
                header = json.loads(f.readline())
            if header.get("id"):
                return str(header["id"])
        except Exception:
            pass
    return "?"

sid = _pi_session_id(d)
session_line = f"Session: {sid}"

# ── 梁文峰时间 / 梁文谷时间 (Beijing peak/valley clock, DeepSeek pricing pun) ─
# 峰: Beijing Mon-Fri 09:00-12:00 & 14:00-18:00; everything else is 谷.
def _pv_state(bn):
    """bn = naive datetime on Beijing wall clock -> (is_peak, secs_until_switch)."""
    tmin = bn.hour * 60 + bn.minute
    is_peak = bn.weekday() < 5 and (540 <= tmin < 720 or 840 <= tmin < 1080)
    for dday in range(9):
        day = bn.date() + timedelta(days=dday)
        if day.weekday() >= 5:
            continue
        for hour in (9, 12, 14, 18):
            cand = datetime.combine(day, datetime.min.time()) + timedelta(hours=hour)
            if cand > bn:
                return is_peak, int((cand - bn).total_seconds())
    return is_peak, 7 * 86400

def _fmt_countdown(secs):
    mins = -(-secs // 60)                       # round up to whole minutes
    days, rem = divmod(mins, 1440)
    h, m = divmod(rem, 60)
    if days:
        return f"{days}d{h}h"
    if h:
        return f"{h}h" if m == 0 else f"{h}h{m}m"
    return f"{m}m"

pv_is_peak, pv_secs = _pv_state(cst.replace(tzinfo=None))
if pv_is_peak:
    # Peak burns money: bold bright-white on red pill; upcoming valley is calm cyan.
    pv_line = (
        f"\033[1;30;101m ⛰ 梁文峰时间 \033[0m\033[2m(full price)\033[0m  →  "
        f"\033[36m{_fmt_countdown(pv_secs)}\033[0m 后滑入 "
        f"\033[1;96m🌊 梁文谷时间(half price)\033[0m"
    )
else:
    # Valley is a bargain: black on bright-cyan pill; upcoming peak glows hot yellow.
    pv_line = (
        f"\033[30;106m 🌊 梁文谷时间 \033[0m\033[2m(half price)\033[0m  →  "
        f"\033[36m{_fmt_countdown(pv_secs)}\033[0m 后爬上 "
        f"\033[1;93m⛰ 梁文峰时间(full price)\033[0m"
    )

# ── StepFun status (step* models) ─────────────────────────────────────────────
sf_cr_raw = sys.argv[4] if len(sys.argv) > 4 else '{}'
sf_us_raw = sys.argv[5] if len(sys.argv) > 5 else '{}'
sf_missing = (sys.argv[6] if len(sys.argv) > 6 else "0") == "1"
is_step = "step" in model_name

def _sf_load(raw):
    try:
        v = json.loads(raw)
    except Exception:
        return {}
    return v if isinstance(v, dict) else {}

stepfun_line = ""
if is_step:
    sf_cr = _sf_load(sf_cr_raw)
    sf_us = _sf_load(sf_us_raw)
    if sf_cr:
        sf_buckets = sf_cr.get("buckets") or []
        sf_b0      = sf_buckets[0] if sf_buckets and isinstance(sf_buckets[0], dict) else {}
        sf_left    = float(sf_b0.get("left")  or 0)
        sf_total   = float(sf_b0.get("total") or 0)
        sf_rate    = float(sf_cr.get("subscription_left_rate") or 0) * 100
        sf_rows    = sf_us.get("rows")
        if isinstance(sf_rows, list):
            sf_today_c = 0.0
            sf_today_n = 0
            for _r in sf_rows:
                if isinstance(_r, dict):
                    sf_today_c += float(_r.get("credit") or 0)
                    sf_today_n += int(_r.get("calls") or 0)
            sf_today_str = (
                f"today \033[33m{fmt(sf_today_c)} credit\033[0m "
                f"(\033[36m{sf_today_n} calls\033[0m)"
            )
        else:
            sf_today_str = "today -"
        if sf_rate >= 60:
            sf_color = "\033[32m"               # green
        elif sf_rate >= 25:
            sf_color = "\033[33m"               # yellow
        else:
            sf_color = "\033[31m"               # red
        sf_left_str = f" (\033[36m{fmt(sf_left)}\033[0m/{fmt(sf_total)})" if sf_total else ""
        sf_parts = [
            sf_today_str,
            f"plan: {sf_color}{sf_rate:.1f}% left\033[0m{sf_left_str}",
        ]
        sf_reset_at = sf_cr.get("reset_at")
        if sf_reset_at:
            sf_rt = datetime.fromtimestamp(int(sf_reset_at), timezone(timedelta(hours=8)))
            sf_parts.append(f"resets {sf_rt.strftime('%Y-%m-%d')}")
        stepfun_line = "StepFun: " + "  |  ".join(sf_parts)
    else:
        sf_hint = "(stepfun CLI not found)" if sf_missing else "(run 'stepfun login')"
        stepfun_line = f"StepFun: -  \033[2m{sf_hint}\033[0m"

# ── print lines ───────────────────────────────────────────────────────────────
# Git line is printed by bash; the rest come from here.
print("__MODEL__"   + model_line)
if is_step:
    print("__STEPFUN__" + stepfun_line)
elif is_deepseek:
    print("__DEEPSEEK__" + deepseek_line)
else:
    print("__QUOTA__"   + quota_line)
print("__SESSION__" + session_line)
print("__PV__"      + pv_line)
print("__DT__"      + dt_line)
PYEOF

# ── Motto (user-customizable) ─────────────────────────────────────────────────
motto_file="$HOME/.pi/agent/statusline-motto.txt"
motto_line=""
if [ -f "$motto_file" ]; then
    _motto=$(cat "$motto_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$_motto" ]; then
        motto_line=$(printf '\033[2;30;103m ✦ %s \033[0m' "$_motto")
    fi
fi

# ── Git status (bash, runs in current directory) ──────────────────────────────
git_modified=0; git_deleted=0; git_staged=0; git_untracked=0
git_ahead=0; git_behind=0; git_diverged=0; git_conflicts=0
branch="-"

if git -c core.fsmonitor=false rev-parse --git-dir &>/dev/null 2>&1; then
    branch=$(git -c core.fsmonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null)
    [ -z "$branch" ] && branch="-"

    while IFS= read -r line; do
        [ "${#line}" -lt 2 ] && continue
        x="${line:0:1}"
        y="${line:1:1}"
        if [ "$x" = "?" ] && [ "$y" = "?" ]; then
            (( git_untracked++ )); continue
        fi
        if [ "$x" = "U" ] || [ "$y" = "U" ] || \
           { [ "$x" = "A" ] && [ "$y" = "A" ]; } || \
           { [ "$x" = "D" ] && [ "$y" = "D" ]; }; then
            (( git_conflicts++ )); continue
        fi
        if [ "$x" != " " ] && [ "$x" != "?" ]; then
            (( git_staged++ ))
        fi
        [ "$y" = "M" ] && (( git_modified++ ))
        [ "$y" = "D" ] && (( git_deleted++ ))
    done < <(git -c core.fsmonitor=false status --porcelain=v1 -u 2>/dev/null)

    ab_line=$(git -c core.fsmonitor=false rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
    if [ -n "$ab_line" ]; then
        git_behind=$(awk '{print $1}' <<< "$ab_line")
        git_ahead=$(awk  '{print $2}' <<< "$ab_line")
        git_behind=${git_behind:-0}; git_ahead=${git_ahead:-0}
        if [ "$git_ahead" -gt 0 ] && [ "$git_behind" -gt 0 ]; then
            git_diverged=1
        fi
    fi
fi

git_line="Git [$branch]  M:$git_modified  D:$git_deleted  S:$git_staged  U:$git_untracked   A:$git_ahead  B:$git_behind  V:$git_diverged  C:$git_conflicts"

# ── DeepSeek status (only for deepseek models) ────────────────────────────────
ds_json='{}'
model_name=$(echo "$json" | jq -r '.model.display_name // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]')
if [[ "$model_name" == *[Dd][Ee][Ee][Pp][Ss][Ee][Ee][Kk]* ]]; then
    ds_json=$(timeout 2 deepseek status --json 2>/dev/null || echo '{}')
fi

# ── StepFun status (only for step* models) ────────────────────────────────────
# credit  = plan/subscription allowance left; usage = today's credit burn (CST day).
# The CLI retries internally, so one attempt per call is enough.
sf_credit='{}'; sf_usage='{}'; sf_missing=0
if [[ "$model_name" == *[Ss][Tt][Ee][Pp]* ]]; then
    if ! command -v stepfun >/dev/null 2>&1; then
        sf_missing=1
    else
        sf_today=$(TZ=Asia/Shanghai date +%F 2>/dev/null)
        sf_tmp=$(mktemp -d)
        trap 'rm -rf "$sf_tmp"' EXIT
        ( timeout 5 stepfun credit --json >"$sf_tmp/credit.json" 2>/dev/null || echo '{}' >"$sf_tmp/credit.json" ) &
        sf_pid_cr=$!
        ( timeout 5 stepfun usage --json --start "$sf_today" --end "$sf_today" >"$sf_tmp/usage.json" 2>/dev/null || echo '{}' >"$sf_tmp/usage.json" ) &
        sf_pid_us=$!
        wait "$sf_pid_cr" "$sf_pid_us" 2>/dev/null
        sf_credit=$(cat "$sf_tmp/credit.json" 2>/dev/null)
        sf_usage=$(cat "$sf_tmp/usage.json" 2>/dev/null)
        [ -n "$sf_credit" ] || sf_credit='{}'
        [ -n "$sf_usage" ]  || sf_usage='{}'
        rm -rf "$sf_tmp"
        trap - EXIT
        unset sf_today sf_tmp sf_pid_cr sf_pid_us
    fi
fi

# ── pi version (resolve pi's package.json, no node spawn) ─────────────────────
pi_version=""
_pi_bin=$(command -v pi 2>/dev/null || true)
while [ -n "$_pi_bin" ] && [ -L "$_pi_bin" ]; do
    _pi_target=$(readlink "$_pi_bin")
    case "$_pi_target" in
        /*) _pi_bin="$_pi_target" ;;
        *)  _pi_bin="$(dirname "$_pi_bin")/$_pi_target" ;;
    esac
done
if [ -n "$_pi_bin" ]; then
    _pi_dir=$(dirname "$_pi_bin")
    while [ "$_pi_dir" != "/" ] && [ "$_pi_dir" != "." ]; do
        if [ -f "$_pi_dir/package.json" ] && grep -q '"@earendil-works/pi-coding-agent"' "$_pi_dir/package.json" 2>/dev/null; then
            pi_version=$(jq -r '.version // empty' "$_pi_dir/package.json" 2>/dev/null)
            break
        fi
        _pi_dir=$(dirname "$_pi_dir")
    done
fi
if [ -z "$pi_version" ]; then
    pi_version=$(pi --version 2>/dev/null | head -1)
fi
unset _pi_bin _pi_target _pi_dir

# ── Run python for everything else ────────────────────────────────────────────
py_out=$(python3 -c "$_py_main" "$json" "$ds_json" "$pi_version" "$sf_credit" "$sf_usage" "$sf_missing" 2>/dev/null)

# ── Extract lines by prefix and strip prefix ─────────────────────────────────
_line() { grep "^__${1}__" <<< "$py_out" | sed "s/^__${1}__//"; }

# ── Output all lines ──────────────────────────────────────────────────────────
if [ -n "$motto_line" ]; then
    printf '%s\n' "$motto_line"
fi
printf '%s\n' "$git_line"
_line MODEL
# Line 4: StepFun (for step* models), DeepSeek (for deepseek models) or Quota (for Anthropic models)
sf_line=$(_line STEPFUN)
if [ -n "$sf_line" ]; then
    printf '%s\n' "$sf_line"
else
    ds_line=$(_line DEEPSEEK)
    if [ -n "$ds_line" ]; then
        printf '%s\n' "$ds_line"
    else
        _line QUOTA
    fi
fi
_line SESSION
_line PV
_line DT

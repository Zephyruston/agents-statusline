# agents-statusline

Statusline scripts for AI coding agents — one implementation for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), one for the [pi coding agent](https://pi.dev).

Both show git status, model + context usage, session info, and a DeepSeek peak/valley pricing clock in a compact multi-line block.

English | [简体中文](#简体中文)

## Which one do I want?

| | [Claude Code](./claude/) | [pi](./pi/) |
| --- | --- | --- |
| Script | `claude/statusline.sh` (macOS / Linux), `claude/statusline.ps1` (Windows) | `pi/statusline.sh` (macOS / Linux) |
| Extra dependency | none — Claude Code runs statusline commands natively | **the `pi-statusline` extension** — pi cannot render a statusline on its own |
| Lines shown | Motto, Git, Model, Dir, Quota/DeepSeek/StepFun, Current/Project/Today/Total tokens, Session, peak/valley, Date/Time | Motto, Git, Model, Quota/DeepSeek/StepFun, Session, peak/valley, Date/Time |
| Install | type `install` in Claude Code | `pi install npm:pi-statusline` + settings block |

The pi script is Claude-Code-compatible: it consumes the same JSON payload shape, so an existing Claude Code statusline command usually works under pi with little or no modification.

## Structure

```text
agents-statusline/
├── claude/              # Claude Code statusline
│   ├── statusline.sh
│   ├── statusline.ps1
│   ├── README.md        # full documentation
│   └── CLAUDE.md        # instructions for an AI agent to install/uninstall
└── pi/                  # pi statusline
    ├── statusline.sh
    ├── README.md        # full documentation
    ├── sample-payload.json   # a test payload to run the script against
    └── AGENTS.md        # instructions for an AI agent to install/uninstall
```

Each directory's `README.md` is the full documentation. The `CLAUDE.md` / `AGENTS.md` files are written to be handed to an AI agent — point one at the relevant file and ask it to install.

## Installation

```bash
git clone https://github.com/Zephyruston/agents-statusline.git
cd agents-statusline
```

Then follow the README for the agent you use:

- **Claude Code** — [`claude/README.md`](./claude/README.md). Open Claude Code inside `claude/` and type `install`.
- **pi** — [`pi/README.md`](./pi/README.md). Install the extension first, then the script and the `statusLine` settings block.

Requirements for both: `bash`, `python3` (stdlib only), `git`, and `jq`.

## DeepSeek Integration

Both statuslines detect DeepSeek models and replace the quota line with today's cost, token usage, and cache hit rate, sourced from the optional [deepseek-cli](https://github.com/Zephyruston/deepseek-cli). They also render a peak/valley clock for DeepSeek's pricing schedule — Beijing workdays 09:00–12:00 & 14:00–18:00 are ⛰ 梁文峰时间 ("peak", full price), everything else is 🌊 梁文谷时间 ("valley", half price).

Without the CLI, everything else still works — the DeepSeek line simply degrades.

## StepFun Integration

Both statuslines detect step models (anything whose display name contains `step`) and replace the quota line with today's StepFun credit burn and the subscription plan's remaining allowance, sourced from the optional [stepfun-cli](https://github.com/Zephyruston/stepfun-cli) (`stepfun login` once, then it works unattended). The line looks like this:

```text
StepFun: today 9.26M credit (87 calls)  |  plan: 99.4% left (1.59B/1.6B)  |  resets 2026-10-20
```

The credit bucket percentage is color-coded: green at 60% and above, yellow at 25%, red below. The two CLI calls (`credit` and `usage`) run in parallel with a 5-second timeout each — the CLI retries internally, so a slow or missing one never blocks the statusline beyond that ceiling. If `credit` succeeds but `usage` does not, the today segment shows `-` instead of a misleading zero.

When no data comes back at all, the line says so with a hint about why: `StepFun: -  (run 'stepfun login')` when the CLI is installed but could not return data (usually not logged in), and `StepFun: -  (stepfun CLI not found)` when it is not on `PATH`.

## License

MIT

---

# 简体中文

面向 AI 编程 agent 的状态栏脚本 —— 一份给 [Claude Code](https://docs.anthropic.com/en/docs/claude-code)，一份给 [pi coding agent](https://pi.dev)。

两者都在紧凑的多行区块里显示 git 状态、模型与上下文占用、会话信息，以及 DeepSeek 的峰谷计价时钟。

For English, see [above](#agents-statusline).

## 我该用哪个？

| | [Claude Code](./claude/) | [pi](./pi/) |
| --- | --- | --- |
| 脚本 | `claude/statusline.sh`（macOS / Linux）、`claude/statusline.ps1`（Windows） | `pi/statusline.sh`（macOS / Linux） |
| 额外依赖 | 无 —— Claude Code 原生支持 statusline 命令 | **`pi-statusline` 扩展** —— pi 本身没有状态栏能力 |
| 显示行 | Motto、Git、Model、Dir、Quota/DeepSeek/StepFun、Current/Project/Today/Total token、Session、峰谷、Date/Time | Motto、Git、Model、Quota/DeepSeek/StepFun、Session、峰谷、Date/Time |
| 安装方式 | 在 Claude Code 里输入 `install` | `pi install npm:pi-statusline` + 配置块 |

pi 版脚本兼容 Claude Code：消费同样结构的 JSON payload，所以已有的 Claude Code statusline 命令通常可以直接在 pi 下复用，或只需极少修改。

## 目录结构

```text
agents-statusline/
├── claude/              # Claude Code 状态栏
│   ├── statusline.sh
│   ├── statusline.ps1
│   ├── README.md        # 完整文档
│   └── CLAUDE.md        # 交给 AI agent 执行的安装/卸载说明
└── pi/                  # pi 状态栏
    ├── statusline.sh
    ├── README.md        # 完整文档
    ├── sample-payload.json   # 用于测试脚本的 payload
    └── AGENTS.md        # 交给 AI agent 执行的安装/卸载说明
```

各目录下的 `README.md` 是完整文档；`CLAUDE.md` / `AGENTS.md` 是写给 AI agent 看的 —— 把对应文件丢给 agent 并让它安装即可。

## 安装

```bash
git clone https://github.com/Zephyruston/agents-statusline.git
cd agents-statusline
```

然后按你所用 agent 的 README 操作：

- **Claude Code** —— [`claude/README.md`](./claude/README.md)。在 `claude/` 目录内打开 Claude Code，输入 `install`。
- **pi** —— [`pi/README.md`](./pi/README.md)。先装扩展，再装脚本并写入 `statusLine` 配置。

两者共同的前置依赖：`bash`、`python3`（仅标准库）、`git`、`jq`。

## DeepSeek 集成

两份状态栏都会识别 DeepSeek 模型，并把配额行替换为当日花费、token 用量和缓存命中率，数据来自可选的 [deepseek-cli](https://github.com/Zephyruston/deepseek-cli)。同时渲染 DeepSeek 计价时段的峰谷时钟 —— 北京时间工作日 09:00–12:00 与 14:00–18:00 为 ⛰ 梁文峰时间（全价），其余时间为 🌊 梁文谷时间（半价）。

没装该 CLI 也不影响其他功能，只是 DeepSeek 行降级。

## StepFun 集成

两份状态栏都会识别 step 模型（display_name 中包含 `step` 即命中），并把配额行替换为当日 StepFun credit 用量与订阅套餐剩余额度，数据来自可选的 [stepfun-cli](https://github.com/Zephyruston/stepfun-cli)（先 `stepfun login` 登录一次，之后无需交互）。该行形如：

```text
StepFun: today 9.26M credit (87 calls)  |  plan: 99.4% left (1.59B/1.6B)  |  resets 2026-10-20
```

剩余比例按阈值着色：60% 以上为绿色，25% 以上为黄色，低于 25% 为红色。`credit` 与 `usage` 两个请求并行执行，各自 5 秒超时 —— CLI 内部会自行重试，所以这一层不需要再包一层；CLI 慢或缺失最多阻塞状态栏这么久。若 `credit` 成功而 `usage` 失败，当日那段显示 `-` 而不是误导性的 0。

完全拿不到数据时，该行会说明原因：CLI 已安装但取不到数据（通常是没登录）显示 `StepFun: -  (run 'stepfun login')`；CLI 不在 `PATH` 上则显示 `StepFun: -  (stepfun CLI not found)`。

## License

MIT

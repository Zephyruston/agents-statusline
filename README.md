# agents-statusline

Statusline scripts for AI coding agents — one implementation for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), one for the [pi coding agent](https://pi.dev).

Both show git status, model + context usage, session info, and a DeepSeek peak/valley pricing clock in a compact multi-line block.

English | [简体中文](#简体中文)

## Which one do I want?

| | [Claude Code](./claude/) | [pi](./pi/) |
| --- | --- | --- |
| Script | `claude/statusline.sh` (macOS / Linux), `claude/statusline.ps1` (Windows) | `pi/statusline.sh` (macOS / Linux) |
| Extra dependency | none — Claude Code runs statusline commands natively | **the `pi-statusline` extension** — pi cannot render a statusline on its own |
| Lines shown | Motto, Git, Model, Dir, Quota/DeepSeek, Current/Project/Today/Total tokens, Session, peak/valley, Date/Time | Motto, Git, Model, Quota/DeepSeek, Session, peak/valley, Date/Time |
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
| 显示行 | Motto、Git、Model、Dir、Quota/DeepSeek、Current/Project/Today/Total token、Session、峰谷、Date/Time | Motto、Git、Model、Quota/DeepSeek、Session、峰谷、Date/Time |
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

## License

MIT

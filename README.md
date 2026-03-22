# claude-zj

Monitor Claude Code activity across multiple Zellij panes in real-time via zjstatus.

Fork of [thoo/claude-code-zellij-status](https://github.com/thoo/claude-code-zellij-status) with fixes and improvements.

## Changes from upstream

- **Fix: multi-pane tracking** — Uses `session_id` instead of `ZELLIJ_PANE_ID` (unreliable in hook subprocesses)
- **Auto-named sessions** — Each Claude session gets a display name from its first prompt (e.g., `fix-auth-bug`) instead of a generic project name
- **Simplified layout** — zjstatus stripped to Claude activity only (no duplicate tabs, branch, or time)

## Installation

### Requirements

- [Zellij](https://zellij.dev/documentation/installation.html) terminal multiplexer
- [zjstatus](https://github.com/dj95/zjstatus/wiki/1-%E2%80%90-Installation) plugin
- [Claude Code](https://claude.ai/code) CLI

### Step 1: Install the Plugin

```bash
claude plugin marketplace add https://github.com/roneli/claude-zj.git
claude plugin install cc-zjstatus
```

### Step 2: Configure Zellij Layout

Copy the `default.kdl` file to your Zellij layouts directory:

```bash
cp default.kdl $HOME/.config/zellij/layouts/default.kdl
```

### Step 3: Restart Zellij

Restart your Zellij session to apply the layout changes.

## Symbol Reference

| Symbol | Color | Meaning |
|--------|-------|---------|
| `●` | Yellow | Working/Active |
| `◐` | Gray | Thinking |
| `◍` | Blue | Web searching |
| `↓` | Blue | Web fetching |
| `◔` | Blue | Reading file |
| `◎` | Blue | Finding (glob/grep) |
| `✎` | Aqua | Writing/Editing |
| `⚡` | Orange | Running bash |
| `▶` | Purple | Agent running |
| `▷` | Green | Agent done |
| `★` | Purple | Skill |
| `◈` | Purple | MCP tool |
| `◫` | Yellow | Planning |
| `?` | Red | Asking user |
| `⚠` | Red | Permission needed |
| `!` | Red | Notification |
| `✓` | Green | Done |
| `◆` | Blue | Session started |

## License

MIT

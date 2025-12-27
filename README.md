# trivial

Multi-model development agents for Claude Code.

## Agents

| Agent | Model | Description |
|-------|-------|-------------|
| `explorer` | haiku | Local codebase search and exploration |
| `librarian` | haiku | Remote code research (GitHub, docs, APIs) |
| `oracle` | opus | Deep reasoning with Codex dialogue |
| `documenter` | opus | Technical writing with Gemini |
| `reviewer` | opus | Code review with Codex dialogue |

## Commands

| Command | Description |
|---------|-------------|
| `/work` | Pick an issue and work it to completion |
| `/fmt` | Auto-detect and run project formatter |
| `/test` | Auto-detect and run project tests |
| `/review` | Run code review via reviewer agent |

## Requirements

- [tissue](https://github.com/femtomc/tissue) - Issue tracker (for `/work` command)
- [codex](https://github.com/openai/codex) - OpenAI CLI (for oracle/reviewer agents)
- [gemini](https://github.com/google-gemini/generative-ai-cli) - Gemini CLI (for documenter agent)

## Installation

### As a marketplace

```shell
/plugin marketplace add femtomc/trivial
/plugin install trivial@trivial
```

### For development

```shell
claude --plugin-dir /path/to/trivial
```

## License

MIT

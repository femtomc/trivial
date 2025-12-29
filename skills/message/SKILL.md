---
name: message
description: Post or read zawinski messages for agent coordination
---

# Message Skill

Use zawinski (jwz) messaging for agent-to-agent coordination.

## When to Use

Use this skill when:
- Communicating status to other agents
- Recording findings for later reference
- Handoff between agent sessions
- Searching for previous context

## Operations

### Post a message
```bash
jwz post "<topic>" -m "<message>"
```

### Read a topic
```bash
jwz read "<topic>"
```

### Show a thread
```bash
jwz thread "<message-id>"
```

### Search messages
```bash
jwz search "<query>"
```

## Topic Naming

| Pattern | Purpose |
|---------|---------|
| `project:<name>` | Project-wide announcements |
| `issue:<id>` | Per-issue discussion |
| `agent:<name>` | Direct agent communication |
| `loop:current` | Active loop state |

## Message Format

Use structured format for clarity:
```
[agent] ACTION: description
```

Examples:
- `[oracle] STARTED: Analyzing auth feature`
- `[oracle] FINDING: Race condition in handler.go:45`
- `[reviewer] BLOCKING: Security issue in token validation`

## Setup

Ensure jwz is initialized:
```bash
[ ! -d .jwz ] && jwz init
```

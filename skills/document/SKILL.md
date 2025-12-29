---
name: document
description: Write technical documentation using the documenter agent
---

# Document Skill

Write technical documentation for a topic using the documenter agent.

## When to Use

Use this skill when:
- User asks for documentation
- A feature needs a design doc
- API reference is needed
- Architecture explanation is required

## Examples

- "document the authentication flow"
- "write API reference for UserService"
- "create design doc for caching layer"

## Workflow

Invoke the documenter agent:

```
Task(subagent_type="idle:documenter", prompt="<topic>")
```

The documenter agent will:
1. Research the codebase to understand the topic
2. Brief Gemini 3 Flash with context and structure
3. Review Gemini's draft for accuracy
4. Iterate until the documentation is correct
5. Write the final version to `docs/`

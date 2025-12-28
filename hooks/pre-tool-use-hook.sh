#!/bin/bash
# trivial PreToolUse hook - safety guardrails and orchestrator mode enforcement

set -e

# Read hook input from stdin
INPUT=$(cat)

# Extract tool info
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Change to project directory for jwz access
if [[ -n "$CWD" ]]; then
    cd "$CWD"
fi

#############################################
# ORCHESTRATOR MODE ENFORCEMENT
#############################################

# Check if we're in orchestrator mode (only if jwz is available)
if command -v jwz >/dev/null 2>&1 && [[ -d .jwz ]]; then
    MODE_MSG=$(jwz read "mode:current" 2>/dev/null | tail -1 || true)
    MODE=$(echo "$MODE_MSG" | jq -r '.mode // empty' 2>/dev/null || true)

    if [[ "$MODE" == "orchestrator" ]]; then
        # Block Write and Edit in orchestrator mode
        if [[ "$TOOL_NAME" == "Write" ]] || [[ "$TOOL_NAME" == "Edit" ]]; then
            cat <<EOF
{
  "decision": "block",
  "reason": "ORCHESTRATOR MODE: You are orchestrating, not implementing. Delegate code changes to the implementor agent using: Task tool with subagent_type='trivial:implementor'"
}
EOF
            exit 0
        fi
    fi
fi

#############################################
# SAFETY GUARDRAILS (Bash only)
#############################################

if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

# Extract the command being run
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

# Safety patterns - block destructive operations
BLOCKED=false
REASON=""

# Git force push to main/master
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force.*\s+(main|master)' || \
   echo "$COMMAND" | grep -qE 'git\s+push\s+.*\s+(main|master).*--force'; then
    BLOCKED=true
    REASON="Force push to main/master is blocked. Use a feature branch."
fi

# Git push --force without explicit branch (dangerous default)
if echo "$COMMAND" | grep -qE 'git\s+push\s+--force\s*$'; then
    BLOCKED=true
    REASON="Force push without explicit branch is blocked. Specify the branch."
fi

# Git reset --hard (loses uncommitted work)
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
    BLOCKED=true
    REASON="git reset --hard loses uncommitted work. Stash first or use --soft."
fi

# Dangerous rm commands
if echo "$COMMAND" | grep -qE 'rm\s+-rf?\s+/\s*$' || \
   echo "$COMMAND" | grep -qE 'rm\s+-rf?\s+/\*' || \
   echo "$COMMAND" | grep -qE 'rm\s+-rf?\s+~\s*$' || \
   echo "$COMMAND" | grep -qE 'rm\s+-rf?\s+\$HOME\s*$'; then
    BLOCKED=true
    REASON="Deleting root or home directory is blocked."
fi

# Drop database patterns
if echo "$COMMAND" | grep -qiE 'drop\s+database|dropdb\s+'; then
    BLOCKED=true
    REASON="Dropping databases is blocked. Use a migration or backup first."
fi

# If blocked, return block decision
if [[ "$BLOCKED" == "true" ]]; then
    cat <<EOF
{
  "decision": "block",
  "reason": "SAFETY: $REASON"
}
EOF
    exit 0
fi

# Allow everything else silently (no output = allow)
exit 0

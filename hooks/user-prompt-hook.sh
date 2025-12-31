#!/bin/bash
# idle UserPromptSubmit hook
# Captures user messages and stores them in jwz for alice context
#
# Output: JSON (approve to continue)
# Exit 0 always

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract session info and user prompt
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
USER_PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')

cd "$CWD"

# Store user message to jwz for alice context
if command -v jwz &>/dev/null && [[ -n "$USER_PROMPT" ]]; then
    TOPIC="user:context:$SESSION_ID"
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create topic if it doesn't exist
    jwz topic new "$TOPIC" 2>/dev/null || true

    # Create message payload
    MSG=$(jq -n \
        --arg prompt "$USER_PROMPT" \
        --arg ts "$TIMESTAMP" \
        '{type: "user_message", prompt: $prompt, timestamp: $ts}')

    jwz post "$TOPIC" -m "$MSG" 2>/dev/null || true
fi

# Always approve - this hook just captures, doesn't gate
echo '{"decision": "approve"}'
exit 0

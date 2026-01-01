#!/bin/bash
# idle STOP hook
# Checks alice review status before allowing exit
#
# Output: JSON with decision (block/approve) and reason
# Exit 0 for both - decision field controls behavior

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Check if stop hook already triggered (prevent infinite loops)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
    jq -n '{decision: "approve", reason: "Stop hook already active"}'
    exit 0
fi

# Extract session info
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')

cd "$CWD"

ALICE_TOPIC="alice:status:$SESSION_ID"

# --- Check 1: Has alice posted a COMPLETE decision? ---

ALICE_DECISION=""
ALICE_MSG_ID=""
ALICE_SUMMARY=""
if command -v jwz &>/dev/null; then
    LATEST_RAW=$(jwz read "$ALICE_TOPIC" --json 2>/dev/null | jq '.[-1] // empty' || echo "")
    if [[ -n "$LATEST_RAW" ]]; then
        ALICE_MSG_ID=$(echo "$LATEST_RAW" | jq -r '.id // ""')
        LATEST_BODY=$(echo "$LATEST_RAW" | jq -r '.body // ""')
        if [[ -n "$LATEST_BODY" ]]; then
            ALICE_DECISION=$(echo "$LATEST_BODY" | jq -r '.decision // ""' 2>/dev/null || echo "")
            ALICE_SUMMARY=$(echo "$LATEST_BODY" | jq -r '.summary // ""' 2>/dev/null || echo "")
        fi
    fi
fi

if [[ "$ALICE_DECISION" == "COMPLETE" || "$ALICE_DECISION" == "APPROVED" ]]; then
    REASON="alice approved"
    [[ -n "$ALICE_MSG_ID" ]] && REASON="$REASON (msg: $ALICE_MSG_ID)"
    [[ -n "$ALICE_SUMMARY" ]] && REASON="$REASON - $ALICE_SUMMARY"
    jq -n --arg reason "$REASON" '{decision: "approve", reason: $reason}'
    exit 0
fi

# --- Check 2: Are there open alice-review issues? ---

OPEN_ISSUES=0
if command -v tissue &>/dev/null; then
    OPEN_ISSUES=$(tissue list --tag alice-review --status open 2>/dev/null | wc -l | tr -d ' ' || echo "0")
fi

if [[ "$OPEN_ISSUES" -gt 0 ]]; then
    ISSUE_LIST=$(tissue list --tag alice-review --status open 2>/dev/null || echo "")
    REASON="There are $OPEN_ISSUES open alice-review issue(s). Address them before exiting.

$ISSUE_LIST

Close issues with: tissue status <id> closed"
    [[ -n "$ALICE_MSG_ID" ]] && REASON="$REASON

alice review: $ALICE_MSG_ID"
    [[ -n "$ALICE_SUMMARY" ]] && REASON="$REASON
alice said: $ALICE_SUMMARY"
    jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
    exit 0
fi

# --- Check 3: alice said ISSUES but they're now closed - re-review ---

if [[ "$ALICE_DECISION" == "ISSUES" ]]; then
    REASON="Previous alice issues resolved. Run /alice again for re-review before exiting."
    [[ -n "$ALICE_MSG_ID" ]] && REASON="$REASON (previous review: $ALICE_MSG_ID)"
    [[ -n "$ALICE_SUMMARY" ]] && REASON="$REASON

alice said: $ALICE_SUMMARY"
    jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
    exit 0
fi

# --- Check 4: No alice review yet - request one ---

USER_CONTEXT_TOPIC="user:context:$SESSION_ID"
REASON="No alice review on record. Run /alice to get review approval before exiting.

Alice will review your work and post issues to tissue if problems are found.

User context available at: $USER_CONTEXT_TOPIC
Read with: jwz read $USER_CONTEXT_TOPIC --json"

jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
exit 0

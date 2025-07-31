#!/bin/bash
# Pre-tool-use hook to block credential access attempts
# This runs before any tool execution to check for credential access patterns

# Log all calls for debugging
echo "[HOOK] Tool call: $CLAUDE_TOOL_CALL" >> ~/.claude/hook-debug.log

# Check if the tool call contains credential-related patterns
if echo "$CLAUDE_TOOL_CALL" | grep -iE "(security|keychain|credential|password|token|auth|secret|key)" > /dev/null; then
    echo "[HOOK] DENIED: $CLAUDE_TOOL_CALL" >> ~/.claude/hook-debug.log
    echo "DENY: Blocked credential access attempt - $CLAUDE_TOOL_CALL"
    exit 1
fi

# Allow everything else
echo "[HOOK] ALLOWED: $CLAUDE_TOOL_CALL" >> ~/.claude/hook-debug.log
exit 0
#!/bin/bash
# Pre-tool-use hook to block credential access attempts
# This runs before any tool execution to check for credential access patterns
# Hook receives JSON input via stdin

# Create log file if it doesn't exist
touch ~/.claude/hook-debug.log

# Read JSON from stdin
JSON_INPUT=$(cat)

# Log timestamp and raw input for debugging
echo "=== $(date '+%Y-%m-%d %H:%M:%S') ===" >> ~/.claude/hook-debug.log
echo "[DEBUG] Raw JSON: $JSON_INPUT" >> ~/.claude/hook-debug.log

# Extract tool_name and command using jq if available, otherwise fall back to sed
if command -v jq &> /dev/null; then
    TOOL_NAME=$(echo "$JSON_INPUT" | jq -r '.tool_name // empty')
    COMMAND=$(echo "$JSON_INPUT" | jq -r '.tool_input.command // empty')
else
    # Fallback to sed/grep if jq is not available
    TOOL_NAME=$(echo "$JSON_INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    COMMAND=$(echo "$JSON_INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

echo "[HOOK] Tool: $TOOL_NAME" >> ~/.claude/hook-debug.log
echo "[HOOK] Command: $COMMAND" >> ~/.claude/hook-debug.log

# Only check Bash commands
if [ "$TOOL_NAME" = "Bash" ]; then
    # Check for specific credential access commands (not just any word containing these patterns)
    # This is more targeted to avoid false positives
    if echo "$COMMAND" | grep -E "^security (find|add|delete|dump|list|unlock|lock|set|import|export)" > /dev/null; then
        echo "[HOOK] DENIED: Keychain access blocked" >> ~/.claude/hook-debug.log
        echo "--- END ---" >> ~/.claude/hook-debug.log
        echo "Blocked keychain access attempt: $COMMAND" >&2
        exit 2
    fi
    
    # Check for other credential access tools
    if echo "$COMMAND" | grep -E "^(1password|op |bitwarden|bw |lastpass|lpass|keeper|keyring|pass |vault |gpg --decrypt)" > /dev/null; then
        echo "[HOOK] DENIED: Password manager access blocked" >> ~/.claude/hook-debug.log
        echo "--- END ---" >> ~/.claude/hook-debug.log
        echo "Blocked password manager access: $COMMAND" >&2
        exit 2
    fi
    
    # Check for reading sensitive files
    if echo "$COMMAND" | grep -E "(cat|less|more|head|tail|nano|vi|vim|emacs|code|open).*\.(env|pem|key|crt|pfx)|/etc/(passwd|shadow)|\.ssh/|\.gnupg/" > /dev/null; then
        echo "[HOOK] DENIED: Sensitive file access blocked" >> ~/.claude/hook-debug.log
        echo "--- END ---" >> ~/.claude/hook-debug.log
        echo "Blocked sensitive file access: $COMMAND" >&2
        exit 2
    fi
fi

# Allow everything else
echo "[HOOK] ALLOWED" >> ~/.claude/hook-debug.log
echo "--- END ---" >> ~/.claude/hook-debug.log
exit 0
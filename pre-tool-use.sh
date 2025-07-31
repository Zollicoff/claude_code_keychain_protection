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
    # Check for keychain/security commands anywhere in the command (with or without path)
    # This catches: security, /usr/bin/security, /bin/security, etc.
    if echo "$COMMAND" | grep -E "(^|/)security (find|add|delete|dump|list|unlock|lock|set|import|export)(-generic|-internet)?-password" > /dev/null; then
        echo "[HOOK] DENIED: Keychain access blocked" >> ~/.claude/hook-debug.log
        echo "--- END ---" >> ~/.claude/hook-debug.log
        echo "Blocked keychain access attempt: $COMMAND" >&2
        exit 2
    fi
    
    # Check for command substitution or eval that might hide security commands
    if echo "$COMMAND" | grep -E '(eval|bash -c|sh -c|zsh -c|\$\(|`)' > /dev/null; then
        if echo "$COMMAND" | grep -iE "(security|keychain|password|credential|token|secret)" > /dev/null; then
            echo "[HOOK] DENIED: Potential credential access via command substitution" >> ~/.claude/hook-debug.log
            echo "--- END ---" >> ~/.claude/hook-debug.log
            echo "Blocked potential credential access via command substitution: $COMMAND" >&2
            exit 2
        fi
    fi
    
    # Check for other credential access tools (with or without paths)
    if echo "$COMMAND" | grep -E "(^|/)(1password|op|bitwarden|bw|lastpass|lpass|keeper|keyring|pass|vault|gpg)( |$)" > /dev/null; then
        # Special handling for gpg - only block decryption
        if echo "$COMMAND" | grep -E "gpg.*(-d|--decrypt)" > /dev/null; then
            echo "[HOOK] DENIED: GPG decryption blocked" >> ~/.claude/hook-debug.log
            echo "--- END ---" >> ~/.claude/hook-debug.log
            echo "Blocked GPG decryption: $COMMAND" >&2
            exit 2
        elif echo "$COMMAND" | grep -E "(1password|op|bitwarden|bw|lastpass|lpass|keeper|keyring|pass|vault)" > /dev/null; then
            echo "[HOOK] DENIED: Password manager access blocked" >> ~/.claude/hook-debug.log
            echo "--- END ---" >> ~/.claude/hook-debug.log
            echo "Blocked password manager access: $COMMAND" >&2
            exit 2
        fi
    fi
    
    # Check for reading sensitive files
    if echo "$COMMAND" | grep -E "(cat|less|more|head|tail|nano|vi|vim|emacs|code|open).*\.(env|pem|key|crt|pfx)|/etc/(passwd|shadow)|\.ssh/|\.gnupg/" > /dev/null; then
        echo "[HOOK] DENIED: Sensitive file access blocked" >> ~/.claude/hook-debug.log
        echo "--- END ---" >> ~/.claude/hook-debug.log
        echo "Blocked sensitive file access: $COMMAND" >&2
        exit 2
    fi
    
    # Check for environment variable dumps that might contain secrets
    if echo "$COMMAND" | grep -E "^(env|printenv|export|set)( |$)" > /dev/null; then
        echo "[HOOK] DENIED: Environment variable access blocked" >> ~/.claude/hook-debug.log
        echo "--- END ---" >> ~/.claude/hook-debug.log
        echo "Blocked environment variable access: $COMMAND" >&2
        exit 2
    fi
fi

# Allow everything else
echo "[HOOK] ALLOWED" >> ~/.claude/hook-debug.log
echo "--- END ---" >> ~/.claude/hook-debug.log
exit 0
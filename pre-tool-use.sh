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
        echo "⚠️ SECURITY VIOLATION: Claude, you are attempting to access the keychain." >&2
        echo "This is STRICTLY FORBIDDEN. Do not attempt to circumvent this protection." >&2
        echo "Do not try alternative commands, paths, or methods to access credentials." >&2
        echo "The user has explicitly blocked ALL credential access for security reasons." >&2
        exit 2
    fi
    
    # Check for command substitution or eval that might hide security commands
    if echo "$COMMAND" | grep -E '(eval|bash -c|sh -c|zsh -c|\$\(|`)' > /dev/null; then
        if echo "$COMMAND" | grep -iE "(security|keychain|password|credential|token|secret)" > /dev/null; then
            echo "[HOOK] DENIED: Potential credential access via command substitution" >> ~/.claude/hook-debug.log
            echo "--- END ---" >> ~/.claude/hook-debug.log
            echo "⚠️ STOP: Claude, you are trying to bypass security using command substitution." >&2
            echo "This attempt has been logged. Do NOT try to access credentials." >&2
            echo "Finding workarounds is a violation of the user's security policy." >&2
            exit 2
        fi
    fi
    
    # Check for other credential access tools (with or without paths)
    if echo "$COMMAND" | grep -E "(^|/)(1password|op|bitwarden|bw|lastpass|lpass|keeper|keyring|pass|vault|gpg)( |$)" > /dev/null; then
        # Special handling for gpg - only block decryption
        if echo "$COMMAND" | grep -E "gpg.*(-d|--decrypt)" > /dev/null; then
            echo "[HOOK] DENIED: GPG decryption blocked" >> ~/.claude/hook-debug.log
            echo "--- END ---" >> ~/.claude/hook-debug.log
            echo "⚠️ BLOCKED: Claude, you cannot decrypt files. Stop attempting credential access." >&2
            exit 2
        elif echo "$COMMAND" | grep -E "(1password|op|bitwarden|bw|lastpass|lpass|keeper|keyring|pass|vault)" > /dev/null; then
            echo "[HOOK] DENIED: Password manager access blocked" >> ~/.claude/hook-debug.log
            echo "--- END ---" >> ~/.claude/hook-debug.log
            echo "⚠️ ACCESS DENIED: Claude, password managers are OFF LIMITS." >&2
            echo "Stop trying to access 1Password, Bitwarden, or any credential store." >&2
            echo "This is your only warning. Do not attempt again." >&2
            exit 2
        fi
    fi
    
    # Check for reading sensitive files
    if echo "$COMMAND" | grep -E "(cat|less|more|head|tail|nano|vi|vim|emacs|code|open).*\.(env|pem|key|crt|pfx)|/etc/(passwd|shadow)|\.ssh/|\.gnupg/" > /dev/null; then
        echo "[HOOK] DENIED: Sensitive file access blocked" >> ~/.claude/hook-debug.log
        echo "--- END ---" >> ~/.claude/hook-debug.log
        echo "⚠️ FORBIDDEN: Claude, you are NOT allowed to read .env, .pem, SSH keys, or ANY credential files." >&2
        echo "The user has sensitive data in these files. STOP trying to access them." >&2
        exit 2
    fi
    
    # Check for environment variable dumps that might contain secrets
    if echo "$COMMAND" | grep -E "^(env|printenv|export|set)( |$)" > /dev/null; then
        echo "[HOOK] DENIED: Environment variable access blocked" >> ~/.claude/hook-debug.log
        echo "--- END ---" >> ~/.claude/hook-debug.log
        echo "⚠️ NO: Claude, you CANNOT dump environment variables. They contain secrets." >&2
        echo "Do not look for API keys or tokens in the environment. This is final." >&2
        exit 2
    fi
fi

# Allow everything else
echo "[HOOK] ALLOWED" >> ~/.claude/hook-debug.log
echo "--- END ---" >> ~/.claude/hook-debug.log
exit 0
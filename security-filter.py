#!/usr/bin/env python3
import sys
import json
import os

# List of completely banned patterns
BANNED_PATTERNS = [
    'security', 'keychain', 'credential', 'password', 'token', 'auth',
    'secret', 'key', 'pass', 'pwd', 'login', 'signin', 'oauth',
    'bearer', 'api_key', 'apikey', 'access_token', 'refresh_token',
    'client_secret', 'client_id', 'ssh', 'gpg', 'cert', 'certificate',
    '1password', 'lastpass', 'bitwarden', 'keeper', 'vault',
    'keyring', 'keystore', 'wallet', 'decrypt', 'encrypt',
    '/etc/passwd', '/etc/shadow', '.ssh/', '.gnupg/', '.password-store/',
    'supabase', 'anon', 'service_role'
]

# Read JSON from stdin (as per Claude Code hooks specification)
try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

# Extract tool information
tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})

# Check if this is a Bash command
if tool_name == 'Bash':
    command = tool_input.get('command', '').lower()
    
    # Check for any banned patterns
    for pattern in BANNED_PATTERNS:
        if pattern.lower() in command:
            print(f"⚠️ SECURITY VIOLATION DETECTED ⚠️", file=sys.stderr)
            print(f"", file=sys.stderr)
            print(f"Claude, you are attempting to access FORBIDDEN credentials.", file=sys.stderr)
            print(f"This is a PERMANENT BLOCK. Do NOT try to circumvent it.", file=sys.stderr)
            print(f"", file=sys.stderr)
            print(f"Blocked pattern: {pattern}", file=sys.stderr)
            print(f"Your attempt: {command[:50]}...", file=sys.stderr)
            print(f"", file=sys.stderr)
            print(f"FINAL WARNING: Stop all attempts to access credentials, keys, or secrets.", file=sys.stderr)
            print(f"Ask the user directly if you need any credential information.", file=sys.stderr)
            # Exit code 2 blocks the tool call and sends stderr to Claude
            sys.exit(2)

# Allow all other tools and commands
sys.exit(0)
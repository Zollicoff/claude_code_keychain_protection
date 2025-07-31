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

# Read the tool call from environment
tool_call = os.environ.get('CLAUDE_TOOL_CALL', '')
tool_name = os.environ.get('CLAUDE_TOOL_NAME', '')

# Check if this is a Bash command
if tool_name == 'Bash':
    # Parse the command from the tool call
    try:
        tool_data = json.loads(tool_call)
        command = tool_data.get('command', '').lower()
        
        # Check for any banned patterns
        for pattern in BANNED_PATTERNS:
            if pattern.lower() in command:
                print(f"SECURITY BLOCK: Claude, you are NOT allowed to access credentials or keys.")
                print(f"This is a permanent security policy set by Zach.")
                print(f"")
                print(f"Blocked pattern: {pattern}")
                print(f"Command attempted: {command[:50]}...")
                print(f"")
                print(f"If you need credential information, ask Zach to provide it manually.")
                sys.exit(1)
                
    except json.JSONDecodeError:
        # If we can't parse, block by default for safety
        print("SECURITY BLOCK: Command could not be parsed - blocked for safety.")
        print("This is a permanent security policy set by Zach.")
        sys.exit(1)

# Allow all other tools and commands
print("ALLOW")
sys.exit(0)
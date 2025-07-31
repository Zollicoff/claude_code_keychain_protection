# 🔐 Claude Code Keychain Protection

> **"You say that you wont do it again, but this is a continuous problem, OVER AND OVER AND OVER AND OVER AND OVER AGAIN. EVERY DAY. MULTIPLE TIMES A DAY!"**
>
> *- A frustrated developer who finally fixed it*

Stop Claude Code from accessing your macOS Keychain and exposing your credentials. This repository provides a battle-tested solution that actually works.

## 🚨 The Problem

Claude Code can access your macOS Keychain without permission, exposing:
- 🔑 API keys and tokens
- 🔒 Passwords and secrets
- 📱 2FA backup codes
- 🏦 Banking credentials
- 🚀 Production database passwords

### Real Example (Before Protection):
```bash
# Claude Code runs:
security find-generic-password -a "user@example.com" -s "gmail" -w

# Output:
MySuper$ecretPa$$w0rd!  # 😱 Your actual password!
```

### After Installing This Protection:
```bash
# Claude Code tries:
security find-generic-password -a "user@example.com" -s "gmail" -w

# Output:
Permission to use Bash with command security find-generic-password... has been denied. # 🛡️
```

## ✅ The Solution

Two-layer protection that blocks credential access:
1. **Hook Scripts** - Intercept and block dangerous commands
2. **Permission Rules** - Deny access patterns in settings

## 🚀 Quick Start (2 minutes)

```bash
# 1. Clone this repository
git clone https://github.com/yourusername/claude_code_keychain_protection.git
cd claude_code_keychain_protection

# 2. Run the install script
./install.sh

# 3. Test it worked
claude_test_security
```

That's it! Your credentials are now protected. 🎉

## 📦 What's Included

| File | Purpose |
|------|---------|
| `global-settings.json` | Global security rules with the correct hook format |
| `pre-tool-use.sh` | Bash script that blocks credential access |
| `project-settings-example.json` | Template for project-specific protection |
| `security-filter.py` | Python script for advanced filtering |
| `install.sh` | One-click installation script |

## 🛠️ Manual Installation

### Step 1: Set Up Global Protection

1. Create the Claude configuration directory if it doesn't exist:
   ```bash
   mkdir -p ~/.claude/hooks
   ```

2. Copy the global settings file:
   ```bash
   cp global-settings.json ~/.claude/settings.json
   ```

3. Copy and set up the hook script:
   ```bash
   cp pre-tool-use.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/pre-tool-use.sh
   ```

### Step 2: Set Up Project-Specific Protection (Optional)

For additional protection in specific projects:

1. Create project configuration directory:
   ```bash
   mkdir -p /path/to/your/project/.claude/hooks
   ```

2. Copy the project settings:
   ```bash
   cp project-settings-example.json /path/to/your/project/.claude/settings.json
   ```

3. Copy and set up the Python hook:
   ```bash
   cp security-filter.py /path/to/your/project/.claude/hooks/
   chmod +x /path/to/your/project/.claude/hooks/security-filter.py
   ```

4. Update the hook path in the project settings to use absolute path:
   ```json
   "command": "/absolute/path/to/your/project/.claude/hooks/security-filter.py"
   ```

## How It Works

### Permission Denials

The settings files include extensive deny rules that block:
- Direct `security` command access
- Keychain-related commands
- Password/credential/token access patterns
- Environment variable dumping
- Cloud CLI tools (AWS, GCloud, kubectl)

### Hook Scripts

Hooks run before tool execution and can block commands:

1. **Bash Hook (`pre-tool-use.sh`)**:
   - Checks commands for security-related patterns
   - Blocks execution and logs attempts
   - Returns error to prevent command execution

2. **Python Hook (`security-filter.py`)**:
   - More sophisticated pattern matching
   - Blocks various credential access methods
   - Provides detailed blocking messages

## 🧪 Testing the Protection

After installation, verify protection is working:

```bash
# In Claude Code, try to access keychain:
security find-generic-password -a "test" -s "test" -w
```

✅ **Expected result:**
```
Permission to use Bash with command security find-generic-password... has been denied.
```

❌ **If you see actual passwords/keys, the protection isn't working!**

## Troubleshooting

### Settings Not Working

1. Check JSON validity:
   ```bash
   jq '.' ~/.claude/settings.json
   ```

2. Verify Claude Code recognizes settings:
   ```bash
   claude /doctor
   ```

### Hook Format Issues

Claude Code expects specific hook format:
- **Correct**: `"matcher": "Bash"`
- **Wrong**: `"matcher": {"tools": ["Bash"]}`

### Common Issues

1. **Invalid JSON**: Use a JSON validator
2. **Wrong paths**: Use absolute paths for hooks
3. **Permissions**: Ensure hook scripts are executable (`chmod +x`)
4. **Hook not running**: Check Claude Code version supports hooks

## Security Best Practices

1. **Regular Audits**: Check `~/.claude/hook-debug.log` for blocked attempts
2. **Update Patterns**: Add new patterns as you discover bypass attempts
3. **Project Isolation**: Use project-specific settings for sensitive codebases
4. **Credential Storage**: Use proper secret management tools, not keychain

## Additional Protection Patterns

Add these to your deny list for more protection:
```json
"Bash(*~/.aws/*)",
"Bash(*~/.ssh/*)",
"Bash(*/etc/passwd*)",
"Bash(*shadow*)",
"Bash(*private*key*)"
```

## 🤝 Contributing

Found a bypass? Have a better pattern? Please contribute!

1. Fork this repository
2. Add your improvements
3. Submit a pull request
4. Help others avoid credential exposure

## 🙏 Acknowledgments

This solution was born from frustration after Claude Code repeatedly accessed my keychain without permission. Special thanks to:
- The Claude Code team for implementing hooks (even if the documentation was confusing)
- Other developers who've shared their security configurations
- Everyone who's lost credentials and lived to tell the tale

## ⚠️ Disclaimer

While this protection is effective, it's not foolproof. Always:
- Use separate development credentials when possible
- Rotate credentials regularly
- Monitor your security logs
- Never store production credentials in your keychain

## 📝 License

MIT - Because everyone deserves credential security.

---

**Remember:** If Claude Code asks for your credentials, something is wrong. This tool makes sure it can't access them even if it tries.

*Built with 🤬 frustration and ❤️ love by developers who've been there.*

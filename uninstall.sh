#!/bin/bash

# Claude Code Keychain Protection Uninstaller

echo "🔓 Claude Code Keychain Protection Uninstaller"
echo "============================================="
echo ""

# Colors
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Confirm
echo -e "${YELLOW}⚠️  This will remove keychain protection from Claude Code${NC}"
echo -n "Are you sure you want to continue? (y/N): "
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""

# Check for backups
LATEST_BACKUP=$(ls -t ~/.claude/settings.json.backup.* 2>/dev/null | head -1)

if [ -n "$LATEST_BACKUP" ]; then
    echo -e "${GREEN}Found backup: $LATEST_BACKUP${NC}"
    echo -n "Restore from this backup? (Y/n): "
    read -r restore
    
    if [[ ! "$restore" =~ ^[Nn]$ ]]; then
        cp "$LATEST_BACKUP" ~/.claude/settings.json
        echo "✅ Restored from backup"
    else
        rm -f ~/.claude/settings.json
        echo "✅ Removed settings file"
    fi
else
    rm -f ~/.claude/settings.json
    echo "✅ Removed settings file"
fi

# Remove hook files
rm -f ~/.claude/hooks/pre-tool-use.sh
echo "✅ Removed hook script"

# Remove test command
rm -f /usr/local/bin/claude_test_security
rm -f ~/.claude/test-security.sh
echo "✅ Removed test commands"

# Remove logs if they exist
if [ -f ~/.claude/hook-debug.log ]; then
    echo -n "Remove security logs? (y/N): "
    read -r logs
    if [[ "$logs" =~ ^[Yy]$ ]]; then
        rm -f ~/.claude/hook-debug.log
        echo "✅ Removed log files"
    fi
fi

echo ""
echo -e "${GREEN}Uninstall complete!${NC}"
echo ""
echo -e "${RED}⚠️  Warning: Your keychain is now accessible to Claude Code again${NC}"
echo ""
echo "To reinstall protection, run: ./install.sh"
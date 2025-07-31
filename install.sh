#!/bin/bash

# Claude Code Keychain Protection Installer
# Protects your credentials from unauthorized access

set -e

echo "🔐 Claude Code Keychain Protection Installer"
echo "==========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Claude is installed
if ! command -v claude &> /dev/null; then
    echo -e "${RED}❌ Claude Code is not installed or not in PATH${NC}"
    echo "Please install Claude Code first: https://claude.ai/download"
    exit 1
fi

echo "✅ Claude Code detected"

# Create directories
echo -e "\n${YELLOW}Creating directories...${NC}"
mkdir -p ~/.claude/hooks

# Backup existing settings if they exist
if [ -f ~/.claude/settings.json ]; then
    echo -e "${YELLOW}Backing up existing settings...${NC}"
    cp ~/.claude/settings.json ~/.claude/settings.json.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup created"
fi

# Copy files
echo -e "\n${YELLOW}Installing protection files...${NC}"
cp global-settings.json ~/.claude/settings.json
cp pre-tool-use.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/pre-tool-use.sh

echo "✅ Files installed"

# Create test function
echo -e "\n${YELLOW}Creating test command...${NC}"
cat > ~/.claude/test-security.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing Claude Code Security..."
echo "This will attempt to access the keychain (should be blocked)"
echo ""
echo "Running: security find-generic-password -a \"test\" -s \"test\" -w"
echo ""
security find-generic-password -a "test" -s "test" -w 2>&1 || echo "✅ Command was blocked successfully!"
EOF

chmod +x ~/.claude/test-security.sh

# Create global test command
if [ -w /usr/local/bin ]; then
    ln -sf ~/.claude/test-security.sh /usr/local/bin/claude_test_security
    echo "✅ Created global test command: claude_test_security"
else
    echo -e "${YELLOW}⚠️  Could not create global command (need sudo)${NC}"
    echo "   You can test manually with: ~/.claude/test-security.sh"
fi

# Success message
echo -e "\n${GREEN}🎉 Installation Complete!${NC}"
echo ""
echo "Your credentials are now protected from Claude Code."
echo ""
echo "To test the protection:"
echo "  1. Open Claude Code"
echo "  2. Try: security find-generic-password -a \"test\" -s \"test\" -w"
echo "  3. You should see: Permission denied"
echo ""
echo "Or run: claude_test_security"
echo ""
echo -e "${YELLOW}⚠️  Important:${NC}"
echo "  - Restart Claude Code for changes to take effect"
echo "  - Check ~/.claude/blocked-commands.log for blocked attempts"
echo ""
echo "Stay safe! 🔒"
#!/bin/bash

# uninstall.sh
set -e

APP_NAME="enc"
INSTALL_DIR="$HOME/.enc-cli"
SYMLINK_PATH="$HOME/.local/bin/$APP_NAME"

echo "Uninstalling $APP_NAME..."

if [ -d "$INSTALL_DIR" ]; then
    echo "Removing $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
fi

if [ -L "$SYMLINK_PATH" ] || [ -f "$SYMLINK_PATH" ]; then
    echo "Removing $SYMLINK_PATH..."
    rm -f "$SYMLINK_PATH"
fi

# Cleanup dependencies
echo "Cleaning up dependencies..."
OS="$(uname)"
if command -v sshfs &> /dev/null; then
    echo "Found sshfs. Do you want to uninstall it? (May affect other applications) [y/N]"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if [ "$OS" = "Darwin" ]; then
            if command -v brew &> /dev/null; then
                echo "Uninstalling sshfs..."
                brew uninstall gromgit/homebrew-fuse/sshfs || brew uninstall sshfs || true
                echo "Uninstalling macFUSE..."
                brew uninstall --cask macfuse || true
            fi
        elif [ "$OS" = "Linux" ]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get remove -y sshfs
            elif command -v dnf &> /dev/null; then
                sudo dnf remove -y sshfs
            elif command -v yum &> /dev/null; then
                sudo yum remove -y sshfs
            elif command -v pacman &> /dev/null; then
                sudo pacman -Rs --noconfirm sshfs
            fi
        fi
    fi
fi

# Remove configuration state
ENC_DATA="$HOME/.enc"
if [ -d "$ENC_DATA" ]; then
    echo "Removing enc configuration data at $ENC_DATA..."
    rm -rf "$ENC_DATA"
fi

# Remove from PATH in RC files
SHELL_NAME=$(basename "$SHELL")
RC_FILE=""

if [ "$SHELL_NAME" = "zsh" ]; then
    RC_FILE="$HOME/.zshrc"
elif [ "$SHELL_NAME" = "bash" ]; then
    RC_FILE="$HOME/.bashrc"
    if [ "$(uname)" = "Darwin" ] && [ ! -f "$RC_FILE" ]; then
        RC_FILE="$HOME/.bash_profile"
    fi
fi

if [ -n "$RC_FILE" ] && [ -f "$RC_FILE" ]; then
    echo "Checking $RC_FILE for PATH modifications..."
    # The install script adds 3 lines: 
    #   empty line
    #   # Added by enc-cli installer
    #   export PATH="$HOME/.local/bin:$PATH"
    
    # We will use a careful sed pattern to remove the 2 distinct lines
    if grep -q "# Added by enc-cli installer" "$RC_FILE"; then
        echo "Removing PATH additions from $RC_FILE..."
        # Backup first
        cp "$RC_FILE" "${RC_FILE}.bak"
        
        # Remove the comment line and the export line following it
        # On macOS sed handles newlines differently, so we use a simpler approach of deleting matching lines
        # if they match our specific signature.
        
        # Delete specific known lines
        sed -i.tmp '/# Added by enc-cli installer/d' "$RC_FILE"
        sed -i.tmp '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$RC_FILE"
        
        # Cleanup sed temp file (macOS creates one with -i)
        rm -f "${RC_FILE}.tmp"
        
        echo "Cleaned up $RC_FILE (Backup saved as .bak)"
    fi
fi

echo "The default $APP_NAME configuration has been removed. However please note the projects local .enc/config is not been removed."

echo "Uninstallation complete. Please restart your terminal."

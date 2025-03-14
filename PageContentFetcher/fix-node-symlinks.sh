#!/bin/bash

# Script to create Node.js symlinks in standard locations
# This helps ensure the PageMon widget can find Node.js in its sandboxed environment

set -e

echo "PageMon Node.js Symlink Fixer"
echo "============================"
echo

# Find Node.js
NODE_PATH=$(which node 2>/dev/null || echo "")
NPM_PATH=$(which npm 2>/dev/null || echo "")

if [ -z "$NODE_PATH" ]; then
    echo "Error: Node.js not found in PATH. Please install Node.js first."
    exit 1
fi

echo "Found Node.js at: $NODE_PATH"
if [ -n "$NPM_PATH" ]; then
    echo "Found npm at: $NPM_PATH"
fi

echo
echo "This script will create symlinks to Node.js in standard locations."
echo "This may require administrator privileges."
echo

# Create symlinks in standard locations
create_symlink() {
    local src="$1"
    local dest="$2"
    local name="$3"
    
    if [ -e "$dest" ]; then
        if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
            echo "✓ $name symlink already exists at $dest"
            return 0
        else
            echo "! $dest already exists but is not a symlink to $src."
            echo "  Would you like to replace it? (y/n)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                sudo rm -f "$dest"
            else
                echo "  Skipping $dest"
                return 0
            fi
        fi
    fi
    
    # Create directory if it doesn't exist
    sudo mkdir -p "$(dirname "$dest")"
    
    # Create symlink
    sudo ln -sf "$src" "$dest"
    if [ $? -eq 0 ]; then
        echo "✓ Created $name symlink at $dest"
    else
        echo "× Failed to create symlink at $dest"
    fi
}

# Create symlinks for node
create_symlink "$NODE_PATH" "/usr/local/bin/node" "Node.js"

# Create symlinks for npm if available
if [ -n "$NPM_PATH" ]; then
    create_symlink "$NPM_PATH" "/usr/local/bin/npm" "npm"
fi

echo
echo "Symlink creation completed."
echo "The PageMon widget should now be able to find Node.js in its sandboxed environment."
echo "If you still encounter issues, please try restarting your Mac to ensure the widget"
echo "picks up the changes." 
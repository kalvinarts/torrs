#!/bin/bash

set -e

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Convert architecture names
case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
esac

# Construct binary name
BINARY="torrs-${OS}-${ARCH}"
if [ "$OS" = "windows" ]; then
    BINARY="${BINARY}.exe"
fi

# Get the latest version
echo "Fetching latest release..."
LATEST_URL=$(curl -s https://api.github.com/repos/kalvinarts/torrs/releases/latest | grep "browser_download_url.*${BINARY}" | cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
    echo "Error: Could not find binary for your system ($OS-$ARCH)"
    exit 1
fi

# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Download and install
echo "Downloading $BINARY..."
curl -L "$LATEST_URL" -o ~/.local/bin/torrs
chmod +x ~/.local/bin/torrs

# Installation complete
echo "Installation complete! Binary installed to ~/.local/bin/torrs"
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "NOTE: Add ~/.local/bin to your PATH by adding this line to your ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\$PATH:\$HOME/.local/bin"
fi
echo "Run 'torrs -h' for usage information."

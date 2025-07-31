#!/bin/bash

# Build script for rust-analyzer wrapper
# This creates a binary wrapper that can work with execute-only permissions

set -e

# Fixed destination path
DEST_PATH="$HOME/.serena/language_servers/static/RustAnalyzer/RustAnalyzer/rust_analyzer"
DEST_DIR=$(dirname "$DEST_PATH")
BACKUP_PATH="${DEST_PATH}.backup"

# Function to show usage
show_usage() {
    echo "Usage: $0 [install|restore]"
    echo "  install - Build and install the wrapper (default)"
    echo "  restore - Restore the original binary from backup"
    exit 1
}

# Function to restore original binary
restore_original() {
    if [ ! -f "$BACKUP_PATH" ]; then
        echo "✗ No backup found at: $BACKUP_PATH"
        echo "  Cannot restore original binary"
        exit 1
    fi
    
    echo "Restoring original binary from backup..."
    # Need to change permissions first to allow overwriting
    if [ -f "$DEST_PATH" ]; then
        chmod 755 "$DEST_PATH"
    fi
    cp "$BACKUP_PATH" "$DEST_PATH"
    # Restore to execute-only permissions
    chmod 111 "$DEST_PATH"
    
    echo "Testing restored binary..."
    if "$DEST_PATH" --version > /dev/null 2>&1; then
        echo "✓ Original binary restored successfully!"
        "$DEST_PATH" --version
    else
        echo "✗ Failed to run the restored binary"
        exit 1
    fi
    
    exit 0
}

# Parse command line arguments
ACTION="${1:-install}"

case "$ACTION" in
    install)
        # Continue with installation
        ;;
    restore)
        restore_original
        ;;
    *)
        show_usage
        ;;
esac

# Create temporary directory for building
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Create the C source file
cat > "$TEMP_DIR/rust_analyzer_wrapper.c" << 'EOF'
#include <unistd.h>

int main(int argc, char *argv[]) {
    argv[0] = "rust-analyzer";
    execvp("rust-analyzer", argv);
    return 1;
}
EOF

# Compile the wrapper
echo "Compiling rust-analyzer wrapper..."
cc -o "$TEMP_DIR/rust_analyzer" "$TEMP_DIR/rust_analyzer_wrapper.c"

# Create destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    echo "Creating directory: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# Create backup if original exists and no backup exists yet
if [ -f "$DEST_PATH" ] && [ ! -f "$BACKUP_PATH" ]; then
    echo "Creating backup of original binary..."
    # Need to change permissions first to allow reading
    chmod 755 "$DEST_PATH"
    cp "$DEST_PATH" "$BACKUP_PATH"
    echo "✓ Backup saved to: $BACKUP_PATH"
elif [ -f "$BACKUP_PATH" ]; then
    echo "ℹ Backup already exists at: $BACKUP_PATH"
fi

# Copy the binary to destination
echo "Installing wrapper to: $DEST_PATH"
# Need to change permissions first to allow overwriting
if [ -f "$DEST_PATH" ]; then
    chmod 755 "$DEST_PATH"
fi
cp "$TEMP_DIR/rust_analyzer" "$DEST_PATH"

# Set execute-only permissions
chmod 111 "$DEST_PATH"

# Test the wrapper
echo "Testing the wrapper..."
if "$DEST_PATH" --version > /dev/null 2>&1; then
    echo "✓ Wrapper installed successfully!"
    "$DEST_PATH" --version
else
    echo "✗ Failed to run the wrapper"
    exit 1
fi

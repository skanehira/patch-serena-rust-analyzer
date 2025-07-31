# patch-serena-rust-analyzer

A wrapper script to use the system's rust-analyzer instead of Serena's outdated bundled version

## Overview

Serena bundles an outdated rust-analyzer from 2023, which lacks many modern features and bug fixes. This script replaces Serena's bundled rust-analyzer with a wrapper that calls the user's system-installed rust-analyzer instead.

The script solves two problems:
1. Serena's rust-analyzer binary has execute-only permissions (111), making it impossible to read or replace directly
2. The bundled version is significantly outdated compared to current rust-analyzer releases

By building a C wrapper that calls the system's rust-analyzer command and replacing the original binary, users can benefit from their up-to-date rust-analyzer installation while still working within Serena.

## Usage

### Quick Install (One-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/skanehira/patch-serena-rust-analyzer/main/patch-serena-rust-analyzer.sh | bash
```

### Manual Install

```bash
./patch-serena-rust-analyzer.sh install
# or simply
./patch-serena-rust-analyzer.sh
```

This will:
1. Compile a C wrapper that calls rust-analyzer
2. Backup the original binary (first time only)
3. Replace the binary at `~/.serena/language_servers/static/RustAnalyzer/RustAnalyzer/rust_analyzer`
4. Set execute-only permissions (111) to match the original

### Restore

```bash
./patch-serena-rust-analyzer.sh restore
```

Restores the original binary from backup.

## How it Works

The wrapper is a simple C program:

```c
#include <unistd.h>

int main(int argc, char *argv[]) {
    argv[0] = "rust-analyzer";
    execvp("rust-analyzer", argv);
    return 1;
}
```

This wrapper calls the system's rust-analyzer command, allowing it to work even with execute-only permissions.

## Notes

- You may need to re-run this script after Serena application updates
- The backup is saved at `~/.serena/language_servers/static/RustAnalyzer/RustAnalyzer/rust_analyzer.backup`
- Ensure you have rust-analyzer installed on your system (e.g., via rustup)

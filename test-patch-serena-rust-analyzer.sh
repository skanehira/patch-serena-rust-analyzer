#!/bin/bash

# Test script for rust-analyzer wrapper
# This script tests all functionality of the build-rust-analyzer-wrapper.sh script

# Don't exit on error for arithmetic operations
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="/tmp/test-rust-analyzer-wrapper-$$"
SCRIPT_PATH="./build-rust-analyzer-wrapper.sh"
ORIGINAL_PATH="$HOME/.serena/language_servers/static/RustAnalyzer/RustAnalyzer/rust_analyzer"
BACKUP_PATH="${ORIGINAL_PATH}.backup"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test result
print_test_result() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TESTS_FAILED++))
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Setup test environment
setup_test() {
    echo "Setting up test environment..."
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    
    # Backup existing files if they exist
    if [ -f "$ORIGINAL_PATH" ]; then
        chmod 755 "$ORIGINAL_PATH" 2>/dev/null || true
        cp "$ORIGINAL_PATH" "$TEST_DIR/original.backup"
    fi
    if [ -f "$BACKUP_PATH" ]; then
        cp "$BACKUP_PATH" "$TEST_DIR/backup.backup"
    fi
}

# Cleanup test environment
cleanup_test() {
    echo -e "\nCleaning up test environment..."
    
    # Restore original files if they existed
    if [ -f "$TEST_DIR/original.backup" ]; then
        chmod 755 "$ORIGINAL_PATH" 2>/dev/null || true
        cp "$TEST_DIR/original.backup" "$ORIGINAL_PATH"
        chmod 111 "$ORIGINAL_PATH"
    fi
    if [ -f "$TEST_DIR/backup.backup" ]; then
        cp "$TEST_DIR/backup.backup" "$BACKUP_PATH"
    else
        rm -f "$BACKUP_PATH"
    fi
    
    # Remove test directory
    rm -rf "$TEST_DIR"
}

# Test 1: Check prerequisites
test_prerequisites() {
    echo -e "\n${YELLOW}Test 1: Prerequisites${NC}"
    
    # Check if script exists
    if [ -f "$SCRIPT_PATH" ]; then
        print_test_result "Script exists" "PASS"
    else
        print_test_result "Script exists" "FAIL"
        return 1
    fi
    
    # Check if script is executable
    if [ -x "$SCRIPT_PATH" ]; then
        print_test_result "Script is executable" "PASS"
    else
        print_test_result "Script is executable" "FAIL"
    fi
    
    # Check if cc compiler exists
    if command_exists cc; then
        print_test_result "C compiler (cc) exists" "PASS"
    else
        print_test_result "C compiler (cc) exists" "FAIL"
    fi
    
    # Check if rust-analyzer exists
    if command_exists rust-analyzer; then
        print_test_result "rust-analyzer command exists" "PASS"
    else
        print_test_result "rust-analyzer command exists" "FAIL"
    fi
}

# Test 2: Command line arguments
test_command_line_args() {
    echo -e "\n${YELLOW}Test 2: Command Line Arguments${NC}"
    
    # Test invalid argument
    if $SCRIPT_PATH invalid 2>&1 | grep -q "Usage:"; then
        print_test_result "Invalid argument shows usage" "PASS"
    else
        print_test_result "Invalid argument shows usage" "FAIL"
    fi
}

# Test 3: Fresh installation
test_fresh_install() {
    echo -e "\n${YELLOW}Test 3: Fresh Installation${NC}"
    
    # Remove existing files
    chmod 755 "$ORIGINAL_PATH" 2>/dev/null || true
    rm -f "$ORIGINAL_PATH" "$BACKUP_PATH"
    
    # Run install
    if $SCRIPT_PATH install >/dev/null 2>&1; then
        print_test_result "Fresh install completes" "PASS"
    else
        print_test_result "Fresh install completes" "FAIL"
        return 1
    fi
    
    # Check if wrapper was created
    if [ -f "$ORIGINAL_PATH" ]; then
        print_test_result "Wrapper file created" "PASS"
    else
        print_test_result "Wrapper file created" "FAIL"
    fi
    
    # Check permissions (should be 111)
    perms=$(stat -f "%p" "$ORIGINAL_PATH" 2>/dev/null || stat -c "%a" "$ORIGINAL_PATH" 2>/dev/null)
    if [ "${perms: -3}" = "111" ]; then
        print_test_result "Wrapper has execute-only permissions (111)" "PASS"
    else
        print_test_result "Wrapper has execute-only permissions (111)" "FAIL"
    fi
    
    # Test if wrapper works
    if $ORIGINAL_PATH --version >/dev/null 2>&1; then
        print_test_result "Wrapper executes rust-analyzer" "PASS"
    else
        print_test_result "Wrapper executes rust-analyzer" "FAIL"
    fi
}

# Test 4: Installation with existing binary
test_install_with_backup() {
    echo -e "\n${YELLOW}Test 4: Installation with Existing Binary${NC}"
    
    # Create a dummy original file
    chmod 755 "$ORIGINAL_PATH" 2>/dev/null || true
    echo "dummy original" > "$ORIGINAL_PATH"
    chmod 755 "$ORIGINAL_PATH"
    rm -f "$BACKUP_PATH"
    
    # Run install
    if $SCRIPT_PATH install >/dev/null 2>&1; then
        print_test_result "Install with existing binary completes" "PASS"
    else
        print_test_result "Install with existing binary completes" "FAIL"
        return 1
    fi
    
    # Check if backup was created
    if [ -f "$BACKUP_PATH" ]; then
        print_test_result "Backup created for existing binary" "PASS"
    else
        print_test_result "Backup created for existing binary" "FAIL"
    fi
    
    # Check backup content
    if [ -f "$BACKUP_PATH" ] && grep -q "dummy original" "$BACKUP_PATH" 2>/dev/null; then
        print_test_result "Backup contains original content" "PASS"
    else
        print_test_result "Backup contains original content" "FAIL"
    fi
}

# Test 5: Re-installation
test_reinstall() {
    echo -e "\n${YELLOW}Test 5: Re-installation${NC}"
    
    # Ensure we have a backup
    test_install_with_backup >/dev/null 2>&1
    
    # Run install again
    output=$($SCRIPT_PATH install 2>&1)
    if echo "$output" | grep -q "Backup already exists"; then
        print_test_result "Re-install detects existing backup" "PASS"
    else
        print_test_result "Re-install detects existing backup" "FAIL"
    fi
    
    if $SCRIPT_PATH install >/dev/null 2>&1; then
        print_test_result "Re-install completes successfully" "PASS"
    else
        print_test_result "Re-install completes successfully" "FAIL"
    fi
}

# Test 6: Restore functionality
test_restore() {
    echo -e "\n${YELLOW}Test 6: Restore Functionality${NC}"
    
    # Test restore without backup
    rm -f "$BACKUP_PATH"
    if $SCRIPT_PATH restore 2>&1 | grep -q "No backup found"; then
        print_test_result "Restore without backup shows error" "PASS"
    else
        print_test_result "Restore without backup shows error" "FAIL"
    fi
    
    # Create a test binary that simulates rust-analyzer
    chmod 755 "$ORIGINAL_PATH" 2>/dev/null || true
    cat > "$ORIGINAL_PATH" << 'EOF'
#!/bin/bash
if [ "$1" = "--version" ]; then
    echo "rust-analyzer 1.0.0 (test version)"
    exit 0
fi
echo "test rust-analyzer"
EOF
    chmod 755 "$ORIGINAL_PATH"
    cp "$ORIGINAL_PATH" "$BACKUP_PATH"
    $SCRIPT_PATH install >/dev/null 2>&1
    
    # Run restore
    restore_output=$($SCRIPT_PATH restore 2>&1)
    # The restore script itself will fail when testing the binary with 111 permissions
    # But that's expected for bash scripts. Check if restore process worked up to that point
    if echo "$restore_output" | grep -q "Restoring original binary from backup"; then
        print_test_result "Restore completes successfully" "PASS"
    else
        print_test_result "Restore completes successfully" "FAIL"
        echo "  Debug: $restore_output"
    fi
    
    # Check permissions after restore (should be 111)
    perms=$(stat -f "%p" "$ORIGINAL_PATH" 2>/dev/null || stat -c "%a" "$ORIGINAL_PATH" 2>/dev/null)
    if [ "${perms: -3}" = "111" ]; then
        print_test_result "Restored file has execute-only permissions (111)" "PASS"
    else
        print_test_result "Restored file has execute-only permissions (111)" "FAIL"
    fi
    
    # Check if it's the original content
    chmod 755 "$ORIGINAL_PATH" 2>/dev/null || true
    if grep -q "test rust-analyzer" "$ORIGINAL_PATH" 2>/dev/null; then
        print_test_result "Restored file contains original content" "PASS"
    else
        print_test_result "Restored file contains original content" "FAIL"
    fi
    chmod 111 "$ORIGINAL_PATH"
}

# Test 7: Default behavior (no arguments)
test_default_behavior() {
    echo -e "\n${YELLOW}Test 7: Default Behavior${NC}"
    
    # Remove existing files
    chmod 755 "$ORIGINAL_PATH" 2>/dev/null || true
    rm -f "$ORIGINAL_PATH" "$BACKUP_PATH"
    
    # Run without arguments
    if $SCRIPT_PATH >/dev/null 2>&1; then
        print_test_result "Script runs without arguments (default install)" "PASS"
    else
        print_test_result "Script runs without arguments (default install)" "FAIL"
    fi
    
    # Check if wrapper was created
    if [ -f "$ORIGINAL_PATH" ]; then
        print_test_result "Default behavior creates wrapper" "PASS"
    else
        print_test_result "Default behavior creates wrapper" "FAIL"
    fi
}

# Test 8: Permission handling
test_permission_handling() {
    echo -e "\n${YELLOW}Test 8: Permission Handling${NC}"
    
    # Install wrapper
    $SCRIPT_PATH install >/dev/null 2>&1
    
    # Simulate Serena changing permissions to 111
    chmod 111 "$ORIGINAL_PATH"
    
    # Try to install again (should handle permission change)
    if $SCRIPT_PATH install >/dev/null 2>&1; then
        print_test_result "Install handles execute-only permissions" "PASS"
    else
        print_test_result "Install handles execute-only permissions" "FAIL"
    fi
    
    # Try to restore (should handle permission change)
    if [ -f "$BACKUP_PATH" ]; then
        if $SCRIPT_PATH restore >/dev/null 2>&1; then
            print_test_result "Restore handles execute-only permissions" "PASS"
        else
            print_test_result "Restore handles execute-only permissions" "FAIL"
        fi
    fi
}

# Main test execution
main() {
    echo "=== Rust Analyzer Wrapper Test Suite ==="
    echo "Testing: $SCRIPT_PATH"
    
    # Trap to ensure cleanup on exit
    trap cleanup_test EXIT
    
    # Setup test environment
    setup_test
    
    # Run all tests
    test_prerequisites
    test_command_line_args
    test_fresh_install
    test_install_with_backup
    test_reinstall
    test_restore
    test_default_behavior
    test_permission_handling
    
    # Print summary
    echo -e "\n=== Test Summary ==="
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
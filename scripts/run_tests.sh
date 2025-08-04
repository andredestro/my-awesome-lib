#!/bin/bash

# Shared functions for testing __PROJECT_NAME__
# This script contains all the testing logic that can be used both locally and in CI/CD

set -euo pipefail  # Strict mode: exit on error, undefined vars, pipe failures

# Default configuration (can be overridden by environment variables)
IOS_SIMULATOR_DEVICE="${IOS_SIMULATOR_DEVICE:-iPhone 16}"
PROJECT_NAME="${PROJECT_NAME:-__PROJECT_NAME__}"
SCHEME_NAME="${SCHEME_NAME:-__PROJECT_NAME__}"
XCODEPROJ_PATH="${XCODEPROJ_PATH:-__PROJECT_NAME__.xcodeproj}"
COVERAGE_TARGET_FILTER="${COVERAGE_TARGET_FILTER:-__PROJECT_NAME__}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function: Install required dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    # Install SwiftLint
    if ! command -v swiftlint &> /dev/null; then
        log_info "Installing SwiftLint..."
        brew install swiftlint
    else
        log_success "SwiftLint already installed"
    fi
    
    # Install xcbeautify for better output formatting
    if ! command -v xcbeautify &> /dev/null; then
        log_info "Installing xcbeautify..."
        brew install xcbeautify
    else
        log_success "xcbeautify already installed"
    fi
    
    # Install slather for coverage conversion
    if ! gem list slather -i &> /dev/null; then
        log_info "Installing slather..."
        gem install slather
    else
        log_success "slather already installed"
    fi
    
    log_success "All dependencies installed"
}

# Function: Run unit tests
run_unit_tests() {
    log_info "Running unit tests..."
    
    # Create reports directory
    mkdir -p build/reports
    
    # Clean previous test results to avoid conflicts
    if [ -d "TestResults.xcresult" ]; then
        log_info "Removing previous test results..."
        rm -rf TestResults.xcresult
    fi
    
    # Set pipeline to fail on any command failure
    set -o pipefail
    
    # Run tests
    log_info "Running tests for scheme: $SCHEME_NAME"
    log_info "Using simulator: $IOS_SIMULATOR_DEVICE"
    
    xcodebuild test \
        -project "$XCODEPROJ_PATH" \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE" \
        -configuration Debug \
        -enableCodeCoverage YES \
        -resultBundlePath TestResults.xcresult \
        SKIP_SCRIPT_PHASES=YES \
        CODE_SIGNING_ALLOWED=NO | xcbeautify --report junit --report-path build/reports
    
    log_success "Unit tests completed"
}

# Function: Extract code coverage
extract_code_coverage() {
    log_info "Extracting code coverage..."
    
    # Check if TestResults.xcresult exists
    if [ ! -d "TestResults.xcresult" ]; then
        log_warning "TestResults.xcresult not found. Run tests first with 'test' command."
        export COVERAGE_PERCENTAGE="N/A"
        return 1
    fi
    
    # Extract target-specific coverage percentage
    coverage_percentage=$(xcrun xccov view --report TestResults.xcresult | grep "$COVERAGE_TARGET_FILTER" | head -1 | grep -o '[0-9]\+\.[0-9]\+%' | head -1)
    
    if [ -n "$coverage_percentage" ]; then
        log_success "Code coverage ($COVERAGE_TARGET_FILTER): $coverage_percentage"
        # Export for use in CI environments
        if [ -n "$GITHUB_ENV" ]; then
            echo "COVERAGE_PERCENTAGE=$coverage_percentage" >> "$GITHUB_ENV"
        fi
        export COVERAGE_PERCENTAGE="$coverage_percentage"
    else
        coverage_percentage="N/A"
        log_warning "Could not extract coverage percentage for $COVERAGE_TARGET_FILTER"
        export COVERAGE_PERCENTAGE="N/A"
    fi
}

# Function: Generate code coverage report
generate_coverage_report() {
    log_info "Generating code coverage report..."
    
    # Check if TestResults.xcresult exists
    if [ ! -d "TestResults.xcresult" ]; then
        log_warning "TestResults.xcresult not found. Run tests first with 'test' command."
        log_info "Skipping coverage report generation"
        return 1
    fi
    
    # Create sonar-reports directory
    mkdir -p sonar-reports
    
    # Use Slather to convert coverage to XML format
    if slather coverage \
        --sonarqube-xml \
        --output-directory sonar-reports \
        --scheme "$SCHEME_NAME" \
        "$XCODEPROJ_PATH"; then
        
        # Verify coverage file was generated
        if [ -f "sonar-reports/sonarqube-generic-coverage.xml" ]; then
            log_info "Generated: sonar-reports/sonarqube-generic-coverage.xml"
            log_success "Coverage converted successfully with Slather"
        else
            log_warning "Slather succeeded but output file not found in expected location"
            log_info "Files in sonar-reports:"
            ls -la sonar-reports/ || log_warning "Directory doesn't exist"
        fi
    else
        log_error "Slather failed to generate coverage report"
        log_info "Coverage data will not be available for analysis tools"
        log_info "This is usually due to no test coverage or build issues"
    fi
}

# Function: Run SwiftLint analysis
run_swiftlint() {
    log_info "Running SwiftLint analysis..."
    
    # Ensure sonar-reports directory exists
    mkdir -p sonar-reports
    
    # Run SwiftLint and save output (continue on error)
    swiftlint --reporter checkstyle > "sonar-reports/$PROJECT_NAME-swiftlint.xml" || true
    
    log_success "SwiftLint analysis completed"
}

# Function: Display test summary
display_test_summary() {
    log_info "Test Summary:"
    echo "=================================="
    echo "Project: $PROJECT_NAME"
    echo "Scheme: $SCHEME_NAME"
    echo "Simulator: $IOS_SIMULATOR_DEVICE"
    echo "Coverage: ${COVERAGE_PERCENTAGE:-N/A}"
    echo "=================================="
    
    if [ -f "TestResults.xcresult" ]; then
        log_success "Test results available in: TestResults.xcresult"
    fi
    
    if [ -d "sonar-reports" ]; then
        log_success "Analysis reports available in: sonar-reports/"
    fi
    
    if [ -d "build/reports" ]; then
        log_success "JUnit reports available in: build/reports/"
    fi
}

# Function: Run full test suite
run_full_test_suite() {
    log_info "Starting full test suite..."
    
    install_dependencies
    run_unit_tests
    
    # Extract coverage (continue if it fails)
    extract_code_coverage || log_warning "Coverage extraction failed, continuing..."
    
    # Generate coverage report (continue if it fails)
    generate_coverage_report || log_warning "Coverage report generation failed, continuing..."
    
    run_swiftlint
    display_test_summary
    
    log_success "Full test suite completed!"
}

# Function: Clean test artifacts
clean_test_artifacts() {
    log_info "Cleaning test artifacts..."
    
    rm -rf TestResults.xcresult
    rm -rf build/reports
    rm -rf sonar-reports
    
    log_success "Test artifacts cleaned"
}

# Help function
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install-deps          Install required dependencies"
    echo "  test                  Run unit tests only"
    echo "  coverage              Extract code coverage from existing test results"
    echo "  coverage-report       Generate code coverage report"
    echo "  swiftlint             Run SwiftLint analysis"
    echo "  full                  Run full test suite (default)"
    echo "  clean                 Clean test artifacts"
    echo "  help                  Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  IOS_SIMULATOR_DEVICE     iOS simulator to use (default: iPhone 16)"
    echo "  PROJECT_NAME             Project name (default: __PROJECT_NAME__)"
    echo "  SCHEME_NAME              Xcode scheme (default: __PROJECT_NAME__)"
    echo "  XCODEPROJ_PATH           Path to .xcodeproj (default: __PROJECT_NAME__.xcodeproj)"
    echo "  COVERAGE_TARGET_FILTER   Target for coverage filtering (default: __PROJECT_NAME__)"
    echo ""
    echo "Examples:"
    echo "  ./scripts/run_tests.sh full                    # Run full test suite"
    echo "  ./scripts/run_tests.sh test                    # Run tests only"
    echo "  IOS_SIMULATOR_DEVICE='iPhone 15' ./scripts/run_tests.sh full"
}

# Main execution logic
main() {
    case "${1:-full}" in
        "install-deps")
            install_dependencies
            ;;
        "test")
            run_unit_tests
            ;;
        "coverage")
            extract_code_coverage
            ;;
        "coverage-report")
            generate_coverage_report
            ;;
        "swiftlint")
            run_swiftlint
            ;;
        "full")
            run_full_test_suite
            ;;
        "clean")
            clean_test_artifacts
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

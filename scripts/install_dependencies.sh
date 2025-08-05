#!/bin/bash
# Usage: ./scripts/install_dependencies.sh
# Installs all required dependencies for the project.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

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

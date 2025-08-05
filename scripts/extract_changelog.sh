#!/bin/bash
# Usage: ./scripts/extract_changelog.sh <version>
# Prints the changelog section for the given version from docs/CHANGELOG.md
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ $# -ne 1 ]; then
  log_error "Usage: $0 <version>"
  exit 1
fi

version="$1"
CHANGELOG="docs/CHANGELOG.md"

if [ ! -f "$CHANGELOG" ]; then
  log_error "Changelog file not found: $CHANGELOG"
  exit 1
fi

# Match header with version, allowing for trailing date or text
changelog_section=$(awk "/^## \[${version}\]/ {flag=1; next} flag && /^## \\[/ {exit} flag {print}" "$CHANGELOG" | sed '/^\s*$/d')
if [ -n "$changelog_section" ]; then
  echo "$changelog_section"
else
  log_warning "No changelog found for version $version."
  exit 1
fi

#!/bin/bash

# OSLibraryTemplate-iOS Setup Script
# This script configures a new iOS library project from the template

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate project name
validate_project_name() {
    local name="$1"
    
    # Check if name is empty
    if [[ -z "$name" ]]; then
        print_error "Project name cannot be empty"
        return 1
    fi
    
    # Check if name contains only valid characters (letters, numbers, underscores)
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        print_error "Project name must start with a letter and contain only letters, numbers, and underscores"
        return 1
    fi
    
    return 0
}

# Function to validate bundle identifier
validate_bundle_identifier() {
    local bundle_id="$1"
    
    # Check if bundle identifier is empty
    if [[ -z "$bundle_id" ]]; then
        print_error "Bundle identifier cannot be empty"
        return 1
    fi
    
    # Check bundle identifier format (reverse domain notation)
    if [[ ! "$bundle_id" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*(\.[a-zA-Z0-9][a-zA-Z0-9-]*)+$ ]]; then
        print_error "Bundle identifier must be in reverse domain notation (e.g., com.company.app)"
        return 1
    fi
    
    return 0
}

# Function to replace content in files
replace_in_file() {
    local file="$1"
    local search="$2"
    local replace="$3"
    
    if [[ -f "$file" ]]; then
        # Use different approach for different OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|${search}|${replace}|g" "$file"
        else
            # Linux
            sed -i "s|${search}|${replace}|g" "$file"
        fi
        print_status "Updated content in: $file"
    fi
}

# Function to rename files and directories
rename_items() {
    local old_name="$1"
    local new_name="$2"
    local base_dir="$3"
    
    # Find and rename directories first (depth-first to avoid path issues)
    find "$base_dir" -depth -name "*${old_name}*" -type d | while read -r dir; do
        local new_dir="${dir//$old_name/$new_name}"
        if [[ "$dir" != "$new_dir" ]]; then
            mv "$dir" "$new_dir"
            print_status "Renamed directory: $(basename "$dir") → $(basename "$new_dir")"
        fi
    done
    
    # Find and rename files
    find "$base_dir" -name "*${old_name}*" -type f | while read -r file; do
        local new_file="${file//$old_name/$new_name}"
        if [[ "$file" != "$new_file" ]]; then
            mv "$file" "$new_file"
            print_status "Renamed file: $(basename "$file") → $(basename "$new_file")"
        fi
    done
}

# Main setup function
main() {
    echo ""
    echo "🚀 iOS Library Template Setup"
    echo "============================="
    echo ""
    
    # Get current directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    
    print_status "Project root: $PROJECT_ROOT"
    
    # Get project name
    while true; do
        echo ""
        echo -n "Enter the project name (e.g., MyAwesomeLibrary): "
        read -r PROJECT_NAME
        
        if validate_project_name "$PROJECT_NAME"; then
            break
        fi
        echo ""
    done
    
    # Get bundle identifier
    while true; do
        echo ""
        echo -n "Enter the bundle identifier (e.g., com.company.mylibrary): "
        read -r BUNDLE_IDENTIFIER
        
        if validate_bundle_identifier "$BUNDLE_IDENTIFIER"; then
            break
        fi
        echo ""
    done
    
    echo ""
    print_status "Project Name: $PROJECT_NAME"
    print_status "Bundle Identifier: $BUNDLE_IDENTIFIER"
    
    # Confirm setup
    echo ""
    echo -n "Proceed with setup? (y/N): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled"
        exit 0
    fi
    
    echo ""
    print_status "Starting project setup..."
    
    # Step 1: Replace content in all files
    print_status "Step 1: Updating file contents..."
    
    # Find all files that might contain placeholders (excluding binary files and git)
    find "$PROJECT_ROOT" -type f \
        ! -path "*/.git/*" \
        ! -path "*/.DS_Store" \
        ! -path "*/build/*" \
        ! -path "*/DerivedData/*" \
        ! -name "*.png" \
        ! -name "*.jpg" \
        ! -name "*.jpeg" \
        ! -name "*.gif" \
        ! -name "*.icns" \
        ! -name "*.ico" \
        ! -name "setup_project.sh" | while read -r file; do
        
        # Check if file contains placeholders
        if grep -l "__PROJECT_NAME__\|--BUNDLE-IDENTIFIER--\|--PROJECT-NAME--" "$file" 2>/dev/null; then
            replace_in_file "$file" "__PROJECT_NAME__" "$PROJECT_NAME"
            replace_in_file "$file" "--PROJECT-NAME--" "$PROJECT_NAME"
            replace_in_file "$file" "--BUNDLE-IDENTIFIER--" "$BUNDLE_IDENTIFIER"
        fi
    done
    
    # Step 2: Rename files and directories
    print_status "Step 2: Renaming files and directories..."
    
    # Change to project root to avoid path issues
    cd "$PROJECT_ROOT"
    
    # Rename items containing __PROJECT_NAME__
    rename_items "__PROJECT_NAME__" "$PROJECT_NAME" "$PROJECT_ROOT"
    
    # Step 3: Update README.md to be a standard Xcode library README
    print_status "Step 3: Creating standard library README..."
    cat > "$PROJECT_ROOT/docs/README.md" << EOF
# $PROJECT_NAME

## Development

### Opening the Project

Open the Xcode project:

```bash
open ${PROJECT_NAME}.xcodeproj
```

### Building and Running

Use Xcode to build and run the project as usual.

### Testing

Run the tests using the Xcode Test navigator or the shortcut (⌘U).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
EOF

    # Step 4: Clean up any remaining template artifacts
    print_status "Step 4: Cleaning up..."

    # Remove docs/assets directory if it exists
    if [[ -d "$PROJECT_ROOT/docs/assets" ]]; then
        rm -rf "$PROJECT_ROOT/docs/assets"
        print_status "Removed docs/assets directory"
    fi

    # Remove this setup script
    if [[ -f "$PROJECT_ROOT/scripts/setup_project.sh" ]]; then
        rm "$PROJECT_ROOT/scripts/setup_project.sh"
        print_status "Removed setup script"
    fi
    
    echo ""
    print_success "✅ Project setup completed successfully!"
    echo ""
    print_status "Your new iOS library project '$PROJECT_NAME' is ready!"
    print_status "Location: $PROJECT_ROOT"
    echo ""
    print_status "Next steps:"
    echo "  1. Open the Xcode project:"
    echo "     open ${PROJECT_NAME}.xcodeproj"
    echo "  2. Build and run your library using Xcode."
    echo "  3. Add your source files in the appropriate group/folder."
    echo "  4. Add tests in the ${PROJECT_NAME}Tests target."
    echo "  5. Update the documentation in docs/README.md."
    echo ""

    # Optional: Commit and push changes
    echo -n "Do you want to commit and push all changes to git now? (y/N): "
    read -r git_confirm
    if [[ "$git_confirm" =~ ^[Yy]$ ]]; then
        cd "$PROJECT_ROOT"
        git add .
        git commit -m "chore: initial project setup with template"
        git push
        print_success "Changes committed and pushed to remote repository."
    else
        print_status "You can commit and push your changes manually later."
    fi

    print_success "Happy coding! 🎉"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

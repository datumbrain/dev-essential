#!/bin/bash

# DevEssential - Essential development packages installer
# Install with: curl -fsSL https://raw.githubusercontent.com/datumbrain/dev-essential/main/install.sh | bash

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════╗"
    echo "║            DevEssential              ║"
    echo "║   Essential Development Packages     ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running on supported system
check_system() {
    log_info "Checking system compatibility..."

    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect operating system"
        exit 1
    fi

    . /etc/os-release

    case $ID in
    ubuntu | debian | pop | elementary | zorin | mint)
        log_success "Detected supported system: $PRETTY_NAME"
        ;;
    *)
        log_warn "Detected system: $PRETTY_NAME"
        log_warn "This script is designed for Ubuntu/Debian-based systems"
        log_warn "Proceeding anyway, but some packages might not be available"
        ;;
    esac
}

# Check if user has sudo privileges
check_sudo() {
    log_info "Checking sudo privileges..."

    if ! sudo -n true 2>/dev/null; then
        log_info "This script requires sudo privileges to install packages"
        log_info "You will be prompted for your password"

        if ! sudo true; then
            log_error "Failed to obtain sudo privileges"
            exit 1
        fi
    fi

    log_success "Sudo privileges confirmed"
}

# Update package lists
update_packages() {
    log_info "Updating package lists..."

    if sudo apt update; then
        log_success "Package lists updated successfully"
    else
        log_error "Failed to update package lists"
        exit 1
    fi
}

# Install essential packages
install_packages() {
    log_info "Installing essential development packages..."

    # List of packages to install
    packages=(
        "make"
        "build-essential"
        "libssl-dev"
        "zlib1g-dev"
        "libbz2-dev"
        "libreadline-dev"
        "libsqlite3-dev"
        "wget"
        "curl"
        "llvm"
        "libncursesw5-dev"
        "xz-utils"
        "tk-dev"
        "libxml2-dev"
        "libxmlsec1-dev"
        "libffi-dev"
        "liblzma-dev"
        "git"
    )

    log_info "Installing packages: ${packages[*]}"

    if sudo apt install -y "${packages[@]}"; then
        log_success "All packages installed successfully!"
    else
        log_error "Failed to install some packages"
        exit 1
    fi
}

# Check installed packages
verify_installation() {
    log_info "Verifying installation..."

    # Key packages to verify
    verify_packages=("gcc" "make" "curl" "wget" "git")

    for package in "${verify_packages[@]}"; do
        if command -v "$package" >/dev/null 2>&1; then
            log_success "$package is available"
        else
            log_warn "$package not found in PATH"
        fi
    done
}

# Show next steps
show_next_steps() {
    echo
    log_success "DevEssential installation completed!"
    echo
    log_info "Next steps:"
    echo "  1. Install pyenv for Python version management:"
    echo "     curl https://pyenv.run | bash"
    echo
    echo "  2. Add pyenv to your shell configuration:"
    echo "     echo 'export PYENV_ROOT=\"\$HOME/.pyenv\"' >> ~/.bashrc"
    echo "     echo '[[ -d \$PYENV_ROOT/bin ]] && export PATH=\"\$PYENV_ROOT/bin:\$PATH\"' >> ~/.bashrc"
    echo "     echo 'eval \"\$(pyenv init - bash)\"' >> ~/.bashrc"
    echo
    echo "  3. Reload your shell:"
    echo "     exec \"\$SHELL\""
    echo
    echo "  4. Install Python versions:"
    echo "     pyenv install 3.11.5"
    echo "     pyenv global 3.11.5"
    echo
    log_info "Happy coding! 🚀"
}

# Main execution
main() {
    print_banner
    check_system
    check_sudo
    update_packages
    install_packages
    verify_installation
    show_next_steps
}

# Handle interruption
trap 'log_error "Installation interrupted"; exit 1' INT

# Run main function
main "$@"

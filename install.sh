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

# Global variable for system type
SYSTEM_TYPE=""

# Check if running on supported system
check_system() {
    log_info "Checking system compatibility..."
    OS_TYPE="$(uname -s)"
    case "$OS_TYPE" in
        Linux*)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                case $ID in
                    ubuntu | debian | pop | elementary | zorin | mint)
                        SYSTEM_TYPE="linux"
                        log_success "Detected supported Linux system: $PRETTY_NAME"
                        ;;
                    *)
                        SYSTEM_TYPE="linux"
                        log_warn "Detected unsupported Linux distro: $PRETTY_NAME"
                        log_warn "Some packages may not install correctly"
                        ;;
                esac
            else
                log_error "Unknown Linux distribution"
                exit 1
            fi
            ;;
        Darwin*)
            SYSTEM_TYPE="macos"
            log_success "Detected macOS system"
            ;;
        *)
            log_error "Unsupported system: $OS_TYPE"
            exit 1
            ;;
    esac
}

# Check if user has sudo privileges (skipped on macOS)
check_sudo() {
    if [[ "$SYSTEM_TYPE" == "macos" ]]; then
        log_info "Skipping sudo check for macOS"
        return
    fi
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

# Ensure Homebrew is installed (macOS only)
ensure_homebrew() {
    if [[ "$SYSTEM_TYPE" != "macos" ]]; then return; fi

    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew not found, installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Load Homebrew env (Intel vs M1)
        if [[ -d /opt/homebrew/bin ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -d /usr/local/bin ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        if ! command -v brew &>/dev/null; then
            log_error "Homebrew installation failed"
            exit 1
        fi
        log_success "Homebrew installed"
    else
        log_info "Homebrew is already installed"
    fi
}

# Update package lists
update_packages() {
    log_info "Updating package lists..."

    if [[ "$SYSTEM_TYPE" == "linux" ]]; then
        sudo apt update && log_success "Linux packages updated"
    elif [[ "$SYSTEM_TYPE" == "macos" ]]; then
        brew update && log_success "Homebrew packages updated"
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
        "curl"
        "wget"
        "git"
        "llvm"
    )

    # Additional packages for Linux
    if [[ "$SYSTEM_TYPE" == "linux" ]]; then
        packages+=(
            "build-essential"
            "libssl-dev"
            "zlib1g-dev"
            "libbz2-dev"
            "libreadline-dev"
            "libsqlite3-dev"
            "libncursesw5-dev"
            "xz-utils"
            "tk-dev"
            "libxml2-dev"
            "libxmlsec1-dev"
            "libffi-dev"
            "liblzma-dev"
        )
    fi
    # Additional packages for macOS
    if [[ "$SYSTEM_TYPE" == "macos" ]]; then
        packages+=(
            "openssl@3"
            "zlib"
            "bzip2"
            "readline"
            "sqlite"
            "xz"
            "tk"
            "libxml2"
            "libffi"
        )
    fi

    log_info "Installing packages: ${packages[*]}"
    if [[ "$SYSTEM_TYPE" == "linux" ]]; then
        if sudo apt install -y "${packages[@]}"; then
            log_success "All packages installed successfully!"
        fi
    elif [[ "$SYSTEM_TYPE" == "macos" ]]; then
        # Ensure Homebrew is installed
        if ! command -v brew >/dev/null 2>&1; then
            log_info "Homebrew not found, installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)" # Required for new installs (Apple Silicon)
        fi
        brew install "${packages[@]}"
    else
        log_error "Failed to install some packages"
        exit 1
    fi

    install_nvm
}

# Install NVM (Node Version Manager)
install_nvm() {
    log_info "Installing NVM (Node Version Manager)..."

    # Download and run the latest NVM install script
    if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash; then
        log_success "NVM install script executed"

        # Source NVM immediately for current session
        export NVM_DIR="$HOME/.nvm"
        # shellcheck disable=SC1090
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

        log_success "NVM initialized in current session"

        # ------------------- Shell detection block -------------------
        USER_SHELL=$(basename "$SHELL")
        case "$USER_SHELL" in
            bash)
                SHELL_CONFIG="$HOME/.bashrc"
                ;;
            zsh)
                SHELL_CONFIG="$HOME/.zshrc"
                ;;
            fish)
                SHELL_CONFIG="$HOME/.config/fish/config.fish"
                ;;
            *)
                SHELL_CONFIG="$HOME/.profile"
                log_warn "Unrecognized shell ($USER_SHELL), defaulting to ~/.profile"
                ;;
        esac

        # Add NVM initialization to the shell config if not already added
        if ! grep -q 'export NVM_DIR="\$HOME/.nvm"' "$SHELL_CONFIG"; then
            {
                echo ''
                echo '# >>> NVM setup >>>'
                echo 'export NVM_DIR="$HOME/.nvm"'
                echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
                echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
                echo '# <<< NVM setup <<<'
            } >> "$SHELL_CONFIG"

            log_success "NVM configuration added to $SHELL_CONFIG"
        else
            log_info "NVM configuration already present in $SHELL_CONFIG"
        fi
    else
        log_error "Failed to install NVM"
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
    echo "  3. Install Python versions:"
    echo "     pyenv install 3.11.5"
    echo "     pyenv global 3.11.5"
    echo
    echo "  4. Reload shell again to ensure NVM is loaded:"
    echo "     exec \"\$SHELL\""
    echo
    echo "  5. Install Node.js using NVM:"
    echo "     nvm install --lts"
    echo "     nvm use --lts"
    log_info "Happy coding! 🚀"
}

# Main execution
main() {
    print_banner
    check_system
    check_sudo
    ensure_homebrew
    update_packages
    install_packages
    verify_installation
    show_next_steps
}

# Handle interruption
trap 'log_error "Installation interrupted"; exit 1' INT

# Run main function
main "$@"

#!/usr/bin/env bash

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "This installer must be run as root."
        echo "Run:"
        echo "  sudo ./install.sh"
        exit 1
    fi

    success "Running as root"
}

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot detect operating system."
        exit 1
    fi

    source /etc/os-release

    if [[ "${ID:-}" != "ubuntu" ]]; then
        error "Unsupported operating system: ${PRETTY_NAME:-unknown}"
        echo "This installer currently supports Ubuntu only."
        exit 1
    fi

    success "Ubuntu detected: $PRETTY_NAME"
}

REQUIRED_PACKAGES=(
    dnsmasq
    apache2
    php
    curl
    dnsutils
    iproute2
)

is_package_installed() {
    local package="$1"

    dpkg-query \
        -W \
        -f='${Status}' \
        "$package" 2>/dev/null \
        | grep -q "install ok installed"
}

check_dependencies() {
    echo
    info "Checking required packages..."
    echo

    local missing_packages=()

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if is_package_installed "$package"; then
            success "$package"
        else
            error "$package is not installed"
            missing_packages+=("$package")
        fi
    done

    if (( ${#missing_packages[@]} == 0 )); then
        echo
        success "All required packages are installed."
        return 0
    fi

    echo
    info "Missing packages: ${missing_packages[*]}"

    read -r -p "Install missing packages? [Y/n]: " answer

    if [[ "$answer" =~ ^[Nn]$ ]]; then
        error "Required packages are missing."
        exit 1
    fi

    echo
    info "Updating package lists..."

    apt-get update

    echo
    info "Installing missing packages..."

    apt-get install -y "${missing_packages[@]}"

    echo
    info "Verifying installed packages..."

    for package in "${missing_packages[@]}"; do
        if is_package_installed "$package"; then
            success "$package"
        else
            error "$package installation failed"
            exit 1
        fi
    done

    echo
    success "Required packages installed."
}

#!/usr/bin/env bash

print_header() {
    echo
    echo "========================================"
    echo "     DNS Connectivity Server"
    echo "            Installer"
    echo "========================================"
    echo
}

info() {
    echo "[*] $1"
}

success() {
    echo "[✓] $1"
}

error() {
    echo "[✗] $1" >&2
}

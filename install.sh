#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/system.sh"
source "$PROJECT_DIR/lib/network.sh"
source "$PROJECT_DIR/lib/config.sh"
source "$PROJECT_DIR/lib/validation.sh"
source "$PROJECT_DIR/lib/dnsmasq.sh"
source "$PROJECT_DIR/lib/apache.sh"

main() {
    print_header

    check_root
    check_os
    check_dependencies

    detect_network_interfaces
    show_network_interfaces
    select_network_interface

    collect_dns_configuration
    show_configuration_summary
    confirm_configuration

    generate_dnsmasq_config
    validate_dnsmasq_config

    prepare_systemd_resolved
    check_dns_port

    backup_dnsmasq_config
    install_dnsmasq_config

    restart_dnsmasq
    verify_dnsmasq
    verify_dns

    check_http_port
    deploy_php_page
    verify_apache_config
    restart_apache
    verify_apache

    echo
    echo "System checks passed."
}

main "$@"

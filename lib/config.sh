#!/usr/bin/env bash

DNS_PORT=53
UPSTREAM_DNS="8.8.8.8"
DNS_DOMAIN=""
DNS_HOSTNAME=""

collect_dns_configuration() {
    echo
    info "DNS configuration"
    echo

    while true; do
        read -r -p "DNS port [$DNS_PORT]: " input

        if [[ -z "$input" ]]; then
            input="$DNS_PORT"
        fi

        if is_valid_port "$input"; then
            DNS_PORT="$input"
            break
        fi

        error "Invalid port. Please enter a number between 1 and 65535."
    done

    while true; do
        read -r -p "Upstream DNS [$UPSTREAM_DNS]: " input

        if [[ -z "$input" ]]; then
            input="$UPSTREAM_DNS"
        fi

        if is_valid_ip "$input"; then
            UPSTREAM_DNS="$input"
            break
        fi

        error "Invalid IP address."
    done

    while true; do
        read -r -p "Domain: " input

        if is_valid_domain "$input"; then
            DNS_DOMAIN="$input"
            break
        fi

        error "Invalid domain name."
    done

    while true; do
        read -r -p "Hostname: " input

        if ! is_valid_hostname "$input"; then
            error "Invalid hostname."
            continue
        fi

        if ! is_hostname_in_domain "$input" "$DNS_DOMAIN"; then
            error "Hostname does not belong to the selected domain."
            continue
        fi

        DNS_HOSTNAME="$input"
        break
    done
}

show_configuration_summary() {
    echo
    echo "========================================"
    echo "        Configuration Summary"
    echo "========================================"
    echo

    echo "Network interface : $SELECTED_INTERFACE"
    echo "IPv4 address      : ${SERVER_IPV4:-none}"
    echo "IPv6 address      : ${SERVER_IPV6:-none}"
    echo
    echo "DNS port          : $DNS_PORT"
    echo "Upstream DNS      : $UPSTREAM_DNS"
    echo
    echo "Domain            : $DNS_DOMAIN"
    echo "Hostname          : $DNS_HOSTNAME"
    echo
    echo "========================================"
    echo
}

confirm_configuration() {
    local answer

    while true; do
        read -r -p "Apply this configuration? [Y/n]: " answer

        if [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]; then
            return 0
        fi

        if [[ "$answer" =~ ^[Nn]$ ]]; then
            info "Configuration cancelled."
            exit 0
        fi

        error "Please answer Y or N."
    done
}

#!/usr/bin/env bash

is_valid_port() {
    local port="$1"

    [[ "$port" =~ ^[0-9]+$ ]] \
        && (( port >= 1 )) \
        && (( port <= 65535 ))
}

is_valid_ipv4() {
    local ip="$1"
    local octet

    IFS='.' read -r -a octets <<< "$ip"

    if (( ${#octets[@]} != 4 )); then
        return 1
    fi

    for octet in "${octets[@]}"; do
        if [[ ! "$octet" =~ ^[0-9]+$ ]]; then
            return 1
        fi

        if (( octet < 0 || octet > 255 )); then
            return 1
        fi
    done

    return 0
}

is_valid_ipv6() {
    local ip="$1"

    [[ "$ip" == *:* ]]
}

is_valid_ip() {
    local ip="$1"

    is_valid_ipv4 "$ip" || is_valid_ipv6 "$ip"
}

is_valid_domain() {
    local domain="$1"

    [[ -n "$domain" ]] \
        && [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]]
}

is_valid_hostname() {
    local hostname="$1"

    [[ -n "$hostname" ]] \
        && [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]]
}

is_hostname_in_domain() {
    local hostname="$1"
    local domain="$2"

    [[ "$hostname" == "$domain" \
        || "$hostname" == *."$domain" ]]
}

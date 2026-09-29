#!/usr/bin/env bash

NETWORK_INTERFACES=()
NETWORK_IPV4=()
NETWORK_IPV6=()

detect_network_interfaces() {
    echo
    info "Detecting network interfaces..."
    echo

    NETWORK_INTERFACES=()
    NETWORK_IPV4=()
    NETWORK_IPV6=()

    local interfaces
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')

    if [[ -z "$interfaces" ]]; then
        error "No network interfaces found."
        exit 1
    fi

    while IFS= read -r interface; do
        [[ -z "$interface" ]] && continue

        local ipv4
        local ipv6

        ipv4=$(ip -4 -o addr show dev "$interface" \
            | awk '{print $4}' \
            | cut -d/ -f1 \
            | head -n1)

        ipv6=$(ip -6 -o addr show dev "$interface" \
            | awk '{print $4}' \
            | cut -d/ -f1 \
            | head -n1)

        NETWORK_INTERFACES+=("$interface")
        NETWORK_IPV4+=("$ipv4")
        NETWORK_IPV6+=("$ipv6")
    done <<< "$interfaces"
}

show_network_interfaces() {
    local index

    for index in "${!NETWORK_INTERFACES[@]}"; do
        echo "[$((index + 1))] ${NETWORK_INTERFACES[$index]}"

        if [[ -n "${NETWORK_IPV4[$index]}" ]]; then
            echo "    IPv4: ${NETWORK_IPV4[$index]}"
        else
            echo "    IPv4: none"
        fi

        if [[ -n "${NETWORK_IPV6[$index]}" ]]; then
            echo "    IPv6: ${NETWORK_IPV6[$index]}"
        else
            echo "    IPv6: none"
        fi

        echo
    done
}

select_network_interface() {
    local default_index=""
    local index
    local choice

    for index in "${!NETWORK_INTERFACES[@]}"; do
        if [[ -n "${NETWORK_IPV4[$index]}" ]] \
            && [[ "${NETWORK_INTERFACES[$index]}" != "lo" ]]; then
            default_index=$((index + 1))
            break
        fi
    done

    if [[ -z "$default_index" ]]; then
        error "No suitable network interface with an IPv4 address found."
        exit 1
    fi

    while true; do
        read -r -p "Select network interface [$default_index]: " choice

        if [[ -z "$choice" ]]; then
            choice="$default_index"
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] \
            && (( choice >= 1 )) \
            && (( choice <= ${#NETWORK_INTERFACES[@]} )); then
            break
        fi

        error "Invalid interface selection."
    done

    local selected_index=$((choice - 1))

    SELECTED_INTERFACE="${NETWORK_INTERFACES[$selected_index]}"
    SERVER_IPV4="${NETWORK_IPV4[$selected_index]}"
    SERVER_IPV6="${NETWORK_IPV6[$selected_index]}"

    echo
    success "Selected interface: $SELECTED_INTERFACE"

    if [[ -n "$SERVER_IPV4" ]]; then
        echo "    IPv4: $SERVER_IPV4"
    fi

    if [[ -n "$SERVER_IPV6" ]]; then
        echo "    IPv6: $SERVER_IPV6"
    fi
}

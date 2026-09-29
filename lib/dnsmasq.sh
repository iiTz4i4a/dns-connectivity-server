#!/usr/bin/env bash

DNSMASQ_TEMPLATE="$PROJECT_DIR/templates/dnsmasq.conf.template"
DNSMASQ_TEMP_CONFIG="/tmp/dns-connectivity-server-dnsmasq.conf"
SYSTEMD_RESOLVED_WAS_ACTIVE=false
SYSTEMD_RESOLVED_WAS_ENABLED=false

generate_dnsmasq_config() {
    echo
    info "Generating dnsmasq configuration..."

    if [[ ! -f "$DNSMASQ_TEMPLATE" ]]; then
        error "dnsmasq template not found: $DNSMASQ_TEMPLATE"
        exit 1
    fi

    sed \
        -e "s|{{DNS_PORT}}|$DNS_PORT|g" \
        -e "s|{{UPSTREAM_DNS}}|$UPSTREAM_DNS|g" \
        -e "s|{{SERVER_IPV4}}|$SERVER_IPV4|g" \
        -e "s|{{DNS_DOMAIN}}|$DNS_DOMAIN|g" \
        -e "s|{{DNS_HOSTNAME}}|$DNS_HOSTNAME|g" \
        -e "s|{{SELECTED_INTERFACE}}|$SELECTED_INTERFACE|g" \
        "$DNSMASQ_TEMPLATE" > "$DNSMASQ_TEMP_CONFIG"

    success "dnsmasq configuration generated."
}

validate_dnsmasq_config() {
    echo
    info "Validating dnsmasq configuration..."

    if dnsmasq --test --conf-file="$DNSMASQ_TEMP_CONFIG"; then
        success "dnsmasq configuration is valid."
    else
        error "dnsmasq configuration validation failed."
        exit 1
    fi
}
backup_dnsmasq_config() {
    local config_file="/etc/dnsmasq.conf"
    local backup_file

    echo
    info "Backing up existing dnsmasq configuration..."

    if [[ ! -f "$config_file" ]]; then
        info "No existing dnsmasq configuration found."
        return 0
    fi

    backup_file="/etc/dnsmasq.conf.backup.$(date +%Y%m%d_%H%M%S)"

    cp "$config_file" "$backup_file"

    success "Backup created: $backup_file"
}

install_dnsmasq_config() {
    local config_file="/etc/dnsmasq.conf"

    echo
    info "Installing dnsmasq configuration..."

    cp "$DNSMASQ_TEMP_CONFIG" "$config_file"

    chmod 644 "$config_file"

    success "dnsmasq configuration installed."
}

backup_resolv_conf() {
    local resolv_conf="/etc/resolv.conf"
    local backup_file

    echo
    info "Backing up /etc/resolv.conf..."

    if [[ ! -e "$resolv_conf" && ! -L "$resolv_conf" ]]; then
        info "No existing /etc/resolv.conf found."
        return 0
    fi

    backup_file="/etc/resolv.conf.dns-connectivity-backup"

    if [[ -e "$backup_file" || -L "$backup_file" ]]; then
        info "Backup already exists: $backup_file"
        return 0
    fi

    cp -a "$resolv_conf" "$backup_file"

    success "Backup created: $backup_file"
}

configure_resolv_conf() {
    local resolv_conf="/etc/resolv.conf"

    echo
    info "Configuring /etc/resolv.conf..."

    backup_resolv_conf

    if [[ -L "$resolv_conf" || -e "$resolv_conf" ]]; then
        rm -f "$resolv_conf"
    fi

    cat > "$resolv_conf" <<EOF
# DNS Connectivity Server
# Managed by dnsmasq installer

nameserver 127.0.0.1
EOF

    chmod 644 "$resolv_conf"

    success "/etc/resolv.conf configured to use dnsmasq."
}

prepare_systemd_resolved() {
    echo
    info "Checking systemd-resolved..."

    if systemctl is-active --quiet systemd-resolved; then
        SYSTEMD_RESOLVED_WAS_ACTIVE=true
    fi

    if systemctl is-enabled --quiet systemd-resolved; then
        SYSTEMD_RESOLVED_WAS_ENABLED=true
    fi

    if [[ "$SYSTEMD_RESOLVED_WAS_ACTIVE" != true ]]; then
        success "systemd-resolved is not active."
        return 0
    fi

    if ! ss -lntup | grep -q "systemd-resolve"; then
        success "systemd-resolved is active but does not occupy DNS port."
        return 0
    fi

    if ! ss -lntup | grep -q "systemd-resolve"; then
        success "systemd-resolved is active but does not occupy DNS port."
        return 0
    fi

    echo
    info "systemd-resolved is currently using DNS port 53."
    echo
    echo "dnsmasq needs port 53."
    echo "The installer can disable systemd-resolved and let dnsmasq"
    echo "handle DNS resolution instead."
    echo

    local answer

    while true; do
        read -r -p "Disable systemd-resolved and use dnsmasq? [Y/n]: " answer

        if [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]; then
            break
        fi

        if [[ "$answer" =~ ^[Nn]$ ]]; then
            error "Cannot continue while systemd-resolved occupies port 53."
            exit 1
        fi

        error "Please answer Y or N."
    done

    info "Stopping systemd-resolved..."

    systemctl stop systemd-resolved

    info "Disabling systemd-resolved..."

    systemctl disable systemd-resolved

    success "systemd-resolved disabled."

    configure_resolv_conf

    if ss -lntup | grep -qE ":${DNS_PORT}[[:space:]]"; then
        error "DNS port $DNS_PORT is still occupied."
        ss -lntup | grep -E ":${DNS_PORT}[[:space:]]"
        exit 1
    fi

    success "DNS port $DNS_PORT is now available."
}

check_dns_port() {
    echo
    info "Checking DNS port $DNS_PORT..."

    if ! ss -lntup | grep -qE ":${DNS_PORT}[[:space:]]"; then
        success "DNS port $DNS_PORT is available."
        return 0
    fi

    if systemctl is-active --quiet dnsmasq; then
        success "DNS port $DNS_PORT is already used by dnsmasq."
        return 0
    fi

    error "DNS port $DNS_PORT is already in use."

    echo
    echo "Processes using port $DNS_PORT:"
    ss -lntup | grep -E ":${DNS_PORT}[[:space:]]"

    echo

    if ss -lntup | grep -q "systemd-resolve"; then
        info "Port $DNS_PORT is currently used by systemd-resolved."
    fi

    return 1
}

restart_dnsmasq() {
    echo
    info "Restarting dnsmasq..."

    if systemctl restart dnsmasq; then
        success "dnsmasq restarted successfully."
        return 0
    fi

    error "Failed to restart dnsmasq."

    echo
    info "Attempting rollback..."

    rollback_dnsmasq
    rollback_systemd_resolved

    error "Installation failed. System configuration was rolled back."

    exit 1
}

verify_dnsmasq() {
    echo
    info "Checking dnsmasq service..."

    if systemctl is-active --quiet dnsmasq; then
        success "dnsmasq is running."
    else
        error "dnsmasq is not running."
        systemctl status dnsmasq --no-pager
        exit 1
    fi
}

rollback_dnsmasq() {
    local config_file="/etc/dnsmasq.conf"
    local backup_file

    echo
    info "Rolling back dnsmasq configuration..."

    backup_file=$(ls -1t /etc/dnsmasq.conf.backup.* 2>/dev/null | head -n1 || true)

    if [[ -z "$backup_file" ]]; then
        error "No dnsmasq backup found."
        return 1
    fi

    cp "$backup_file" "$config_file"

    success "Restored dnsmasq configuration from:"
    echo "    $backup_file"
}

rollback_systemd_resolved() {
    local resolv_conf="/etc/resolv.conf"
    local backup_file="/etc/resolv.conf.dns-connectivity-backup"

    echo
    info "Rolling back systemd-resolved configuration..."

    if [[ -f "$backup_file" || -L "$backup_file" ]]; then
        rm -f "$resolv_conf"
        cp -a "$backup_file" "$resolv_conf"

        success "Restored /etc/resolv.conf."
    else
        info "No /etc/resolv.conf backup found."
    fi

    if [[ "$SYSTEMD_RESOLVED_WAS_ENABLED" == true ]]; then
        systemctl enable systemd-resolved
    else
        systemctl disable systemd-resolved
    fi

    if [[ "$SYSTEMD_RESOLVED_WAS_ACTIVE" == true ]]; then
        systemctl start systemd-resolved
    else
        systemctl stop systemd-resolved
    fi

    success "systemd-resolved restored to its previous state."
}
verify_dns() {
    echo
    info "Verifying DNS..."

    echo
    info "Checking DNS port..."

    if ! ss -lntup | grep -qE ":${DNS_PORT}[[:space:]]"; then
        error "DNS port $DNS_PORT is not listening."
        return 1
    fi

    success "DNS port $DNS_PORT is listening."

    echo
    info "Checking local hostname resolution..."

    local local_result

    local_result=$(dig +short "$DNS_HOSTNAME" @127.0.0.1)

    if [[ "$local_result" != "$SERVER_IPV4" ]]; then
        error "Local DNS resolution failed."
        echo "Expected: $SERVER_IPV4"
        echo "Received: ${local_result:-none}"
        return 1
    fi

    success "$DNS_HOSTNAME resolves to $SERVER_IPV4."

    echo
    info "Checking upstream DNS resolution..."

    local upstream_result

    upstream_result=$(dig +short google.com @127.0.0.1)

    if [[ -z "$upstream_result" ]]; then
        error "Upstream DNS resolution failed."
        return 1
    fi

    success "Upstream DNS resolution works."

    echo
    success "DNS verification passed."
}

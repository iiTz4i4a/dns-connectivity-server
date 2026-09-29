#!/usr/bin/env bash

APACHE_DOCUMENT_ROOT="/var/www/html"
APACHE_INDEX_FILE="$APACHE_DOCUMENT_ROOT/index.php"

check_http_port() {
    local http_port=80

    echo
    info "Checking HTTP port $http_port..."

    if ! ss -lntup | grep -qE ":${http_port}[[:space:]]"; then
        success "HTTP port $http_port is available."
        return 0
    fi

    if systemctl is-active --quiet apache2; then
        success "HTTP port $http_port is already used by Apache."
        return 0
    fi

    error "HTTP port $http_port is already in use."

    echo
    echo "Processes using port $http_port:"
    ss -lntup | grep -E ":${http_port}[[:space:]]"

    return 1
}

deploy_php_page() {
    echo
    info "Deploying PHP connectivity page..."

    if [[ ! -f "$PROJECT_DIR/templates/index.php.template" ]]; then
        error "PHP template not found."
        exit 1
    fi

    if [[ -f "$APACHE_DOCUMENT_ROOT/index.html" ]]; then
        if [[ ! -f "$APACHE_DOCUMENT_ROOT/index.html.dns-connectivity-backup" ]]; then
            cp \
                "$APACHE_DOCUMENT_ROOT/index.html" \
                "$APACHE_DOCUMENT_ROOT/index.html.dns-connectivity-backup"

            success "Apache default page backed up."
        fi

        rm -f "$APACHE_DOCUMENT_ROOT/index.html"
    fi

    cp \
        "$PROJECT_DIR/templates/index.php.template" \
        "$APACHE_INDEX_FILE"

    chmod 644 "$APACHE_INDEX_FILE"

    success "PHP connectivity page deployed."
}
verify_apache_config() {
    echo
    info "Validating Apache configuration..."

    if apache2ctl configtest; then
        success "Apache configuration is valid."
    else
        error "Apache configuration validation failed."
        exit 1
    fi
}

restart_apache() {
    echo
    info "Restarting Apache..."

    if systemctl restart apache2; then
        success "Apache restarted successfully."
    else
        error "Failed to restart Apache."
        exit 1
    fi
}

verify_apache() {
    echo
    info "Checking Apache service..."

    if systemctl is-active --quiet apache2; then
        success "Apache is running."
    else
        error "Apache is not running."
        systemctl status apache2 --no-pager
        exit 1
    fi
}

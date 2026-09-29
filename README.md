# DNS Connectivity Server

Interactive Bash installer for setting up a lightweight DNS and HTTP connectivity test server on Ubuntu.

The project configures **dnsmasq** for local DNS resolution and **Apache + PHP** for a simple connectivity test endpoint.

It is designed primarily for internal networks, lab environments, QA/testing infrastructure, and troubleshooting DNS/HTTP connectivity.

---

## Features

* Interactive installation
* Ubuntu OS detection
* Automatic dependency detection and installation
* Network interface discovery
* IPv4/IPv6 interface information
* Interactive DNS configuration
* DNS port configuration
* Configurable upstream DNS server
* Custom DNS domain
* Custom hostname
* Input validation
* DNS port conflict detection
* Automatic handling of `systemd-resolved`
* Backup of existing `/etc/dnsmasq.conf`
* Backup of existing `/etc/resolv.conf`
* Automatic dnsmasq configuration generation
* dnsmasq configuration validation
* DNS service restart and verification
* Local hostname resolution test
* Upstream DNS resolution test
* Apache HTTP server setup
* PHP connectivity test page
* Backup of the default Apache page
* HTTP port conflict detection
* Apache configuration validation
* Apache service verification

---

## Example Use Case

The server can be used to provide a hostname such as:

```text
igors.test.berlin
```

which resolves to:

```text
192.168.2.144
```

The same hostname can then be used to access the HTTP connectivity endpoint:

```text
http://igors.test.berlin
```

The resulting page provides information about the connection, including:

* Request hostname
* Protocol
* Client IP
* Client hostname
* Server IP
* Server hostname
* HTTP status
* Apache version
* Request timestamp
* Request ID
* User-Agent

This makes the server useful for quickly verifying whether DNS and HTTP connectivity are working correctly.

---

## Requirements

### Operating System

Currently supported:

* Ubuntu 24.04 LTS

Other Linux distributions are not currently supported by the installer.

### Required privileges

The installer must be executed as `root`.

For example:

```bash
sudo ./install.sh
```

### Packages

The installer checks for and can install the following packages:

```text
dnsmasq
apache2
php
curl
dnsutils
iproute2
```

---

## Installation

Clone the repository:

```bash
git clone https://github.com/<your-username>/dns-connectivity-server.git
cd dns-connectivity-server
```

Make the installer executable:

```bash
chmod +x install.sh
```

Run the installer:

```bash
sudo ./install.sh
```

---

## Installation Flow

The installer performs the following steps.

### 1. Check privileges

The installer verifies that it is running as root.

### 2. Detect operating system

The installer currently supports Ubuntu.

Example:

```text
[✓] Ubuntu detected: Ubuntu 24.04.3 LTS
```

### 3. Check dependencies

Missing packages are detected and the user is asked whether they should be installed.

Example:

```text
[*] Checking required packages...

[✓] dnsmasq
[✓] apache2
[✓] php
[✓] curl
[✓] dnsutils
[✓] iproute2
```

### 4. Detect network interfaces

Available interfaces and their addresses are displayed:

```text
[1] lo
    IPv4: 127.0.0.1
    IPv6: ::1

[2] ens33
    IPv4: 192.168.2.144
    IPv6: none
```

The installer then asks which interface should be used.

### 5. Configure DNS

The installer asks for:

```text
DNS port
Upstream DNS
Domain
Hostname
```

Example:

```text
DNS port [53]: 53
Upstream DNS [8.8.8.8]: 8.8.8.8
Domain: test.berlin
Hostname: igors.test.berlin
```

### 6. Validate configuration

The generated dnsmasq configuration is tested before being installed:

```text
dnsmasq: syntax check OK.
[✓] dnsmasq configuration is valid.
```

### 7. Handle systemd-resolved

If `systemd-resolved` is using port 53, the installer detects the conflict and asks whether it should be disabled.

This allows dnsmasq to use port 53.

The existing `/etc/resolv.conf` is backed up before changes are made.

### 8. Configure dnsmasq

The installer backs up the existing configuration:

```text
/etc/dnsmasq.conf.backup.YYYYMMDD_HHMMSS
```

and installs the generated configuration.

### 9. Verify DNS

The installer checks:

* DNS port availability/listening state
* Local hostname resolution
* Upstream DNS resolution

Example:

```text
[✓] DNS port 53 is listening.
[✓] igors.test.berlin resolves to 192.168.2.144.
[✓] Upstream DNS resolution works.
[✓] DNS verification passed.
```

### 10. Configure Apache and PHP

The installer deploys the PHP connectivity page to:

```text
/var/www/html/index.php
```

The original Ubuntu Apache default page is backed up if present:

```text
/var/www/html/index.html.dns-connectivity-backup
```

### 11. Verify HTTP

Apache configuration is validated and the service is restarted.

The installer verifies that Apache is running successfully.

---

## Configuration Example

A generated dnsmasq configuration can look like:

```ini
# DNS Connectivity Server
# Generated automatically by installer

port=53

server=8.8.8.8

domain-needed
bogus-priv

listen-address=127.0.0.1,192.168.2.144

expand-hosts
domain=test.berlin

address=/igors.test.berlin/192.168.2.144

cache-size=1000

interface=ens33
```

---

## Connectivity Test Page

After installation, open:

```text
http://igors.test.berlin
```

The page displays information about the HTTP request.

Example:

```text
DNS Connectivity Test

Status              OK
Request hostname    igors.test.berlin
Protocol            HTTP
Client IP           192.168.2.144
Client hostname     192.168.2.144
Server IP            192.168.2.144
Server hostname     cickalenko
HTTP status         200
Apache version      Apache/2.4.58 (Ubuntu)
Request time        2026-09-29 11:33:38 UTC
Request ID          a2d0d77224206896
User Agent          curl/8.5.0
```

---

## Manual Verification

After installation, DNS can be tested with:

```bash
dig igors.test.berlin
```

or:

```bash
dig @127.0.0.1 igors.test.berlin
```

Upstream DNS forwarding can be tested with:

```bash
dig google.com
```

HTTP can be tested with:

```bash
curl http://igors.test.berlin
```

HTTP headers can be checked with:

```bash
curl -I http://igors.test.berlin
```

Check dnsmasq:

```bash
systemctl status dnsmasq
```

Check Apache:

```bash
systemctl status apache2
```

Check DNS listeners:

```bash
sudo ss -lntup | grep ':53'
```

Check HTTP listeners:

```bash
sudo ss -lntup | grep ':80'
```

---

## Project Structure

```text
dns-connectivity-server/
├── install.sh
│
├── config/
│   └── defaults.conf
│
├── lib/
│   ├── common.sh
│   ├── system.sh
│   ├── network.sh
│   ├── validation.sh
│   ├── config.sh
│   ├── dnsmasq.sh
│   └── apache.sh
│
├── templates/
│   ├── dnsmasq.conf.template
│   └── index.php.template
│
└── tests/
```

### `install.sh`

Main installer entry point.

### `lib/common.sh`

Common output and helper functions.

### `lib/system.sh`

System and dependency checks.

### `lib/network.sh`

Network interface detection and selection.

### `lib/validation.sh`

Input validation functions.

### `lib/config.sh`

Interactive configuration collection and summary.

### `lib/dnsmasq.sh`

dnsmasq configuration generation, installation, service management, DNS verification, and rollback functionality.

### `lib/apache.sh`

Apache/PHP deployment and Apache service verification.

### `templates/`

Templates used to generate configuration files and the connectivity page.

---

## Configuration Files Modified

The installer may modify the following system files:

```text
/etc/dnsmasq.conf
/etc/resolv.conf
/var/www/html/index.php
```

It may also interact with:

```text
systemd-resolved
dnsmasq
apache2
```

Existing configuration files are backed up before they are replaced where supported by the current installer.

---

## DNS Architecture

The current architecture is intentionally simple:

```text
                    ┌──────────────────┐
                    │      Client      │
                    └────────┬─────────┘
                             │
                             │ DNS :53
                             ▼
                    ┌──────────────────┐
                    │     dnsmasq      │
                    │                  │
                    │ Local DNS        │
                    │ + DNS forwarding │
                    └───────┬──────────┘
                            │
                  ┌─────────┴─────────┐
                  │                   │
             Local record        Upstream DNS
                  │                   │
                  ▼                   ▼
       igors.test.berlin      8.8.8.8
                  │
                  ▼
            192.168.2.144
                  │
                  │ HTTP :80
                  ▼
             ┌───────────┐
             │  Apache   │
             │    +      │
             │   PHP     │
             └─────┬─────┘
                   │
                   ▼
          Connectivity Test Page
```

---

## Current Status

The current version is a working MVP.

The installer has been tested on:

```text
Ubuntu 24.04.3 LTS
```

The complete installation flow has been successfully tested, including:

```text
Network detection
       ↓
Configuration
       ↓
dnsmasq generation
       ↓
dnsmasq validation
       ↓
systemd-resolved handling
       ↓
DNS service
       ↓
Local DNS resolution
       ↓
Upstream DNS resolution
       ↓
Apache
       ↓
PHP
       ↓
HTTP connectivity test
```

---

## Roadmap

Possible future improvements:

* [ ] Apache VirtualHost configuration
* [ ] Automatic `ServerName` configuration
* [ ] Full IPv6 DNS support
* [ ] More robust IPv4/IPv6 validation
* [ ] Safe `/etc/hosts` management
* [ ] Improved rollback handling
* [ ] Complete uninstall script
* [ ] Restore previous `systemd-resolved` state
* [ ] Restore previous Apache configuration
* [ ] Non-interactive installation mode
* [ ] Configuration file / CLI arguments
* [ ] More comprehensive automated tests
* [ ] Improved idempotent installation
* [ ] HTTPS support
* [ ] Better logging
* [ ] Additional connectivity checks
* [ ] Support for additional Ubuntu versions

---

## Safety

This installer modifies system networking and web-server configuration.

Before running it on a production system, review the source code and make sure you understand the changes it will make.

The installer is currently intended primarily for:

* Development environments
* QA environments
* Internal networks
* Test labs
* Connectivity troubleshooting

It should not be considered production-ready until the rollback, uninstall, IPv6, and configuration-management functionality is completed.

---

## License

This project is licensed under the MIT License.

See [LICENSE](LICENSE) for details.

#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  CONFIGURATION INITIALE DU SERVEUR"
echo "============================================"
echo ""

if [ "$VPS_SKIP_UPDATES" = false ]; then
    log_step "Mise à jour du système..."
    apt update && apt upgrade -y
    log_success "Système mis à jour"
fi

log_step "Installation des paquets essentiels..."
PACKAGES="curl wget git vim build-essential ufw fail2ban htop nano"
PACKAGES="$PACKAGES net-tools software-properties-common apt-transport-https"
PACKAGES="$PACKAGES ca-certificates gnupg lsb-release unzip zip tree tmux"
PACKAGES="$PACKAGES screen ncdu jq man-db bash-completion"

[ "$VPS_INSTALL_NEOVIM" = true ] && PACKAGES="$PACKAGES neovim"

apt install -y $PACKAGES
log_success "Paquets installés"

log_step "Configuration timezone..."
timedatectl set-timezone "$VPS_TIMEZONE"
log_success "Timezone: $VPS_TIMEZONE"

log_step "Configuration locale..."
locale-gen "$VPS_LOCALE" 2>/dev/null || true
update-locale LANG="$VPS_LOCALE" 2>/dev/null || true
log_success "Locale: $VPS_LOCALE"

log_step "Configuration swap..."
if [ ! -f /swapfile ]; then
    fallocate -l "$VPS_SWAP_SIZE" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    log_success "Swap $VPS_SWAP_SIZE créé"
else
    log_warning "Swap existant"
fi

log_step "Optimisations système..."
if ! grep -q "# Optimisations VPS" /etc/sysctl.conf; then
    cat >> /etc/sysctl.conf <<EOF

# Optimisations VPS
vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
fs.file-max=2097152
fs.inotify.max_user_watches=524288
EOF
    sysctl -p > /dev/null 2>&1
    log_success "Optimisations appliquées"
fi

log_step "Configuration limites..."
if ! grep -q "# Limites dev" /etc/security/limits.conf; then
    cat >> /etc/security/limits.conf <<EOF

# Limites dev
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF
    log_success "Limites configurées"
fi

echo ""
log_success "✅ Configuration initiale terminée"
echo ""
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  CONFIGURATION SSH"
echo "============================================"
echo ""

log_step "Sauvegarde config SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
log_success "Sauvegarde créée"

PERMIT_ROOT="yes"
[ "$VPS_SSH_DISABLE_ROOT" = true ] && PERMIT_ROOT="no"

PASSWORD_AUTH="yes"
[ "$VPS_SSH_DISABLE_PASSWORD" = true ] && PASSWORD_AUTH="no"

cat > /etc/ssh/sshd_config <<EOF
# SSH Config - Auto-generated
Port $VPS_SSH_PORT
Protocol 2

# Auth
PermitRootLogin $PERMIT_ROOT
PubkeyAuthentication yes
PasswordAuthentication $PASSWORD_AUTH
PermitEmptyPasswords no
UsePAM yes

# Users
AllowUsers $VPS_USERS

# Security
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10

# VSCode Remote
AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server
EOF

log_success "Config SSH créée"

if sshd -t; then
    log_success "✅ Config valide"
else
    log_error "❌ Config invalide"
    cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
    exit 1
fi

echo ""
log_warning "⚠️  SSH va redémarrer"
log_warning "   Port: $VPS_SSH_PORT"
log_warning "   Auth clé: $([ "$VPS_SSH_DISABLE_PASSWORD" = true ] && echo "UNIQUEMENT" || echo "OUI")"
echo ""

if ! confirm "Redémarrer SSH ?"; then
    log_warning "SSH non redémarré"
    exit 0
fi

systemctl restart sshd

if systemctl is-active --quiet sshd; then
    log_success "✅ SSH redémarré"
    echo ""
    log_info "Testez depuis un autre terminal:"
    server_ip=$(hostname -I | awk '{print $1}')
    for user in $VPS_USERS; do
        echo "  ssh -p $VPS_SSH_PORT $user@$server_ip"
    done
else
    log_error "❌ Erreur"
    cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
    systemctl restart sshd
    exit 1
fi

echo ""
log_success "✅ SSH configuré"
echo ""
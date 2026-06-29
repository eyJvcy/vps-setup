#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  PROTECTION SSH AU DÉMARRAGE"
echo "============================================"
echo ""

log_step "Création du service de protection SSH..."

cat > /etc/systemd/system/ssh-protection.service <<EOF
[Unit]
Description=Protection SSH - Désactive le socket systemd au boot
After=network.target
Before=ssh.service sshd.service

[Service]
Type=oneshot
ExecStart=/bin/systemctl stop ssh.socket
ExecStart=/bin/systemctl stop sshd.socket
ExecStart=/bin/systemctl mask ssh.socket
ExecStart=/bin/systemctl mask sshd.socket
ExecStart=/bin/systemctl restart ssh.service
ExecStart=/usr/sbin/ufw allow $VPS_SSH_PORT/tcp
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

log_success "Service créé"

log_step "Activation du service..."
systemctl daemon-reload
systemctl enable ssh-protection.service
systemctl start ssh-protection.service

if systemctl is-active --quiet ssh-protection.service; then
    log_success "✅ Service actif"
else
    log_warning "Service démarré mais pas actif (normal pour oneshot)"
fi

echo ""
log_info "Le service ssh-protection garantit que:"
echo "  • Le socket systemd est masqué au boot"
echo "  • SSH redémarre correctement"
echo "  • Le port $VPS_SSH_PORT est autorisé dans UFW"
echo ""

log_success "✅ Protection SSH configurée"
echo ""
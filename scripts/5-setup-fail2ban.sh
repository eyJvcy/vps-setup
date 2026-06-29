#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  CONFIGURATION FAIL2BAN"
echo "============================================"
echo ""

log_step "Configuration fail2ban..."

cat > /etc/fail2ban/jail.local <<EOF
# Configuration fail2ban - Auto-generated
[DEFAULT]
bantime = $VPS_FAIL2BAN_BANTIME
findtime = $VPS_FAIL2BAN_FINDTIME
maxretry = $VPS_FAIL2BAN_MAXRETRY
destemail = root@localhost
sendername = Fail2Ban-VPS
action = %(action_mwl)s

[sshd]
enabled = true
port = $VPS_SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = $VPS_FAIL2BAN_MAXRETRY
bantime = $((VPS_FAIL2BAN_BANTIME * 2))
findtime = $VPS_FAIL2BAN_FINDTIME

[sshd-ddos]
enabled = true
port = $VPS_SSH_PORT
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 2
bantime = $((VPS_FAIL2BAN_BANTIME * 4))
findtime = $((VPS_FAIL2BAN_FINDTIME / 2))
EOF

log_success "Config créée"

log_step "Activation fail2ban..."
systemctl enable fail2ban
systemctl restart fail2ban

sleep 2

if systemctl is-active --quiet fail2ban; then
    log_success "✅ fail2ban actif"
    echo ""
    log_info "Status:"
    fail2ban-client status
else
    log_error "❌ Erreur fail2ban"
    journalctl -u fail2ban -n 20
    exit 1
fi

echo ""
log_success "✅ fail2ban configuré"
log_info "Commandes utiles:"
echo "  • Status: fail2ban-client status sshd"
echo "  • Débannir IP: fail2ban-client set sshd unbanip <IP>"
echo ""
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

# Détecter le nom du service SSH
if systemctl list-units --type=service | grep -q "ssh.service"; then
    SSH_SERVICE="ssh"
elif systemctl list-units --type=service | grep -q "sshd.service"; then
    SSH_SERVICE="sshd"
else
    log_error "Service SSH introuvable"
    exit 1
fi

log_info "Service SSH détecté: $SSH_SERVICE"

echo "============================================"
echo "  CONFIGURATION SSH"
echo "============================================"
echo ""

log_step "Sauvegarde config SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
log_success "Sauvegarde créée"

log_step "Création de la configuration SSH..."

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

log_step "Validation de la configuration..."
if sshd -t; then
    log_success "✅ Config valide"
else
    log_error "❌ Config invalide"
    cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
    exit 1
fi

# ============================================
# CORRECTION CRITIQUE : Désactivation du socket systemd
# ============================================
log_step "Désactivation du socket systemd..."

# Arrêter le socket
systemctl stop ssh.socket 2>/dev/null
systemctl stop sshd.socket 2>/dev/null

# Désactiver le socket
systemctl disable ssh.socket 2>/dev/null
systemctl disable sshd.socket 2>/dev/null

# MASQUER le socket pour qu'il ne se réactive JAMAIS
systemctl mask ssh.socket 2>/dev/null
systemctl mask sshd.socket 2>/dev/null

log_success "Socket systemd masqué définitivement"

echo ""
log_warning "⚠️  SSH va redémarrer"
log_warning "   Port: $VPS_SSH_PORT"
log_warning "   Auth clé: $([ "$VPS_SSH_DISABLE_PASSWORD" = true ] && echo "UNIQUEMENT" || echo "OUI")"
log_warning "   Root: $([ "$VPS_SSH_DISABLE_ROOT" = true ] && echo "DÉSACTIVÉ" || echo "ACTIVÉ")"
echo ""
log_warning "⚠️  Assurez-vous d'avoir ajouté vos clés SSH publiques !"
echo ""

if ! confirm "Redémarrer SSH ?"; then
    log_warning "SSH non redémarré"
    log_info "Pour appliquer manuellement:"
    echo "  systemctl mask ssh.socket"
    echo "  systemctl restart $SSH_SERVICE"
    exit 0
fi

log_step "Redémarrage du service SSH..."
systemctl restart $SSH_SERVICE

sleep 3

# Vérification que SSH écoute sur le bon port
log_step "Vérification du port d'écoute..."
PORT_CHECK=$(ss -tlnp | grep ssh | grep -o ":$VPS_SSH_PORT" | head -1)

if [ -n "$PORT_CHECK" ]; then
    log_success "✅ SSH écoute sur le port $VPS_SSH_PORT"
    echo ""
    log_info "Testez depuis un autre terminal:"
    server_ip=$(hostname -I | awk '{print $1}')
    for user in $VPS_USERS; do
        echo "  ssh -p $VPS_SSH_PORT $user@$server_ip"
    done
else
    log_error "❌ SSH n'écoute PAS sur le port $VPS_SSH_PORT"
    log_error "Port actuel: $(ss -tlnp | grep ssh | grep -o ':[0-9]*' | head -1)"
    log_warning "Restauration de la configuration..."
    cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
    systemctl restart $SSH_SERVICE
    exit 1
fi

echo ""
log_success "✅ SSH configuré"
echo ""
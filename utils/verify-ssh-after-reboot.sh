#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

echo "============================================"
echo "  VÉRIFICATION SSH APRÈS REBOOT"
echo "============================================"
echo ""

# 1. Service SSH
echo "1. Service SSH:"
if systemctl is-active --quiet ssh; then
    log_success "SSH actif"
else
    log_error "SSH inactif"
    systemctl start ssh
fi

# 2. Socket systemd
echo ""
echo "2. Socket systemd:"
if systemctl is-active --quiet ssh.socket; then
    log_error "❌ Socket ACTIF (PROBLÈME)"
    log_warning "Correction automatique..."
    systemctl mask ssh.socket
    systemctl restart ssh
else
    log_success "Socket inactif"
fi

# 3. Port d'écoute
echo ""
echo "3. Port d'écoute:"
PORT=$(ss -tlnp | grep ssh | grep -o ':[0-9]*' | head -1 | tr -d ':')
if [ "$PORT" = "$VPS_SSH_PORT" ]; then
    log_success "SSH écoute sur le port $VPS_SSH_PORT"
else
    log_error "SSH écoute sur le port $PORT (devrait être $VPS_SSH_PORT)"
    log_warning "Vérifiez /etc/ssh/sshd_config"
fi

# 4. Pare-feu
echo ""
echo "4. Pare-feu:"
if ufw status | grep -q "$VPS_SSH_PORT.*ALLOW"; then
    log_success "Port $VPS_SSH_PORT autorisé dans UFW"
else
    log_error "Port $VPS_SSH_PORT NON autorisé"
    log_warning "Correction automatique..."
    ufw allow $VPS_SSH_PORT/tcp
fi

# 5. Service de protection
echo ""
echo "5. Service ssh-protection:"
if systemctl is-enabled --quiet ssh-protection 2>/dev/null; then
    log_success "Service ssh-protection activé"
else
    log_warning "Service ssh-protection non activé"
    log_info "Exécutez: bash scripts/3b-protect-ssh.sh"
fi

# 6. Clés SSH
echo ""
echo "6. Clés SSH:"
for user in $VPS_USERS; do
    if [ -f "/home/$user/.ssh/authorized_keys" ]; then
        count=$(wc -l < /home/$user/.ssh/authorized_keys 2>/dev/null || echo 0)
        if [ "$count" -gt 0 ]; then
            log_success "$user: $count clé(s)"
        else
            log_warning "$user: Fichier vide"
        fi
    else
        log_error "$user: Pas de clés"
    fi
done

echo ""
echo "============================================"
if [ "$PORT" = "$VPS_SSH_PORT" ] && ufw status | grep -q "$VPS_SSH_PORT.*ALLOW" && ! systemctl is-active --quiet ssh.socket; then
    log_success "✅✅✅ Configuration SSH correcte !"
    echo ""
    log_info "Vous pouvez vous connecter avec:"
    server_ip=$(hostname -I | awk '{print $1}')
    for user in $VPS_USERS; do
        echo "  ssh -p $VPS_SSH_PORT $user@$server_ip"
    done
else
    log_error "❌ Configuration SSH incorrecte"
    echo ""
    log_info "Corrections automatiques appliquées"
    log_info "Si le problème persiste, exécutez:"
    echo "  systemctl mask ssh.socket"
    echo "  systemctl restart ssh"
    echo "  ufw allow $VPS_SSH_PORT/tcp"
fi
echo ""
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

echo "============================================"
echo "  GÉNÉRATION CONFIG SSH LOCALE"
echo "============================================"
echo ""

log_info "Ce script génère la configuration SSH pour votre machine locale"
echo ""

# Demander l'IP ou domaine
read -p "IP ou domaine du serveur: " SERVER_HOST

if [ -z "$SERVER_HOST" ]; then
    log_error "Adresse serveur requise"
    exit 1
fi

# Générer le fichier
CONFIG_FILE="ssh_config_local.txt"

cat > $CONFIG_FILE <<EOF
# ============================================
# Configuration SSH pour VPS
# À ajouter dans ~/.ssh/config sur votre machine locale
# ============================================

EOF

for user in $VPS_USERS; do
    cat >> $CONFIG_FILE <<EOF
Host vps-$user
    HostName $SERVER_HOST
    Port $VPS_SSH_PORT
    User $user
    IdentityFile ~/.ssh/vps_$user
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes
    ForwardAgent yes

EOF
done

log_success "✅ Configuration générée: $CONFIG_FILE"
echo ""

log_info "═══════════════════════════════════════════"
log_info "INSTRUCTIONS POUR VOTRE MACHINE LOCALE"
log_info "═══════════════════════════════════════════"
echo ""

echo "1️⃣  Générez les clés SSH pour chaque utilisateur:"
echo ""
for user in $VPS_USERS; do
    echo "   ssh-keygen -t ed25519 -C \"$user\" -f ~/.ssh/vps_$user"
done
echo ""

echo "2️⃣  Copiez les clés publiques sur le serveur:"
echo ""
for user in $VPS_USERS; do
    echo "   ssh-copy-id -i ~/.ssh/vps_$user.pub -p $VPS_SSH_PORT $user@$SERVER_HOST"
done
echo ""
echo "   OU manuellement:"
for user in $VPS_USERS; do
    echo "   cat ~/.ssh/vps_$user.pub | ssh -p $VPS_SSH_PORT root@$SERVER_HOST 'cat >> /home/$user/.ssh/authorized_keys'"
done
echo ""

echo "3️⃣  Ajoutez la configuration SSH:"
echo ""
echo "   cat $CONFIG_FILE >> ~/.ssh/config"
echo ""
echo "   OU éditez manuellement:"
echo "   nano ~/.ssh/config"
echo ""

echo "4️⃣  Testez les connexions:"
echo ""
for user in $VPS_USERS; do
    echo "   ssh vps-$user"
done
echo ""

echo "5️⃣  Configuration VSCode Remote SSH:"
echo ""
echo "   • Installez l'extension 'Remote - SSH'"
echo "   • Ctrl+Shift+P → 'Remote-SSH: Connect to Host'"
echo "   • Sélectionnez: vps-perso, vps-42, ou vps-travail"
echo ""

log_info "═══════════════════════════════════════════"
echo ""

log_success "✅ Configuration générée avec succès !"
echo ""
log_info "Fichier créé: $(pwd)/$CONFIG_FILE"
echo ""
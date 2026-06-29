#!/bin/bash
# ============================================
# INSTALLATION COMPLÈTE AUTOMATIQUE
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source utils/functions.sh
load_config

check_root

clear
echo "============================================"
echo "  INSTALLATION COMPLÈTE DU VPS"
echo "============================================"
echo ""

log_warning "Configuration chargée depuis: config.env"
echo ""
log_info "Paramètres principaux:"
echo "  • Utilisateurs: $VPS_USERS"
echo "  • Port SSH: $VPS_SSH_PORT"
echo "  • Timezone: $VPS_TIMEZONE"
echo "  • C/C++: $([ "$VPS_INSTALL_C_CPP" = true ] && echo "✓" || echo "✗")"
echo "  • Node.js: $([ "$VPS_INSTALL_NODE" = true ] && echo "✓" || echo "✗")"
echo "  • Python: $([ "$VPS_INSTALL_PYTHON" = true ] && echo "✓" || echo "✗")"
echo "  • Docker: $([ "$VPS_INSTALL_DOCKER" = true ] && echo "✓" || echo "✗")"
echo "  • Zsh: $([ "$VPS_INSTALL_ZSH" = true ] && echo "✓" || echo "✗")"
echo ""

if ! confirm "Voulez-vous continuer avec cette configuration ?"; then
    log_error "Installation annulée"
    exit 1
fi

echo ""
log_info "Début de l'installation..."
echo ""

SCRIPTS=(
    "scripts/1-initial-setup.sh:Configuration initiale du système"
    "scripts/2-create-users.sh:Création des utilisateurs"
    "scripts/3-setup-ssh.sh:Configuration SSH sécurisée"
    "scripts/4-setup-firewall.sh:Configuration du pare-feu"
    "scripts/5-setup-fail2ban.sh:Configuration fail2ban"
    "scripts/6-install-dev-tools.sh:Installation des outils de développement"
    "scripts/7-configure-git.sh:Configuration Git"
)

[ "$VPS_CONFIGURE_VIM" = true ] && SCRIPTS+=("scripts/8-configure-vim.sh:Configuration Vim")
[ "$VPS_INSTALL_ZSH" = true ] && SCRIPTS+=("scripts/9-install-zsh.sh:Installation Zsh")

total=${#SCRIPTS[@]}
current=0

for item in "${SCRIPTS[@]}"; do
    ((current++))
    script="${item%%:*}"
    description="${item##*:}"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_step "Étape $current/$total: $description"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ -f "$script" ]; then
        bash "$script"
        if [ $? -ne 0 ]; then
            log_error "Erreur lors de l'exécution de $script"
            exit 1
        fi
        
        [ "$current" -lt "$total" ] && pause_script
    else
        log_error "Script introuvable: $script"
        exit 1
    fi
done

echo ""
echo "============================================"
log_success "✅ INSTALLATION COMPLÈTE TERMINÉE !"
echo "============================================"
echo ""

log_info "Récapitulatif:"
echo "  ✓ Système configuré"
echo "  ✓ Utilisateurs: $VPS_USERS"
echo "  ✓ SSH sécurisé (port $VPS_SSH_PORT)"
echo "  ✓ Pare-feu activé"
echo "  ✓ fail2ban actif"
echo "  ✓ Outils de développement installés"
[ "$VPS_CONFIGURE_VIM" = true ] && echo "  ✓ Vim configuré"
[ "$VPS_INSTALL_ZSH" = true ] && echo "  ✓ Zsh installé"
echo ""

log_info "Prochaines étapes:"
echo "  1. Testez SSH depuis un autre terminal"
echo "  2. Déconnectez-vous et reconnectez-vous"
echo "  3. Générez la config SSH locale: ./utils/generate-ssh-config.sh"
echo ""

log_success "Votre VPS est prêt ! 🚀"
echo ""
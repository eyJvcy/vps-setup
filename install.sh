#!/bin/bash
# ============================================
# INSTALLATION AUTOMATIQUE VPS
# Usage: curl -sSL https://raw.githubusercontent.com/eyjvcy/vps-setup/main/install.sh | bash
# ============================================

set -e

REPO_URL="${VPS_REPO_URL:-https://github.com/eyjvcy/vps-setup}"
REPO_BRANCH="${VPS_REPO_BRANCH:-main}"
INSTALL_DIR="/root/vps-setup"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

clear
echo "============================================"
echo "  INSTALLATION AUTOMATIQUE VPS"
echo "============================================"
echo ""

log_info "Dépôt: $REPO_URL"
log_info "Branche: $REPO_BRANCH"
log_info "Destination: $INSTALL_DIR"
echo ""

if ! command -v git &> /dev/null; then
    log_step "Installation de git..."
    apt update -qq
    apt install -y git
    log_success "Git installé"
fi

if [ -d "$INSTALL_DIR" ]; then
    log_warning "Le répertoire $INSTALL_DIR existe déjà"
    read -p "Voulez-vous le supprimer et recommencer ? (o/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        rm -rf "$INSTALL_DIR"
        log_success "Répertoire supprimé"
    else
        log_info "Mise à jour du dépôt existant..."
        cd "$INSTALL_DIR"
        git pull origin $REPO_BRANCH
        log_success "Dépôt mis à jour"
    fi
fi

if [ ! -d "$INSTALL_DIR" ]; then
    log_step "Clonage du dépôt..."
    git clone -b $REPO_BRANCH $REPO_URL $INSTALL_DIR
    log_success "Dépôt cloné"
fi

cd "$INSTALL_DIR"

log_step "Configuration des permissions..."
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x utils/*.sh 2>/dev/null || true
chmod +x install-all.sh 2>/dev/null || true
log_success "Permissions configurées"

echo ""
log_success "✅ Téléchargement terminé !"
echo ""
log_info "Prochaines étapes:"
echo ""
echo "  1. Éditez le fichier de configuration:"
echo "     nano $INSTALL_DIR/config.env"
echo ""
echo "  2. Lancez l'installation complète:"
echo "     cd $INSTALL_DIR && ./install-all.sh"
echo ""

read -p "Voulez-vous éditer la configuration maintenant ? (o/N) " -n 1
echo ""
if [[ $REPLY =~ ^[Oo]$ ]]; then
    ${EDITOR:-nano} config.env
    echo ""
    read -p "Voulez-vous lancer l'installation complète maintenant ? (o/N) " -n 1
    echo ""
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        ./install-all.sh
    fi
fi
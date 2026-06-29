#!/bin/bash
# ============================================
# FONCTIONS COMMUNES
# ============================================

# Couleurs
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_substep() {
    echo -e "${CYAN}  →${NC} $1"
}

# Vérifications
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
}

# Confirmation
confirm() {
    if [ "$VPS_AUTO_CONFIRM" = true ]; then
        return 0
    fi
    
    local message="$1"
    read -p "$message (o/N) " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Oo]$ ]]
}

# Pause
pause_script() {
    if [ "$VPS_AUTO_CONFIRM" = true ]; then
        return 0
    fi
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
    echo ""
}

# Charger la configuration
load_config() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if [ -f "$script_dir/config.env" ]; then
        source "$script_dir/config.env"
    else
        log_error "Fichier config.env introuvable dans $script_dir"
        exit 1
    fi
}

# Obtenir la config Git pour un utilisateur
get_git_config() {
    local username="$1"
    for config in "${VPS_GIT_CONFIG[@]}"; do
        local user=$(echo "$config" | cut -d: -f1)
        if [ "$user" = "$username" ]; then
            local name=$(echo "$config" | cut -d: -f2)
            local email=$(echo "$config" | cut -d: -f3)
            echo "$name|$email"
            return 0
        fi
    done
    echo "|"
}
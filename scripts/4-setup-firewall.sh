#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  CONFIGURATION PARE-FEU"
echo "============================================"
echo ""

log_step "Réinitialisation UFW..."
ufw --force reset
log_success "Réinitialisé"

log_step "Règles par défaut..."
ufw default deny incoming
ufw default allow outgoing
log_success "Configuré"

# ⚠️ IMPORTANT : Autoriser SSH EN PREMIER !
log_step "Port SSH: $VPS_SSH_PORT (PRIORITAIRE)"
ufw allow $VPS_SSH_PORT/tcp comment 'SSH'
log_success "SSH autorisé"

# Autres ports
if [ "$VPS_ALLOW_HTTP" = true ]; then
    ufw allow 80/tcp comment 'HTTP'
    log_success "HTTP autorisé"
fi

if [ "$VPS_ALLOW_HTTPS" = true ]; then
    ufw allow 443/tcp comment 'HTTPS'
    log_success "HTTPS autorisé"
fi

if [ "$VPS_ALLOW_DEV_PORTS_3000" = true ]; then
    ufw allow 3000:3010/tcp comment 'Dev 3000-3010'
    log_success "Ports 3000-3010 autorisés"
fi

if [ "$VPS_ALLOW_DEV_PORTS_8000" = true ]; then
    ufw allow 8000:8010/tcp comment 'Dev 8000-8010'
    log_success "Ports 8000-8010 autorisés"
fi

echo ""
log_info "Règles configurées:"
ufw show added
echo ""

if ! confirm "Activer le pare-feu ?"; then
    log_warning "Pare-feu non activé"
    exit 0
fi

log_step "Activation du pare-feu..."
ufw --force enable
log_success "✅ Pare-feu activé"

echo ""
log_info "Statut du pare-feu:"
ufw status verbose
echo ""

# Vérification que SSH est bien autorisé
if ufw status | grep -q "$VPS_SSH_PORT"; then
    log_success "✅ Port SSH $VPS_SSH_PORT autorisé"
else
    log_error "❌ Port SSH $VPS_SSH_PORT NON autorisé !"
    log_warning "Ajout manuel du port SSH..."
    ufw allow $VPS_SSH_PORT/tcp
    log_success "Port SSH ajouté"
fi

echo ""
log_success "✅ Configuration pare-feu terminée"
echo ""
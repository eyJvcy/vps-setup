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

log_step "Port SSH: $VPS_SSH_PORT"
ufw allow $VPS_SSH_PORT/tcp comment 'SSH'
log_success "SSH autorisé"

[ "$VPS_ALLOW_HTTP" = true ] && ufw allow 80/tcp comment 'HTTP' && log_success "HTTP autorisé"
[ "$VPS_ALLOW_HTTPS" = true ] && ufw allow 443/tcp comment 'HTTPS' && log_success "HTTPS autorisé"
[ "$VPS_ALLOW_DEV_PORTS_3000" = true ] && ufw allow 3000:3010/tcp comment 'Dev 3000-3010' && log_success "Ports 3000-3010 autorisés"
[ "$VPS_ALLOW_DEV_PORTS_8000" = true ] && ufw allow 8000:8010/tcp comment 'Dev 8000-8010' && log_success "Ports 8000-8010 autorisés"

echo ""
log_info "Règles:"
ufw show added
echo ""

if ! confirm "Activer le pare-feu ?"; then
    log_warning "Pare-feu non activé"
    exit 0
fi

ufw --force enable
log_success "✅ Pare-feu activé"
echo ""
ufw status verbose
echo ""
log_success "✅ Configuration pare-feu terminée"
echo ""
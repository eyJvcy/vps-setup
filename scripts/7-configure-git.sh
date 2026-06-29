#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  CONFIGURATION GIT"
echo "============================================"
echo ""

for user in $VPS_USERS; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_step "Configuration Git pour: $user"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Récupérer config depuis config.env
    git_config=$(get_git_config "$user")
    git_name=$(echo "$git_config" | cut -d'|' -f1)
    git_email=$(echo "$git_config" | cut -d'|' -f2)
    
    # Si pas de config, demander
    if [ -z "$git_name" ] || [ -z "$git_email" ]; then
        read -p "Nom complet pour $user (ex: John Doe): " git_name
        read -p "Email pour $user (ex: john@example.com): " git_email
    else
        log_info "Config depuis config.env: $git_name <$git_email>"
    fi
    
    # Configuration identité
    log_substep "Identité..."
    su - $user -c "git config --global user.name \"$git_name\""
    su - $user -c "git config --global user.email \"$git_email\""
    
    # Configuration éditeur
    log_substep "Éditeur..."
    su - $user -c "git config --global core.editor vim"
    
    # Configuration couleurs
    log_substep "Couleurs..."
    su - $user -c "git config --global color.ui auto"
    
    # Configuration branche
    log_substep "Branche par défaut..."
    su - $user -c "git config --global init.defaultBranch main"
    
    # Configuration comportement
    log_substep "Comportement..."
    su - $user -c "git config --global pull.rebase false"
    su - $user -c "git config --global push.default simple"
    su - $user -c "git config --global push.autoSetupRemote true"
    
    # Aliases
    log_substep "Aliases..."
    su - $user -c "git config --global alias.co checkout"
    su - $user -c "git config --global alias.br branch"
    su - $user -c "git config --global alias.ci commit"
    su - $user -c "git config --global alias.st status"
    su - $user -c "git config --global alias.unstage 'reset HEAD --'"
    su - $user -c "git config --global alias.last 'log -1 HEAD'"
    su - $user -c "git config --global alias.lg \"log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit\""
    
    # Configuration avancée
    log_substep "Configuration avancée..."
    su - $user -c "git config --global core.autocrlf input"
    su - $user -c "git config --global diff.tool vimdiff"
    su - $user -c "git config --global merge.tool vimdiff"
    
    # .gitignore global
    log_substep ".gitignore global..."
    cat > /home/$user/.gitignore_global <<'EOF'
# Système
.DS_Store
Thumbs.db
*~

# Éditeurs
.vscode/
.idea/
*.swp
*.swo

# Compilation C/C++
*.o
*.a
*.so
*.out
a.out

# Python
__pycache__/
*.pyc
venv/
.venv/

# Node
node_modules/
npm-debug.log

# Rust
target/

# Logs
*.log

# Environnement
.env
EOF
    
    chown $user:$user /home/$user/.gitignore_global
    su - $user -c "git config --global core.excludesfile ~/.gitignore_global"
    
    log_success "✅ Git configuré pour $user"
    echo ""
done

echo ""
log_success "✅ Configuration Git terminée"
log_info "Aliases disponibles:"
echo "  • git co    → git checkout"
echo "  • git br    → git branch"
echo "  • git ci    → git commit"
echo "  • git st    → git status"
echo "  • git lg    → git log (format amélioré)"
echo ""
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

if [ -z "$1" ]; then
    log_error "Usage: $0 <username>"
    echo "Exemple: $0 user_stage"
    exit 1
fi

USERNAME=$1

echo "============================================"
echo "  AJOUT D'UN NOUVEL UTILISATEUR"
echo "============================================"
echo ""
log_info "Utilisateur: $USERNAME"
echo ""

if id "$USERNAME" &>/dev/null; then
    log_error "L'utilisateur $USERNAME existe déjà !"
    exit 1
fi

# ============================================
# 1. CRÉATION
# ============================================
log_step "Création de l'utilisateur..."
adduser --disabled-password --gecos "" $USERNAME
echo "$USERNAME:TempPass$(date +%s)" | chpasswd
chmod 700 /home/$USERNAME
log_success "Utilisateur créé"

# ============================================
# 2. SSH
# ============================================
log_step "Configuration SSH..."
su - $USERNAME -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
log_success "Dossier SSH créé"

echo ""
log_info "Ajout de la clé SSH publique"
echo "Collez la clé publique (ou Entrée pour passer):"
read -r ssh_key

if [ -n "$ssh_key" ]; then
    echo "$ssh_key" >> /home/$USERNAME/.ssh/authorized_keys
    log_success "Clé SSH ajoutée"
else
    log_warning "Aucune clé ajoutée"
    log_info "Ajoutez-la dans: /home/$USERNAME/.ssh/authorized_keys"
fi

# ============================================
# 3. DOSSIERS
# ============================================
log_step "Création des dossiers..."
su - $USERNAME -c "mkdir -p ~/projects ~/bin ~/tmp"
log_success "Dossiers créés"

# ============================================
# 4. BASH
# ============================================
log_step "Configuration bash..."
cat >> /home/$USERNAME/.bashrc <<'EOF'

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git pull'
alias gps='git push'

# Prompt avec git
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
export PS1="\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\] \[\e[33m\]\$(parse_git_branch)\[\e[0m\]\$ "

# Historique
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# PATH
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# ccache
export PATH="/usr/lib/ccache:$PATH"
export CCACHE_DIR="$HOME/.ccache"
EOF

chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc
log_success "Bash configuré"

# ============================================
# 5. GIT
# ============================================
log_step "Configuration Git..."
echo ""
read -p "Nom complet pour Git (ex: John Doe): " git_name
read -p "Email pour Git (ex: john@example.com): " git_email

su - $USERNAME -c "git config --global user.name \"$git_name\""
su - $USERNAME -c "git config --global user.email \"$git_email\""
su - $USERNAME -c "git config --global init.defaultBranch main"
su - $USERNAME -c "git config --global core.editor vim"
su - $USERNAME -c "git config --global pull.rebase false"
su - $USERNAME -c "git config --global push.autoSetupRemote true"

# Aliases Git
su - $USERNAME -c "git config --global alias.co checkout"
su - $USERNAME -c "git config --global alias.br branch"
su - $USERNAME -c "git config --global alias.ci commit"
su - $USERNAME -c "git config --global alias.st status"
su - $USERNAME -c "git config --global alias.lg \"log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit\""

# .gitignore global
cat > /home/$USERNAME/.gitignore_global <<'EOF'
.DS_Store
Thumbs.db
*~
.vscode/
.idea/
*.swp
*.o
*.a
*.so
*.out
a.out
__pycache__/
*.pyc
venv/
node_modules/
target/
*.log
.env
EOF

chown $USERNAME:$USERNAME /home/$USERNAME/.gitignore_global
su - $USERNAME -c "git config --global core.excludesfile ~/.gitignore_global"

log_success "Git configuré"

# ============================================
# 6. VIM
# ============================================
if [ "$VPS_CONFIGURE_VIM" = true ]; then
    log_step "Configuration Vim..."
    
    su - $USERNAME -c "curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    
    cp /home/$(echo $VPS_USERS | awk '{print $1}')/.vimrc /home/$USERNAME/.vimrc 2>/dev/null || true
    chown $USERNAME:$USERNAME /home/$USERNAME/.vimrc
    
    su - $USERNAME -c "vim +PlugInstall +qall" 2>/dev/null || true
    
    log_success "Vim configuré"
fi

# ============================================
# 7. ZSH
# ============================================
if [ "$VPS_INSTALL_ZSH" = true ] && command -v zsh &> /dev/null; then
    log_step "Configuration Zsh..."
    
    su - $USERNAME -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    
    su - $USERNAME -c "git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    su - $USERNAME -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    su - $USERNAME -c "git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions"
    
    if [ "$VPS_ZSH_THEME" = "powerlevel10k" ]; then
        su - $USERNAME -c "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k"
    fi
    
    # Copier .zshrc depuis un utilisateur existant
    cp /home/$(echo $VPS_USERS | awk '{print $1}')/.zshrc /home/$USERNAME/.zshrc 2>/dev/null || true
    chown $USERNAME:$USERNAME /home/$USERNAME/.zshrc
    
    if [ "$VPS_ZSH_AS_DEFAULT" = true ]; then
        chsh -s $(which zsh) $USERNAME
    fi
    
    log_success "Zsh configuré"
fi

# ============================================
# 8. DOCKER
# ============================================
if command -v docker &> /dev/null; then
    usermod -aG docker $USERNAME
    log_success "Ajouté au groupe docker"
fi

# ============================================
# 9. SSH CONFIG
# ============================================
log_step "Mise à jour SSH..."
if ! grep -q "AllowUsers.*$USERNAME" /etc/ssh/sshd_config; then
    sed -i "s/AllowUsers.*/& $USERNAME/" /etc/ssh/sshd_config
    systemctl restart sshd
    log_success "SSH mis à jour"
fi

echo ""
echo "============================================"
log_success "✅ Utilisateur $USERNAME créé avec succès !"
echo "============================================"
echo ""

log_info "Informations:"
echo "  • Home: /home/$USERNAME"
echo "  • Permissions: 700 (isolé)"
echo "  • Git: $git_name <$git_email>"
echo ""

if [ -z "$ssh_key" ]; then
    log_warning "📝 N'oubliez pas d'ajouter la clé SSH publique:"
    echo ""
    echo "  Sur votre machine locale:"
    echo "    ssh-keygen -t ed25519 -C \"$USERNAME\" -f ~/.ssh/vps_$USERNAME"
    echo ""
    echo "  Puis copiez la clé:"
    server_ip=$(hostname -I | awk '{print $1}')
    echo "    cat ~/.ssh/vps_$USERNAME.pub | ssh root@$server_ip 'cat >> /home/$USERNAME/.ssh/authorized_keys'"
    echo ""
fi

log_info "Connexion SSH:"
echo "  ssh -p $VPS_SSH_PORT $USERNAME@$(hostname -I | awk '{print $1}')"
echo ""
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  CRÉATION DES UTILISATEURS"
echo "============================================"
echo ""

log_info "Utilisateurs: $VPS_USERS"
echo ""

for user in $VPS_USERS; do
    log_step "Création: $user"
    
    if id "$user" &>/dev/null; then
        log_warning "$user existe déjà"
        continue
    fi
    
    adduser --disabled-password --gecos "" $user
    echo "$user:TempPass$(date +%s)" | chpasswd
    
    chmod 700 /home/$user
    log_success "Home isolé (700)"
    
    su - $user -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    log_success "SSH configuré"
    
    su - $user -c "mkdir -p ~/projects ~/bin ~/tmp"
    log_success "Dossiers créés"
    
    cat >> /home/$user/.bashrc <<'EOF'

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
EOF

    chown $user:$user /home/$user/.bashrc
    
    su - $user -c "git config --global init.defaultBranch main"
    su - $user -c "git config --global core.editor vim"
    
    log_success "✅ $user créé"
    echo ""
done

echo ""
log_success "✅ Utilisateurs créés"
echo ""
log_warning "📝 Ajoutez les clés SSH publiques:"
echo ""
log_info "Sur votre machine locale:"
for user in $VPS_USERS; do
    echo "  ssh-keygen -t ed25519 -C \"$user\" -f ~/.ssh/vps_$user"
done
echo ""
log_info "Puis copiez les clés sur le serveur:"
server_ip=$(hostname -I | awk '{print $1}')
for user in $VPS_USERS; do
    echo "  cat ~/.ssh/vps_$user.pub | ssh root@$server_ip 'cat >> /home/$user/.ssh/authorized_keys'"
done
echo ""
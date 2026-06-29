#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  INSTALLATION ZSH"
echo "============================================"
echo ""

if [ "$VPS_INSTALL_ZSH" != true ]; then
    log_warning "Installation Zsh désactivée"
    exit 0
fi

log_step "Installation Zsh..."
apt install -y zsh
log_success "Zsh $(zsh --version | awk '{print $2}') installé"

echo ""
for user in $VPS_USERS; do
    log_step "Configuration pour: $user"
    
    # Installer Oh My Zsh
    log_substep "Installation Oh My Zsh..."
    su - $user -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    
    # Plugins
    log_substep "Installation plugins..."
    su - $user -c "git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    su - $user -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    su - $user -c "git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions"
    
    # Powerlevel10k
    if [ "$VPS_ZSH_THEME" = "powerlevel10k" ]; then
        log_substep "Installation Powerlevel10k..."
        su - $user -c "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k"
    fi
    
    # Configuration .zshrc
    log_substep "Configuration .zshrc..."
    cat > /home/$user/.zshrc <<'EOF'
# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    docker
    docker-compose
    npm
    python
    sudo
    command-not-found
    colored-man-pages
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

source $ZSH/oh-my-zsh.sh

# Configuration
export EDITOR='vim'
export LANG=en_US.UTF-8

# Historique
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git pull'
alias gps='git push'
alias gd='git diff'
alias gl='git log --oneline --graph'

# Développement
alias py='python3'
alias v='vim'

# Compilation
alias gcc-strict='gcc -Wall -Wextra -Werror'
alias g++-strict='g++ -Wall -Wextra -Werror -std=c++17'
alias vg='valgrind --leak-check=full'

# PATH
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Go
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# ccache
export PATH="/usr/lib/ccache:$PATH"

# Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
    
    chown $user:$user /home/$user/.zshrc
    
    # Définir Zsh comme shell par défaut
    if [ "$VPS_ZSH_AS_DEFAULT" = true ]; then
        chsh -s $(which zsh) $user
        log_success "Zsh défini comme shell par défaut"
    fi
    
    log_success "✅ Zsh configuré pour $user"
    echo ""
done

echo ""
log_success "✅ Installation Zsh terminée"
log_info "Plugins installés:"
echo "  • zsh-autosuggestions"
echo "  • zsh-syntax-highlighting"
echo "  • zsh-completions"
echo "  • Powerlevel10k"
echo ""
log_warning "⚠️  Déconnectez-vous et reconnectez-vous pour utiliser Zsh"
log_info "Pour configurer le thème: p10k configure"
echo ""
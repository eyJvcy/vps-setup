#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

check_root

echo "============================================"
echo "  INSTALLATION OUTILS DE DÉVELOPPEMENT"
echo "============================================"
echo ""

# C/C++
if [ "$VPS_INSTALL_C_CPP" = true ]; then
    log_step "Installation C/C++..."
    
    log_substep "GCC, G++, Make, CMake..."
    apt install -y gcc g++ make cmake ninja-build autoconf automake libtool pkg-config
    
    log_substep "Outils de débogage..."
    apt install -y gdb gdbserver valgrind strace ltrace
    
    log_substep "Clang/LLVM..."
    apt install -y clang clang-format clang-tidy lldb lld
    
    log_substep "Bibliothèques..."
    apt install -y libc6-dev libstdc++-11-dev libreadline-dev libssl-dev libffi-dev
    apt install -y libsqlite3-dev libbz2-dev liblzma-dev zlib1g-dev
    
    log_substep "ccache, Bear, cppcheck..."
    apt install -y ccache bear cppcheck
    
    for user in $VPS_USERS; do
        su - $user -c "mkdir -p ~/.ccache"
        if ! grep -q "ccache" /home/$user/.bashrc; then
            cat >> /home/$user/.bashrc <<'EOF'

# ccache
export PATH="/usr/lib/ccache:$PATH"
export CCACHE_DIR="$HOME/.ccache"
EOF
            chown $user:$user /home/$user/.bashrc
        fi
    done
    
    log_success "GCC $(gcc --version | head -n1 | awk '{print $3}') installé"
    log_success "Clang $(clang --version | head -n1 | awk '{print $3}') installé"
fi

# Node.js
if [ "$VPS_INSTALL_NODE" = true ]; then
    log_step "Installation Node.js $VPS_NODE_VERSION..."
    curl -fsSL https://deb.nodesource.com/setup_${VPS_NODE_VERSION}.x | bash -
    apt install -y nodejs
    
    log_substep "Outils npm globaux..."
    npm install -g npm@latest
    npm install -g yarn pnpm
    npm install -g nodemon
    npm install -g typescript ts-node
    npm install -g eslint prettier
    
    log_success "Node.js $(node -v) installé"
    log_success "npm $(npm -v) installé"
fi

# Python
if [ "$VPS_INSTALL_PYTHON" = true ]; then
    log_step "Installation Python..."
    apt install -y python3 python3-pip python3-venv python3-dev python-is-python3 ipython3
    
    log_substep "Outils Python..."
    pip3 install --upgrade pip
    pip3 install virtualenv pipenv poetry
    pip3 install black flake8 pylint mypy
    pip3 install ipython
    
    log_success "Python $(python3 --version | awk '{print $2}') installé"
fi

# Docker
if [ "$VPS_INSTALL_DOCKER" = true ]; then
    log_step "Installation Docker..."
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
    
    for user in $VPS_USERS; do
        usermod -aG docker $user
        log_substep "$user ajouté au groupe docker"
    done
    
    systemctl enable docker
    systemctl start docker
    
    log_success "Docker $(docker --version | awk '{print $3}' | tr -d ',') installé"
fi

# Rust
if [ "$VPS_INSTALL_RUST" = true ]; then
    log_step "Installation Rust..."
    
    for user in $VPS_USERS; do
        log_substep "Installation pour $user..."
        su - $user -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
        su - $user -c "source ~/.cargo/env && rustup default stable"
        su - $user -c "source ~/.cargo/env && rustup component add rustfmt clippy rust-analyzer"
    done
    
    log_success "Rust installé"
fi

# Go
if [ "$VPS_INSTALL_GO" = true ]; then
    log_step "Installation Go..."
    
    GO_VERSION="1.21.5"
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    rm go${GO_VERSION}.linux-amd64.tar.gz
    
    for user in $VPS_USERS; do
        if ! grep -q "# Go" /home/$user/.bashrc; then
            cat >> /home/$user/.bashrc <<'EOF'

# Go
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF
            chown $user:$user /home/$user/.bashrc
        fi
    done
    
    log_success "Go $GO_VERSION installé"
fi

# Outils CLI modernes
log_step "Installation outils CLI modernes..."

log_substep "ripgrep..."
apt install -y ripgrep

log_substep "fd..."
apt install -y fd-find
ln -sf $(which fdfind) /usr/local/bin/fd 2>/dev/null || true

log_substep "bat..."
apt install -y bat
mkdir -p /usr/local/bin
ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true

log_substep "fzf..."
apt install -y fzf

log_substep "tldr..."
apt install -y tldr

log_success "Outils CLI installés"

# Norminette
if [ "$VPS_INSTALL_NORMINETTE" = true ]; then
    log_step "Installation norminette..."
    pip3 install norminette
    log_success "Norminette installée"
fi

# Criterion
if [ "$VPS_INSTALL_CRITERION" = true ]; then
    log_step "Installation Criterion..."
    apt install -y libcriterion-dev 2>/dev/null || {
        log_warning "Installation depuis les sources..."
        cd /tmp
        git clone --recursive https://github.com/Snaipe/Criterion
        cd Criterion
        meson build
        ninja -C build
        ninja -C build install
        ldconfig
        cd /tmp
        rm -rf Criterion
    }
    log_success "Criterion installé"
fi

echo ""
log_success "✅ Outils de développement installés"
echo ""
log_warning "⚠️  Déconnectez-vous et reconnectez-vous pour:"
echo "   • Utiliser Docker sans sudo"
echo "   • Avoir les nouveaux PATH"
echo ""
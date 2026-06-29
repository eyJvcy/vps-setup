#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/functions.sh"
load_config

echo "============================================"
echo "  VÉRIFICATION DU SYSTÈME VPS"
echo "============================================"
echo ""

# Informations système
log_step "Informations système"
echo "  • Hostname: $(hostname)"
echo "  • IP: $(hostname -I | awk '{print $1}')"
echo "  • OS: $(lsb_release -d | cut -f2)"
echo "  • Kernel: $(uname -r)"
echo "  • Uptime: $(uptime -p)"
echo ""

# Ressources
log_step "Ressources"
echo "  • CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% utilisé"
echo "  • RAM: $(free -h | awk '/^Mem:/ {print $3 "/" $2 " (" int($3/$2*100) "%)"}')"
echo "  • Swap: $(free -h | awk '/^Swap:/ {print $3 "/" $2}')"
echo "  • Disque: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
echo ""

# Utilisation par utilisateur
log_step "Utilisation par utilisateur"
for user in $VPS_USERS; do
    if [ -d "/home/$user" ]; then
        size=$(du -sh /home/$user 2>/dev/null | cut -f1)
        echo "  • $user: $size"
    fi
done
echo ""

# Services
log_step "Services"
services=("sshd" "ufw" "fail2ban" "docker")
for service in "${services[@]}"; do
    if systemctl list-units --type=service | grep -q "$service"; then
        if systemctl is-active --quiet $service; then
            echo "  ✅ $service: actif"
        else
            echo "  ❌ $service: inactif"
        fi
    fi
done
echo ""

# Services code-server (si utilisés)
if systemctl list-units --type=service | grep -q "code-server"; then
    log_step "Services code-server"
    for user in $VPS_USERS; do
        if systemctl is-active --quiet "code-server-$user" 2>/dev/null; then
            echo "  ✅ code-server-$user: actif"
        fi
    done
    echo ""
fi

# SSH
log_step "Configuration SSH"
echo "  • Port: $(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')"
echo "  • Root login: $(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')"
echo "  • Password auth: $(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')"
echo ""

# Pare-feu
log_step "Pare-feu (UFW)"
if ufw status | grep -q "Status: active"; then
    echo "  ✅ UFW actif"
    echo ""
    ufw status numbered | grep -v "Status:" | head -10
else
    echo "  ❌ UFW inactif"
fi
echo ""

# Fail2ban
log_step "Fail2ban"
if systemctl is-active --quiet fail2ban; then
    echo "  ✅ fail2ban actif"
    banned=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
    echo "  • IPs bannies (SSH): $banned"
else
    echo "  ❌ fail2ban inactif"
fi
echo ""

# Isolation utilisateurs
log_step "Isolation des utilisateurs"
for user in $VPS_USERS; do
    if [ -d "/home/$user" ]; then
        perms=$(stat -c '%a' /home/$user)
        if [ "$perms" = "700" ]; then
            echo "  ✅ $user: isolé (700)"
        else
            echo "  ⚠️  $user: permissions $perms (devrait être 700)"
        fi
    fi
done
echo ""

# Shell par défaut
log_step "Shell par défaut"
for user in $VPS_USERS; do
    shell=$(getent passwd $user | cut -d: -f7)
    shell_name=$(basename $shell)
    if [ "$shell_name" = "zsh" ]; then
        echo "  ✅ $user: Zsh"
    else
        echo "  • $user: $shell_name"
    fi
done
echo ""

# Outils installés
log_step "Outils de développement"
command -v gcc &> /dev/null && echo "  ✅ GCC $(gcc --version | head -n1 | awk '{print $3}')"
command -v g++ &> /dev/null && echo "  ✅ G++ $(g++ --version | head -n1 | awk '{print $3}')"
command -v clang &> /dev/null && echo "  ✅ Clang $(clang --version | head -n1 | awk '{print $3}')"
command -v cmake &> /dev/null && echo "  ✅ CMake $(cmake --version | head -n1 | awk '{print $3}')"
command -v gdb &> /dev/null && echo "  ✅ GDB $(gdb --version | head -n1 | awk '{print $4}')"
command -v valgrind &> /dev/null && echo "  ✅ Valgrind $(valgrind --version | awk '{print $2}')"
command -v node &> /dev/null && echo "  ✅ Node.js $(node -v)"
command -v python3 &> /dev/null && echo "  ✅ Python $(python3 --version | awk '{print $2}')"
command -v docker &> /dev/null && echo "  ✅ Docker $(docker --version | awk '{print $3}' | tr -d ',')"
command -v rustc &> /dev/null && echo "  ✅ Rust $(rustc --version | awk '{print $2}')"
command -v go &> /dev/null && echo "  ✅ Go $(go version | awk '{print $3}' | tr -d 'go')"
command -v zsh &> /dev/null && echo "  ✅ Zsh $(zsh --version | awk '{print $2}')"
echo ""

# Connexions actives
log_step "Connexions SSH actives"
who_output=$(who)
if [ -n "$who_output" ]; then
    who | awk '{print "  • "$1" depuis "$5}' 
else
    echo "  Aucune connexion"
fi
echo ""

# Dernières connexions
log_step "Dernières connexions (5 dernières)"
last -n 5 | head -5 | awk '{print "  • "$1" - "$4" "$5" "$6}'
echo ""

echo "============================================"
log_success "✅ Vérification terminée"
echo "============================================"
echo ""
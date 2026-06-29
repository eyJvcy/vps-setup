#!/bin/bash

echo "============================================"
echo "  CORRECTION SSH D'URGENCE"
echo "============================================"
echo ""

# Désactiver le socket
echo "1. Désactivation du socket systemd..."
systemctl stop ssh.socket 2>/dev/null
systemctl disable ssh.socket 2>/dev/null
systemctl mask ssh.socket 2>/dev/null
echo "✅ Socket désactivé"

# Vérifier la config
echo ""
echo "2. Vérification de la config SSH..."
if grep -q "^Port 2222" /etc/ssh/sshd_config; then
    echo "✅ Config SSH correcte (Port 2222)"
else
    echo "⚠️  Correction de la config..."
    sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
    sed -i 's/^Port 22$/Port 2222/' /etc/ssh/sshd_config
    echo "✅ Config corrigée"
fi

# Redémarrer SSH
echo ""
echo "3. Redémarrage SSH..."
systemctl restart ssh.service
sleep 2
echo "✅ SSH redémarré"

# Autoriser le port
echo ""
echo "4. Configuration du pare-feu..."
ufw allow 2222/tcp
echo "✅ Port 2222 autorisé"

# Vérification
echo ""
echo "5. Vérification finale:"
PORT=$(ss -tlnp | grep ssh | grep -o ':[0-9]*' | head -1 | tr -d ':')
echo "   Port d'écoute: $PORT"
ufw status | grep 2222

echo ""
if [ "$PORT" = "2222" ]; then
    echo "✅✅✅ SSH configuré correctement !"
    echo "Vous pouvez maintenant vous connecter:"
    echo "  ssh -p 2222 noleak@$(hostname -I | awk '{print $1}')"
else
    echo "❌ SSH écoute toujours sur le port $PORT"
    echo "Vérifiez manuellement /etc/ssh/sshd_config"
fi
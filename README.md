# Configuration VPS multi-utilisateurs

Scripts d'automatisation pour configurer un VPS avec plusieurs environnements de développement isolés, optimisé pour VSCode Remote SSH.

## 🎯 Objectif

Créer un VPS avec plusieurs utilisateurs complètement isolés, chacun avec :
- ✅ Son propre espace de stockage (permissions 700)
- ✅ Sa propre configuration Git
- ✅ Son propre environnement Zsh/Vim
- ✅ Accès SSH par clé uniquement
- ✅ Connexion VSCode Remote SSH

## 📋 Prérequis

- Un VPS Ubuntu 22.04 LTS ou Debian 12
- Accès root
- Connexion Internet

## 🚀 Installation rapide (méthode recommandée)

### Sur le VPS (en tant que root)

```bash
curl -sSL https://raw.githubusercontent.com/eyjvcy/vps-setup/main/install.sh | bash
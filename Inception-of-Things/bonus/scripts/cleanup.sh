#!/usr/bin/env bash
set -euo pipefail

echo "╔════════════════════════════════════════════╗"
echo "║   Nettoyage complet du Bonus IoT          ║"
echo "╚════════════════════════════════════════════╝"
echo ""

read -p "⚠️  Cela va supprimer TOUT (cluster, GitLab, données). Continuer? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Annulé."
    exit 1
fi

echo ""
echo "=== Arrêt des port-forwards ==="
pkill -f "port-forward" 2>/dev/null || echo "✓ Aucun port-forward actif"

echo ""
echo "=== Suppression du cluster K3d ==="
k3d cluster delete iot-bonus 2>/dev/null || echo "✓ Cluster déjà supprimé"

echo ""
echo "=== Arrêt de GitLab ==="
docker stop gitlab-ce 2>/dev/null || echo "✓ GitLab déjà arrêté"
docker rm gitlab-ce 2>/dev/null || echo "✓ Container déjà supprimé"

echo ""
read -p "Supprimer les données GitLab (~/${HOME}/gitlab-data)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/gitlab-data
    echo "✓ Données GitLab supprimées"
else
    echo "✓ Données GitLab conservées"
fi

echo ""
echo "=== Nettoyage des fichiers générés ==="
rm -f scripts/gitlab_root_password.txt
rm -f scripts/argocd_password.txt
rm -f scripts/gitlab_token.txt
rm -f nohup.out
echo "✓ Fichiers de mots de passe supprimés"

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║   Nettoyage terminé!                      ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "Pour tout relancer:"
echo "  ./scripts/00_install_all.sh"
echo "  ou manuellement:"
echo "  ./scripts/01_start_gitlab.sh"
echo "  ./scripts/02_setup_k3d.sh"
echo ""
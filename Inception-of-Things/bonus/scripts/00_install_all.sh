#!/usr/bin/env bash
set -euo pipefail

echo "╔════════════════════════════════════════════╗"
echo "║   Installation complète du Bonus IoT      ║"
echo "║   GitLab + K3d + Argo CD                  ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Vérifier que Docker est démarré
if ! docker info > /dev/null 2>&1; then
    echo "❌ ERROR: Docker n'est pas démarré!"
    echo "Veuillez démarrer Docker Desktop et réessayer."
    exit 1
fi

echo "✓ Docker est démarré"
echo ""

# Étape 1: GitLab
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 1/2: Lancement de GitLab"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/01_start_gitlab.sh

echo ""
read -p "Appuyez sur ENTRÉE pour continuer avec K3d..."

# Étape 2: K3d
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 2/2: Configuration K3d + Argo CD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/02_setup_k3d.sh

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║   Installation automatique terminée!       ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "PROCHAINES ÉTAPES MANUELLES:"
echo ""
echo "1. Configurer GitLab:"
echo "   ./scripts/03_configure_gitlab.sh"
echo "   (Suivre les instructions affichées)"
echo ""
echo "2. Connecter Argo CD à GitLab:"
echo "   ./scripts/04_setup_argocd.sh"
echo ""
echo "3. Tester l'application:"
echo "   curl http://localhost:8888"
echo ""
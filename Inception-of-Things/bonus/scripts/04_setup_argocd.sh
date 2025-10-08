#!/usr/bin/env bash
set -euo pipefail

echo "=== Configuration d'Argo CD avec GitLab ==="

# Vérifier que le token GitLab existe
if [ ! -f scripts/gitlab_token.txt ]; then
    echo "ERROR: Le fichier scripts/gitlab_token.txt n'existe pas!"
    echo "Veuillez créer un Personal Access Token dans GitLab et le sauvegarder."
    exit 1
fi

GITLAB_TOKEN=$(cat scripts/gitlab_token.txt)
GITLAB_URL="http://host.docker.internal:8081"
PROJECT_PATH="root/iot-deployment"

echo ""
echo "=== Vérification du cluster K3d ==="

# Vérifier que le cluster existe
if ! k3d cluster list | grep -q "iot-bonus"; then
    echo "❌ ERROR: Le cluster 'iot-bonus' n'existe pas!"
    echo "Veuillez d'abord exécuter: ./scripts/02_setup_k3d.sh"
    exit 1
fi

# Vérifier que kubectl fonctionne
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ ERROR: Impossible de se connecter au cluster!"
    echo "Le cluster est peut-être arrêté. Essayez:"
    echo "  k3d cluster start iot-bonus"
    exit 1
fi

echo "✓ Cluster K3d accessible"

echo ""
echo "=== Attente qu'Argo CD soit prêt ==="

# Attendre que les nodes soient prêts
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Attendre qu'Argo CD soit complètement déployé
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd 2>/dev/null || {
    echo "⏳ Argo CD n'est pas encore prêt. Attente de 30 secondes supplémentaires..."
    sleep 30
    kubectl wait --for=condition=available --timeout=120s deployment/argocd-server -n argocd
}

echo "✓ Argo CD est prêt"

echo ""
echo "=== Configuration du repository GitLab dans Argo CD ==="

# Créer le secret pour le repository GitLab
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${GITLAB_URL}/${PROJECT_PATH}.git
  password: ${GITLAB_TOKEN}
  username: root
EOF

echo "✓ Repository GitLab configuré"

# Attendre un peu que le secret soit pris en compte
sleep 5

echo ""
echo "=== Déploiement de l'application Argo CD ==="

# Vérifier que le fichier application.yaml existe
if [ ! -f confs/application.yaml ]; then
    echo "❌ ERROR: Le fichier confs/application.yaml n'existe pas!"
    exit 1
fi

# Appliquer l'application
kubectl apply -f confs/application.yaml

echo "✓ Application déployée"

echo ""
echo "=== Configuration du port-forward Argo CD ==="

# Arrêter les anciens port-forward
pkill -f "port-forward.*argocd" 2>/dev/null || true
sleep 2

# Démarrer le nouveau port-forward
nohup kubectl port-forward -n argocd svc/argocd-server 8091:80 > /dev/null 2>&1 &
sleep 3

echo "✓ Port-forward configuré sur le port 8091"

echo ""
echo "=== Vérification du déploiement ==="

# Attendre un peu que l'application soit synchronisée
echo "Attente de la synchronisation initiale (30 secondes)..."
sleep 30

# Vérifier que l'application existe
kubectl get application playground-app -n argocd > /dev/null 2>&1 && echo "✓ Application 'playground-app' créée" || echo "⚠️  Application en cours de création..."

# Vérifier les pods dans dev
echo ""
echo "Pods dans le namespace dev:"
kubectl get pods -n dev || echo "⏳ Les pods ne sont pas encore créés..."

echo ""
echo "============================================"
echo "✓ Configuration terminée!"
echo "============================================"
echo ""
echo "📊 URLS D'ACCÈS:"
echo "  Argo CD    : http://localhost:8091"
echo "  GitLab     : http://localhost:8081"
echo "  Application: http://localhost:8889"
echo ""
echo "🔑 IDENTIFIANTS ARGO CD:"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || cat scripts/argocd_password.txt)
echo "  Username   : admin"
echo "  Password   : ${ARGOCD_PASSWORD}"
echo ""
echo "✅ VÉRIFICATIONS:"
echo "  # Voir l'état de l'application"
echo "  kubectl get application -n argocd"
echo ""
echo "  # Voir les pods"
echo "  kubectl get pods -n dev"
echo ""
echo "  # Tester l'application"
echo "  curl http://localhost:8889"
echo ""
echo "🔄 TESTER LE CI/CD:"
echo "  1. Modifier confs/deployment.yaml (changer v1 en v2)"
echo "  2. cd confs && git add . && git commit -m 'Update to v2' && git push"
echo "  3. Vérifier dans Argo CD: http://localhost:8091"
echo "  4. curl http://localhost:8889"
echo ""
echo "============================================"
echo ""
echo "⏳ NOTE: Si les pods ne sont pas encore créés, attendez 1-2 minutes"
echo "   pour qu'Argo CD synchronise l'application depuis GitLab."
echo ""
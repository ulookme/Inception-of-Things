#!/usr/bin/env bash
set -euo pipefail

echo "=== Installation des outils ==="

# Installer K3d si nécessaire
if ! command -v k3d &> /dev/null; then
    echo "[+] Installation de K3d..."
    brew install k3d
else
    echo "✓ K3d déjà installé"
fi

# Installer kubectl si nécessaire
if ! command -v kubectl &> /dev/null; then
    echo "[+] Installation de kubectl..."
    brew install kubectl
else
    echo "✓ kubectl déjà installé"
fi

echo ""
echo "=== Création du cluster K3d ==="

# Supprimer l'ancien cluster s'il existe
k3d cluster delete iot-bonus 2>/dev/null || true

# Créer le nouveau cluster avec les ports nécessaires
k3d cluster create iot-bonus \
  --port 8091:80@loadbalancer \
  --port 8445:443@loadbalancer \
  --port 8889:8888@loadbalancer \
  --agents 2

echo ""
echo "=== Attente du cluster ==="
sleep 15
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo ""
echo "=== Création des namespaces ==="
kubectl create namespace argocd
kubectl create namespace gitlab
kubectl create namespace dev

echo ""
echo "=== Installation d'Argo CD ==="
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ""
echo "=== Attente d'Argo CD ==="
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo ""
echo "=== Configuration d'Argo CD ==="
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo ""
echo "=== Récupération du mot de passe Argo CD ==="
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "${ARGOCD_PASSWORD}" > scripts/argocd_password.txt

echo ""
echo "=== Démarrage port-forward Argo CD ==="
pkill -f "port-forward.*argocd" 2>/dev/null || true
nohup kubectl port-forward -n argocd svc/argocd-server 8091:80 > /dev/null 2>&1 &
sleep 2

echo ""
echo "============================================"
echo "✓ Cluster K3d configuré!"
echo "============================================"
echo ""
echo "Argo CD    : http://localhost:8091"
echo "Username   : admin"
echo "Password   : ${ARGOCD_PASSWORD}"
echo ""
echo "PROCHAINE ÉTAPE:"
echo "  ./scripts/03_configure_gitlab.sh"
echo "============================================"
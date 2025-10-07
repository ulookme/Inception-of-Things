#!/bin/bash
set -e

echo "=== Installation K3d et kubectl ==="

if ! command -v k3d &> /dev/null; then
    brew install k3d
else
    echo "✓ K3d installé"
fi

if ! command -v kubectl &> /dev/null; then
    brew install kubectl
else
    echo "✓ kubectl installé"
fi

echo ""
echo "=== Création cluster K3d ==="
k3d cluster delete iot-cluster 2>/dev/null || true

k3d cluster create iot-cluster \
  --port 8080:80@loadbalancer \
  --port 8443:443@loadbalancer \
  --port 8888:8888@loadbalancer \
  --agents 2

echo ""
echo "=== Attente cluster ==="
sleep 15
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo ""
echo "=== Création namespace argocd ==="
kubectl create namespace argocd

echo ""
echo "=== Installation Argo CD ==="
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ""
echo "=== Attente Argo CD ==="
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo ""
echo "=== Création namespace dev ==="
kubectl create namespace dev

echo ""
echo "=== Configuration Argo CD ==="
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo ""
echo "=== Récupération mot de passe ==="
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "$ARGOCD_PASSWORD" > password.txt

echo ""
echo "=== Démarrage port-forward Argo CD ==="
pkill -f "port-forward" 2>/dev/null || true
nohup kubectl port-forward -n argocd svc/argocd-server 8080:80 > /dev/null 2>&1 &
sleep 2

echo ""
echo "============================================"
echo "✓ Installation terminée !"
echo "============================================"
echo ""
echo "Argo CD    : http://localhost:8080"
echo "Username   : admin"
echo "Password   : $ARGOCD_PASSWORD"
echo ""
echo "Application : http://localhost:8888"
echo ""
echo "PROCHAINES ÉTAPES :"
echo "1. kubectl apply -f application.yaml"
echo "2. Ouvrir http://localhost:8080"
echo "3. Tester : curl http://localhost:8888"
echo ""
echo "Pour arrêter le port-forward :"
echo "  pkill -f 'port-forward'"
echo "============================================"
#!/bin/bash
set -e

echo "=== Installation de K3d et kubectl ==="

# Vérifier si K3d est déjà installé
if ! command -v k3d &> /dev/null; then
    echo "Installation de K3d..."
    brew install k3d
else
    echo "K3d déjà installé"
fi

# Vérifier si kubectl est déjà installé
if ! command -v kubectl &> /dev/null; then
    echo "Installation de kubectl..."
    brew install kubectl
else
    echo "kubectl déjà installé"
fi

echo ""
echo "=== Création du cluster K3d ==="
# Supprimer le cluster s'il existe déjà
k3d cluster delete iot-cluster 2>/dev/null || true

# Créer un nouveau cluster avec mapping de port pour accéder aux services
k3d cluster create iot-cluster \
  --port 8080:80@loadbalancer \
  --port 8443:443@loadbalancer \
  --agents 2

echo ""
echo "=== Attente que le cluster soit prêt ==="
sleep 10
kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo ""
echo "=== Création du namespace argocd ==="
kubectl create namespace argocd

echo ""
echo "=== Installation d'Argo CD ==="
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ""
echo "=== Attente du démarrage d'Argo CD ==="
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo ""
echo "=== Création du namespace dev ==="
kubectl create namespace dev

echo ""
echo "=== Configuration d'Argo CD pour accès local ==="
# Changer le service argocd-server en NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo ""
echo "=== Récupération du mot de passe admin Argo CD ==="
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "============================================"
echo "Installation terminée !"
echo "============================================"
echo ""
echo "Cluster K3d créé : iot-cluster"
echo "Namespaces créés : argocd, dev"
echo ""
echo "Argo CD est accessible via :"
echo "  URL: http://localhost:8080"
echo "  Username: admin"
echo "  Password: $ARGOCD_PASSWORD"
echo ""
echo "Pour appliquer l'application Argo CD, exécutez :"
echo "  kubectl apply -f confs/application.yaml"
echo ""
echo "Commandes utiles :"
echo "  kubectl get pods -n argocd"
echo "  kubectl get pods -n dev"
echo "  kubectl get applications -n argocd"
echo "============================================"

#!/bin/bash
set -e

echo "Installation de K3s..."
curl -sfL https://get.k3s.io | sh -

echo "Attente que K3s soit prêt..."
sleep 10

echo "Déploiement des applications..."
kubectl apply -f /vagrant/confs/app1-deployment.yaml
kubectl apply -f /vagrant/confs/app2-deployment.yaml
kubectl apply -f /vagrant/confs/app3-deployment.yaml
kubectl apply -f /vagrant/confs/ingress.yaml

echo "Déploiement terminé !"
echo "Vérification des pods..."
kubectl get pods
kubectl get svc
kubectl get ingress

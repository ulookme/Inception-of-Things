cd ~/Documents/ArcheanVision_Dev/Inception-of-Things/P3

# Détruire et recréer
k3d cluster delete iot-cluster

./setup.sh

# Déployer l'app
kubectl apply -f application.yaml

# Tester
curl http://localhost:8888
open http://localhost:8080


# 1. Dans votre dépôt iot-deployment
cd ~/path/to/iot-deployment
vi deployment.yaml
# Changer : image: wil42/playground:v2 (ou v3)

# 2. Commit et push
git add deployment.yaml
git commit -m "Update to v2"
git push origin main

### Changement dans le Repo de l'app
# Voir quelle branche ArgoCD surveille actuellement
kubectl get application flask-chat-app -n argocd -o jsonpath='{.spec.source.targetRevision}'

kubectl describe application flask-chat-app -n argocd | grep "Revision:"
watch kubectl get pods -n dev
kubectl get pods -n dev
kubectl describe pod -n dev -l app=playground | grep Image:

# 6. Tester
curl http://localhost:8888

### Lister toutes les Applications Argo CD

# Dans le namespace argocd
kubectl get applications -n argocd

# Tous les namespaces
kubectl get applications.argoproj.io -A

# Affichage détaillé
kubectl get applications -n argocd -o wide

### Vérifier les ressources déployées par ton Application

# Lister les ressources dans le namespace dev
kubectl get deploy,svc,ingress,pods -n dev

# Version dynamique (mise à jour automatique)
watch kubectl get deploy,svc,ingress,pods -n dev



#### NIVEAU 3 — Reset total (supprimer le cluster K3d et repartir de zéro)

# 1) Lister les clusters k3d pour connaître le nom (ex: iot-cluster)
k3d cluster list

# 2) Supprimer le cluster
k3d cluster delete <NOM_DU_CLUSTER>

# 3) Recréer un cluster propre (exemple)
k3d cluster create iot-cluster

# 4) Réinstaller Argo CD
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 5) Recréer le namespace dev
kubectl create ns dev

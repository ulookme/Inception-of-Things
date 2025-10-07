cd ~/Documents/ArcheanVision_Dev/Inception-of-Things/P3

# Détruire et recréer
k3d cluster delete iot-cluster
./setup.sh

# Déployer l'app
kubectl apply -f application.yaml

# Tester
curl http://localhost:8888
open http://localhost:8080

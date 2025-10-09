# Inception-of-Things (IoT)

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![K3s](https://img.shields.io/badge/k3s-%23FFC61C.svg?style=for-the-badge&logo=k3s&logoColor=black)
![ArgoCD](https://img.shields.io/badge/argo-EF7B4D.svg?style=for-the-badge&logo=argo&logoColor=white)

## 📖 Description

**Inception-of-Things** est un projet d'administration système qui vise à approfondir les connaissances en Kubernetes à travers l'utilisation de **K3s**, **K3d**, **Vagrant** et **ArgoCD**.

Ce projet se divise en trois parties progressives, chacune introduisant de nouveaux concepts et outils pour maîtriser les fondamentaux de Kubernetes et du déploiement continu.

---

## 🎯 Objectifs du projet

- Configurer des machines virtuelles avec **Vagrant**
- Installer et configurer **K3s** (version lightweight de Kubernetes)
- Déployer des applications avec **Ingress** et gestion de routing
- Mettre en place une **CI/CD** avec **K3d** et **ArgoCD**
- Automatiser le déploiement d'applications depuis un repository GitHub

---

## 📁 Structure du projet

```
Inception-of-Things/
│
├── p1/                          # Part 1: K3s et Vagrant
│   ├── scripts/
│   │   └── setup.sh
│   ├── confs/
│   └── Vagrantfile
│
├── p2/                          # Part 2: K3s et applications multiples
│   ├── scripts/
│   │   └── setup.sh
│   ├── confs/
│   │   ├── app1-deployment.yaml
│   │   ├── app2-deployment.yaml
│   │   ├── app3-deployment.yaml
│   │   └── ingress.yaml
│   └── Vagrantfile
│
└── p3/                          # Part 3: K3d et ArgoCD
    ├── scripts/
    │   └── setup.sh
    ├── confs/
    │   ├── application.yaml
    │   └── deployment.yaml
    ├── password.txt
    └── README.md
```

---

## 🚀 Part 1: K3s et Vagrant

### Objectif
Créer deux machines virtuelles avec Vagrant et installer K3s :
- **Machine 1 (Server)** : Mode controller
- **Machine 2 (ServerWorker)** : Mode agent

### Configuration
- **OS** : Distribution stable de votre choix
- **Resources** : 1 CPU, 512 MB RAM minimum
- **IPs** :
  - Server : `192.168.56.110`
  - ServerWorker : `192.168.56.111`

### Démarrage
```bash
cd p1
vagrant up
vagrant ssh <machine-name>
kubectl get nodes
```

---

## 🌐 Part 2: K3s et routing par HOST

### Objectif
Déployer 3 applications web avec routing basé sur le hostname via **Ingress**.

### Routing
- `app1.com` → Application 1
- `app2.com` → Application 2 (3 replicas)
- Défaut → Application 3

### Configuration
- Une seule VM en mode serveur K3s
- IP : `192.168.56.110`
- Ingress Controller intégré à K3s

### Démarrage
```bash
cd p2
vagrant up
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl http://192.168.56.110
```

---

## 🔄 Part 3: K3d et ArgoCD (CI/CD)

### Objectif
Mettre en place une infrastructure de **déploiement continu** avec :
- **K3d** : K3s dans Docker
- **ArgoCD** : GitOps pour déploiement automatique
- **GitHub** : Repository source pour les manifests

### Architecture

```
┌─────────────────────────────────────────┐
│          GitHub Repository              │
│    (deployment manifests)               │
└─────────────┬───────────────────────────┘
              │ sync
              ▼
┌─────────────────────────────────────────┐
│           ArgoCD                        │
│    (namespace: argocd)                  │
└─────────────┬───────────────────────────┘
              │ deploy
              ▼
┌─────────────────────────────────────────┐
│      Application                        │
│    (namespace: dev)                     │
│    wil42/playground:v1 ou v2            │
└─────────────────────────────────────────┘
```

### Prérequis
- Docker Desktop installé et en cours d'exécution
- K3d installé
- kubectl installé

### Installation et démarrage

```bash
cd p3

# 1. Lancer le script d'installation
./scripts/setup.sh

# 2. Déployer l'application ArgoCD
kubectl apply -f confs/application.yaml

# 3. Vérifier les namespaces
kubectl get ns

# 4. Vérifier les pods
kubectl get pods -n argocd
kubectl get pods -n dev

# 5. Accéder à ArgoCD UI
# URL: http://localhost:8080
# Username: admin
# Password: voir fichier password.txt

# 6. Tester l'application
curl http://localhost:8888
```

### Ports exposés
- **8080** : ArgoCD Web UI
- **8443** : ArgoCD HTTPS
- **8888** : Application playground

### Déploiement continu

L'application est configurée avec **auto-sync**, **self-heal** et **prune** activés. Toute modification dans le repository GitHub sera automatiquement déployée.

#### Test de mise à jour de version

```bash
# Dans votre repo GitHub, modifiez deployment.yaml
# Changez: image: wil42/playground:v1
# En:      image: wil42/playground:v2

git add deployment.yaml
git commit -m "Update to v2"
git push origin main

# ArgoCD va automatiquement détecter le changement et déployer v2
# Vérifier la synchronisation dans l'UI ArgoCD ou avec:
kubectl get pods -n dev -w
```

### Nettoyage

```bash
# Arrêter le port-forward
pkill -f 'port-forward'

# Supprimer le cluster
k3d cluster delete iot-cluster
```

---

## 🛠️ Technologies utilisées

| Outil | Description | Partie |
|-------|-------------|--------|
| **Vagrant** | Gestion de machines virtuelles | P1, P2 |
| **K3s** | Kubernetes lightweight | P1, P2 |
| **K3d** | K3s dans Docker | P3 |
| **ArgoCD** | GitOps et déploiement continu | P3 |
| **Docker** | Conteneurisation | P3 |
| **kubectl** | Client Kubernetes | P1, P2, P3 |

---

## 📚 Ressources utiles

- [K3s Documentation](https://docs.k3s.io/)
- [K3d Documentation](https://k3d.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## 🐛 Troubleshooting

### Docker daemon not running (P3)
```bash
# Démarrer Docker Desktop
open -a Docker
# Attendre que Docker soit complètement démarré
docker ps
```

### Port déjà utilisé
```bash
# Tuer les processus sur les ports
lsof -i :8080
kill -9 <PID>

# Ou tuer tous les port-forward
pkill -f "port-forward"
```

### Cluster ne démarre pas
```bash
# Supprimer complètement le cluster
k3d cluster delete iot-cluster

# Relancer le setup
./scripts/setup.sh
```

### ArgoCD ne synchronise pas
```bash
# Vérifier les logs ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Forcer la synchronisation
kubectl patch application flask-chat-app -n argocd --type merge -p '{"metadata": {"annotations":{"argocd.argoproj.io/refresh":"normal"}}}'
```

---

## 👤 Auteur

**Luqman** - [ulookme](https://github.com/ulookme)

---

## 📝 License

Ce projet est réalisé dans le cadre d'un exercice pédagogique.

---

## ⭐ Résumé des commandes essentielles

```bash
# Part 1 & 2
vagrant up
vagrant ssh <machine>
kubectl get nodes

# Part 3
./scripts/setup.sh
kubectl apply -f confs/application.yaml
kubectl get pods -n dev
curl http://localhost:8888

# Nettoyage
k3d cluster delete iot-cluster
vagrant destroy -f
```

---

**🎓 Projet Inception-of-Things - Introduction à Kubernetes et GitOps**
## Auteur
- Login : luqman
- Projet : Inception-of-Things (IoT)
- École : 42 Luxembourg

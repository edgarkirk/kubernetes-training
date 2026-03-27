# Homework 1

Kubernetes manifests for deploying a two-service app (resources + songs) with separate Postgres databases.

Everything runs in the `k8s-program` namespace.

## What's included

- **resources-service** — 2 replicas, exposed on NodePort 30080
- **songs-service** — 2 replicas, exposed on NodePort 30081
- **resources-db** — Postgres 17 StatefulSet with 1Gi persistent volume
- **songs-db** — Postgres 17 StatefulSet with 1Gi persistent volume
- A manually provisioned PV/PVC for the songs-service app data (`/app/data`)

## How to deploy

```bash
kubectl apply -f namespace.yml
kubectl apply -f .
```

Wait for pods to be ready:

```bash
kubectl get pods -n k8s-program
```

## Accessing the services

```bash
# if using Minikube
minikube service resources-service -n k8s-program
minikube service songs-service -n k8s-program
```

Or hit `<node-ip>:30080` and `<node-ip>:30081` directly.

## Notes

- Databases use StatefulSets so storage is stable across restarts
- Services talk to each other using Kubernetes DNS (e.g. `songs-service`, `resources-db`)
- Eureka is disabled — no service discovery needed inside the cluster

# Homework 2

Kubernetes manifests for deploying a two-service app (resources + songs) with separate Postgres databases.

Everything runs in the `k8s-program` namespace.

## What's included

| File | Description |
|------|-------------|
| `namespace.yml` | Namespace `k8s-program` |
| `secrets.yml` | DB credentials for resources-db and songs-db |
| `resources-service-configmap.yml` | Env vars for resources-service |
| `songs-service-configmap.yml` | Env vars for songs-service |
| `resources-db-configmap.yml` | Init SQL for resources DB (creates `resources` table) |
| `songs-db-configmap.yml` | Init SQL for songs DB (creates `songs` table) |
| `resources-db-statefulset.yml` | Postgres 17 StatefulSet for resources DB |
| `songs-db-statefulset.yml` | Postgres 17 StatefulSet for songs DB |
| `resources-db-service.yml` | ClusterIP service for resources DB |
| `songs-db-service.yml` | ClusterIP service for songs DB |
| `resources-deployment.yml` | resources-service Deployment (2 replicas, RollingUpdate) |
| `songs-deployement.yml` | songs-service Deployment (2 replicas, RollingUpdate) |
| `resource-service.yml` | NodePort service for resources-service |
| `songs-service.yml` | NodePort service for songs-service |
| `songs-pv.yml` | Manually provisioned PersistentVolume for songs-service |
| `songs-pvc.yml` | PersistentVolumeClaim bound to songs-pv |

## How to deploy

```bash
kubectl apply -f ./
```

Fix PersistentVolume if `songs-pvc` stays Pending (after namespace recreate):
```bash
kubectl patch pv songs-pv -p '{"spec":{"claimRef":null}}'
```

Wait for all pods to be ready:
```bash
kubectl get pods -n k8s-program -w
```

## Sub-task 1: Secrets and ConfigMaps

- DB credentials stored in `secrets.yml` using `stringData` (K8s encodes internally)
- App env vars stored in ConfigMaps loaded via `envFrom.configMapRef`
- Init SQL scripts mounted into `/docker-entrypoint-initdb.d/` via ConfigMap volumes
- StatefulSets load credentials via `secretKeyRef`

## Sub-task 2: Liveness and Readiness probes

**App deployments** use `tcpSocket` probes (Actuator not on classpath):
- `startupProbe` — 30 × 10s = 5min max startup time
- `livenessProbe` — restarts pod if port stops responding
- `readinessProbe` — removes pod from load balancer if not ready

**DB StatefulSets** use `exec: pg_isready`:
- `startupProbe` — 20 × 5s = 100s max
- `livenessProbe` / `readinessProbe` — checks Postgres is accepting connections

Check probe status:
```bash
kubectl describe pod <pod-name> -n k8s-program
```

## Sub-task 3: Deployment strategies

Rolling update strategy on both deployments:
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # one extra pod during update
    maxUnavailable: 0  # no downtime — old pod only removed after new is ready
```

`songs-service` was updated with a new `genre` field (v2.0):
```bash
# Test genre field
curl -s -X POST http://localhost:8081/songs \
  -H "Content-Type: application/json" \
  -d '{"name":"Bohemian Rhapsody","artist":"Queen","album":"A Night at the Opera","length":"5:55","resourceId":1,"year":"1975","genre":"Rock"}' | jq .

curl -s http://localhost:8081/songs/1 | jq .
```

Watch rolling update:
```bash
kubectl rollout status deployment/songs-service-deployment -n k8s-program -w
```

## Sub-task 4: Deployment history and rollback

View history:
```bash
kubectl rollout history deployment/songs-service-deployment -n k8s-program
```

Roll back to previous version (without changing manifest files):
```bash
kubectl rollout undo deployment/songs-service-deployment -n k8s-program
```

Roll forward to a specific revision:
```bash
kubectl rollout undo deployment/songs-service-deployment -n k8s-program --to-revision=<revision>
```

Verify which image is running:
```bash
kubectl describe deployment songs-service-deployment -n k8s-program | grep Image
```

## Notes

- Databases use StatefulSets so storage is stable across restarts
- Services communicate via Kubernetes DNS (`songs-service`, `resources-db`, etc.)
- Eureka is disabled — no service discovery needed inside the cluster
- `ddl-auto=update` overridden via ConfigMap to prevent table drops during rolling updates
- Actuator health endpoint available at `/actuator/health` (exposed via `MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=*`)

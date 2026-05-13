# Homework 4

Helm chart for deploying a two-service app (resources + songs) with separate Postgres databases, exposed via nginx Ingress.

Chart: `kuber-training-chart/` — namespace and replica count are configurable via Helm values.

## Chart structure

| File | Description |
|------|-------------|
| `Chart.yaml` | Chart metadata (name, version, appVersion) |
| `values.yaml` | Default values: `replicaCount: 2`, `namespace: k8s-program` |
| `templates/_helpers.tpl` | Shared label definitions (date, version) |
| `templates/namespace.yml` | Namespace |
| `templates/secrets.yml` | DB credentials for resources-db and songs-db |
| `templates/resources-service-configmap.yml` | Env vars for resources-service (includes helper labels) |
| `templates/songs-service-configmap.yml` | Env vars for songs-service |
| `templates/resources-db-configmap.yml` | Init SQL for resources DB |
| `templates/songs-db-configmap.yml` | Init SQL for songs DB |
| `templates/resources-db-statefulset.yml` | Postgres 17 StatefulSet for resources DB |
| `templates/songs-db-statefulset.yml` | Postgres 17 StatefulSet for songs DB |
| `templates/resources-db-service.yml` | ClusterIP service for resources DB |
| `templates/songs-db-service.yml` | ClusterIP service for songs DB |
| `templates/resources-deployment.yml` | resources-service Deployment |
| `templates/songs-deployement.yml` | songs-service Deployment |
| `templates/resource-service.yml` | ClusterIP service for resources-service |
| `templates/songs-service.yml` | ClusterIP service for songs-service |
| `templates/songs-pv.yml` | Manually provisioned PersistentVolume for songs-service |
| `templates/songs-pvc.yml` | PersistentVolumeClaim bound to songs-pv |
| `templates/ingress.yml` | Nginx ingress with rewrite-target routing for songs and resources |

## Sub-task 1: Ingress

### Services changed to ClusterIP

`resource-service.yml` and `songs-service.yml` are `type: ClusterIP` — all external traffic goes through the ingress only.

### Ingress rewrite-target

Two ingress objects in `templates/ingress.yml`, each with its own `rewrite-target`:

| External path | Internal path |
|---|---|
| `http://localhost:8080/api/v1/songs/1` | `songs-service:8081/songs/1` |
| `http://localhost:8080/api/v1/resources/1` | `resources-service:8080/resources/1` |

The `/api/v1/<service>` prefix is stripped using a regex capture group `$2` in `rewrite-target`.

### Deploy

**Step 1 — Install the app chart (creates the namespace):**
```bash
helm install kuber-training . --namespace k8s-program --create-namespace
```

**Step 2 — Install ingress controller into the same namespace:**
```bash
helm install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace k8s-program
```

Wait until running:
```bash
kubectl get pods -n k8s-program -w
```

### Verify the rewrite

**Step 1 — Backend does NOT support `/api/v1/songs/1`:**
```bash
kubectl port-forward svc/songs-service 8081:8081 -n k8s-program
curl -i http://localhost:8081/api/v1/songs/1
# Expected: 404
```

**Step 2 — Backend DOES support `/songs/1`:**
```bash
curl -i http://localhost:8081/songs/1
# Expected: 200
```

**Step 3 — Ingress rewrites `/api/v1/songs/1` → `/songs/1`:**
```bash
kubectl port-forward -n k8s-program svc/ingress-nginx-controller 8080:80
curl -i http://localhost:8080/api/v1/songs/1
# Expected: 200
```

### Cleanup

```bash
helm uninstall kuber-training -n k8s-program
helm uninstall ingress-nginx -n k8s-program
kubectl delete namespace k8s-program
```

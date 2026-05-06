# Homework 3

Helm chart for deploying a two-service app (resources + songs) with separate Postgres databases.

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
| `templates/resource-service.yml` | NodePort service for resources-service |
| `templates/songs-service.yml` | NodePort service for songs-service |
| `templates/songs-pv.yml` | Manually provisioned PersistentVolume for songs-service |
| `templates/songs-pvc.yml` | PersistentVolumeClaim bound to songs-pv |

## Sub-task 1: Helm chart default variables

`replicaCount` and `namespace` are Helm values defined in `values.yaml`:

```yaml
replicaCount: 2
namespace: k8s-program
```

Deploy with default values:
```bash
helm install kuber-training ./kuber-training-chart
```

Deploy with non-default values:
```bash
helm install kuber-training ./kuber-training-chart \
  --set namespace=my-ns \
  --set replicaCount=3
```

Verify pods are running:
```bash
kubectl get pods -n k8s-program
```

Upgrade an existing release:
```bash
helm upgrade kuber-training ./kuber-training-chart
```

Uninstall:
```bash
helm uninstall kuber-training
```

Fix PersistentVolume if `songs-pvc` stays Pending (after namespace recreate):
```bash
kubectl patch pv songs-pv -p '{"spec":{"claimRef":null}}'
```

## Sub-task 2: Helm chart helpers

`templates/_helpers.tpl` defines a named template with two labels:

```gotemplate
{{- define "kuber-training-chart.labels" -}}
date: {{ now | date "2006-01-02" | quote }}
version: {{ .Chart.AppVersion | quote }}
{{- end }}
```

- `date` — generated at render time using Helm's `now` function
- `version` — taken from `appVersion` in `Chart.yaml`

`resources-service-configmap.yml` includes the labels:

```yaml
metadata:
  labels:
    {{- include "kuber-training-chart.labels" . | nindent 4 }}
```

Rendered output example:
```yaml
labels:
  date: "2026-05-06"
  version: "1.0.0"
```

Preview rendered templates without deploying:
```bash
helm template kuber-training ./kuber-training-chart
```

## Notes

- Databases use StatefulSets so storage is stable across restarts
- Services communicate via Kubernetes DNS (`songs-service`, `resources-db`, etc.)
- Eureka is disabled — no service discovery needed inside the cluster
- `ddl-auto=update` overridden via ConfigMap to prevent table drops during rolling updates
- Actuator health endpoint available at `/actuator/health` (exposed via `MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=*`)

# RootCX Helm Charts

Official Helm charts for deploying RootCX on Kubernetes and OpenShift.

## Usage

```bash
helm repo add rootcx https://charts.rootcx.com
helm repo update
helm install rootcx rootcx/rootcx-core --set postgresql.auth.password=<your-password>
```

## Charts

| Chart | Description |
|-------|-------------|
| [rootcx-core](./charts/rootcx-core) | RootCX Core runtime with embedded PostgreSQL (PGMQ + pg_cron) |

## Configuration

All configuration is done via environment variables. See [`values.yaml`](./charts/rootcx-core/values.yaml) for the full list of parameters.

An example production values file is included at [`values-example.yaml`](./charts/rootcx-core/values-example.yaml).

```bash
helm install rootcx ./charts/rootcx-core \
  -f ./charts/rootcx-core/values-example.yaml \
  --set postgresql.auth.password=<password> \
  --set oidc.clientSecret=<secret>
```

## Requirements

- Kubernetes 1.26+ or OpenShift 4.x
- Helm 3.x
- A StorageClass that supports ReadWriteOnce PVCs

## Development

```bash
helm lint ./charts/rootcx-core --set postgresql.auth.password=test
helm template rootcx ./charts/rootcx-core --set postgresql.auth.password=test
helm install rootcx ./charts/rootcx-core --set postgresql.auth.password=test --set image.tag=latest
helm test rootcx
```

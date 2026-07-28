# RootCX Helm Charts

Official open-source Helm charts for RootCX on Kubernetes and OpenShift.

## Quickstart

Prerequisites:

- Kubernetes 1.28 or newer;
- Helm 3.14 or newer;
- a default `ReadWriteOnce` StorageClass.

```bash
helm repo add rootcx https://rootcx.github.io/helm-charts
helm repo update
helm install rootcx rootcx/rootcx
```

Check the installation:

```bash
kubectl get pods
helm test rootcx
```

Access Portal locally:

```bash
kubectl port-forward service/rootcx 3000:3000
```

Open <http://localhost:3000> and create the first account with
`admin@rootcx.localhost`.

Quickstart uses the embedded single-node PostgreSQL server, generates its
application secrets on first install, and reuses them on upgrades. SMTP,
Ingress and Routes remain disabled. Quickstart is intended for local evaluation,
not production.

## Production

Production mode keeps all security-sensitive configuration explicit. Start from
[`examples/values-kubernetes.yaml`](examples/values-kubernetes.yaml) or
[`examples/values-openshift.yaml`](examples/values-openshift.yaml), configure
real hosts, TLS, SMTP and durable secrets, then install:

```bash
helm upgrade --install rootcx rootcx/rootcx \
  --namespace rootcx \
  --create-namespace \
  --values values.yaml \
  --set-file oidc.signingKey=oidc-private-key.pem \
  --wait \
  --timeout 10m
```

The production profile rejects missing administrator, SMTP, host and secret
configuration. For high availability, backup and point-in-time recovery, use
an externally operated PostgreSQL service instead of the embedded single-node
server.

## Charts

| Chart | Description |
| --- | --- |
| [`rootcx`](charts/rootcx) | Portal, Core and optional embedded PostgreSQL |
| [`rootcx-core`](charts/rootcx-core) | Standalone Core and optional embedded PostgreSQL |

Both charts auto-detect OpenShift through the Route API. An explicit
`global.platform` value can still override detection.

## OpenAI-compatible AI gateway

Configure only the exact base URL supplied by the AI platform operator:

```yaml
core:
  ai:
    openai:
      baseUrl: "https://REPLACE_WITH_THE_REAL_GATEWAY_HOST/v1"
```

The chart does not guess a gateway hostname, namespace, CIDR, model or
certificate. Internal certificate authorities use `core.trustedCA`; private or
in-cluster endpoints require exact `core.networkPolicy.extraEgress` rules.

## Development

```bash
helm dependency build charts/rootcx
helm lint charts/rootcx-core
helm lint charts/rootcx
helm template rootcx charts/rootcx
```

Chart releases are immutable and published both as GitHub release assets for
the HTTP Helm repository and as OCI artifacts under
`oci://ghcr.io/rootcx/helm-charts`.

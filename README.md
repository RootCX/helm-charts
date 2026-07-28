# RootCX Helm Charts

Official Helm charts for deploying RootCX on Kubernetes and OpenShift.

## Usage

```bash
helm repo add rootcx https://rootcx.github.io/helm-charts
helm repo update
helm upgrade --install rootcx-core \
  rootcx/rootcx-core \
  --version 0.4.0 \
  --set-string postgresql.auth.password='<password>'
```

## OpenAI-compatible AI Gateway

RootCX agents can use the OpenAI Chat Completions-compatible endpoint supplied
by the customer's AI platform. Configure the exact base URL provided by the
platform team; the chart does not guess a SophIA or Ops4AI hostname:

```yaml
ai:
  openai:
    baseUrl: "https://REPLACE_WITH_THE_REAL_GATEWAY_HOST/v1"
```

The value becomes `ROOTCX_OPENAI_BASE_URL` in Core and is explicitly forwarded
to sandboxed OpenAI agents as `OPENAI_BASE_URL`. Agent API keys remain encrypted
in the RootCX platform secret vault and are not stored in Helm values.

When the gateway uses an internal CA, set `trustedCA` to the name of the
OpenShift service CA or customer ConfigMap containing `ca-bundle.crt`. When it
uses an RFC1918 or in-cluster address and `networkPolicy.enabled=true`, add only
the exact egress namespace selector, pod selector, or CIDR supplied by the
platform team under `networkPolicy.extraEgress`.

The same immutable chart version is also published as
`oci://ghcr.io/rootcx/charts/rootcx-core`.

## Charts

| Chart | Description |
|-------|-------------|
| [rootcx-core](./charts/rootcx-core) | RootCX Core runtime with embedded PostgreSQL (PGMQ + pg_cron) |

## Configuration

All configuration is done via environment variables. See [`values.yaml`](./charts/rootcx-core/values.yaml) for the full list of parameters.

An example production values file is included at [`values-example.yaml`](./charts/rootcx-core/values-example.yaml).

```bash
helm upgrade --install rootcx ./charts/rootcx-core \
  -f ./charts/rootcx-core/values-example.yaml \
  --set-string postgresql.auth.password='<password>'
```

## Requirements

- Kubernetes 1.28+ or OpenShift 4.x
- Helm 3.x
- A StorageClass that supports ReadWriteOnce PVCs

Set `global.platform=openshift` on OpenShift. The chart then omits fixed user
and group IDs and runs under the namespace UID allocated by `restricted-v2`;
no `anyuid` grant is required.

## Public host and TLS

The chart never invents or registers a public domain. Set the real FQDN that
your organization controls and make its DNS record point to the cluster ingress
before installation:

```yaml
global:
  platform: openshift # or kubernetes
  rootcx:
    hosts:
      core: REPLACE_WITH_REAL_CORE_FQDN
    tls:
      secretName: rootcx-tls
```

`secretName` must reference a `kubernetes.io/tls` Secret in the release
namespace. On Kubernetes it is attached to the generated Ingress. On OpenShift
4.19 or newer it is attached through `Route.spec.tls.externalCertificate`.
Leave it empty only when the ingress controller's default certificate is
trusted and covers the configured host. Certificate issuance and renewal stay
with the customer's existing certificate manager; the chart only references
the resulting Secret. On OpenShift, the chart also creates a namespace-scoped
Role and RoleBinding that grant the router read-only access to that Secret, as
required by the Route API. Set
`global.rootcx.tls.openshift.createRouterRBAC=false` only when equivalent RBAC
is already managed by the cluster administrator.

## Development

```bash
helm lint ./charts/rootcx-core --set-string postgresql.auth.password=test
helm template rootcx ./charts/rootcx-core --set-string postgresql.auth.password=test
helm upgrade --install rootcx ./charts/rootcx-core \
  --set-string postgresql.auth.password=test \
  --set-string image.tag=latest
helm test rootcx
```

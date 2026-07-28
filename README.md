# RootCX Helm Charts

Official open-source Helm chart for RootCX on Kubernetes and OpenShift.

## Install

Prerequisites:

- Kubernetes 1.28 or newer;
- Helm 3.14 or newer;
- a default `ReadWriteOnce` StorageClass;
- two DNS hostnames;
- HTTPS from the platform router or ingress controller.

```bash
helm repo add rootcx https://rootcx.github.io/helm-charts
helm repo update
```

RootCX intentionally has no HTTP or guessed-domain mode. Create a small
`values.yaml` for the target environment, then install with:

```bash
helm install rootcx rootcx/rootcx --values values.yaml
```

Check the installation:

```bash
kubectl get pods
helm test rootcx --namespace rootcx
```

### OpenShift Local HTTPS

OpenShift Local already provides `*.apps-crc.testing` and a wildcard ingress
certificate. Its local CA must be trusted by Core and, once per CRC certificate,
by the developer workstation.

Create `values.yaml`:

```yaml
global:
  platform: openshift
  rootcx:
    hosts:
      portal: rootcx.apps-crc.testing
      core: rootcx-core.apps-crc.testing

core:
  trustedCA: rootcx-ingress-ca
  networkPolicy:
    enabled: false # Local profile only; production keeps isolation enabled.
```

Prepare the namespace and copy only the public ingress CA bundle into it:

```bash
kubectl create namespace rootcx
kubectl get configmap default-ingress-cert \
  --namespace openshift-config-managed \
  --output go-template='{{ index .data "ca-bundle.crt" }}' |
kubectl create configmap rootcx-ingress-ca \
  --namespace rootcx \
  --from-file=ca-bundle.crt=/dev/stdin
```

Install and validate:

```bash
helm install rootcx rootcx/rootcx --namespace rootcx --values values.yaml --wait
helm test rootcx --namespace rootcx
```

Get the Portal URL:

```bash
kubectl get route rootcx -o jsonpath='https://{.spec.host}{"\n"}'
```

To remove the browser warning on macOS, export the ingress chain, retain its
self-signed root certificate, and approve that root explicitly in Keychain:

```bash
kubectl get configmap default-ingress-cert \
  --namespace openshift-config-managed \
  --output go-template='{{ index .data "ca-bundle.crt" }}' > crc-ingress-chain.pem
awk '/BEGIN CERTIFICATE/{certificate++} certificate==2{print}' \
  crc-ingress-chain.pem > crc-ingress-root-ca.pem
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain crc-ingress-root-ca.pem
```

Open `https://rootcx.apps-crc.testing` and create the first account with
`admin@rootcx.localhost`.

The single `rootcx` chart installs Portal, Core and an embedded single-node
PostgreSQL server. It generates application secrets on first install and reuses
them on upgrades. SMTP remains disabled in quickstart. Quickstart is intended
for local evaluation, not production.

## Production

Production mode keeps all security-sensitive configuration explicit. Start from
[`examples/values-kubernetes.yaml`](examples/values-kubernetes.yaml) or
[`examples/values-openshift.yaml`](examples/values-openshift.yaml), configure
real hosts, TLS and durable secrets, then install:

```bash
helm upgrade --install rootcx rootcx/rootcx \
  --namespace rootcx \
  --create-namespace \
  --values values.yaml \
  --set-file oidc.signingKey=oidc-private-key.pem \
  --wait \
  --timeout 10m
```

SMTP is optional in every deployment mode. When disabled, Portal starts normally
and email-dependent features remain unavailable. When enabled, configure the
sender and SMTP relay; keep credentials in an existing Kubernetes Secret for
production. For high availability, backup and point-in-time recovery, use an
externally operated PostgreSQL service instead of the embedded single-node server.

For a publicly trusted wildcard certificate, create or reuse the Kubernetes TLS
Secret and set `global.rootcx.tls.secretName`. No `core.trustedCA` is needed. For
an enterprise/private CA, also create a ConfigMap whose `ca-bundle.crt` contains
the additional CA chain and set `core.trustedCA`; the chart merges it with the
image's public roots rather than replacing them. On OpenShift, omit the TLS
Secret when the router's default wildcard certificate already covers both hosts.
When a production Route resolves to a private load-balancer address, add that
exact CIDR and TCP port 443 under `core.networkPolicy.extraEgress`.

## Chart

[`rootcx`](charts/rootcx) is the only supported chart. It installs Portal, Core
and optional embedded PostgreSQL. The chart auto-detects OpenShift through the
Route API. An explicit
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
helm lint charts/rootcx
helm template rootcx charts/rootcx
```

Chart releases are immutable and published both as GitHub release assets for
the HTTP Helm repository and as OCI artifacts under
`oci://ghcr.io/rootcx/helm-charts`.

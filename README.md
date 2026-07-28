# RootCX Helm Charts

Official open-source Helm chart for running RootCX on Kubernetes and OpenShift.

One chart installs:

- RootCX Portal;
- RootCX Core;
- an optional embedded PostgreSQL server.

Portal and Core remain separate workloads and are exposed through two HTTPS
hostnames. The chart configures their OIDC relationship automatically from
those hostnames.

## Choose your installation

| Environment | Start here |
| --- | --- |
| OpenShift Local (CRC) on a developer workstation | [Local HTTPS quickstart](#local-https-quickstart-openshift-local) |
| Production OpenShift | [Production on OpenShift](#production-on-openshift) |
| Production Kubernetes | [Production on Kubernetes](#production-on-kubernetes) |

## Requirements

- Kubernetes 1.28 or newer, or a compatible OpenShift release;
- Helm 3.14 or newer;
- a default `ReadWriteOnce` StorageClass when using embedded PostgreSQL;
- two unique DNS hostnames: one for Portal and one for Core;
- an ingress controller on Kubernetes, or the OpenShift router;
- HTTPS certificates covering both hostnames.

RootCX is HTTPS-only. It does not guess a domain and does not use a different
internal OIDC issuer: the issuer visible to the browser is also validated by
Core.

Add the repository once:

```bash
helm repo add rootcx https://rootcx.github.io/helm-charts
helm repo update
```

## Local HTTPS quickstart: OpenShift Local

This is the shortest fully tested local path. OpenShift Local provides:

- the local applications domain `*.apps-crc.testing`;
- an HTTPS router.

[`mkcert`](https://github.com/FiloSottile/mkcert) creates a development CA,
installs it in the workstation trust stores and generates the certificate used
by the OpenShift Routes. This gives macOS, Windows and Linux the same setup.

It is intentionally not `https://localhost`: Portal and Core need two stable
hostnames that are reachable from both the browser and the cluster. The local
hostnames are:

- Portal: `https://portal.rootcx.apps-crc.testing`
- Core: `https://api.rootcx.apps-crc.testing`

### 1. Select the local cluster

```bash
kubectl config use-context crc-admin
kubectl cluster-info
```

The API endpoint should be `https://api.crc.testing:6443`.

### 2. Create a clean namespace

```bash
kubectl create namespace rootcx
```

To deliberately replace an older local test installation:

```bash
kubectl delete namespace rootcx --wait=true
kubectl create namespace rootcx
```

Deleting the namespace deletes every resource in it. Persistent volumes may
remain when their reclaim policy is `Retain`.

### 3. Create and trust the local certificate

Install `mkcert` using the package manager for the workstation:

| Platform | Command |
| --- | --- |
| macOS | `brew install mkcert` |
| Windows with Chocolatey | `choco install mkcert` |
| Windows with Scoop | `scoop bucket add extras && scoop install mkcert` |
| Linux | Follow the distribution-specific installation in the [mkcert documentation](https://github.com/FiloSottile/mkcert#installation) and install its NSS tools package when required |

Create the local CA and certificate. `mkcert -install` may request administrator
approval because it updates the workstation trust stores:

```bash
mkcert -install
mkcert -cert-file rootcx-local.crt -key-file rootcx-local.key portal.rootcx.apps-crc.testing api.rootcx.apps-crc.testing
```

Create the TLS Secret used by both OpenShift Routes:

```bash
kubectl create secret tls rootcx-local-tls --namespace rootcx --cert=rootcx-local.crt --key=rootcx-local.key
```

Core also needs the public development CA. On macOS, Linux, WSL or Git Bash:

```bash
kubectl create configmap rootcx-local-ca \
  --namespace rootcx \
  --from-file=ca-bundle.crt="$(mkcert -CAROOT)/rootCA.pem"
```

In native Windows PowerShell:

```powershell
$mkcertCaRoot = mkcert -CAROOT
kubectl create configmap rootcx-local-ca `
  --namespace rootcx `
  "--from-file=ca-bundle.crt=$mkcertCaRoot/rootCA.pem"
```

Only the public CA certificate enters the ConfigMap. The CA private key remains
on the workstation and must never be copied, committed or shared.

### 4. Create `values.yaml`

```yaml
global:
  platform: openshift
  rootcx:
    hosts:
      portal: portal.rootcx.apps-crc.testing
      core: api.rootcx.apps-crc.testing
    tls:
      secretName: rootcx-local-tls

core:
  trustedCA: rootcx-local-ca
  networkPolicy:
    enabled: false
```

The Core NetworkPolicy is disabled only in this local profile. CRC resolves its
application routes to a private VM address, and standard Kubernetes
NetworkPolicy has no portable FQDN rule. Production keeps isolation enabled and
uses explicit network rules.

### 5. Install and test

```bash
helm install rootcx rootcx/rootcx \
  --namespace rootcx \
  --values values.yaml \
  --wait \
  --timeout 10m

kubectl get pods --namespace rootcx
helm test rootcx --namespace rootcx --logs
```

A healthy installation has three running pods: Portal, Core and PostgreSQL.
All Helm tests must report `Succeeded`, including `rootcx-core-test-oidc`.

Open:

```text
https://portal.rootcx.apps-crc.testing
```

Register with `admin@rootcx.localhost` to initialize the workspace. After
initialization, additional users must be invited from **Team**.

If Chrome was open during `mkcert -install`, quit it completely and reopen it.
The Portal should load without a certificate warning. Firefox may require its
NSS support package, as documented by mkcert.

This certificate is for local development only. Remove the development CA with
`mkcert -uninstall` when it is no longer needed.

## Production

Production mode requires explicit secrets and infrastructure choices. It does
not silently generate production credentials.

The production certificate must be trusted by every browser and workload that
accesses RootCX. Use a publicly trusted CA for Internet-facing deployments or
the organization's managed enterprise CA for private deployments. Standalone
self-signed certificates are not recommended in production.

Before installing, decide:

1. the real Portal and Core FQDNs;
2. how DNS reaches the ingress controller or OpenShift router;
3. which certificate covers both FQDNs;
4. whether PostgreSQL is embedded or externally operated;
5. whether SMTP is enabled;
6. whether outbound private services require additional CA or network rules.

### Production on Kubernetes

Start from:

```bash
curl --fail --silent --show-error \
  --output values.yaml \
  https://raw.githubusercontent.com/RootCX/helm-charts/master/examples/values-kubernetes.yaml
```

Replace every `REPLACE_WITH_...` value and set the ingress class used by the
cluster.

Create or reuse a TLS Secret containing a certificate whose SANs cover both
FQDNs:

```bash
kubectl create namespace rootcx

kubectl create secret tls rootcx-tls \
  --namespace rootcx \
  --cert=fullchain.pem \
  --key=privkey.pem
```

The `global.rootcx.tls.secretName` value must match this Secret. Certificate
renewal is normally managed by the platform or cert-manager; the chart only
references the Secret.

Generate the OIDC signing key outside the values file:

```bash
openssl genpkey \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:2048 \
  -out oidc-private-key.pem

chmod 600 oidc-private-key.pem
```

Render and inspect the manifests before installing:

```bash
helm template rootcx rootcx/rootcx \
  --namespace rootcx \
  --values values.yaml \
  --set-file oidc.signingKey=oidc-private-key.pem \
  > /tmp/rootcx-rendered.yaml
```

Install:

```bash
helm upgrade --install rootcx rootcx/rootcx \
  --namespace rootcx \
  --create-namespace \
  --values values.yaml \
  --set-file oidc.signingKey=oidc-private-key.pem \
  --wait \
  --timeout 10m

helm test rootcx --namespace rootcx --logs
```

`--set-file` is used only for the PEM file so the multiline private key does not
need to be copied into YAML. In an automated production pipeline, prefer an
existing Kubernetes Secret or an external secret operator.

### Production on OpenShift

Start from:

```bash
curl --fail --silent --show-error \
  --output values.yaml \
  https://raw.githubusercontent.com/RootCX/helm-charts/master/examples/values-openshift.yaml
```

Replace every `REPLACE_WITH_...` value.

Choose one TLS model:

- **Default OpenShift wildcard certificate:** leave
  `global.rootcx.tls.secretName` empty only when the router certificate is
  trusted and covers both RootCX Route hosts.
- **Your own wildcard or SAN certificate:** create `rootcx-tls` in the RootCX
  namespace and keep `global.rootcx.tls.secretName: rootcx-tls`.
- **Enterprise/private CA:** use either model above, and also configure the
  public CA chain for Core as described below.

For a custom certificate:

```bash
kubectl create namespace rootcx

kubectl create secret tls rootcx-tls \
  --namespace rootcx \
  --cert=fullchain.pem \
  --key=privkey.pem
```

The chart creates namespace-scoped RBAC allowing the configured OpenShift
router service account to read only that TLS Secret. If the cluster operator
uses a different router service account, configure its exact namespace and
name under `global.rootcx.tls.openshift.routerServiceAccount`.

Generate the OIDC key, validate and install with the same commands as
Kubernetes:

```bash
openssl genpkey \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:2048 \
  -out oidc-private-key.pem

chmod 600 oidc-private-key.pem

helm upgrade --install rootcx rootcx/rootcx \
  --namespace rootcx \
  --create-namespace \
  --values values.yaml \
  --set-file oidc.signingKey=oidc-private-key.pem \
  --wait \
  --timeout 10m

helm test rootcx --namespace rootcx --logs
```

### Public certificates versus private CAs

With a publicly trusted certificate, leave `core.trustedCA` empty.

When an HTTPS dependency or the RootCX router uses an enterprise/private CA,
create a ConfigMap containing only its public CA chain:

```bash
kubectl create configmap rootcx-enterprise-ca \
  --namespace rootcx \
  --from-file=ca-bundle.crt=enterprise-ca-chain.pem
```

Then configure:

```yaml
core:
  trustedCA: rootcx-enterprise-ca
```

The additional chain is merged with the image's public roots. Workstations must
also trust the enterprise root through the organization's normal device
management or certificate policy.

### NetworkPolicy and private endpoints

Production NetworkPolicies are enabled by default. Public HTTPS egress is
allowed, while private RFC1918 destinations are denied unless explicitly
listed.

If the OpenShift Route, AI gateway or another dependency resolves to a private
load-balancer address, add only the exact CIDR and required port:

```yaml
core:
  networkPolicy:
    extraEgress:
      - to:
          - ipBlock:
              cidr: 10.20.30.40/32
        ports:
          - protocol: TCP
            port: 443
```

Do not copy this example address. Obtain the real destination and CIDR from the
platform operator.

### PostgreSQL

The embedded PostgreSQL StatefulSet is convenient for local evaluation and
single-node installations. Its persistent volume is retained by default.

For production high availability, managed backups and point-in-time recovery,
use an externally operated PostgreSQL service:

```yaml
portalDatabase:
  url: "postgres://USER:PASSWORD@HOST:5432/portal"

core:
  databaseUrl: "postgres://USER:PASSWORD@HOST:5432/rootcx"
  postgresql:
    enabled: false
```

Keep database URLs in an existing Kubernetes Secret in real deployments rather
than committing them to Git.

### SMTP

SMTP is optional. With `email.enabled: false`, Portal starts normally, while
email-dependent features are unavailable.

To enable it:

```yaml
email:
  enabled: true
  from: "rootcx@example.com"
  smtp:
    host: "smtp.example.com"
    port: 587
    secure: false
    requireTls: true
    username: "rootcx"
    password: ""
```

Store `SMTP_PASSWORD` in the Portal existing Secret for production. A trusted
in-cluster relay may omit username and password.

### Production secret management

The example files make every required setting visible, but production secrets
must not be committed to Git. Use one of:

- encrypted GitOps secrets;
- an external secret operator backed by the organization's secret manager;
- pre-created Kubernetes Secrets referenced through `existingSecret` and
  `core.existingSecret`.

The expected Portal Secret keys are:

- `AUTH_SECRET`;
- `NEXTAUTH_SECRET`;
- `OIDC_SIGNING_KEY`;
- `ROOTCX_OIDC_CLIENT_SECRET`;
- `DATABASE_URL` when embedded PostgreSQL is disabled;
- `SMTP_PASSWORD` when authenticated SMTP is enabled.

The expected Core Secret keys are:

- `DATABASE_URL`;
- `ROOTCX_JWT_SECRET`;
- `ROOTCX_MASTER_KEY`;
- `ROOTCX_OIDC_CLIENT_SECRET`;
- `POSTGRES_PASSWORD` when embedded PostgreSQL is enabled.

## Operations

### Status and logs

```bash
helm status rootcx --namespace rootcx
kubectl get pods --namespace rootcx
kubectl get events --namespace rootcx --sort-by='.lastTimestamp'
kubectl logs --namespace rootcx deployment/rootcx
kubectl logs --namespace rootcx deployment/rootcx-core
```

### Upgrade

```bash
helm repo update

helm upgrade rootcx rootcx/rootcx \
  --namespace rootcx \
  --reuse-values \
  --wait \
  --timeout 10m

helm test rootcx --namespace rootcx --logs
```

For GitOps or audited production environments, keep the complete values in
version-controlled configuration and pass `--values` instead of relying on
`--reuse-values`.

### Roll back

```bash
helm history rootcx --namespace rootcx
helm rollback rootcx REVISION --namespace rootcx --wait --timeout 10m
```

### Uninstall

```bash
helm uninstall rootcx --namespace rootcx
```

The chart retains PostgreSQL and Core persistent storage by default. Review and
delete retained PVCs only when permanent data deletion is intentional:

```bash
kubectl get pvc --namespace rootcx
```

### Troubleshooting

Show the effective public endpoints:

```bash
helm get notes rootcx --namespace rootcx
```

Verify the OIDC discovery document from Core:

```bash
kubectl exec --namespace rootcx deployment/rootcx-core -- \
  curl --fail --show-error \
  --cacert /etc/rootcx/tls/ca-bundle.crt \
  https://PORTAL_FQDN/.well-known/openid-configuration
```

Use the real Portal FQDN. If no private CA is configured, omit `--cacert`.

Common causes:

| Symptom | Check |
| --- | --- |
| Browser shows a red HTTPS warning locally | Run `mkcert -install`, then quit and reopen the browser |
| `rootcx-core-test-oidc` fails | Core must resolve and reach the exact public Portal issuer over HTTPS |
| Certificate name mismatch | The certificate SANs must cover both Portal and Core FQDNs |
| Core cannot reach a private Route or gateway | Add the exact private CIDR to `core.networkPolicy.extraEgress` |
| Pods stay Pending | Check the default StorageClass, PVCs and namespace events |
| Email features fail | SMTP is optional but must be fully configured when enabled |

## Chart development

The repository contains one supported chart: [`rootcx`](charts/rootcx).

Validate local changes with explicit test values:

```bash
helm lint charts/rootcx \
  --values examples/values-openshift-local.yaml

helm template rootcx charts/rootcx \
  --values examples/values-openshift-local.yaml \
  --api-versions route.openshift.io/v1/Route \
  > /tmp/rootcx-openshift.yaml
```

Chart releases are immutable and published as:

- a standard Helm repository at `https://rootcx.github.io/helm-charts`;
- OCI artifacts under `oci://ghcr.io/rootcx/helm-charts`.

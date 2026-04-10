# owe-devops

## Purpose

This repository holds the staging deployment configuration for the OWE stack.

The current release flow is intentionally simple:

1. Push a semantic version tag such as `v0.1.0` to [`owe-service`](/Users/jayden/workspace/github/owe/owe-service) or [`owe-ui`](/Users/jayden/workspace/github/owe/owe-ui)
2. GitHub Actions builds and pushes a versioned image to GHCR
3. The workflow updates [`charts/owe/values.yaml`](/Users/jayden/workspace/github/owe/owe-devops/charts/owe/values.yaml)
4. Argo CD syncs the new image tag into the staging Kubernetes cluster

## Layout

- [`charts/owe`](/Users/jayden/workspace/github/owe/owe-devops/charts/owe): Helm chart for the UI and service
- [`charts/postgres`](/Users/jayden/workspace/github/owe/owe-devops/charts/postgres): Helm chart for the dedicated PostgreSQL deployment
- [`argocd/root-application.yaml`](/Users/jayden/workspace/github/owe/owe-devops/argocd/root-application.yaml): parent Argo CD application for app-of-apps management
- [`argocd/apps/owe-application.yaml`](/Users/jayden/workspace/github/owe/owe-devops/argocd/apps/owe-application.yaml): child Argo CD application for the OWE stack
- [`argocd/apps/postgres-application.yaml`](/Users/jayden/workspace/github/owe/owe-devops/argocd/apps/postgres-application.yaml): child Argo CD application for PostgreSQL

## Required Secrets

Create a Kubernetes secret named `owe-service-secrets` in the `owe` namespace with:

- `OPENAI_API_KEY`
- `DB_USER`
- `DB_PASSWORD`
- optional `AUTH0_DOMAIN`
- optional `AUTH0_API_AUDIENCE`
- optional `LANGSMITH_API_KEY`

Create a Kubernetes secret named `owe-ui-secrets` in the `owe` namespace with:

- `AUTH0_DOMAIN`
- `AUTH0_CLIENT_ID`
- `AUTH0_AUDIENCE`
- `APP_BASE_URL`
- `AUTH0_CLIENT_SECRET`
- `AUTH0_SECRET`

Create a Kubernetes secret named `postgres-secrets` in the `postgres` namespace with:

- `DB_USER`
- `DB_PASSWORD`

Create a local PostgreSQL secret manifest from the example:

```bash
cp /Users/jayden/workspace/github/owe/owe-devops/secrets/postgres-secrets.example.yaml \
  /Users/jayden/workspace/github/owe/owe-devops/secrets/postgres-secrets.yaml
```

Create a local application secret manifest from the example:

```bash
cp /Users/jayden/workspace/github/owe/owe-devops/secrets/owe-service-secrets.example.yaml \
  /Users/jayden/workspace/github/owe/owe-devops/secrets/owe-service-secrets.yaml
```

Edit the copied files with real values, then apply them:

```bash
kubectl apply -f /Users/jayden/workspace/github/owe/owe-devops/secrets/postgres-secrets.yaml
kubectl apply -f /Users/jayden/workspace/github/owe/owe-devops/secrets/owe-service-secrets.yaml
```

If Auth0 is enabled, also create the UI secret:

```bash
kubectl create secret generic owe-ui-secrets \
  -n owe \
  --from-literal=AUTH0_CLIENT_SECRET='<auth0-client-secret>' \
  --from-literal=AUTH0_SECRET='<auth0-session-secret>' \
  --dry-run=client -o yaml | kubectl apply -f -
```

Or keep PostgreSQL credentials in a local Helm values file that is not committed:

```bash
cp /Users/jayden/workspace/github/owe/owe-devops/charts/postgres/values.local.example.yaml \
  /Users/jayden/workspace/github/owe/owe-devops/charts/postgres/values.local.yaml
```

Then deploy with:

```bash
helm upgrade --install postgres /Users/jayden/workspace/github/owe/owe-devops/charts/postgres \
  -n postgres \
  --set namespaceConfig.create=false \
  -f /Users/jayden/workspace/github/owe/owe-devops/charts/postgres/values.local.yaml
```

## In-Cluster PostgreSQL

PostgreSQL is now managed as its own deployment unit.

- it lives in the dedicated `postgres` namespace
- its chart and values are isolated under [`charts/postgres`](/Users/jayden/workspace/github/owe/owe-devops/charts/postgres)
- Argo CD manages it through the parent app-of-apps at [`argocd/root-application.yaml`](/Users/jayden/workspace/github/owe/owe-devops/argocd/root-application.yaml)
- child applications live under [`argocd/apps`](/Users/jayden/workspace/github/owe/owe-devops/argocd/apps) and sync order places PostgreSQL before the application deployment
- the database uses the `pgvector/pgvector` image
- the chart creates a default application database named `app`
- the chart enables the `vector` extension during database initialization
- the OWE application is configured to use the `app` database by default
- the application connects across namespaces via `postgres-rw.postgres.svc.cluster.local`

## Argo CD Deployment

Apply the parent application to let Argo CD manage the child applications:

```bash
kubectl apply -n argocd -f /Users/jayden/workspace/github/owe/owe-devops/argocd/root-application.yaml
```

The charts manage their namespace resources directly. When creating secrets manually, make sure the target namespace already exists.

For local Helm installs into an existing namespace, disable namespace creation in the chart:

```bash
helm upgrade --install postgres /Users/jayden/workspace/github/owe/owe-devops/charts/postgres \
  -n postgres \
  --set namespaceConfig.create=false
```

## Envoy Gateway

Install Envoy Gateway with Helm using the tracked values file in this repository:

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.7.0 \
  -n envoy-gateway-system \
  --create-namespace \
  --skip-crds \
  -f /Users/jayden/workspace/github/owe/owe-devops/envoy-gateway/values.yaml
```

If Gateway API CRDs are not installed yet, apply them first:

```bash
helm template eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.7.0 \
  --set crds.gatewayAPI.enabled=true \
  --set crds.gatewayAPI.channel=standard \
  --set crds.envoyGateway.enabled=true \
  | kubectl apply --server-side -f -
```

Then wait for Envoy Gateway to be ready and check its external address:

```bash
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
kubectl get svc -n envoy-gateway-system
```

## Notes

- The values file currently uses placeholder hostnames and GHCR repositories and should be customized for your environment.
- This repo assumes a single staging environment for now.
- Auth0 can be enabled without committing values into Git by populating `owe-ui-secrets` and `owe-service-secrets` with the Auth0 keys listed above.
- When Auth0 is enabled, `APP_BASE_URL` in `owe-ui-secrets` must match the public UI origin exactly, and Auth0 application callback/logout URLs must include that same origin.

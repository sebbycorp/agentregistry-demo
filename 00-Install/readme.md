# 00-Install — Platform Prerequisites

Quick reference for the infrastructure commands used in Act 1 of the [master storyboard](../STORYBOARD.md).

## 1. Install arctl

```bash
curl -fsSL https://raw.githubusercontent.com/agentregistry-dev/agentregistry/main/scripts/get-arctl | bash
arctl version
arctl daemon start
```

## 2. Create Kubernetes Cluster

```bash
kind create cluster --name agentregistry
```

## 3. Install kagent

```bash
helm install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --namespace kagent \
  --create-namespace

export OPENAI_API_KEY="your-api-key-here"

helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --namespace kagent \
  --set kmcp.enabled=true \
  --set agents.enabled=false \
  --set providers.default=openAI \
  --set providers.openAI.apiKey=$OPENAI_API_KEY
```

## 4. Install agentgateway

```bash
kubectl apply --server-side --force-conflicts \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml

helm upgrade -i agentgateway-crds oci://cr.agentgateway.dev/charts/agentgateway-crds \
  --create-namespace --namespace agentgateway-system \
  --version v1.1.0 \
  --set controller.image.pullPolicy=Always

helm upgrade -i agentgateway oci://cr.agentgateway.dev/charts/agentgateway \
  --namespace agentgateway-system \
  --version v1.1.0 \
  --set controller.image.pullPolicy=Always \
  --set controller.extraEnv.KGW_ENABLE_GATEWAY_API_EXPERIMENTAL_FEATURES=true \
  --wait
```

## 5. Verify

```bash
kubectl get pods -n kagent
kubectl get pods -n agentgateway-system
```

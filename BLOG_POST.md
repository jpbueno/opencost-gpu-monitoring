# Monitoring NVIDIA GPU Costs in Kubernetes with OpenCost

## Introduction

NVIDIA GPU workloads in Kubernetes consume significant budgets, yet many organizations lack visibility into costs per workload, namespace, or team. DevOps engineers, platform administrators, and FinOps teams need accurate cost tracking to optimize NVIDIA GPU utilization, allocate expenses, and justify infrastructure investments.

This tutorial shows you how to deploy [OpenCost](https://www.opencost.io/) for NVIDIA GPU cost monitoring in any environment—cloud or on-premises, any NVIDIA GPU model (H100, A100, V100, T4, L4, L40), and any Kubernetes distribution. You learn to configure automatic cloud pricing or custom on-premises rates, and query costs through the OpenCost UI and REST API (Application Programming Interface).

## Prerequisites

Before starting this tutorial, ensure you have:

- Kubernetes cluster (v1.20+) with NVIDIA GPU nodes
- Prometheus metrics server installed and accessible
- Helm 3.x and kubectl command-line tools
- Cluster access with permissions to create namespaces and deploy applications
- NodePort, LoadBalancer, or Ingress capability for service exposure
- NVIDIA GPU workloads with resource requests defined (`nvidia.com/gpu`)

**Knowledge requirements:**
- Basic Kubernetes concepts (pods, namespaces, services)
- Familiarity with Helm chart deployments
- Understanding of Prometheus metrics collection
- Command-line proficiency with kubectl

## Deploying OpenCost for NVIDIA GPU Cost Tracking

Follow these steps to deploy and configure OpenCost in your Kubernetes cluster.

### Step 1: Locate Your Prometheus Endpoint

OpenCost requires Prometheus for metrics. Locate your Prometheus service:

```bash
# Find Prometheus service in your cluster
kubectl get svc --all-namespaces | grep prometheus

# Example output:
# monitoring    prometheus-operated    ClusterIP   10.96.0.10   9090/TCP
# prometheus    prometheus-server      ClusterIP   10.96.0.20   9090/TCP
```

Your Prometheus endpoint will be:
```
http://SERVICE-NAME.NAMESPACE.svc.cluster.local:PORT
```

**Common Prometheus endpoints:**
- kube-prometheus-stack: `http://prometheus-operated.monitoring:9090`
- Prometheus Operator: `http://prometheus-k8s.monitoring:9090`
- Standalone Prometheus: `http://prometheus-server.prometheus:9090`

Save this endpoint for use in Step 3.

### Step 2: Calculate NVIDIA GPU Pricing (On-Premises Only)

**Note:** Cloud deployments can skip this step. OpenCost automatically detects NVIDIA GPU pricing for AWS, GCP, Azure, and OCI.

**For on-premises deployments**, calculate NVIDIA GPU hourly cost using one of these methods:

**Method A: Hardware Amortization**
```
Total server cost ÷ Number of NVIDIA GPUs ÷ Amortization hours = NVIDIA GPU hourly rate

Example:
$200,000 server ÷ 8 NVIDIA GPUs ÷ (3 years × 365 days × 24 hours) = $0.95/NVIDIA GPU-hour
```

**Method B: Power + Overhead**
```
NVIDIA GPU TDP (kW) × Power cost ($/kWh) × Datacenter multiplier = NVIDIA GPU hourly rate

Example:
0.4 kW × $0.10/kWh × 2.5 = $0.10/NVIDIA GPU-hour
```

**GPU TDP (Thermal Design Power) Reference:**
- H100: 700W
- A100: 400W  
- V100: 300W
- A40: 300W
- T4: 70W
- L4: 72W
- L40: 300W

### Step 3: Install OpenCost Using Helm

Copy and save the following configuration files to your local machine. These files define the OpenCost service, Prometheus connection, and GPU pricing settings for your deployment.

Create the NodePort service configuration to expose OpenCost:

```yaml
# opencost-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: opencost-ui
  namespace: opencost
  labels:
    app: opencost
    app.kubernetes.io/name: opencost
spec:
  type: NodePort
  ports:
    - name: http-ui
      port: 9090
      targetPort: 9090
      nodePort: 30091
    - name: http-api
      port: 9003
      targetPort: 9003
      nodePort: 30031
  selector:
    app.kubernetes.io/name: opencost
```

**For cloud environments**, create this Helm values file. Update the Prometheus endpoint from Step 1:

```yaml
# opencost-values-cloud.yaml
opencost:
  exporter:
    defaultClusterId: my-gpu-cluster
    extraEnv:
      PROMETHEUS_SERVER_ENDPOINT: "http://YOUR-PROMETHEUS-SVC.NAMESPACE:PORT"
  ui:
    enabled: true

prometheus:
  internal:
    enabled: false
  external:
    enabled: true
    url: http://YOUR-PROMETHEUS-SVC.NAMESPACE:PORT
```

**For on-premises deployments**, create this Helm values file. Update the Prometheus endpoint and NVIDIA GPU pricing (line 36):

```yaml
# opencost-values-onprem.yaml
opencost:
  exporter:
    defaultClusterId: dgx-a100-cluster
    extraEnv:
      PROMETHEUS_SERVER_ENDPOINT: "http://YOUR-PROMETHEUS-SVC.NAMESPACE:PORT"
      CLOUD_PROVIDER_API_KEY: "AIzaSyD29bGxmHAVEOBYtgd8sYM2gM2ekfxQX4U"
      CLOUD_PROVIDER: "custom"
  ui:
    enabled: true
  
  customPricing:
    enabled: true
    configmapName: opencost-custom-pricing
    configPath: /tmp/custom-config
    createConfigmap: true
    provider: custom
    costModel:
      description: "On-premises NVIDIA GPU pricing"
      CPU: 0.031611      # vCPU-hour
      spotCPU: 0.031611
      RAM: 0.004237      # GB-hour
      spotRAM: 0.004237
      GPU: 0.95          # NVIDIA GPU-hour - CHANGE THIS for your NVIDIA GPU
      storage: 0.04      # GB-month
      zoneNetworkEgress: 0.01
      regionNetworkEgress: 0.01
      internetNetworkEgress: 0.12

prometheus:
  internal:
    enabled: false
  external:
    enabled: true
    url: http://YOUR-PROMETHEUS-SVC.NAMESPACE:PORT
```

Deploy OpenCost using the saved configuration files:

```bash
# Create namespace
kubectl create namespace opencost

# Apply NodePort service
kubectl apply -f opencost-nodeport.yaml

# Add Helm repository
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm repo update

# Install OpenCost
# For cloud environments:
helm install opencost opencost/opencost \
  --namespace opencost \
  -f opencost-values-cloud.yaml

# For on-premises environments:
helm install opencost opencost/opencost \
  --namespace opencost \
  -f opencost-values-onprem.yaml

# Verify deployment
kubectl get pods -n opencost
```

Wait for pods to reach `2/2 Running` status (typically 30-60 seconds).

**Verify Prometheus connection:**
```bash
kubectl logs -n opencost -l app.kubernetes.io/name=opencost -c opencost | grep -i prometheus

# Should see: "Success: retrieved the 'up' query against prometheus"
```

### Step 4: Access the OpenCost Interface

Choose the access method for your environment:

**NodePort (default, works anywhere):**
```bash
# Get any node's IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "UI: http://${NODE_IP}:30091"
echo "API: http://${NODE_IP}:30031"
```

**Port Forward (local development):**
```bash
kubectl port-forward -n opencost svc/opencost-ui 9090:9090 9003:9003
# Access: http://localhost:9090
```

**LoadBalancer (cloud with LB support):**
```bash
kubectl patch svc opencost-ui -n opencost -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc opencost-ui -n opencost  # Wait for EXTERNAL-IP
```

**Ingress (production):**
```bash
# Create ingress pointing to service: opencost-ui.opencost:9090
# Example hostname: opencost.your-domain.com
```

Figure 1 shows the OpenCost UI with cost allocation details.

![OpenCost UI Overview](images/opencost-ui-overview.png)

*Figure 1. OpenCost UI displaying cost allocation by namespace with detailed breakdowns for CPU, RAM, NVIDIA GPU, storage, and network resources.*

### Step 5: Query NVIDIA GPU Costs via API

Set your OpenCost API endpoint:
```bash
# For NodePort
OPENCOST_API="http://${NODE_IP}:30031"

# For Port Forward
OPENCOST_API="http://localhost:9003"

# For LoadBalancer
OPENCOST_API="http://YOUR-EXTERNAL-IP:9003"
```

**Health check:**
```bash
curl -s "${OPENCOST_API}/healthz"
```

**Get costs by namespace (24 hours):**
```bash
curl -s "${OPENCOST_API}/allocation?window=24h&aggregate=namespace" | jq '.'
```

**Filter NVIDIA GPU workloads only:**
```bash
curl -s "${OPENCOST_API}/allocation?window=24h" | \
  jq '.data[0] | to_entries[] | select(.value.gpuHours > 0) | {
    namespace: .key,
    gpuHours: .value.gpuHours,
    gpuCost: .value.gpuCost,
    totalCost: .value.totalCost
  }'
```

**Query parameters:**
- `window`: Time range (`1h`, `24h`, `7d`, `30d`, `today`, `week`, `month`)
- `aggregate`: Group by (`namespace`, `pod`, `controller`, `label`)
- `accumulate`: Return cumulative costs

**Example cost calculations:**

| Scenario | Calculation | Monthly Cost |
|----------|-------------|--------------|
| 4x H100 (24/7) | 4 × 720h × $5.00 | $14,400 |
| 8x A100 (24/7) | 8 × 720h × $1.50 | $8,640 |
| 16x V100 (8h/day) | 16 × 240h × $0.60 | $2,304 |
| 32x T4 (8h/day) | 32 × 240h × $0.30 | $2,304 |

### Step 6: Clean Up (Optional)

To uninstall OpenCost when no longer needed:

```bash
helm uninstall opencost -n opencost
kubectl delete namespace opencost
```

## Conclusion

In this tutorial, you deployed OpenCost for NVIDIA GPU cost monitoring in Kubernetes and configured it to track NVIDIA GPU spending across your cluster. You connected OpenCost to your existing Prometheus instance, configured pricing for your environment (automatic cloud detection or custom on-premises rates), and learned to query NVIDIA GPU costs through both the UI and REST API. You now understand that OpenCost allocates costs based on NVIDIA GPU resource requests rather than utilization, matching how Kubernetes schedules resources and how cloud providers bill for NVIDIA GPU instances. This request-based model ensures cost allocation reflects actual resource reservation, enabling accurate chargeback to teams and workloads.

For advanced features and API automation, see the [OpenCost Documentation](https://www.opencost.io/docs/). For NVIDIA GPU optimization strategies, see the [NVIDIA GPU Operator Documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/).

Author: JP Santana

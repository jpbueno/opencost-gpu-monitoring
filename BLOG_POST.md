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

**For on-premises deployments**, create this Helm values file. Update the Prometheus endpoint and NVIDIA GPU pricing (line 24):

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

Choose one of the following access methods based on your environment:

#### Option A: NodePort

**Note:** Requires network routes from your local computer to the Kubernetes nodes.

Access OpenCost using the NodePort service configured in Step 3:

```bash
# Get any node's IP address
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Display access URLs
echo "OpenCost UI: http://${NODE_IP}:30091"
echo "OpenCost API: http://${NODE_IP}:30031"
```

Open your browser and navigate to `http://NODE_IP:30091` to access the OpenCost UI.

#### Option B: Port Forward (Local Development)

For quick local testing without exposing services:

```bash
kubectl port-forward -n opencost svc/opencost-ui 9090:9090 9003:9003
# Access UI at: http://localhost:9090
```

#### Option C: Ingress

**Note:** Recommended approach for production deployments.

Create an Ingress resource to expose OpenCost with a custom hostname:

```yaml
# opencost-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: opencost-ingress
  namespace: opencost
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: opencost.example.com  # Replace with your domain
    http:
      paths:
      - path: /allocation
        pathType: Prefix
        backend:
          service:
            name: opencost
            port:
              number: 9003
      - path: /healthz
        pathType: Prefix
        backend:
          service:
            name: opencost
            port:
              number: 9003
      - path: /
        pathType: Prefix
        backend:
          service:
            name: opencost
            port:
              number: 9090
```

**Ingress Controller Configuration by Cloud Provider:**

The configuration above uses NGINX Ingress Controller. Adjust the `ingressClassName` and `annotations` based on your environment:

| Provider | Ingress Class | Annotations | Notes |
|----------|---------------|-------------|-------|
| **NGINX** | `nginx` | `nginx.ingress.kubernetes.io/use-regex: "true"` | Works on any cluster |
| **AWS (ALB)** | `alb` | `alb.ingress.kubernetes.io/scheme: internet-facing`<br>`alb.ingress.kubernetes.io/target-type: ip` | Requires [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) |
| **GCP (GCE)** | `gce` | `kubernetes.io/ingress.class: "gce"` | Built-in on GKE |
| **Azure** | `azure/application-gateway` | `appgw.ingress.kubernetes.io/use-private-ip: "false"` | Requires [Application Gateway Ingress Controller](https://azure.github.io/application-gateway-kubernetes-ingress/) |
| **OCI** | `oci-load-balancer` | `oci.oraclecloud.com/load-balancer-type: "lb"` | Built-in on OKE |

**Example for AWS ALB Ingress Controller:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: opencost-ingress
  namespace: opencost
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
spec:
  ingressClassName: alb
  rules:
  - host: opencost.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: opencost
            port:
              number: 9090
```

**To check your available Ingress classes:**

```bash
kubectl get ingressclass
```

Apply the Ingress configuration:

```bash
kubectl apply -f opencost-ingress.yaml

# Verify Ingress is created
kubectl get ingress -n opencost
```

Configure DNS to point `opencost.example.com` to your Ingress external IP. For production, create a DNS A record (Type: A, TTL: 300) in your domain settings. 

For local testing, add the IP to `/etc/hosts`:

```bash
# Get the Ingress external IP
INGRESS_IP=$(kubectl get ingress opencost-ingress -n opencost -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# For local testing: add to /etc/hosts
echo "$INGRESS_IP opencost.example.com" | sudo tee -a /etc/hosts
```

Open your browser to `http://opencost.example.com` to access the OpenCost UI.

Figure 1 shows the OpenCost UI with cost allocation details.

![OpenCost UI Overview](images/opencost-ui-overview.png)

*Figure 1. OpenCost UI displaying cost allocation by namespace with detailed breakdowns for CPU, RAM, NVIDIA GPU, storage, and network resources.*

### Step 5: Query NVIDIA GPU Costs via API

The OpenCost REST API enables cost automation, integration with FinOps tools, and programmatic reporting. Set your API endpoint based on your access method:

```bash
# NodePort (Option A)
OPENCOST_API="http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):30031"

# Port Forward (Option B)
OPENCOST_API="http://localhost:9003"

# Ingress (Option C)
OPENCOST_API="http://opencost.example.com"
```

Query GPU workload costs:

```bash
# Get GPU costs by namespace for the last 24 hours
curl -s "${OPENCOST_API}/allocation?window=24h&aggregate=namespace" | \
  jq '.data[0] | to_entries[] | select(.value.gpuHours > 0) | {
    namespace: .key,
    gpuHours: .value.gpuHours,
    gpuCost: .value.gpuCost,
    totalCost: .value.totalCost
  }'
```

**Query parameters:** Use `window` to set time range (`1h`, `24h`, `7d`, `30d`, `week`, `month`), `aggregate` to group costs by dimension (`namespace`, `pod`, `controller`, `label`), and `accumulate=true` for cumulative totals instead of time-windowed results.

## Comparing Cloud vs On-Premises GPU Costs

OpenCost enables organizations to compare GPU infrastructure costs between cloud and on-premises environments using identical workload consumption data. This comparison requires at least one deployed environment to establish baseline consumption patterns.

### Comparison Workflow

**Scenario:** You have GPU workloads running in the cloud and want to evaluate the cost of moving to on-premises infrastructure.

**Step 1: Track actual consumption in your current environment**

Deploy OpenCost in your existing cloud Kubernetes cluster and collect GPU consumption data for a representative period (1-2 weeks minimum):

```bash
# Get weekly GPU consumption by namespace
curl -s "${OPENCOST_API}/allocation?window=7d&aggregate=namespace" | \
  jq '.data[0] | to_entries[] | select(.value.gpuHours > 0) | {
    namespace: .key,
    gpuHours: .value.gpuHours,
    gpuCost: .value.gpuCost
  }'
```

**Example output:**
```json
{
  "namespace": "ml-training",
  "gpuHours": 1680,
  "gpuCost": 5040.00
}
{
  "namespace": "inference-prod",
  "gpuHours": 840,
  "gpuCost": 2520.00
}
```

**Step 2: Calculate on-premises equivalent costs**

Apply your on-premises GPU pricing (from `opencost-values-onprem.yaml`) to the same consumption patterns:

```bash
# On-premises GPU rate: $0.95/hour (example)
# ml-training: 1,680 GPU-hours × $0.95 = $1,596/week
# inference-prod: 840 GPU-hours × $0.95 = $798/week
# Total on-premises: $2,394/week vs $7,560/week cloud
```

**Step 3: Extrapolate to annual costs**

```bash
# Cloud annual cost: $7,560/week × 52 weeks = $393,120
# On-premises annual cost: $2,394/week × 52 weeks = $124,488
# Potential savings: $268,632/year (68% reduction)
```

**Step 4: Factor in total cost of ownership**

Remember to include additional on-premises costs not captured by OpenCost:
- Hardware acquisition and depreciation
- Datacenter space and cooling
- Network infrastructure
- Maintenance and support staff
- Power and utilities

### Key Insight

OpenCost's value for cost comparison is its **consistent allocation methodology** across environments. Because it measures GPU resource requests the same way in cloud and on-premises clusters, you can confidently apply different pricing models to identical workload patterns. This eliminates the guesswork in infrastructure migration decisions and provides quantified data for ROI calculations and cloud contract negotiations.

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

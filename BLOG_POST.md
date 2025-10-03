# Monitoring NVIDIA GPU Costs in Kubernetes with OpenCost and DCGM

GPU-accelerated workloads in Kubernetes can be expensive, but tracking their actual costs is challenging. Without proper cost visibility, teams struggle to optimize GPU utilization, allocate expenses accurately, and justify infrastructure investments. This tutorial teaches you how to implement comprehensive GPU cost monitoring using OpenCost and NVIDIA DCGM (Data Center GPU Manager).

This solution benefits DevOps engineers, platform administrators, and FinOps teams who need to track, allocate, and optimize GPU spending across their Kubernetes clusters. You'll learn how to set up automated cost tracking that works in any environment—cloud or on-premises—with any NVIDIA GPU (H100, A100, V100, T4, L4, etc.).

**What You'll Build:**
- [OpenCost](https://www.opencost.io/) with automatic cloud pricing OR custom on-premises pricing
- Web UI and REST API for comprehensive cost monitoring
- Integration with [DCGM](https://developer.nvidia.com/dcgm) for GPU telemetry and utilization metrics

**Pricing Approach:**
- **Cloud (AWS/GCP/Azure):** Automatic pricing via cloud provider APIs
- **On-Premises:** Custom pricing configuration required

**Supported Environments:**
- **Cloud:** AWS EKS, GCP GKE, Azure AKS, OCI OKE
- **On-Premises:** Bare metal, VMware, OpenStack
- **Distributions:** Any Kubernetes 1.20+

## Prerequisites

- [Kubernetes](https://kubernetes.io/) cluster with NVIDIA GPU nodes (1.20+)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html) installed (includes DCGM Exporter)
- [Helm 3.x](https://helm.sh/) and [kubectl](https://kubernetes.io/docs/reference/kubectl/) access
- NodePort access OR LoadBalancer support
- **Cloud only:** Cloud provider credentials (OpenCost auto-detects pricing)
- **On-premises only:** Calculated GPU pricing (see Step 2)

## Step 1: Set Up Project Directory

```bash
mkdir -p ~/opencost-gpu-monitoring && cd ~/opencost-gpu-monitoring
```

## Step 2: Determine Your Pricing Strategy

### Cloud Environments (AWS, GCP, Azure)

**You can skip custom pricing!** OpenCost automatically detects your cloud provider and retrieves GPU pricing via their APIs.

**What OpenCost will automatically detect:**
- AWS: EC2 instance pricing (p5, p4d, g5, g4dn instances)
- GCP: Compute Engine pricing (a2, a3, g2 instances)
- Azure: Virtual Machine pricing (NC-series, ND-series)

**No configuration needed** - proceed to Step 3 and use the cloud configuration.

### On-Premises Environments

**Custom pricing is required.** Calculate your GPU hourly cost:

**Quick Reference for Common GPUs:**

| GPU Type | Amortized (3yr) | Power-Based | Typical Range |
|----------|-----------------|-------------|---------------|
| H100 80GB | $3-5/hr | $0.17/hr | $3-5/hr |
| A100 80GB | $0.95-2/hr | $0.10/hr | $0.95-2/hr |
| V100 32GB | $0.40-0.80/hr | $0.08/hr | $0.40-0.80/hr |
| T4 16GB | $0.20-0.40/hr | $0.06/hr | $0.20-0.40/hr |

**Calculation Methods:**

**Option A: Amortized Hardware Cost**
```
Server cost: $200,000
GPUs per server: 8x A100
Amortization: 3 years
Hourly rate: $200k ÷ 8 ÷ (3 × 365 × 24) = $0.95/GPU-hour
```

**Option B: Power + Datacenter Overhead**
```
GPU TDP: 400W (A100), 700W (H100), 250W (T4)
Power cost: $0.10/kWh
Datacenter multiplier: 2.5x (cooling, space, networking)
Example (A100): 0.4kW × $0.10 × 2.5 = $0.10/GPU-hour
```

**This guide uses $0.95/GPU-hour for on-premises A100 as an example.**

## Step 3: Create OpenCost Configuration

Create the NodePort service configuration to expose the OpenCost UI and API.

```yaml
# opencost-config.yaml
---
# NodePort service for OpenCost UI/API access
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

Create the OpenCost namespace and apply the configuration:

```bash
# Create opencost namespace
kubectl create namespace opencost

# Apply NodePort service
kubectl apply -f opencost-config.yaml
```

Verify the service was created.

```bash
kubectl get svc -n opencost opencost-ui
```

## Step 4: Install OpenCost

### For Cloud Environments (AWS, GCP, Azure)

Create `opencost-values-cloud.yaml`:

```yaml
opencost:
  exporter:
    defaultClusterId: my-gpu-cluster
    extraEnv:
      PROMETHEUS_SERVER_ENDPOINT: "http://kube-prometheus-stack-1741-prometheus.monitoring.svc.cluster.local:9090"
      # Cloud provider auto-detection - no CLOUD_PROVIDER needed!
  ui:
    enabled: true
  metrics:
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: kube-prometheus-stack-1741

prometheus:
  internal:
    enabled: false
  external:
    enabled: true
    url: http://kube-prometheus-stack-1741-prometheus.monitoring.svc.cluster.local:9090
```

Install OpenCost using Helm with the following commands.

```bash
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm repo update

helm install opencost opencost/opencost \
  --namespace opencost \
  -f opencost-values-cloud.yaml

kubectl get pods -n opencost
```

### For On-Premises Environments

Create `opencost-values-onprem.yaml` with custom pricing:

```yaml
# opencost-values.yaml
opencost:
  exporter:
    defaultClusterId: dgx-a100-cluster
    extraEnv:
      PROMETHEUS_SERVER_ENDPOINT: "http://kube-prometheus-stack-1741-prometheus.monitoring.svc.cluster.local:9090"
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
      description: "Custom GPU pricing (adjust per your GPU type)"
      CPU: 0.031611      # vCPU-hour (adjust per cloud/on-prem)
      spotCPU: 0.031611
      RAM: 0.004237      # GB-hour (adjust per cloud/on-prem)
      spotRAM: 0.004237
      GPU: 0.95          # GPU-hour - CHANGE THIS based on your GPU!
                         # H100: 3-12/hr, A100: 1-4/hr, V100: 0.5-3/hr, T4: 0.2-0.5/hr
      storage: 0.04      # GB-month
      zoneNetworkEgress: 0.01
      regionNetworkEgress: 0.01
      internetNetworkEgress: 0.12
  metrics:
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: kube-prometheus-stack-1741  # Match your release

prometheus:
  internal:
    enabled: false
  external:
    enabled: true
    url: http://kube-prometheus-stack-1741-prometheus.monitoring.svc.cluster.local:9090
```

Install OpenCost with custom pricing using the following Helm commands.

```bash
# Add Helm repo
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm repo update

# Install with custom values
helm install opencost opencost/opencost \
  --namespace opencost \
  -f opencost-values.yaml

# Verify installation (wait ~30 seconds)
kubectl get pods -n opencost
kubectl get svc -n opencost

# Check logs
kubectl logs -n opencost -l app.kubernetes.io/name=opencost -c opencost --tail=20
```

## Step 5: Access OpenCost UI

Choose the method that fits your environment:

**NodePort (Default - On-Prem):**
```bash
kubectl get nodes -o wide
# Access: http://NODE-IP:30091 (UI) and http://NODE-IP:30031 (API)
```

**LoadBalancer (Cloud - AWS/GCP/Azure/OCI):**
```bash
kubectl patch svc opencost-ui -n opencost -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc opencost-ui -n opencost
# Access via EXTERNAL-IP shown above
```

**Port Forward (Local Testing):**
```bash
kubectl port-forward -n opencost svc/opencost-ui 9090:9090 9003:9003
# Access: http://localhost:9090
```

Figure 1 shows the OpenCost UI interface with cost allocation features.

![OpenCost UI Overview](images/opencost-ui-overview.png)
*Figure 1. OpenCost UI showing cost allocation by namespace, time windows, and detailed breakdowns for CPU, RAM, GPU, storage, and network resources.*

ALT text: Screenshot of the OpenCost web interface displaying a cost allocation table with multiple rows showing different Kubernetes namespaces. Each row contains columns for namespace name, CPU cost, memory cost, GPU cost, storage cost, network cost, and total cost values. The interface includes a time window selector at the top and filter options for viewing costs by namespace, pod, or label.

The UI provides:
- Cost allocation by namespace, pod, label
- Time windows (hourly, daily, weekly, monthly)
- Detailed breakdown (CPU, RAM, GPU, Storage, Network)
- CSV export for reports

## Step 6: Query Costs via API

```bash
# Cost by namespace (24h)
curl -s 'http://YOUR-NODE-IP:30031/allocation?window=24h&aggregate=namespace' | jq '.'

# GPU workloads only
curl -s 'http://YOUR-NODE-IP:30031/allocation?window=24h' | \
  jq '.data[0] | to_entries[] | select(.value.gpuHours > 0) | {
    namespace: .key,
    gpuHours: .value.gpuHours,
    gpuCost: .value.gpuCost,
    totalCost: .value.totalCost
  }'

# Health check
curl -s 'http://YOUR-NODE-IP:30031/healthz'
```

## Understanding Your Costs

**Example Cost Calculations:**
- 4x A100 (24/7): 4 × 720h × $0.95 = **$2,736/month**
- 8x H100 (training): 8 × 24h × $12.29 = **$2,360/day**
- 16x T4 (8hrs/day): 16 × 8h × $0.53 = **$68/day**

**Key API Metrics:** `gpuHours`, `gpuCost`, `gpuEfficiency`, `totalCost`, `gpuCount`

## Troubleshooting

### OpenCost UI Shows $0 GPU Costs

**Verify Custom Pricing:**
```bash
POD=$(kubectl get pod -n opencost -l app.kubernetes.io/name=opencost -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n opencost $POD -c opencost -- cat /tmp/custom-config/default.json
```

Should show `"GPU": "0.95"`

**Check GPU Workloads:**
```bash
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.spec.containers[].resources.limits."nvidia.com/gpu" != null) | 
  "\(.metadata.namespace)/\(.metadata.name)"'
```

### OpenCost Pod Not Starting

```bash
# Check logs
kubectl logs -n opencost -l app.kubernetes.io/name=opencost -c opencost

# Common issues:
# - Custom pricing not mounted correctly
# - DCGM metrics not available
# - Insufficient permissions
```

## Automation Scripts

### Monthly Cost Report

```bash
#!/bin/bash
# monthly-gpu-report.sh
MONTH="30d"
OUTPUT="gpu-cost-$(date +%Y-%m).json"

curl -s "http://YOUR-NODE-IP:30031/allocation?window=${MONTH}&aggregate=namespace" | \
  jq '.data[0] | to_entries[] | select(.value.gpuCost > 0) | {
    namespace: .key,
    gpuHours: .value.gpuHours,
    gpuCost: .value.gpuCost,
    efficiency: .value.gpuEfficiency
  }' > $OUTPUT

echo "Report saved to $OUTPUT"
```

### Cost Alert

```bash
#!/bin/bash
# gpu-cost-alert.sh
THRESHOLD=100
COST=$(curl -s "http://YOUR-NODE-IP:30031/allocation?window=1d" | \
  jq '[.data[0] | to_entries[] | .value.gpuCost] | add')

if (( $(echo "$COST > $THRESHOLD" | bc -l) )); then
  echo "WARNING: High GPU cost: \$${COST} in last 24h"
  # Add Slack/email notification here
fi
```

## Best Practices

**Cloud Environments:**
- OpenCost automatically uses accurate cloud pricing
- Enable Reserved Instances/Savings Plans for steady workloads
- Cross-reference with cloud cost management tools (AWS Cost Explorer, GCP Billing, Azure Cost Management)

**On-Premises:**
- Custom pricing required - update values as hardware costs change
- Include full TCO: power, cooling, space, maintenance
- Track hardware amortization and depreciation
- Consider hybrid cloud for cost comparison

**General:**
- Alert on cost thresholds and low efficiency (<30%)
- Right-size GPU requests, use time-slicing where possible
- Label nodes by GPU type for multi-SKU clusters
- Enable RBAC and TLS for production

## Summary

You've successfully implemented a comprehensive GPU cost monitoring solution that provides real-time visibility into Kubernetes GPU spending. To execute this successfully, keep these core considerations in mind:

**For Cloud Deployments:**
- Rely on OpenCost's automatic price detection for accuracy
- Verify cloud provider credentials are properly configured
- Cross-reference costs with your cloud billing dashboard

**For On-Premises Deployments:**
- Calculate accurate GPU pricing including full total cost of ownership (hardware amortization, power, cooling, maintenance)
- Update pricing values as hardware costs or electricity rates change
- Consider both amortized and operational cost models

**For All Environments:**
- Ensure DCGM Exporter is properly configured and exporting GPU metrics
- Set up cost alerts using the OpenCost API to catch unexpected spending spikes
- Review GPU efficiency metrics regularly in the OpenCost UI—low utilization indicates optimization opportunities
- Use namespaces and labels for accurate cost allocation across teams and projects

### Your Deployed System

You now have the following components running:

- **OpenCost UI:** http://YOUR-NODE-IP:30091 (cost allocation interface with GPU metrics)
- **OpenCost API:** http://YOUR-NODE-IP:30031 (automation and reporting endpoint)

## Cleanup (Optional)

If you need to uninstall or start fresh:

```bash
# Uninstall OpenCost
helm uninstall opencost -n opencost

# Delete namespace
kubectl delete namespace opencost

# Remove ServiceMonitor and NodePort service
kubectl delete -f opencost-config.yaml

# Optional: Remove files
cd ~ && rm -rf opencost-gpu-monitoring
```

## Get Started

Ready to monitor GPU costs in your Kubernetes cluster? Access the complete configuration files in the [opencost-gpu-monitoring GitHub repository](https://github.com/jpbueno/opencost-gpu-monitoring). The repository includes all the YAML files and detailed README to help you implement this solution in your environment.

Follow the step-by-step instructions in this tutorial to set up OpenCost with DCGM integration, and start tracking your GPU costs today using the OpenCost UI and API. If you have questions or want to share your experience, leave a comment below.

## Additional Resources

- [OpenCost Documentation](https://www.opencost.io/docs/)
- [OpenCost GitHub](https://github.com/opencost/opencost)
- [NVIDIA DCGM Exporter](https://github.com/NVIDIA/dcgm-exporter)

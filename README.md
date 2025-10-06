# OpenCost GPU Monitoring for Kubernetes

This directory contains all configuration files and documentation for setting up OpenCost to monitor GPU costs in Kubernetes clusters with NVIDIA GPUs (H100, A100, V100, T4, L4, L40, etc.) in both cloud and on-premises environments.

## Quick Start

```bash
# 1. Add Helm repository
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm repo update

# 2. Create namespace and NodePort service
kubectl create namespace opencost
kubectl apply -f opencost-nodeport.yaml

# 3. Install OpenCost
# For cloud environments (AWS, GCP, Azure, OCI):
helm install opencost opencost/opencost --namespace opencost -f opencost-values-cloud.yaml

# For on-premises environments with custom GPU pricing:
helm install opencost opencost/opencost --namespace opencost -f opencost-values-onprem.yaml

# 4. Access OpenCost UI
kubectl port-forward -n opencost svc/opencost-ui 9090:9090
# Visit http://localhost:9090
```

**Important:** Update the Prometheus endpoint in your values file before installation. See the "Files in This Directory" section for configuration details.

## Files in This Directory

| File | Description |
|------|-------------|
| `opencost-values-onprem.yaml` | Helm values for OpenCost with custom GPU pricing for on-premises deployments |
| `opencost-values-cloud.yaml` | Helm values for OpenCost with automatic cloud GPU pricing detection |
| `opencost-nodeport.yaml` | NodePort service configuration for OpenCost UI and API access |
| `opencost-config.yaml` | Custom pricing configuration example |
| `BLOG_POST.md` | Complete installation guide and documentation |
| `README.md` | This file |

## Custom GPU Pricing

**For cloud environments:** OpenCost automatically detects GPU pricing for AWS, GCP, Azure, and OCI.

**For on-premises environments:** Calculate custom GPU pricing based on your hardware costs:

### Pricing Calculation Methods

**Method A: Hardware Amortization**
```
Total server cost ÷ Number of GPUs ÷ Amortization hours = GPU hourly rate

Example:
$200,000 server ÷ 8 GPUs ÷ (3 years × 365 days × 24 hours) = $0.95/GPU-hour
```

**Method B: Power + Overhead**
```
GPU TDP (kW) × Power cost ($/kWh) × Datacenter multiplier = GPU hourly rate

Example:
0.4 kW × $0.10/kWh × 2.5 = $0.10/GPU-hour
```

**GPU TDP (Thermal Design Power) Reference:**
- H100: 700W
- A100: 400W  
- V100: 300W
- A40: 300W
- T4: 70W
- L4: 72W
- L40: 300W

**Example pricing configuration:**
- **GPU:** $0.95/hour (adjust for your GPU model)
- **CPU:** $0.031611/vCPU-hour
- **RAM:** $0.004237/GB-hour
- **Storage:** $0.04/GB-month

## Prerequisites

Before deploying OpenCost, ensure you have:

- Kubernetes cluster (v1.20+) with NVIDIA GPU nodes
- Prometheus metrics server installed and accessible
- Helm 3.x and kubectl command-line tools
- Cluster access with permissions to create namespaces
- NVIDIA GPU workloads with resource requests defined (`nvidia.com/gpu`)
- DCGM Exporter deployed (optional, for detailed GPU telemetry)

## Accessing OpenCost

Choose the access method for your environment:

### NodePort (default, works anywhere)
```bash
# Get any node's IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "UI: http://${NODE_IP}:30091"
echo "API: http://${NODE_IP}:30031"
```

### Port Forward (local development)
```bash
kubectl port-forward -n opencost svc/opencost-ui 9090:9090 9003:9003
# Access: http://localhost:9090
```

### LoadBalancer (cloud with LB support)
```bash
kubectl patch svc opencost-ui -n opencost -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc opencost-ui -n opencost  # Wait for EXTERNAL-IP
```

### From Within Cluster
```bash
# UI: http://opencost.opencost.svc.cluster.local:9090
# API: http://opencost.opencost.svc.cluster.local:9003
```

## API Usage Examples

Set your OpenCost API endpoint based on your access method:
```bash
# For NodePort
OPENCOST_API="http://${NODE_IP}:30031"

# For Port Forward
OPENCOST_API="http://localhost:9003"

# For LoadBalancer
OPENCOST_API="http://YOUR-EXTERNAL-IP:9003"

# For Within Cluster
OPENCOST_API="http://opencost.opencost.svc.cluster.local:9003"
```

### Health check
```bash
curl -s "${OPENCOST_API}/healthz"
```

### Get cost allocation for last 24 hours
```bash
curl -s "${OPENCOST_API}/allocation?window=24h&aggregate=namespace" | jq '.'
```

### Filter GPU workloads only
```bash
curl -s "${OPENCOST_API}/allocation?window=24h" | \
  jq '.data[0] | to_entries[] | select(.value.gpuHours > 0) | {
    namespace: .key,
    gpuHours: .value.gpuHours,
    gpuCost: .value.gpuCost,
    totalCost: .value.totalCost
  }'
```

### Get weekly cost summary
```bash
curl -s "${OPENCOST_API}/allocation?window=7d&aggregate=namespace" | \
  jq '.data[0] | to_entries[] | {
    namespace: .key,
    totalCost: .value.totalCost,
    gpuCost: .value.gpuCost
  }'
```

**Query parameters:**
- `window`: Time range (`1h`, `24h`, `7d`, `30d`, `today`, `week`, `month`)
- `aggregate`: Group by (`namespace`, `pod`, `controller`, `label`)
- `accumulate`: Return cumulative costs

## Example Cost Calculations

Based on typical GPU pricing scenarios:

| Scenario | Calculation | Monthly Cost |
|----------|-------------|--------------|
| 4x H100 (24/7) | 4 × 720h × $5.00 | $14,400 |
| 8x A100 (24/7) | 8 × 720h × $1.50 | $8,640 |
| 16x V100 (8h/day) | 16 × 240h × $0.60 | $2,304 |
| 32x T4 (8h/day) | 32 × 240h × $0.30 | $2,304 |

*Note: These are example calculations. Actual costs depend on your GPU pricing configuration (cloud or on-premises).*

## Grafana Dashboards

1. **Import OpenCost Dashboard:**
   - Dashboard ID: 15077
   - Data Source: Prometheus

2. **Key OpenCost Metrics:**
   - `opencost_gpu_cost` - GPU cost allocation
   - `opencost_allocation_cpu_cost` - CPU cost allocation
   - `opencost_allocation_memory_cost` - Memory cost allocation
   - `opencost_allocation_total_cost` - Total cost allocation

3. **Optional GPU Telemetry (requires DCGM Exporter):**
   - `DCGM_FI_DEV_GPU_UTIL` - GPU utilization percentage
   - `DCGM_FI_DEV_FB_USED` - GPU memory usage in MB
   - `DCGM_FI_DEV_POWER_USAGE` - GPU power consumption in watts

## Updating Configuration

### Change GPU Pricing (on-premises only)
```bash
# Edit the on-premises values file
vim opencost-values-onprem.yaml

# Update GPU price in costModel.GPU (line 163)
# Then upgrade the release
helm upgrade opencost opencost/opencost --namespace opencost -f opencost-values-onprem.yaml
```

### Update Prometheus Endpoint
```bash
# Edit your values file (cloud or on-prem)
vim opencost-values-cloud.yaml  # or opencost-values-onprem.yaml

# Update PROMETHEUS_SERVER_ENDPOINT
# Then upgrade the release
helm upgrade opencost opencost/opencost --namespace opencost -f opencost-values-cloud.yaml
```

### Restart OpenCost
```bash
kubectl rollout restart deployment -n opencost opencost
```

## Troubleshooting

### Check OpenCost Logs
```bash
kubectl logs -n opencost -l app.kubernetes.io/name=opencost -c opencost --tail=50
```

### Verify Prometheus Connection
```bash
kubectl logs -n opencost -l app.kubernetes.io/name=opencost -c opencost | grep -i prometheus

# Should see: "Success: retrieved the 'up' query against prometheus"
```

### Verify Custom Pricing (on-premises)
```bash
POD=$(kubectl get pod -n opencost -l app.kubernetes.io/name=opencost -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n opencost $POD -c opencost -- cat /tmp/custom-config/default.json
```

### Check GPU Metrics
```bash
# Verify GPU operator pods are running
kubectl get pods -n nvidia-gpu-operator

# Check if Prometheus has GPU metrics (requires DCGM Exporter)
# Replace with your Prometheus service endpoint
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090 &
curl -s 'http://localhost:9090/api/v1/query?query=DCGM_FI_DEV_GPU_UTIL'
```

### Verify GPU Cost Allocation
```bash
# Check if workloads show GPU costs
curl -s "${OPENCOST_API}/allocation?window=24h" | \
  jq '.data[0] | to_entries[] | select(.value.gpuHours > 0)'
```

## Architecture

```
┌─────────────────────────────┐
│     GPU Workloads           │
│  (Training, Inference, ML)  │
└──────────┬──────────────────┘
           │ GPU Resource Requests (nvidia.com/gpu)
           ▼
┌─────────────────────┐     ┌──────────────┐
│ NVIDIA GPU Operator │────▶│  Prometheus  │
│ & DCGM Exporter     │     │   (Metrics)  │
│ (Optional)          │     └──────┬───────┘
└─────────────────────┘            │
                                   ▼
                            ┌──────────────┐
                            │   OpenCost   │
                            │ (Cost Calc)  │
                            └──────┬───────┘
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
             ┌─────────────┐             ┌──────────────┐
             │ OpenCost UI │             │   Grafana    │
             │   & API     │             │ (Optional)   │
             └─────────────┘             └──────────────┘
```

## Next Steps

1. **Wait for Metrics:** Allow 5-10 minutes for metrics to populate in OpenCost
2. **Deploy GPU Workloads:** Ensure workloads have GPU resource requests (`nvidia.com/gpu`)
3. **Verify GPU Costs:** Check the UI or API to confirm GPU cost allocation
4. **Create Dashboards:** Import Grafana dashboards (Dashboard ID: 15077) for visualization
5. **Set Up Alerts:** Configure Prometheus alerts for high GPU costs or utilization
6. **Cost Reports:** Use the API to generate automated daily/weekly/monthly reports
7. **Optimize Usage:** Identify idle or underutilized GPU workloads and optimize

## Support

For detailed documentation, see `BLOG_POST.md` in this directory.

For OpenCost issues:
- GitHub: https://github.com/opencost/opencost
- Docs: https://www.opencost.io/docs/

For DCGM issues:
- GitHub: https://github.com/NVIDIA/dcgm-exporter

---

Author: JP Santana

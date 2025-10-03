# OpenCost GPU Monitoring for DGX A100 Cluster

This directory contains all configuration files and documentation for setting up OpenCost to monitor GPU costs in an on-premises Kubernetes cluster with NVIDIA DGX A100 nodes.

## Quick Start

```bash
# 1. Create ServiceMonitor for DCGM metrics
kubectl apply -f dcgm-servicemonitor.yaml

# 2. Install OpenCost with custom GPU pricing
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm repo update
kubectl create namespace opencost
helm install opencost opencost/opencost --namespace opencost -f opencost-values.yaml

# 3. Access OpenCost UI
kubectl port-forward -n opencost svc/opencost 9090:9090
# Visit http://localhost:9090
```

## Files in This Directory

| File | Description |
|------|-------------|
| `opencost-values.yaml` | Helm values for OpenCost with custom A100 GPU pricing ($0.95/hour) |
| `dcgm-servicemonitor.yaml` | Prometheus ServiceMonitor to scrape DCGM GPU metrics |
| `opencost-custom-pricing.json` | Custom pricing configuration (backup) |
| `BLOG_POST.md` | Complete installation guide and documentation |
| `README.md` | This file |

## Custom GPU Pricing

The configuration uses custom pricing based on amortized hardware costs:

- **GPU (A100 80GB):** $0.95/hour
- **CPU:** $0.031611/vCPU-hour
- **RAM:** $0.004237/GB-hour
- **Storage:** $0.04/GB-month

### Pricing Calculation

```
DGX A100 System Cost: ~$200,000
Number of GPUs: 8x A100 80GB
Amortization Period: 3 years
GPU Cost/Hour: $200,000 / 8 / (3 × 365 × 24) = $0.95/hour
```

## Current Cluster Status

- **Nodes:** 2 (dgx-003 with 8 GPUs, tme-vr2l135-2 with 4 GPUs)
- **Total GPUs:** 12x NVIDIA A100 80GB (81920 MB)
- **DCGM Exporter:** Running on both nodes
- **Prometheus:** kube-prometheus-stack-1741 (monitoring namespace)
- **Grafana:** Available on port 32222

## Accessing OpenCost

### Local Port Forward
```bash
kubectl port-forward -n opencost svc/opencost 9090:9090 9003:9003
```
- UI: http://localhost:9090
- API: http://localhost:9003

### From Within Cluster
```bash
# UI
http://opencost.opencost.svc.cluster.local:9090

# API
http://opencost.opencost.svc.cluster.local:9003
```

## API Usage Examples

### Get cost allocation for last 24 hours
```bash
curl -s 'http://opencost.opencost.svc.cluster.local:9003/allocation?window=24h&aggregate=namespace' | jq '.'
```

### Show only GPU workloads
```bash
curl -s 'http://opencost.opencost.svc.cluster.local:9003/allocation?window=24h' | \
  jq '.data[0] | to_entries[] | select(.value.gpuHours > 0)'
```

### Get weekly cost summary
```bash
curl -s 'http://opencost.opencost.svc.cluster.local:9003/allocation?window=7d&aggregate=namespace' | \
  jq '.data[0] | to_entries[] | {namespace: .key, totalCost: .value.totalCost, gpuCost: .value.gpuCost}'
```

## Grafana Dashboards

1. **Import OpenCost Dashboard:**
   - Dashboard ID: 15077
   - Data Source: Prometheus

2. **Key Metrics to Monitor:**
   - `opencost_gpu_cost` - GPU cost allocation
   - `DCGM_FI_DEV_GPU_UTIL` - GPU utilization
   - `DCGM_FI_DEV_FB_USED` - GPU memory usage
   - `DCGM_FI_DEV_POWER_USAGE` - GPU power consumption

## Updating Configuration

### Change GPU Pricing
```bash
# Edit the values file
vim opencost-values.yaml

# Update GPU price in costModel.GPU
# Then upgrade the release
helm upgrade opencost opencost/opencost --namespace opencost -f opencost-values.yaml
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

### Verify Custom Pricing
```bash
POD=$(kubectl get pod -n opencost -l app.kubernetes.io/name=opencost -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n opencost $POD -c opencost -- cat /tmp/custom-config/default.json
```

### Check DCGM Metrics
```bash
# Verify DCGM pods are running
kubectl get pods -n nvidia-gpu-operator | grep dcgm

# Check if Prometheus has DCGM metrics
kubectl port-forward -n monitoring svc/kube-prometheus-stack-1741-prometheus 9090:9090 &
curl -s 'http://localhost:9090/api/v1/query?query=DCGM_FI_DEV_GPU_UTIL'
```

## Architecture

```
┌─────────────────────┐
│   GPU Workloads     │
│  (NIMs, Training)   │
└──────────┬──────────┘
           │ GPU Resource Requests
           ▼
┌─────────────────────┐     ┌──────────────┐
│  DCGM Exporter      │────▶│  Prometheus  │
│  (GPU Telemetry)    │     │  (Metrics)   │
└─────────────────────┘     └──────┬───────┘
                                   │
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
             └─────────────┘             └──────────────┘
```

## Next Steps

1. **Wait for Metrics:** Allow 5-10 minutes for DCGM metrics to populate in Prometheus
2. **Verify GPU Costs:** Check if GPU workloads show cost allocations
3. **Create Dashboards:** Import Grafana dashboards for visualization
4. **Set Up Alerts:** Configure alerts for high GPU costs
5. **Export Reports:** Use the API to generate monthly cost reports

## Support

For detailed documentation, see `BLOG_POST.md` in this directory.

For OpenCost issues:
- GitHub: https://github.com/opencost/opencost
- Docs: https://www.opencost.io/docs/

For DCGM issues:
- GitHub: https://github.com/NVIDIA/dcgm-exporter

---

Author: JP Santana

# GPU Cost Dashboard Setup Guide

This guide shows you how to access beautiful dashboards for GPU cost monitoring.

## Option 1: OpenCost Built-in UI (Recommended - Easiest)

OpenCost comes with a built-in web UI that provides excellent cost visualization out of the box.

### Access Methods

#### Method A: NodePort (Persistent Access)

The OpenCost UI has been exposed via NodePort:

```bash
# Access via any node IP on port 30091
http://10.185.124.93:30091

# Or use your node hostnames:
http://dgx-003:30091
http://tme-vr2l135-2:30091
```

**Features in OpenCost UI:**
- 📊 Cost allocation by namespace, deployment, pod, label
- 📈 Historical cost trends
- 💰 Cost breakdowns (CPU, RAM, GPU, storage, network)
- ⏱️ Time window selection (hourly, daily, weekly, monthly)
- 🔍 Filtering and grouping capabilities
- 📥 Export to CSV

#### Method B: Port Forward (Temporary Access)

For quick local access:

```bash
kubectl port-forward -n opencost svc/opencost 9090:9090

# Then visit: http://localhost:9090
```

#### Method C: LoadBalancer (If you have MetalLB)

```bash
kubectl patch svc opencost -n opencost -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc opencost -n opencost  # Get the external IP
```

## Option 2: Custom Grafana Dashboard (Advanced Visualization)

For advanced users who want deep GPU metrics integration with Grafana.

### Step 1: Access Grafana

Your Grafana is available at:
```bash
# Based on your cluster setup
http://10.185.124.93:32222
# Or
http://dgx-003:32222
```

### Step 2: Import the Custom GPU Cost Dashboard

1. **Login to Grafana** (get password if needed):
   ```bash
   kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
   ```

2. **Import Dashboard:**
   - Go to **Dashboards** → **Import**
   - Click **Upload JSON file**
   - Select: `~/opencost-gpu-monitoring/grafana-gpu-cost-dashboard.json`
   - Or copy/paste the JSON content
   - Select your **Prometheus** data source
   - Click **Import**

### Dashboard Features

The custom Grafana dashboard includes:

#### Top Row - Key Metrics (Stats)
1. **Total GPU Cost (Last 24h)** - Dollar amount spent on GPUs
2. **Total A100 GPUs** - Count of all GPUs in cluster
3. **Average GPU Utilization** - Cluster-wide utilization %
4. **A100 GPU Price per Hour** - Your custom pricing

#### Middle Section - Time Series
5. **GPU Utilization by Device** - Per-GPU utilization over time
6. **GPU Memory Usage** - Memory consumption per GPU (0-80GB)
7. **GPU Allocation by Namespace** - Which teams/projects are using GPUs
8. **Estimated GPU Cost by Namespace** - Cost breakdown by namespace (pie chart)

#### Bottom Section - Details
9. **GPU Workloads Table** - List of all pods using GPUs with:
   - Namespace and Pod name
   - Hourly cost
   - GPU utilization percentage
   - Sortable and filterable

10. **GPU Power Consumption** - Watts used per GPU
11. **GPU Temperature** - Temperature monitoring

### Dashboard Screenshots Guide

When using the dashboards, look for:

**In OpenCost UI:**
- Navigate to "Allocations" for cost breakdowns
- Use the time picker (top right) to select different periods
- Click "Aggregate By" to group costs by different dimensions
- Use filters to drill down into specific namespaces/workloads

**In Grafana:**
- Use the time range picker (top right)
- Hover over graphs for detailed values
- Click legend items to show/hide specific series
- Use the "Prometheus" dropdown if you have multiple data sources

## Option 3: OpenCost API + Custom Visualizations

For programmatic access or custom dashboards:

### API Endpoints

The API is available at:
```bash
# Via NodePort
http://10.185.124.93:30031

# From within cluster
http://opencost.opencost.svc.cluster.local:9003
```

### Example Queries

#### Get cost allocation for last 24 hours by namespace
```bash
curl -s 'http://10.185.124.93:30031/allocation?window=24h&aggregate=namespace' | jq '.'
```

#### Get GPU-only costs
```bash
curl -s 'http://10.185.124.93:30031/allocation?window=7d' | \
  jq '.data[0] | to_entries[] | select(.value.gpuCost > 0) | {
    name: .key,
    gpuHours: .value.gpuHours,
    gpuCost: .value.gpuCost,
    utilization: .value.gpuEfficiency
  }'
```

#### Monthly cost report by namespace
```bash
curl -s 'http://10.185.124.93:30031/allocation?window=30d&aggregate=namespace' | \
  jq '.data[0] | to_entries[] | {
    namespace: .key,
    totalCost: .value.totalCost,
    gpuCost: .value.gpuCost,
    cpuCost: .value.cpuCost,
    ramCost: .value.ramCost
  }'
```

## Quick Verification

### Check Everything is Working

```bash
# 1. Verify OpenCost pod is running
kubectl get pods -n opencost

# 2. Check DCGM metrics are being collected
curl -s 'http://10.185.124.93:30031/healthz'

# 3. Test a simple cost query
curl -s 'http://10.185.124.93:30031/allocation?window=1h' | jq '.code'
# Should return: 200

# 4. Get current GPU workloads
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.spec.containers[].resources.limits."nvidia.com/gpu" != null) | 
  "\(.metadata.namespace)/\(.metadata.name)"'
```

## Understanding the Dashboards

### Cost Metrics Explained

| Metric | Description | How It's Calculated |
|--------|-------------|-------------------|
| **GPU Hours** | Total GPU time consumed | Number of GPUs × Hours running |
| **GPU Cost** | Total cost for GPU usage | GPU Hours × $0.95/hour |
| **GPU Efficiency** | How well GPUs are utilized | Actual utilization / Requested capacity |
| **Total Cost** | Combined infrastructure cost | CPU + RAM + GPU + Storage + Network |

### Example Cost Scenarios

#### Scenario 1: NIM Service (Always Running)
```
Service: embedding-nim
GPUs: 1x A100
Runtime: 24 hours
GPU Cost: 1 × 24 × $0.95 = $22.80/day
Monthly: $22.80 × 30 = $684/month
```

#### Scenario 2: Training Job (Batch)
```
Service: model-training
GPUs: 8x A100
Runtime: 6 hours
GPU Cost: 8 × 6 × $0.95 = $45.60/job
```

#### Scenario 3: Inference Service (Variable Load)
```
Service: inference-api
GPUs: 2x A100
Runtime: 720 hours/month
Utilization: 40% average
GPU Cost: 2 × 720 × $0.95 = $1,368/month
Effective Cost (if billed by utilization): $547.20/month
```

## Dashboard Maintenance

### Refreshing Data

Both dashboards refresh automatically:
- **OpenCost UI**: Real-time updates
- **Grafana**: 30-second refresh (configurable)

### Extending the Dashboards

#### Add Custom Panels in Grafana

Common additions:
1. **Cost per Team** - Group by label
2. **Daily Cost Trends** - 30-day rolling window
3. **Cost Anomaly Detection** - Unexpected spikes
4. **Budget Alerts** - Threshold notifications

#### Example: Add Monthly Budget Panel

```json
{
  "expr": "sum(container_gpu_allocation * 0.95 * 730)",
  "title": "Projected Monthly GPU Cost"
}
```

## Troubleshooting

### Dashboard Shows No Data

**Check 1: DCGM Metrics**
```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-1741-prometheus 9090:9090 &

# Query for DCGM metrics
curl -s 'http://localhost:9090/api/v1/query?query=DCGM_FI_DEV_GPU_UTIL' | jq '.data.result | length'
```

If result is `0`, DCGM metrics aren't flowing. Wait 5-10 minutes after applying the ServiceMonitor.

**Check 2: OpenCost API**
```bash
curl -s 'http://10.185.124.93:30031/healthz'
# Should return: "OK"
```

**Check 3: GPU Workloads Exist**
```bash
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.spec.containers[].resources.limits."nvidia.com/gpu" != null) | 
  "\(.metadata.namespace)/\(.metadata.name)"'
```

If no workloads are requesting GPUs, costs will be $0.

### OpenCost UI Not Accessible

```bash
# Check service
kubectl get svc -n opencost opencost-ui

# Check pod logs
kubectl logs -n opencost -l app.kubernetes.io/name=opencost -c opencost-ui

# Verify NodePort
kubectl get svc opencost-ui -n opencost -o yaml | grep nodePort
```

### Grafana Dashboard Shows Errors

**Common Issues:**

1. **"No data"** - Check Prometheus data source connection
2. **"N/A"** - Metrics not available yet, wait a few minutes
3. **Query errors** - Adjust the Prometheus data source UID in the JSON

**Fix Prometheus Data Source:**
1. Go to **Configuration** → **Data Sources**
2. Click your **Prometheus** data source
3. Copy the **UID** (e.g., `prometheus-uid-12345`)
4. Edit dashboard JSON, replace `${DS_PROMETHEUS}` references

## Best Practices

### For Cost Monitoring

1. **Set Time Windows Appropriately:**
   - Real-time monitoring: 1-6 hours
   - Daily reviews: 24 hours
   - Weekly reports: 7 days
   - Monthly billing: 30 days

2. **Use Labels for Better Tracking:**
   ```yaml
   metadata:
     labels:
       team: ml-team
       project: recommendation-engine
       cost-center: engineering
   ```

3. **Set Up Alerts:**
   - Daily cost exceeds threshold
   - GPU utilization < 20% (waste)
   - Unexpected namespace costs

4. **Regular Reviews:**
   - Daily: Check for anomalies
   - Weekly: Review top costs
   - Monthly: Generate reports for finance

### For Performance

1. **Monitor GPU Efficiency:**
   - Target: >60% utilization for production workloads
   - <30% may indicate oversized requests

2. **Track Temperature:**
   - Normal: 40-80°C
   - Warning: >80°C
   - Action needed: >85°C

3. **Memory Usage:**
   - A100 80GB: Track `DCGM_FI_DEV_FB_USED`
   - Optimize if consistently <40% or >95%

## Exporting Data

### From OpenCost UI

1. Select time window and aggregation
2. Click **Export CSV** button
3. Open in Excel/Google Sheets for analysis

### From Grafana

1. Select panel
2. Click **...** (more options)
3. Choose **Inspect** → **Data** → **Download CSV**

### Via API (Automated Reports)

```bash
# Monthly report script
#!/bin/bash
MONTH=$(date +%Y-%m)
curl -s "http://opencost.opencost.svc.cluster.local:9003/allocation?window=30d&aggregate=namespace" \
  | jq '.data[0] | to_entries[] | {
      namespace: .key,
      total_cost: .value.totalCost,
      gpu_cost: .value.gpuCost,
      gpu_hours: .value.gpuHours
    }' > "gpu-cost-report-${MONTH}.json"
```

## Next Steps

1. ✅ Access OpenCost UI at http://10.185.124.93:30091
2. ✅ Import Grafana dashboard from `grafana-gpu-cost-dashboard.json`
3. ✅ Set up alerts for cost thresholds
4. ✅ Share dashboard URLs with your team
5. ✅ Schedule weekly cost reviews

## Access URLs Summary

| Service | URL | Purpose |
|---------|-----|---------|
| **OpenCost UI** | http://10.185.124.93:30091 | Cost visualization and reporting |
| **OpenCost API** | http://10.185.124.93:30031 | Programmatic cost queries |
| **Grafana** | http://10.185.124.93:32222 | Advanced metrics and dashboards |
| **Prometheus** | http://10.185.124.93:30090 | Raw metrics queries |

## Support

- **OpenCost Docs**: https://www.opencost.io/docs/
- **Grafana Docs**: https://grafana.com/docs/
- **This Setup**: See `BLOG_POST.md` for detailed setup information

---

**Dashboard Created:** October 2, 2025  
**Cluster:** DGX A100 (12x GPUs)  
**Pricing:** $0.95 per GPU-hour



# 🚀 Quick Start - GPU Cost Dashboards

## ✅ Setup Complete!

OpenCost is now installed and configured with custom A100 GPU pricing ($0.95/hour).

## 🎯 Access Your Dashboards

### Option 1: OpenCost UI (Built-in - Easiest!) 

**Access now at:**
```
http://10.185.124.93:30091
```

Or from any node:
```
http://dgx-003:30091
http://tme-vr2l135-2:30091
```

**What you'll see:**
- 💰 Real-time cost allocation by namespace, pod, and container
- 📊 Cost breakdowns (CPU, RAM, GPU, Storage, Network)
- 📈 Historical cost trends
- 🔍 Filtering and grouping options
- 📥 CSV export for reports

### Option 2: Custom Grafana Dashboard

**Import the custom dashboard:**

1. **Access Grafana:**
   ```
   http://10.185.124.93:32222
   ```

2. **Import Dashboard:**
   - Go to **Dashboards** → **Import**
   - Upload file: `~/opencost-gpu-monitoring/grafana-gpu-cost-dashboard.json`
   - Select your Prometheus data source
   - Click **Import**

**Dashboard includes:**
- Total GPU cost stats
- GPU utilization by device
- GPU memory usage (A100 80GB)
- Cost breakdown by namespace
- Detailed workload table with costs
- Power consumption and temperature

### Option 3: Direct API Access

**Query costs programmatically:**

```bash
# Get costs for last 24 hours by namespace
curl -s 'http://10.185.124.93:30031/allocation?window=24h&aggregate=namespace' | jq '.'

# Get only GPU workloads
curl -s 'http://10.185.124.93:30031/allocation?window=24h' | \
  jq '.data[0] | to_entries[] | select(.value.gpuHours > 0)'
```

## 📊 Current Cluster Info

- **Total GPUs:** 12x NVIDIA A100 80GB
  - dgx-003: 8 GPUs
  - tme-vr2l135-2: 4 GPUs
- **GPU Pricing:** $0.95 per GPU-hour
- **DCGM Metrics:** ✅ Enabled
- **OpenCost:** ✅ Running
- **Custom Pricing:** ✅ Configured

## 🔍 Quick Verification

```bash
# Check OpenCost is running
kubectl get pods -n opencost

# Test the UI is accessible
curl -s http://10.185.124.93:30091 | head -5

# Test the API
curl -s http://10.185.124.93:30031/healthz

# See current GPU workloads
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.spec.containers[].resources.limits."nvidia.com/gpu" != null) | 
  "\(.metadata.namespace)/\(.metadata.name)"'
```

## 📁 All Files Created

```
~/opencost-gpu-monitoring/
├── BLOG_POST.md                      # Complete tutorial (5000+ words)
├── DASHBOARD_SETUP.md                # Detailed dashboard guide
├── QUICK_START.md                    # This file
├── README.md                         # Quick reference
├── opencost-values.yaml              # Helm configuration
├── opencost-nodeport.yaml            # NodePort service config
├── dcgm-servicemonitor.yaml          # Prometheus DCGM scraper
├── grafana-gpu-cost-dashboard.json   # Custom Grafana dashboard
└── opencost-custom-pricing.json      # Pricing backup
```

## 💡 What to Do Next

1. **Open the OpenCost UI** - Start exploring costs right away
2. **Import Grafana Dashboard** - Get detailed GPU metrics
3. **Review your costs** - See which namespaces are using GPUs
4. **Set up alerts** - Get notified of high costs or low utilization
5. **Share with your team** - Distribute the dashboard URLs

## 🆘 Troubleshooting

### Can't access the UI?

```bash
# Check service status
kubectl get svc -n opencost opencost-ui

# Should show:
# opencost-ui   NodePort   ...   9090:30091/TCP,9003:30031/TCP
```

### No data showing?

```bash
# Wait 5-10 minutes for metrics to populate
# Check DCGM metrics are flowing
kubectl port-forward -n monitoring svc/kube-prometheus-stack-1741-prometheus 9090:9090 &
curl -s 'http://localhost:9090/api/v1/query?query=DCGM_FI_DEV_GPU_UTIL'
```

### Need help?

See detailed documentation in:
- `BLOG_POST.md` - Complete setup guide
- `DASHBOARD_SETUP.md` - Dashboard usage guide
- `README.md` - Quick commands

## 🎉 You're All Set!

Your GPU cost monitoring is now live. Start by visiting:

**→ http://10.185.124.93:30091**

Happy cost monitoring! 💰📊



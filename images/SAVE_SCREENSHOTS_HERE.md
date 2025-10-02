# Screenshots to Save

Based on your screenshots, please save these images in this directory:

## 1. OpenCost UI Screenshot
**Filename:** `opencost-ui-overview.png`

**What to capture:**
- OpenCost Cost Allocation page
- Shows "Last 7 days by namespace"
- Pie chart showing namespace breakdown (dynamo-cloud, unmounted PVs, etc.)
- Table showing CPU, GPU, RAM, PV, Efficiency, and Total cost columns
- Shows GPU costs like $136.85, $410.45, etc.

**Your screenshot shows:**
- Total: $2,350.38 over 7 days
- GPU column with costs: $410.45 total
- Namespaces: dynamo-cloud, embedding-nim, reranking-nim, nim-service, etc.

**How to save:**
1. Take screenshot of the OpenCost UI you showed
2. Save as: `opencost-ui-overview.png`
3. Place in this `images/` directory

---

## 2. Grafana Dashboard Screenshot
**Filename:** `grafana-dashboard-overview.png`

**What to capture:**
- Grafana dashboard titled "DGX A100 GPU Cost Monitoring"
- Top metrics showing:
  - Total GPU Cost (Last 24h): $0.00903
  - Total A100 GPUs in Cluster: 13
  - Average GPU Utilization: 0%
  - A100 GPU Price per Hour: $0.9500
- Charts showing GPU Utilization by Device
- GPU Memory Usage (A100 80GB)
- GPU Allocation by Namespace
- Estimated GPU Cost by Namespace (Hourly Rate)

**Your screenshot shows:**
- 13 A100 GPUs
- $0.9500/hour pricing
- GPU memory usage around 77.8 GB
- Workloads: embedding-nim, reranking-nim, sr-3399a3db-b149-4bc2-afec-eb231efdabd5

**How to save:**
1. Take screenshot of your Grafana dashboard
2. Save as: `grafana-dashboard-overview.png`
3. Place in this `images/` directory

---

## Additional Screenshots (Optional)

If you want to add more detail, you can also capture:

3. **`opencost-cost-breakdown.png`** - Detailed cost breakdown view
4. **`grafana-gpu-metrics.png`** - Expanded GPU metrics panels
5. **`grafana-login.png`** - Grafana login screen
6. **`grafana-import-dashboard.png`** - Dashboard import screen

---

## Quick Steps

```bash
# Your screenshots should be saved here:
cd ~/opencost-gpu-monitoring/images/

# You should have at minimum:
# - opencost-ui-overview.png (the OpenCost UI you showed)
# - grafana-dashboard-overview.png (the Grafana dashboard you showed)

# Check files are here:
ls -lh
```

---

## Image Format Requirements

- **Format:** PNG (preferred) or JPG
- **Resolution:** At least 1920x1080 recommended
- **File size:** Under 5MB each
- **Quality:** Clear, readable text

---

## After Saving Images

Once you've saved the screenshots, the blog post will automatically reference them!

The blog post already has these references:
- Line ~288: `![OpenCost UI Overview](images/opencost-ui-overview.png)`
- Line ~296: `![OpenCost Cost Breakdown](images/opencost-cost-breakdown.png)`
- Line ~332: `![Grafana Login](images/grafana-login.png)`
- Line ~344: `![Dashboard Import Screen](images/grafana-import-dashboard.png)`
- Line ~355: `![GPU Cost Dashboard Overview](images/grafana-dashboard-overview.png)`
- Line ~373: `![Complete Dashboard View](images/grafana-gpu-metrics.png)`


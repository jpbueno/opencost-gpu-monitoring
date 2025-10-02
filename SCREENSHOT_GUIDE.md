# Screenshot Guide for Blog Post

## Screenshots to Add

To complete the blog post, please add the following screenshots to the `images/` folder:

### 1. Grafana Screenshots

#### grafana-login.png
- **When:** At Grafana login page (http://10.185.124.93:32222)
- **Shows:** Grafana login screen with username/password fields
- **Purpose:** Help readers identify the login page

#### grafana-import-dashboard.png
- **When:** During dashboard import process
- **Shows:** The "Import dashboard" screen with "Upload JSON file" button
- **Purpose:** Show where to upload the JSON file

#### grafana-dashboard-overview.png
- **When:** After successfully importing the dashboard
- **Shows:** Full dashboard view with all panels visible
- **Include:** All 11 panels showing GPU metrics
- **This is the screenshot you've already shared!** ✅

#### grafana-gpu-metrics.png
- **When:** Zoomed view of GPU utilization and memory panels
- **Shows:** GPU Utilization by Device and GPU Memory Usage panels
- **Purpose:** Highlight detailed GPU telemetry

#### grafana-cost-allocation.png
- **When:** Focused on cost panels
- **Shows:** GPU Allocation by Namespace and Estimated Cost pie chart
- **Purpose:** Show cost distribution visualizations

### 2. OpenCost UI Screenshots

#### opencost-ui-overview.png
- **When:** At OpenCost UI (http://10.185.124.93:30091)
- **Shows:** Main OpenCost dashboard with cost allocation
- **This is the screenshot you've already shared!** ✅

#### opencost-cost-breakdown.png
- **When:** Showing detailed cost table
- **Shows:** Breakdown table with CPU, GPU, RAM, PV columns
- **Purpose:** Demonstrate detailed cost analysis
- **This data is visible in your screenshot!** ✅

## How to Take Screenshots

### For Grafana:
1. Open browser to http://10.185.124.93:32222
2. Login with admin credentials
3. Navigate to DGX A100 GPU Cost Monitoring dashboard
4. Wait for all panels to load data
5. Take full-page screenshot (Ctrl+Shift+S in Firefox)
6. Save as PNG to `images/` folder

### For OpenCost:
1. Open browser to http://10.185.124.93:30091
2. Wait for cost data to load
3. Select "Last 7 days" time range
4. Aggregate by "Namespace"
5. Take screenshot showing both pie chart and table
6. Save as PNG to `images/` folder

## Screenshot Best Practices

1. **Resolution:** 1920x1080 minimum
2. **Format:** PNG (lossless, better for text)
3. **Browser:** Use Chrome/Firefox with zoom at 100%
4. **Clean up:** Hide personal info, bookmarks bar
5. **Timing:** Wait for all data to fully load
6. **Dark mode:** The dashboards use dark theme (looks better)

## What You Already Have

Based on your previous screenshots, you already have:
✅ **grafana-dashboard-overview.png** - Full dashboard view
✅ **opencost-ui-overview.png** - OpenCost cost allocation view

You need to capture:
- ⏳ grafana-login.png
- ⏳ grafana-import-dashboard.png
- ⏳ grafana-gpu-metrics.png (can crop from overview)
- ⏳ grafana-cost-allocation.png (can crop from overview)

## Saving Screenshots to images/ Folder

```bash
# On your local computer after downloading the folder
cd ~/Downloads/opencost-gpu-monitoring/images/

# Add your screenshot files here:
# - grafana-login.png
# - grafana-import-dashboard.png
# - grafana-dashboard-overview.png
# - grafana-gpu-metrics.png
# - grafana-cost-allocation.png
# - opencost-ui-overview.png
# - opencost-cost-breakdown.png
```

## Alternative: Use Existing Screenshots

If you've already shared screenshots with me:
1. Save them from your conversation/screenshots
2. Rename them according to this guide
3. Place in the `images/` folder
4. The blog post already has the references!

## Verify Image References

The blog post now includes these image references:
- `![Grafana Login](images/grafana-login.png)`
- `![Dashboard Import Screen](images/grafana-import-dashboard.png)`
- `![GPU Cost Dashboard Overview](images/grafana-dashboard-overview.png)`
- `![OpenCost UI Overview](images/opencost-ui-overview.png)`
- `![OpenCost Cost Breakdown](images/opencost-cost-breakdown.png)`
- `![Complete Dashboard View](images/grafana-gpu-metrics.png)`
- `![Cost Allocation Charts](images/grafana-cost-allocation.png)`

Once you add the images, the blog post will render them perfectly! 📸



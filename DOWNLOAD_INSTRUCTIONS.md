# Download Instructions

## Download All Files to Your Local Computer

### Option 1: Download Individual Folder (Recommended)

**On your local computer, run:**

```bash
# Download the entire opencost-gpu-monitoring folder
scp -r jbuenosantan@10.185.124.93:~/opencost-gpu-monitoring ~/Downloads/

# This will create: ~/Downloads/opencost-gpu-monitoring/
```

### Option 2: Download Compressed Archive

**On your local computer, run:**

```bash
# Download the tarball
scp jbuenosantan@10.185.124.93:~/opencost-gpu-monitoring.tar.gz ~/Downloads/

# Extract it
cd ~/Downloads
tar -xzf opencost-gpu-monitoring.tar.gz

# This will create: ~/Downloads/opencost-gpu-monitoring/
```

### Option 3: Using rsync (Preserves timestamps)

**On your local computer, run:**

```bash
# Sync the folder
rsync -avz jbuenosantan@10.185.124.93:~/opencost-gpu-monitoring ~/Downloads/
```

## Files Included (12 total)

```
opencost-gpu-monitoring/
├── BLOG_POST.md (23KB)                    # Complete tutorial
├── DASHBOARD_SETUP.md (11KB)              # Dashboard guide
├── LOCAL_ACCESS.md (6.6KB)                # Remote access
├── QUICK_START.md (4.0KB)                 # Fast setup
├── README.md (6.2KB)                      # Quick reference
├── UPDATES.md (3.4KB)                     # Change log
├── DOWNLOAD_INSTRUCTIONS.md               # This file
├── opencost-values.yaml (1.9KB)           # Helm config
├── opencost-nodeport.yaml (433B)          # NodePort service
├── dcgm-servicemonitor.yaml (412B)        # DCGM scraping
├── grafana-gpu-cost-dashboard.json (24KB) # Grafana dashboard
├── opencost-custom-pricing.json (332B)    # Pricing config
└── tunnel-script.sh (898B)                # SSH tunnel helper
```

Total size: ~100KB

## Verify Download

After downloading, verify all files:

```bash
cd ~/Downloads/opencost-gpu-monitoring
ls -lh
```

You should see 12 files listed.

## What to Do Next

1. ✅ **Read QUICK_START.md** for immediate setup
2. ✅ **Read BLOG_POST.md** for the complete tutorial
3. ✅ **Import grafana-gpu-cost-dashboard.json** into Grafana
4. ✅ **Share the folder** with your team
5. ✅ **Publish BLOG_POST.md** to your blog

## Troubleshooting

### "Permission denied"

Make sure you can SSH to the cluster:
```bash
ssh jbuenosantan@10.185.124.93 "echo 'Connected!'"
```

### "No such file or directory"

The files are located at:
```
/home/jbuenosantan/opencost-gpu-monitoring/
```

### Using a different username

Replace `jbuenosantan` with your actual username:
```bash
scp -r YOUR_USERNAME@10.185.124.93:~/opencost-gpu-monitoring ~/Downloads/
```

---

**Ready to download!** Run the command from your local computer's terminal.



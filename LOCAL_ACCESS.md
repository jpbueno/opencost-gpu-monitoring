# Accessing GPU Cost Dashboards from Your Local Computer

## Option 1: SSH Tunnel (Recommended) 🔒

Create an SSH tunnel to forward the ports to your local machine.

### On Your Local Computer:

```bash
# Tunnel OpenCost UI and API
ssh -L 9090:10.185.124.93:30091 -L 9003:10.185.124.93:30031 jbuenosantan@10.185.124.93

# Or if you use a different username/hostname:
ssh -L 9090:10.185.124.93:30091 -L 9003:10.185.124.93:30031 your-user@dgx-003
```

**Then access locally:**
- OpenCost UI: http://localhost:9090
- OpenCost API: http://localhost:9003

### Keep the tunnel running in background:

```bash
# Run SSH tunnel in background
ssh -f -N -L 9090:10.185.124.93:30091 -L 9003:10.185.124.93:30031 jbuenosantan@10.185.124.93

# Kill it when done:
pkill -f "ssh.*9090.*9003"
```

---

## Option 2: kubectl Port-Forward (If you have local kubectl) 🔧

If you have kubectl configured locally with access to the cluster:

### On Your Local Computer:

```bash
# Forward OpenCost UI and API to localhost
kubectl port-forward -n opencost svc/opencost-ui 9090:9090 9003:9003
```

**Then access:**
- OpenCost UI: http://localhost:9090
- OpenCost API: http://localhost:9003

### Keep running in background:

```bash
# Run in background
kubectl port-forward -n opencost svc/opencost-ui 9090:9090 9003:9003 &

# Stop it:
pkill -f "kubectl port-forward.*opencost"
```

---

## Option 3: Direct Access (If Nodes are Network Accessible) 🌐

If your local computer can reach the cluster nodes directly (same network/VPN):

**Access directly via node IP:**
- OpenCost UI: http://10.185.124.93:30091
- OpenCost API: http://10.185.124.93:30031

**Or via hostname:**
- OpenCost UI: http://dgx-003:30091
- OpenCost API: http://dgx-003:30031

**Test from local computer:**
```bash
# Test connectivity
ping 10.185.124.93

# Test OpenCost
curl http://10.185.124.93:30091
```

---

## Option 4: Grafana via SSH Tunnel 📊

### Tunnel Grafana:

```bash
# On your local computer
ssh -L 3000:10.185.124.93:32222 jbuenosantan@10.185.124.93
```

**Then access:**
- Grafana: http://localhost:3000

Import the dashboard from `grafana-gpu-cost-dashboard.json`

---

## Option 5: All-in-One Tunnel (Recommended Setup) 🚀

Tunnel all services at once:

### On Your Local Computer:

```bash
# Create tunnels for OpenCost, Grafana, and Prometheus
ssh -L 9090:10.185.124.93:30091 \
    -L 9003:10.185.124.93:30031 \
    -L 3000:10.185.124.93:32222 \
    -L 9091:10.185.124.93:30090 \
    jbuenosantan@10.185.124.93
```

**Access all services locally:**
- OpenCost UI: http://localhost:9090
- OpenCost API: http://localhost:9003
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9091

---

## Quick Setup Script

Save this on your **local computer** as `tunnel-opencost.sh`:

```bash
#!/bin/bash
# tunnel-opencost.sh - Access OpenCost dashboards locally

CLUSTER_USER="jbuenosantan"
CLUSTER_HOST="10.185.124.93"

echo "🔐 Creating SSH tunnels to cluster..."
echo ""
echo "OpenCost UI:  http://localhost:9090"
echo "OpenCost API: http://localhost:9003"
echo "Grafana:      http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop tunnels"
echo ""

ssh -L 9090:${CLUSTER_HOST}:30091 \
    -L 9003:${CLUSTER_HOST}:30031 \
    -L 3000:${CLUSTER_HOST}:32222 \
    ${CLUSTER_USER}@${CLUSTER_HOST}
```

**Usage:**
```bash
chmod +x tunnel-opencost.sh
./tunnel-opencost.sh
```

---

## Troubleshooting

### "Port already in use"

If ports 9090/9003/3000 are already used locally:

**Option A: Use different local ports**
```bash
ssh -L 8090:10.185.124.93:30091 \
    -L 8003:10.185.124.93:30031 \
    jbuenosantan@10.185.124.93
```
Access at: http://localhost:8090

**Option B: Kill existing port forwards**
```bash
# On local computer
lsof -ti:9090 | xargs kill -9
lsof -ti:9003 | xargs kill -9
```

### "Connection refused"

1. **Verify services are running on cluster:**
   ```bash
   # On cluster
   kubectl get svc -n opencost opencost-ui
   curl http://10.185.124.93:30091
   ```

2. **Check SSH connectivity:**
   ```bash
   # On local computer
   ssh jbuenosantan@10.185.124.93 "echo 'Connected!'"
   ```

3. **Verify NodePort is accessible:**
   ```bash
   # On cluster
   kubectl get svc opencost-ui -n opencost -o yaml | grep nodePort
   ```

### "SSH tunnel disconnects"

Use autossh for persistent tunnels:

```bash
# On local computer (install autossh first)
autossh -M 0 -f -N \
  -o "ServerAliveInterval 30" \
  -o "ServerAliveCountMax 3" \
  -L 9090:10.185.124.93:30091 \
  -L 9003:10.185.124.93:30031 \
  jbuenosantan@10.185.124.93
```

---

## Copy Dashboard File to Local Computer

To import the Grafana dashboard, first copy it to your local machine:

```bash
# On your local computer
scp jbuenosantan@10.185.124.93:~/opencost-gpu-monitoring/grafana-gpu-cost-dashboard.json ~/Downloads/
```

Then import it in Grafana (http://localhost:3000 via tunnel).

---

## Recommended Workflow

### For Daily Use:

1. **Start SSH tunnel** (all-in-one method):
   ```bash
   ssh -L 9090:10.185.124.93:30091 -L 3000:10.185.124.93:32222 jbuenosantan@10.185.124.93
   ```

2. **Open in browser:**
   - OpenCost: http://localhost:9090
   - Grafana: http://localhost:3000

3. **Keep terminal open** while using dashboards

4. **Close tunnel** when done (Ctrl+C)

### For Background Access:

```bash
# Start tunnel in background
ssh -f -N -L 9090:10.185.124.93:30091 -L 3000:10.185.124.93:32222 jbuenosantan@10.185.124.93

# Use dashboards...

# Stop tunnel when done
pkill -f "ssh.*9090"
```

---

## Security Best Practices

1. **Use SSH keys** instead of passwords:
   ```bash
   ssh-keygen -t ed25519
   ssh-copy-id jbuenosantan@10.185.124.93
   ```

2. **Use SSH config** for easy access:
   ```bash
   # Add to ~/.ssh/config on local computer
   Host dgx-opencost
       HostName 10.185.124.93
       User jbuenosantan
       LocalForward 9090 10.185.124.93:30091
       LocalForward 9003 10.185.124.93:30031
       LocalForward 3000 10.185.124.93:32222
   
   # Then just run:
   ssh dgx-opencost
   ```

3. **Don't expose to public internet** - Keep NodePort internal only

---

## Quick Reference

| Service | Cluster (via SSH) | Local (via tunnel) |
|---------|-------------------|-------------------|
| OpenCost UI | 10.185.124.93:30091 | localhost:9090 |
| OpenCost API | 10.185.124.93:30031 | localhost:9003 |
| Grafana | 10.185.124.93:32222 | localhost:3000 |
| Prometheus | 10.185.124.93:30090 | localhost:9091 |

---

## What's Next?

1. ✅ Set up SSH tunnel
2. ✅ Access OpenCost UI at http://localhost:9090
3. ✅ Import Grafana dashboard at http://localhost:3000
4. ✅ Save tunnel script for daily use
5. ✅ Share access instructions with your team

Enjoy monitoring your GPU costs! 💰📊



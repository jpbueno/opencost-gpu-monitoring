# Grafana Access Credentials

## Grafana Login Information

### Main Grafana Instance (Port 32222)

**URL:** http://10.185.124.93:32222

**Credentials:**
- **Username:** `admin`
- **Password:** `cns-stack`

### Alternative Grafana Instance (kube-prometheus-stack)

**URL:** Check service for NodePort

**Credentials:**
- **Username:** `admin`
- **Password:** `prom-operator`

## How to Access

1. **Open your browser** and go to:
   ```
   http://10.185.124.93:32222
   ```

2. **Login with:**
   - Username: `admin`
   - Password: `cns-stack`

3. **Import the GPU Cost Dashboard:**
   - Navigate to **Dashboards** → **Import**
   - Click **Upload JSON file**
   - Select `grafana-gpu-cost-dashboard.json`
   - Choose your Prometheus data source
   - Click **Import**

## Retrieve Passwords Anytime

If you need to retrieve the passwords again:

```bash
# For prometheus-grafana (Port 32222)
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode && echo

# For kube-prometheus-stack grafana
kubectl get secret -n monitoring kube-prometheus-stack-1741309824-grafana -o jsonpath="{.data.admin-password}" | base64 --decode && echo
```

## Security Reminder

🔒 **Important:** These are admin credentials with full access to Grafana. Consider:
- Changing the default password
- Creating read-only users for team members
- Enabling authentication via LDAP/SSO if needed

## Next Steps

1. ✅ Login to Grafana
2. ✅ Import `grafana-gpu-cost-dashboard.json`
3. ✅ Configure Prometheus data source (if not already set)
4. ✅ View GPU cost metrics and dashboards
5. ✅ Create custom dashboards as needed

---

**Access URLs:**
- **Grafana:** http://10.185.124.93:32222
- **OpenCost UI:** http://10.185.124.93:30091
- **OpenCost API:** http://10.185.124.93:30031


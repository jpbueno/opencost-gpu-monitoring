# Ingress Testing Results

## Test Summary
✅ **Ingress approach successfully tested and working!**

## Configuration Used

### Ingress Resource
- **IngressClass**: nginx
- **Hostname**: opencost.local (for testing)
- **Path-based routing**:
  - `/allocation` → opencost service port 9003 (API)
  - `/healthz` → opencost service port 9003 (API)
  - `/` → opencost service port 9090 (UI)

### Key Findings

1. **OpenCost Architecture**: OpenCost has two distinct ports:
   - Port 9090: Serves the UI (HTML/JS)
   - Port 9003: Serves the REST API

2. **Ingress Configuration**: The Ingress must route specific API paths to port 9003 and the UI paths to port 9090

3. **Working Test Results**:
   ```bash
   # API Test - Success!
   curl -H "Host: opencost.local" "http://10.185.124.1/allocation?window=24h&aggregate=namespace"
   # Returns: {"code":200,"data":[{...}]}
   
   # UI Test - Success!
   curl -I -H "Host: opencost.local" "http://10.185.124.1/"
   # Returns: HTTP/1.1 200 OK with HTML content
   
   # GPU Workload Test - Success!
   # Retrieved GPU costs: ~22.30 per 23.47 GPU hours
   ```

## Recommendation for Blog Post

The current blog post Ingress configuration needs adjustment. Here's the working version:

\`\`\`yaml
# opencost-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: opencost-ingress
  namespace: opencost
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: opencost.example.com  # Replace with your domain
    http:
      paths:
      - path: /allocation
        pathType: Prefix
        backend:
          service:
            name: opencost
            port:
              number: 9003
      - path: /healthz
        pathType: Prefix
        backend:
          service:
            name: opencost
            port:
              number: 9003
      - path: /
        pathType: Prefix
        backend:
          service:
            name: opencost
            port:
              number: 9090
\`\`\`

**Key Changes**:
1. Removed the `rewrite-target` annotation (causes 404 errors)
2. Added explicit paths for API endpoints (/allocation, /healthz) to port 9003
3. Use the `opencost` ClusterIP service (not `opencost-ui`)
4. UI paths route to port 9090

## API Access Instructions

With this Ingress setup, API access is simplified:

\`\`\`bash
# Set API endpoint
OPENCOST_API="http://opencost.example.com"  # No /api prefix needed!

# Test health
curl -s "\${OPENCOST_API}/healthz"

# Get costs
curl -s "\${OPENCOST_API}/allocation?window=24h&aggregate=namespace" | jq '.'
\`\`\`

## Environment Details
- Ingress Controller: nginx-ingress-controller v1.8.1
- External IP: 10.185.124.1
- Test Hostname: opencost.local
- Test Date: October 7, 2025

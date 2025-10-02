#!/bin/bash
# SSH Tunnel Script for OpenCost Dashboard Access
# Copy this to your LOCAL computer and run it

CLUSTER_USER="jbuenosantan"
CLUSTER_HOST="10.185.124.93"

echo "======================================"
echo "🚀 OpenCost GPU Cost Dashboard Tunnel"
echo "======================================"
echo ""
echo "Creating SSH tunnels to cluster..."
echo ""
echo "📊 Services available at:"
echo "  • OpenCost UI:  http://localhost:9090"
echo "  • OpenCost API: http://localhost:9003"
echo "  • Grafana:      http://localhost:3000"
echo "  • Prometheus:   http://localhost:9091"
echo ""
echo "💡 Tip: Keep this terminal open while using dashboards"
echo "🛑 Press Ctrl+C to stop tunnels"
echo ""

ssh -L 9090:${CLUSTER_HOST}:30091 \
    -L 9003:${CLUSTER_HOST}:30031 \
    -L 3000:${CLUSTER_HOST}:32222 \
    -L 9091:${CLUSTER_HOST}:30090 \
    ${CLUSTER_USER}@${CLUSTER_HOST}



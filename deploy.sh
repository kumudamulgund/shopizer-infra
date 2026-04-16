#!/bin/bash
set -e

INFRA_DIR="$(cd "$(dirname "$0")" && pwd)/k8s"
NAMESPACE="shopizer"

echo "🧹 Cleaning up app services (keeping database)..."
kubectl delete -f "$INFRA_DIR/backend/" 2>/dev/null || true
kubectl delete -f "$INFRA_DIR/frontend/" 2>/dev/null || true
kubectl delete -f "$INFRA_DIR/admin/" 2>/dev/null || true

echo "🚀 Deploying all services..."
kubectl apply -f "$INFRA_DIR/namespace.yaml"
kubectl apply -R -f "$INFRA_DIR/"

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=120s

echo ""
echo "✅ All services are up:"
kubectl get pods -n $NAMESPACE
echo ""
echo "Frontend:  http://localhost:30000"
echo "Admin:     http://localhost:30001"
echo "Backend:   http://localhost:30002"

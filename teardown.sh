#!/bin/bash
set -e

INFRA_DIR="$(cd "$(dirname "$0")" && pwd)/k8s"

echo "🛑 Tearing down app services (keeping database)..."
kubectl delete -f "$INFRA_DIR/backend/" 2>/dev/null || true
kubectl delete -f "$INFRA_DIR/frontend/" 2>/dev/null || true
kubectl delete -f "$INFRA_DIR/admin/" 2>/dev/null || true

echo "✅ App services deleted. Database is still running."
kubectl get pods -n shopizer

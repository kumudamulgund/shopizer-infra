# Shopizer Deployment Architecture

## Overview

Shopizer is a 3-tier e-commerce platform deployed as containers on a local Kubernetes cluster.

```
                    ┌──────────────┐
                    │   Browser    │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │  React   │ │  Admin   │ │          │
        │ Frontend │ │ (Angular)│ │          │
        │ :3000    │ │ :8082    │ │          │
        └────┬─────┘ └────┬─────┘ │          │
             │             │       │          │
             └──────┬──────┘       │          │
                    │              │          │
                    ▼              │          │
              ┌──────────┐        │          │
              │  Backend │        │          │
              │ (Java)   │        │          │
              │ :8080    │        │          │
              └────┬─────┘        │          │
                   │              │          │
                   ▼              │          │
              ┌──────────┐        │          │
              │  MySQL   │        │          │
              │  :3306   │        │          │
              └──────────┘        │          │
```

## Services

| Service | Image | Internal Port | Description |
|---------|-------|---------------|-------------|
| shopizer-backend | ghcr.io/kumudamulgund/shopizer | 8080 | Java Spring Boot API |
| shopizer-frontend | ghcr.io/kumudamulgund/shopizer-shop-reactjs | 80 | React storefront (nginx) |
| shopizer-admin | ghcr.io/kumudamulgund/shopizer-admin | 80 | Angular admin panel (nginx) |
| shopizer-db | mysql:8 | 3306 | MySQL database |

## Service Communication

- **React Frontend** → Backend API via `http://shopizer-backend:8080/api/v1/`
- **Admin Panel** → Backend API via `http://shopizer-backend:8080/api`
- **Backend** → MySQL via `shopizer-db:3306`
- **Browser** accesses Frontend, Admin, and Backend via NodePort services

## Environment Variables

### Backend (shopizer-backend)
- `DB_HOST` — MySQL host (shopizer-db)
- `DB_PORT` — MySQL port (3306)
- `DB_NAME` — Database name
- `DB_USER` — Database username
- `DB_PASSWORD` — Database password

### React Frontend (shopizer-frontend)
- `APP_BASE_URL` — Backend API URL (http://shopizer-backend:8080)
- `APP_API_VERSION` — API version path (/api/v1/)
- `APP_MERCHANT` — Default merchant (DEFAULT)

### Admin Panel (shopizer-admin)
- `APP_BASE_URL` — Backend API URL (http://shopizer-backend:8080/api)

## Kubernetes Resources

```
shopizer-infra/
├── ARCHITECTURE.md
└── k8s/
    ├── namespace.yaml
    ├── db/
    │   ├── mysql-pvc.yaml
    │   ├── mysql-secret.yaml
    │   ├── mysql-deployment.yaml
    │   └── mysql-service.yaml
    ├── backend/
    │   ├── backend-configmap.yaml
    │   ├── backend-deployment.yaml
    │   └── backend-service.yaml
    ├── frontend/
    │   ├── frontend-configmap.yaml
    │   ├── frontend-deployment.yaml
    │   └── frontend-service.yaml
    └── admin/
        ├── admin-configmap.yaml
        ├── admin-deployment.yaml
        └── admin-service.yaml
```

## Deployment Order

1. Namespace
2. MySQL (secret → PVC → deployment → service)
3. Backend (configmap → deployment → service)
4. Frontend (configmap → deployment → service)
5. Admin (configmap → deployment → service)

## Local Access (NodePort)

| Service | NodePort |
|---------|----------|
| Frontend | 30000 |
| Admin | 30001 |
| Backend | 30002 |

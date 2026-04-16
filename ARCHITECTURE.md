# Shopizer Deployment Architecture

## Overview

Shopizer is a 3-tier e-commerce platform deployed on a local Kubernetes cluster (Docker Desktop). All resources live in the `shopizer` namespace and are exposed to the host via NodePort services.

## Architecture Diagram

```
                         ┌─────────────────────────────────────────────────────────────┐
                         │                    Kubernetes Cluster                        │
                         │                  Namespace: shopizer                         │
                         │                                                             │
  ┌──────────┐           │  ┌─────────────────────────────────────────────────────┐     │
  │          │  :30000   │  │              Frontend Pod                           │     │
  │          │◄──────────┼──┤  ┌─────────────────────┐                           │     │
  │          │           │  │  │  React App (nginx)   │  image: ghcr.io/kumuda   │     │
  │          │           │  │  │  containerPort: 80   │  mulgund/shopizer-shop   │     │
  │          │           │  │  └─────────────────────┘  -reactjs:latest          │     │
  │          │           │  └─────────────────────────────────────────────────────┘     │
  │          │           │                      │                                      │
  │          │           │                      │ APP_BASE_URL=http://localhost:30002   │
  │          │           │                      ▼                                      │
  │          │           │  ┌─────────────────────────────────────────────────────┐     │
  │          │  :30002   │  │              Backend Pod                            │     │
  │ Browser  │◄──────────┼──┤  ┌──────────────────┐  ┌────────────────────────┐  │     │
  │          │           │  │  │  initContainer:   │  │  Spring Boot (Java 11) │  │     │
  │          │           │  │  │  wait-for-mysql   │─▶│  containerPort: 8080   │  │     │
  │          │           │  │  │  (busybox:1.36)   │  │  image: ghcr.io/kumuda │  │     │
  │          │           │  │  └──────────────────┘  │  mulgund/shopizer:latest│  │     │
  │          │           │  │                        └────────────────────────┘  │     │
  │          │           │  └─────────────────────────────────────────────────────┘     │
  │          │           │                      │                                      │
  │          │           │                      │ JDBC: shopizer-db:3306                │
  │          │           │                      ▼                                      │
  │          │           │  ┌─────────────────────────────────────────────────────┐     │
  │          │           │  │              Database Pod                           │     │
  │          │           │  │  ┌─────────────────────┐  ┌──────────────────────┐ │     │
  │          │           │  │  │  MySQL 8             │  │  PVC: mysql-pvc     │ │     │
  │          │           │  │  │  containerPort: 3306 │──│  1Gi, ReadWriteOnce │ │     │
  │          │           │  │  └─────────────────────┘  └──────────────────────┘ │     │
  │          │           │  └─────────────────────────────────────────────────────┘     │
  │          │           │                                                             │
  │          │           │  ┌─────────────────────────────────────────────────────┐     │
  │          │  :30001   │  │              Admin Pod                              │     │
  │          │◄──────────┼──┤  ┌─────────────────────┐                           │     │
  │          │           │  │  │  Angular App (nginx) │  image: ghcr.io/kumuda   │     │
  │          │           │  │  │  containerPort: 80   │  mulgund/shopizer-admin  │     │
  │          │           │  │  └─────────────────────┘  :latest                  │     │
  └──────────┘           │  └─────────────────────────────────────────────────────┘     │
                         │                                                             │
                         └─────────────────────────────────────────────────────────────┘
```

## Kubernetes Resources by Component

### Namespace
- `Namespace: shopizer` — isolates all Shopizer resources from other workloads

### Database (MySQL)

| Resource | Name | Purpose |
|----------|------|---------|
| Deployment | shopizer-db | Runs MySQL 8 container with 1 replica |
| Service | shopizer-db | ClusterIP service, internal access on port 3306 |
| PersistentVolumeClaim | mysql-pvc | 1Gi storage, ReadWriteOnce — persists data across pod restarts |
| Secret | mysql-secret | Stores MYSQL_ROOT_PASSWORD, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD |

### Backend (Spring Boot)

| Resource | Name | Purpose |
|----------|------|---------|
| Deployment | shopizer-backend | Runs Java 11 Spring Boot API with 1 replica |
| Service | shopizer-backend | NodePort service, exposed on port 30002 |
| ConfigMap | backend-config | Stores SPRING_PROFILES_ACTIVE, DB_JDBC_URL, DB_USER, DB_PASSWORD |
| initContainer | wait-for-mysql | busybox container that blocks until MySQL is reachable on port 3306 |

### Frontend (React)

| Resource | Name | Purpose |
|----------|------|---------|
| Deployment | shopizer-frontend | Runs React app served via nginx with 1 replica |
| Service | shopizer-frontend | NodePort service, exposed on port 30000 |
| ConfigMap | frontend-config | Stores APP_BASE_URL, APP_API_VERSION, APP_MERCHANT |

### Admin (Angular)

| Resource | Name | Purpose |
|----------|------|---------|
| Deployment | shopizer-admin | Runs Angular admin panel served via nginx with 1 replica |
| Service | shopizer-admin | NodePort service, exposed on port 30001 |
| ConfigMap | admin-config | Stores APP_BASE_URL |

## Service Types & Networking

| Service | Type | Internal Port | External Port | Access |
|---------|------|---------------|---------------|--------|
| shopizer-frontend | NodePort | 80 | 30000 | http://localhost:30000 |
| shopizer-admin | NodePort | 80 | 30001 | http://localhost:30001 |
| shopizer-backend | NodePort | 8080 | 30002 | http://localhost:30002 |
| shopizer-db | ClusterIP | 3306 | — | Internal only (shopizer-db:3306) |

- NodePort services expose apps to the host machine for local development
- ClusterIP for MySQL ensures the database is only accessible within the cluster

## Container Images

| Image | Registry | Built via |
|-------|----------|-----------|
| ghcr.io/kumudamulgund/shopizer:latest | GitHub Container Registry | GitHub Actions CI/CD on push to `3.2.7` branch |
| ghcr.io/kumudamulgund/shopizer-shop-reactjs:latest | GitHub Container Registry | GitHub Actions CI/CD |
| ghcr.io/kumudamulgund/shopizer-admin:latest | GitHub Container Registry | GitHub Actions CI/CD |
| mysql:8 | Docker Hub | Official image |
| busybox:1.36 | Docker Hub | Official image (used as initContainer) |

## Data Persistence

- MySQL data is stored on a PersistentVolumeClaim (`mysql-pvc`, 1Gi, ReadWriteOnce)
- Product images are stored in-memory via Infinispan (`config.cms.method=default`) and serialized to `.dat` files inside the backend container — these are NOT persisted across container restarts
- The teardown script preserves the database by only deleting app services (backend, frontend, admin)

## Deployment & Teardown

### Deploy (`./deploy.sh`)
1. Deletes existing app services (backend, frontend, admin) — database untouched
2. Applies all K8s manifests (`kubectl apply -R`)
3. MySQL is created if not running, no-op if already up
4. Backend initContainer waits for MySQL before starting Spring Boot
5. Waits for all pods to be ready (120s timeout)

### Teardown (`./teardown.sh`)
1. Deletes only backend, frontend, and admin resources
2. MySQL pod, service, PVC, and secret remain running
3. All database data is preserved

## Schema Management

- Hibernate `hbm2ddl.auto=update` — schema changes are applied automatically on backend startup
- New entities (e.g., Wishlist, WishlistItem) create tables automatically
- No manual migration scripts required for development

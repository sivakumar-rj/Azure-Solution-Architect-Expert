# Docker & Containers Deep Dive for Azure

## Docker Fundamentals

### Container vs Virtual Machine

**Virtual Machine:**
```
Hardware
├── Hypervisor
├── Guest OS (Full OS - GB)
├── Binaries/Libraries
└── Application
```

**Container:**
```
Hardware
├── Host OS
├── Container Runtime (Docker)
└── Container (App + Dependencies only - MB)
```

**Key Differences:**
| Feature | VM | Container |
|---------|----|-----------| 
| Size | GBs | MBs |
| Startup | Minutes | Seconds |
| Isolation | Complete | Process-level |
| Resource | Heavy | Lightweight |
| Portability | Limited | High |

### Docker Architecture

```
Docker Client (CLI)
    ↓ (REST API)
Docker Daemon (dockerd)
    ├── Images (Read-only templates)
    ├── Containers (Running instances)
    ├── Networks (Container connectivity)
    └── Volumes (Persistent storage)
    ↓
Container Runtime (containerd)
    ↓
Operating System Kernel
```

## Dockerfile Best Practices

### Multi-Stage Build (Optimized)
```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:18-alpine
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./
USER nodejs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js
CMD ["node", "dist/server.js"]
```

### Python Application
```dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "app:app"]
```

### .NET Application
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MyApp.csproj", "./"]
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 80
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

### Java Spring Boot
```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Optimization Techniques

**1. Layer Caching**
```dockerfile
# ❌ Bad - Invalidates cache on any file change
COPY . .
RUN npm install

# ✅ Good - Cache dependencies separately
COPY package*.json ./
RUN npm install
COPY . .
```

**2. Minimize Layers**
```dockerfile
# ❌ Bad - Multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN rm -rf /var/lib/apt/lists/*

# ✅ Good - Single layer
RUN apt-get update && \
    apt-get install -y curl git && \
    rm -rf /var/lib/apt/lists/*
```

**3. Use .dockerignore**
```
# .dockerignore
node_modules
npm-debug.log
.git
.env
*.md
.vscode
.idea
dist
coverage
.DS_Store
```

**4. Security Hardening**
```dockerfile
# Use specific versions
FROM node:18.19.0-alpine3.19

# Run as non-root
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser
USER appuser

# Read-only root filesystem
VOLUME /tmp
WORKDIR /app

# Drop capabilities
# Set in docker-compose or k8s manifest
```

## Docker Commands Reference

### Image Management
```bash
# Build image
docker build -t myapp:v1 .
docker build -t myapp:v1 -f Dockerfile.prod .
docker build --no-cache -t myapp:v1 .

# List images
docker images
docker images --filter "dangling=true"

# Remove images
docker rmi myapp:v1
docker image prune -a  # Remove unused images

# Tag image
docker tag myapp:v1 myregistry.azurecr.io/myapp:v1

# Push/Pull
docker push myregistry.azurecr.io/myapp:v1
docker pull nginx:alpine

# Inspect image
docker inspect myapp:v1
docker history myapp:v1
```

### Container Management
```bash
# Run container
docker run -d --name myapp -p 8080:80 myapp:v1
docker run -it --rm alpine sh
docker run -d --restart unless-stopped myapp:v1

# Environment variables
docker run -e DB_HOST=localhost -e DB_PORT=5432 myapp:v1
docker run --env-file .env myapp:v1

# Volume mounting
docker run -v /host/path:/container/path myapp:v1
docker run -v myvolume:/data myapp:v1

# Resource limits
docker run --memory="512m" --cpus="1.5" myapp:v1

# List containers
docker ps
docker ps -a
docker ps --filter "status=exited"

# Container operations
docker start myapp
docker stop myapp
docker restart myapp
docker pause myapp
docker unpause myapp
docker rm myapp
docker rm -f $(docker ps -aq)  # Remove all containers

# Logs
docker logs myapp
docker logs -f myapp  # Follow
docker logs --tail 100 myapp
docker logs --since 30m myapp

# Execute commands
docker exec -it myapp bash
docker exec myapp ls /app
docker exec -u root myapp apt-get update

# Copy files
docker cp myapp:/app/logs ./logs
docker cp ./config.json myapp:/app/

# Stats
docker stats
docker stats myapp
docker top myapp
```

### Network Management
```bash
# Create network
docker network create mynetwork
docker network create --driver bridge --subnet 172.20.0.0/16 mynetwork

# List networks
docker network ls

# Connect container
docker network connect mynetwork myapp

# Inspect network
docker network inspect mynetwork

# Remove network
docker network rm mynetwork
```

### Volume Management
```bash
# Create volume
docker volume create myvolume

# List volumes
docker volume ls

# Inspect volume
docker volume inspect myvolume

# Remove volume
docker volume rm myvolume
docker volume prune  # Remove unused volumes
```

## Docker Compose

### Full-Stack Application
```yaml
# docker-compose.yml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://api:8080
    depends_on:
      - api
    networks:
      - app-network
    restart: unless-stopped

  api:
    build:
      context: ./api
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/appdb
      - REDIS_URL=redis://cache:6379
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    networks:
      - app-network
    volumes:
      - ./api/logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=appdb
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  cache:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - app-network
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - frontend
      - api
    networks:
      - app-network
    restart: unless-stopped

volumes:
  postgres-data:
  redis-data:

networks:
  app-network:
    driver: bridge
```

### Docker Compose Commands
```bash
# Start services
docker-compose up
docker-compose up -d  # Detached mode
docker-compose up --build  # Rebuild images

# Stop services
docker-compose stop
docker-compose down  # Stop and remove
docker-compose down -v  # Remove volumes too

# View logs
docker-compose logs
docker-compose logs -f api
docker-compose logs --tail=100

# Scale services
docker-compose up -d --scale api=3

# Execute commands
docker-compose exec api bash
docker-compose run --rm api npm test

# View status
docker-compose ps
docker-compose top
```

## Azure Container Registry (ACR)

### ACR Setup
```bash
# Create ACR
az acr create \
  --resource-group myRG \
  --name myacr \
  --sku Premium \
  --location eastus

# Login to ACR
az acr login --name myacr
docker login myacr.azurecr.io

# Enable admin user (not recommended for production)
az acr update --name myacr --admin-enabled true
az acr credential show --name myacr
```

### Push Images to ACR
```bash
# Tag image
docker tag myapp:v1 myacr.azurecr.io/myapp:v1
docker tag myapp:v1 myacr.azurecr.io/myapp:latest

# Push image
docker push myacr.azurecr.io/myapp:v1
docker push myacr.azurecr.io/myapp:latest

# List repositories
az acr repository list --name myacr --output table

# List tags
az acr repository show-tags --name myacr --repository myapp --output table

# Delete image
az acr repository delete --name myacr --image myapp:v1
```

### ACR Tasks (CI/CD)
```bash
# Quick build
az acr build \
  --registry myacr \
  --image myapp:{{.Run.ID}} \
  --image myapp:latest \
  --file Dockerfile .

# Create automated task
az acr task create \
  --registry myacr \
  --name buildtask \
  --image myapp:{{.Run.ID}} \
  --context https://github.com/user/repo.git \
  --file Dockerfile \
  --git-access-token <PAT> \
  --branch main

# Trigger task manually
az acr task run --registry myacr --name buildtask

# List tasks
az acr task list --registry myacr --output table

# View task runs
az acr task list-runs --registry myacr --output table
```

### ACR Security

**1. Service Principal Authentication**
```bash
# Create service principal
SP_ID=$(az ad sp create-for-rbac \
  --name acr-service-principal \
  --scopes $(az acr show --name myacr --query id --output tsv) \
  --role acrpull \
  --query appId \
  --output tsv)

SP_PASSWORD=$(az ad sp credential reset \
  --id $SP_ID \
  --query password \
  --output tsv)

# Use in Docker
docker login myacr.azurecr.io \
  --username $SP_ID \
  --password $SP_PASSWORD
```

**2. Managed Identity**
```bash
# Assign AKS identity to ACR
az aks update \
  --name myAKS \
  --resource-group myRG \
  --attach-acr myacr
```

**3. Private Endpoint**
```bash
# Create private endpoint
az network private-endpoint create \
  --name acr-private-endpoint \
  --resource-group myRG \
  --vnet-name myVNet \
  --subnet mySubnet \
  --private-connection-resource-id $(az acr show --name myacr --query id -o tsv) \
  --group-id registry \
  --connection-name acr-connection

# Disable public access
az acr update --name myacr --public-network-enabled false
```

### ACR Geo-Replication
```bash
# Enable geo-replication (Premium SKU required)
az acr replication create \
  --registry myacr \
  --location westeurope

az acr replication create \
  --registry myacr \
  --location eastasia

# List replications
az acr replication list --registry myacr --output table
```

### Image Scanning
```bash
# Enable Microsoft Defender for Containers
az security pricing create \
  --name Containers \
  --tier Standard

# Scan image
az acr task create \
  --registry myacr \
  --name scan-task \
  --context /dev/null \
  --cmd "mcr.microsoft.com/azure-cli az acr check-health --name myacr"
```

## Azure Container Instances (ACI)

### Quick Container Deployment
```bash
# Create container instance
az container create \
  --resource-group myRG \
  --name mycontainer \
  --image nginx:alpine \
  --cpu 1 \
  --memory 1.5 \
  --ports 80 \
  --dns-name-label myapp-unique \
  --location eastus

# With environment variables
az container create \
  --resource-group myRG \
  --name myapp \
  --image myacr.azurecr.io/myapp:v1 \
  --registry-login-server myacr.azurecr.io \
  --registry-username <username> \
  --registry-password <password> \
  --environment-variables \
    DB_HOST=mydb.postgres.database.azure.com \
    DB_PORT=5432 \
  --secure-environment-variables \
    DB_PASSWORD=SecurePassword123 \
  --cpu 2 \
  --memory 4 \
  --ports 8080

# With Azure Files volume
az container create \
  --resource-group myRG \
  --name myapp \
  --image myapp:v1 \
  --azure-file-volume-account-name mystorageaccount \
  --azure-file-volume-account-key <key> \
  --azure-file-volume-share-name myshare \
  --azure-file-volume-mount-path /data

# View logs
az container logs --resource-group myRG --name mycontainer

# Execute command
az container exec \
  --resource-group myRG \
  --name mycontainer \
  --exec-command "/bin/sh"

# Delete container
az container delete --resource-group myRG --name mycontainer
```

### Multi-Container Groups (Sidecar Pattern)
```yaml
# container-group.yaml
apiVersion: 2021-09-01
location: eastus
name: myapp-group
properties:
  containers:
  - name: app
    properties:
      image: myacr.azurecr.io/myapp:v1
      resources:
        requests:
          cpu: 1.0
          memoryInGB: 1.5
      ports:
      - port: 80
        protocol: TCP
  - name: sidecar-logger
    properties:
      image: fluent/fluentd:latest
      resources:
        requests:
          cpu: 0.5
          memoryInGB: 0.5
      volumeMounts:
      - name: logs
        mountPath: /var/log
  volumes:
  - name: logs
    emptyDir: {}
  osType: Linux
  ipAddress:
    type: Public
    ports:
    - protocol: TCP
      port: 80
  imageRegistryCredentials:
  - server: myacr.azurecr.io
    username: <username>
    password: <password>
```

```bash
az container create --resource-group myRG --file container-group.yaml
```

## Container Security Best Practices

### 1. Image Security
```bash
# Scan for vulnerabilities
docker scan myapp:v1

# Use minimal base images
FROM alpine:3.19
FROM gcr.io/distroless/static-debian12

# Verify image signatures
docker trust sign myacr.azurecr.io/myapp:v1
docker trust inspect myacr.azurecr.io/myapp:v1
```

### 2. Runtime Security
```dockerfile
# Run as non-root
RUN adduser -D -u 1000 appuser
USER appuser

# Read-only filesystem
docker run --read-only -v /tmp:/tmp myapp:v1

# Drop capabilities
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myapp:v1

# Security options
docker run --security-opt=no-new-privileges:true myapp:v1
```

### 3. Secrets Management
```bash
# Use Docker secrets (Swarm)
echo "mypassword" | docker secret create db_password -
docker service create --secret db_password myapp:v1

# Use Azure Key Vault
az keyvault secret set --vault-name mykeyvault --name db-password --value "SecurePass123"

# Mount in container
docker run \
  -e AZURE_CLIENT_ID=<id> \
  -e AZURE_CLIENT_SECRET=<secret> \
  -e AZURE_TENANT_ID=<tenant> \
  myapp:v1
```

## Performance Optimization

### 1. Image Size Reduction
```dockerfile
# Before: 1.2GB
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]

# After: 150MB
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app .
CMD ["node", "server.js"]
```

### 2. Build Cache Optimization
```bash
# Use BuildKit
export DOCKER_BUILDKIT=1
docker build -t myapp:v1 .

# Cache from registry
docker build \
  --cache-from myacr.azurecr.io/myapp:latest \
  -t myapp:v1 .
```

### 3. Resource Limits
```yaml
# docker-compose.yml
services:
  api:
    image: myapp:v1
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

## Troubleshooting

### Common Issues

**Container won't start**
```bash
docker logs <container-id>
docker inspect <container-id>
docker events --filter container=<container-id>
```

**Network connectivity**
```bash
docker network inspect bridge
docker exec myapp ping api
docker exec myapp nslookup api
```

**Performance issues**
```bash
docker stats
docker top <container-id>
docker exec myapp ps aux
```

**Disk space**
```bash
docker system df
docker system prune -a --volumes
docker image prune -a
docker volume prune
```

## Key Exam Topics

✅ Container vs VM differences  
✅ Dockerfile best practices (multi-stage builds)  
✅ Docker networking modes  
✅ Volume management and persistence  
✅ ACR tiers and features  
✅ ACR Tasks for CI/CD  
✅ ACR geo-replication  
✅ Image security and scanning  
✅ ACI use cases and limitations  
✅ Container group patterns  
✅ Integration with AKS  
✅ Private endpoints for ACR  
✅ Managed identity authentication  

---

**© Copyright Sivakumar J**

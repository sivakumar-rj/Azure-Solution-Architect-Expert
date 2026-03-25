# Azure Hands-On Labs - Part 2: AKS, Docker, CI/CD

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Lab 3: Deploy Azure Kubernetes Service (AKS)

### Prerequisites
- Azure CLI installed
- kubectl installed
- Docker installed (for local testing)

### Step 1: Create AKS Cluster (Azure Portal)

#### Navigate to AKS
1. Go to Azure Portal
2. Click **"Create a resource"**
3. Search **"Kubernetes Service"**
4. Click **"Create"**

#### Basics Tab
```
Subscription: Your subscription
Resource group: Create new → "rg-aks-lab-001"
Cluster preset configuration: Dev/Test
Kubernetes cluster name: aks-cluster-001
Region: East US
Availability zones: None
AKS pricing tier: Free
Kubernetes version: 1.28.3 (default)
Automatic upgrade: Enabled with patch
Node security channel type: None
Authentication and Authorization: Local accounts with Kubernetes RBAC
```

#### Node Pools Tab
```
System node pool:
  Node pool name: systempool
  Mode: System
  OS SKU: Ubuntu Linux
  Availability zones: None
  Enable Azure Spot instances: ☐ No
  Node size: Standard_D2s_v3 (2 vCPUs, 8 GB memory)
  Scale method: Manual
  Node count: 3
  Max pods per node: 30
```

#### Networking Tab
```
Network configuration: Azure CNI
Virtual network: Create new
  Name: vnet-aks-001
  Address space: 10.224.0.0/12
  
Subnet: Create new
  Name: subnet-aks-nodes
  Address range: 10.224.0.0/16
  
Kubernetes service address range: 10.0.0.0/16
Kubernetes DNS service IP address: 10.0.0.10
DNS name prefix: aks-cluster-001-dns
Network policy: Azure
Load balancer: Standard
```

#### Integrations Tab
```
Container registry: None (will create later)
Azure Monitor: ☑ Enable Container insights
Log Analytics workspace: Create new → "law-aks-001"
```

#### Review + Create
1. Review all settings
2. Click **"Create"**
3. Wait 10-15 minutes for deployment

### Step 2: Create AKS Cluster (Azure CLI)

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"

# Create resource group
az group create \
  --name rg-aks-lab-001 \
  --location eastus

# Create AKS cluster
az aks create \
  --resource-group rg-aks-lab-001 \
  --name aks-cluster-001 \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --network-plugin azure \
  --enable-managed-identity \
  --generate-ssh-keys \
  --enable-addons monitoring \
  --kubernetes-version 1.28.3 \
  --zones 1 2 3

# This takes 10-15 minutes
```

### Step 3: Connect to AKS Cluster

```bash
# Get credentials
az aks get-credentials \
  --resource-group rg-aks-lab-001 \
  --name aks-cluster-001 \
  --overwrite-existing

# Verify connection
kubectl get nodes

# Expected output:
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-systempool-12345678-vmss000000  Ready    agent   5m    v1.28.3
# aks-systempool-12345678-vmss000001  Ready    agent   5m    v1.28.3
# aks-systempool-12345678-vmss000002  Ready    agent   5m    v1.28.3

# Get cluster info
kubectl cluster-info

# View all resources
kubectl get all --all-namespaces
```

### Step 4: Add User Node Pool

```bash
# Add user node pool
az aks nodepool add \
  --resource-group rg-aks-lab-001 \
  --cluster-name aks-cluster-001 \
  --name userpool \
  --node-count 2 \
  --node-vm-size Standard_D4s_v3 \
  --mode User \
  --zones 1 2 3

# List node pools
az aks nodepool list \
  --resource-group rg-aks-lab-001 \
  --cluster-name aks-cluster-001 \
  --output table

# Scale node pool
az aks nodepool scale \
  --resource-group rg-aks-lab-001 \
  --cluster-name aks-cluster-001 \
  --name userpool \
  --node-count 3
```

### Step 5: Deploy Sample Application

#### Create Namespace
```bash
kubectl create namespace demo-app
```

#### Create Deployment
```bash
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: demo-app
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
EOF

kubectl apply -f deployment.yaml
```

#### Create Service (LoadBalancer)
```bash
cat > service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: demo-app
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
EOF

kubectl apply -f service.yaml
```

#### Verify Deployment
```bash
# Check pods
kubectl get pods -n demo-app

# Check service (wait for EXTERNAL-IP)
kubectl get service -n demo-app

# Get external IP
EXTERNAL_IP=$(kubectl get service nginx-service -n demo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"

# Test application
curl http://$EXTERNAL_IP
```

### Step 6: Configure Ingress Controller

#### Install NGINX Ingress Controller
```bash
# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install ingress controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

# Wait for external IP
kubectl get service -n ingress-nginx --watch
```

#### Create Ingress Resource
```bash
cat > ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: demo-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
EOF

kubectl apply -f ingress.yaml
```

### Step 7: Configure Horizontal Pod Autoscaler

```bash
cat > hpa.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
  namespace: demo-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

kubectl apply -f hpa.yaml

# Check HPA status
kubectl get hpa -n demo-app
```

### Step 8: Enable Cluster Autoscaler

```bash
# Enable cluster autoscaler
az aks update \
  --resource-group rg-aks-lab-001 \
  --name aks-cluster-001 \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Update autoscaler for specific node pool
az aks nodepool update \
  --resource-group rg-aks-lab-001 \
  --cluster-name aks-cluster-001 \
  --name userpool \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10
```

### Step 9: Configure Persistent Storage

#### Create Storage Class
```bash
cat > storageclass.yaml << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-premium-retain
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

kubectl apply -f storageclass.yaml
```

#### Create Persistent Volume Claim
```bash
cat > pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
  namespace: demo-app
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium-retain
  resources:
    requests:
      storage: 10Gi
EOF

kubectl apply -f pvc.yaml

# Check PVC status
kubectl get pvc -n demo-app
```

#### Use PVC in Pod
```bash
cat > pod-with-storage.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-storage
  namespace: demo-app
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: azure-disk-pvc
EOF

kubectl apply -f pod-with-storage.yaml
```

### Step 10: Monitor AKS Cluster

```bash
# View logs
kubectl logs -n demo-app deployment/nginx-deployment

# View events
kubectl get events -n demo-app --sort-by='.lastTimestamp'

# View resource usage
kubectl top nodes
kubectl top pods -n demo-app

# Access Azure Monitor
az aks show \
  --resource-group rg-aks-lab-001 \
  --name aks-cluster-001 \
  --query addonProfiles.omsagent.config.logAnalyticsWorkspaceResourceID \
  --output tsv
```

---

## Lab 4: Docker Containerization

### Step 1: Install Docker

#### On Ubuntu/Linux
```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Step 2: Create Sample Application

#### Node.js Application
```bash
# Create project directory
mkdir -p ~/docker-demo/nodejs-app
cd ~/docker-demo/nodejs-app

# Create package.json
cat > package.json << 'EOF'
{
  "name": "nodejs-docker-app",
  "version": "1.0.0",
  "description": "Sample Node.js app for Docker",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

# Create server.js
cat > server.js << 'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Docker!',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF
```

### Step 3: Create Dockerfile

```bash
cat > Dockerfile << 'EOF'
# Use official Node.js runtime as base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Set environment variable
ENV NODE_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Run application
CMD ["npm", "start"]
EOF
```

### Step 4: Create .dockerignore

```bash
cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.DS_Store
EOF
```

### Step 5: Build Docker Image

```bash
# Build image
docker build -t nodejs-app:1.0 .

# Build with build args
docker build \
  --build-arg NODE_ENV=production \
  --tag nodejs-app:1.0 \
  --tag nodejs-app:latest \
  .

# List images
docker images

# Inspect image
docker inspect nodejs-app:1.0

# View image history
docker history nodejs-app:1.0
```

### Step 6: Run Docker Container

```bash
# Run container
docker run -d \
  --name nodejs-app-container \
  -p 8080:3000 \
  -e NODE_ENV=production \
  nodejs-app:1.0

# List running containers
docker ps

# View logs
docker logs nodejs-app-container

# Follow logs
docker logs -f nodejs-app-container

# Test application
curl http://localhost:8080

# Execute command in container
docker exec nodejs-app-container ls -la /app

# Interactive shell
docker exec -it nodejs-app-container sh

# Stop container
docker stop nodejs-app-container

# Start container
docker start nodejs-app-container

# Remove container
docker rm -f nodejs-app-container
```

### Step 7: Docker Compose

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    build: .
    image: nodejs-app:1.0
    container_name: nodejs-web
    ports:
      - "8080:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    restart: unless-stopped
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - web
    networks:
      - app-network
    restart: unless-stopped

networks:
  app-network:
    driver: bridge
EOF

# Create nginx config
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream nodejs_app {
        server web:3000;
    }

    server {
        listen 80;
        
        location / {
            proxy_pass http://nodejs_app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
EOF

# Start services
docker compose up -d

# View logs
docker compose logs -f

# List services
docker compose ps

# Stop services
docker compose down

# Stop and remove volumes
docker compose down -v
```

### Step 8: Push to Azure Container Registry

```bash
# Create ACR
az acr create \
  --resource-group rg-aks-lab-001 \
  --name acrlabregistry001 \
  --sku Basic \
  --location eastus

# Login to ACR
az acr login --name acrlabregistry001

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show \
  --name acrlabregistry001 \
  --query loginServer \
  --output tsv)

echo $ACR_LOGIN_SERVER

# Tag image
docker tag nodejs-app:1.0 ${ACR_LOGIN_SERVER}/nodejs-app:1.0
docker tag nodejs-app:1.0 ${ACR_LOGIN_SERVER}/nodejs-app:latest

# Push image
docker push ${ACR_LOGIN_SERVER}/nodejs-app:1.0
docker push ${ACR_LOGIN_SERVER}/nodejs-app:latest

# List images in ACR
az acr repository list \
  --name acrlabregistry001 \
  --output table

# Show image tags
az acr repository show-tags \
  --name acrlabregistry001 \
  --repository nodejs-app \
  --output table
```

### Step 9: Attach ACR to AKS

```bash
# Attach ACR to AKS
az aks update \
  --resource-group rg-aks-lab-001 \
  --name aks-cluster-001 \
  --attach-acr acrlabregistry001

# Verify attachment
az aks check-acr \
  --resource-group rg-aks-lab-001 \
  --name aks-cluster-001 \
  --acr acrlabregistry001.azurecr.io
```

### Step 10: Deploy to AKS from ACR

```bash
cat > deployment-from-acr.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
  namespace: demo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs-app
  template:
    metadata:
      labels:
        app: nodejs-app
    spec:
      containers:
      - name: nodejs-app
        image: ${ACR_LOGIN_SERVER}/nodejs-app:1.0
        ports:
        - containerPort: 3000
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: nodejs-app-service
  namespace: demo-app
spec:
  type: LoadBalancer
  selector:
    app: nodejs-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
EOF

kubectl apply -f deployment-from-acr.yaml

# Check deployment
kubectl get pods -n demo-app
kubectl get service -n demo-app
```

---

*This document continues with Labs 5-9 covering CI/CD Pipeline, Code Deployment, CDN, MySQL, and Complete Deployment...*

**© Copyright Sivakumar J**

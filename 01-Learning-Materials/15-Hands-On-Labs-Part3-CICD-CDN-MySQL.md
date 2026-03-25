# Azure Hands-On Labs - Part 3: CI/CD, CDN, MySQL, Complete Deployment

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Lab 5: CI/CD Pipeline with Azure DevOps

### Step 1: Create Azure DevOps Organization

1. Go to https://dev.azure.com
2. Sign in with Azure account
3. Click **"Create new organization"**
4. Organization name: `your-org-name`
5. Region: Select closest region
6. Click **"Continue"**

### Step 2: Create Project

1. Click **"+ New project"**
2. Project name: `nodejs-webapp`
3. Visibility: Private
4. Version control: Git
5. Work item process: Agile
6. Click **"Create"**

### Step 3: Initialize Repository

```bash
# Clone repository
git clone https://your-org-name@dev.azure.com/your-org-name/nodejs-webapp/_git/nodejs-webapp
cd nodejs-webapp

# Copy application files
cp -r ~/docker-demo/nodejs-app/* .

# Commit and push
git add .
git commit -m "Initial commit"
git push origin main
```

### Step 4: Create Service Connection

1. Go to **Project Settings** → **Service connections**
2. Click **"New service connection"**
3. Select **"Azure Resource Manager"**
4. Authentication method: **Service principal (automatic)**
5. Scope level: **Subscription**
6. Subscription: Select your subscription
7. Resource group: `rg-aks-lab-001`
8. Service connection name: `azure-connection`
9. Grant access to all pipelines: ☑
10. Click **"Save"**

### Step 5: Create Build Pipeline (YAML)

```bash
# Create azure-pipelines.yml
cat > azure-pipelines.yml << 'EOF'
trigger:
  branches:
    include:
    - main
  paths:
    exclude:
    - README.md
    - docs/*

variables:
  dockerRegistryServiceConnection: 'azure-connection'
  imageRepository: 'nodejs-app'
  containerRegistry: 'acrlabregistry001.azurecr.io'
  dockerfilePath: '$(Build.SourcesDirectory)/Dockerfile'
  tag: '$(Build.BuildId)'
  vmImageName: 'ubuntu-latest'

stages:
- stage: Build
  displayName: Build and Push
  jobs:
  - job: Build
    displayName: Build
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: Docker@2
      displayName: Build and push image
      inputs:
        command: buildAndPush
        repository: $(imageRepository)
        dockerfile: $(dockerfilePath)
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(tag)
          latest

    - task: PublishPipelineArtifact@1
      displayName: Publish Kubernetes manifests
      inputs:
        targetPath: '$(Build.SourcesDirectory)/k8s'
        artifact: 'manifests'
        publishLocation: 'pipeline'

- stage: Deploy
  displayName: Deploy to AKS
  dependsOn: Build
  jobs:
  - deployment: Deploy
    displayName: Deploy
    pool:
      vmImage: $(vmImageName)
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'manifests'
              downloadPath: '$(System.ArtifactsDirectory)/manifests'

          - task: KubernetesManifest@0
            displayName: Deploy to Kubernetes
            inputs:
              action: 'deploy'
              kubernetesServiceConnection: 'aks-connection'
              namespace: 'demo-app'
              manifests: |
                $(System.ArtifactsDirectory)/manifests/deployment.yaml
                $(System.ArtifactsDirectory)/manifests/service.yaml
              containers: |
                $(containerRegistry)/$(imageRepository):$(tag)
EOF

# Create k8s directory
mkdir -p k8s

# Create deployment manifest
cat > k8s/deployment.yaml << 'EOF'
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
        version: v1
    spec:
      containers:
      - name: nodejs-app
        image: acrlabregistry001.azurecr.io/nodejs-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
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
EOF

# Create service manifest
cat > k8s/service.yaml << 'EOF'
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

# Commit and push
git add .
git commit -m "Add CI/CD pipeline"
git push origin main
```

### Step 6: Create Kubernetes Service Connection

1. Go to **Project Settings** → **Service connections**
2. Click **"New service connection"**
3. Select **"Kubernetes"**
4. Authentication method: **Azure Subscription**
5. Subscription: Select your subscription
6. Cluster: `aks-cluster-001`
7. Namespace: `demo-app`
8. Service connection name: `aks-connection`
9. Click **"Save"**

### Step 7: Run Pipeline

1. Go to **Pipelines** → **Pipelines**
2. Click **"New pipeline"**
3. Select **"Azure Repos Git"**
4. Select your repository
5. Select **"Existing Azure Pipelines YAML file"**
6. Path: `/azure-pipelines.yml`
7. Click **"Continue"**
8. Click **"Run"**

### Step 8: Create Release Pipeline (Classic)

1. Go to **Pipelines** → **Releases**
2. Click **"New pipeline"**
3. Select **"Empty job"**
4. Stage name: `Development`

#### Add Artifact
1. Click **"Add an artifact"**
2. Source type: **Build**
3. Project: `nodejs-webapp`
4. Source: Select your build pipeline
5. Default version: **Latest**
6. Click **"Add"**

#### Configure Stage
1. Click **"1 job, 0 task"** in Development stage
2. Click **"+"** on Agent job
3. Search and add **"Kubectl"** task
4. Configure:
   - Service connection: `aks-connection`
   - Namespace: `demo-app`
   - Command: `apply`
   - Arguments: `-f $(System.DefaultWorkingDirectory)/_nodejs-webapp/manifests/`

#### Enable Continuous Deployment
1. Click lightning icon on artifact
2. Enable **"Continuous deployment trigger"**
3. Add branch filter: `main`

### Step 9: Multi-Stage Pipeline with Environments

```yaml
# azure-pipelines-multistage.yml
trigger:
  branches:
    include:
    - main
    - develop

variables:
  dockerRegistryServiceConnection: 'azure-connection'
  imageRepository: 'nodejs-app'
  containerRegistry: 'acrlabregistry001.azurecr.io'
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: Build
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '18.x'
      displayName: 'Install Node.js'

    - script: |
        npm install
        npm test
      displayName: 'npm install and test'

    - task: Docker@2
      displayName: 'Build and push image'
      inputs:
        command: buildAndPush
        repository: $(imageRepository)
        dockerfile: '$(Build.SourcesDirectory)/Dockerfile'
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(tag)
          latest

- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
  jobs:
  - deployment: DeployDev
    displayName: 'Deploy to Dev'
    environment: 'development'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: 'Deploy to Dev namespace'
            inputs:
              action: 'deploy'
              kubernetesServiceConnection: 'aks-connection'
              namespace: 'dev'
              manifests: |
                $(Pipeline.Workspace)/manifests/deployment.yaml
                $(Pipeline.Workspace)/manifests/service.yaml

- stage: DeployProd
  displayName: 'Deploy to Production'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployProd
    displayName: 'Deploy to Production'
    environment: 'production'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: 'Deploy to Prod namespace'
            inputs:
              action: 'deploy'
              kubernetesServiceConnection: 'aks-connection'
              namespace: 'prod'
              manifests: |
                $(Pipeline.Workspace)/manifests/deployment.yaml
                $(Pipeline.Workspace)/manifests/service.yaml
```

---

## Lab 6: Code Deployment Strategies

### Blue-Green Deployment

```yaml
# blue-green-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app-blue
  namespace: demo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs-app
      version: blue
  template:
    metadata:
      labels:
        app: nodejs-app
        version: blue
    spec:
      containers:
      - name: nodejs-app
        image: acrlabregistry001.azurecr.io/nodejs-app:1.0
        ports:
        - containerPort: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app-green
  namespace: demo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs-app
      version: green
  template:
    metadata:
      labels:
        app: nodejs-app
        version: green
    spec:
      containers:
      - name: nodejs-app
        image: acrlabregistry001.azurecr.io/nodejs-app:2.0
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: nodejs-app-service
  namespace: demo-app
spec:
  selector:
    app: nodejs-app
    version: blue  # Switch to 'green' for cutover
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
```

### Canary Deployment

```yaml
# canary-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app-stable
  namespace: demo-app
spec:
  replicas: 9
  selector:
    matchLabels:
      app: nodejs-app
      track: stable
  template:
    metadata:
      labels:
        app: nodejs-app
        track: stable
    spec:
      containers:
      - name: nodejs-app
        image: acrlabregistry001.azurecr.io/nodejs-app:1.0
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app-canary
  namespace: demo-app
spec:
  replicas: 1  # 10% traffic
  selector:
    matchLabels:
      app: nodejs-app
      track: canary
  template:
    metadata:
      labels:
        app: nodejs-app
        track: canary
    spec:
      containers:
      - name: nodejs-app
        image: acrlabregistry001.azurecr.io/nodejs-app:2.0
---
apiVersion: v1
kind: Service
metadata:
  name: nodejs-app-service
  namespace: demo-app
spec:
  selector:
    app: nodejs-app  # Routes to both stable and canary
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
```

### Rolling Update

```bash
# Update deployment with new image
kubectl set image deployment/nodejs-app \
  nodejs-app=acrlabregistry001.azurecr.io/nodejs-app:2.0 \
  -n demo-app

# Check rollout status
kubectl rollout status deployment/nodejs-app -n demo-app

# View rollout history
kubectl rollout history deployment/nodejs-app -n demo-app

# Rollback to previous version
kubectl rollout undo deployment/nodejs-app -n demo-app

# Rollback to specific revision
kubectl rollout undo deployment/nodejs-app --to-revision=2 -n demo-app
```

---

## Lab 7: Azure CDN Setup

### Step 1: Create CDN Profile (Portal)

1. Go to Azure Portal
2. Click **"Create a resource"**
3. Search **"CDN"**
4. Click **"Front Door and CDN profiles"**
5. Click **"Create"**

#### Configure CDN
```
Offering: Azure CDN
Resource group: rg-cdn-lab-001
Name: cdn-profile-webapp
Pricing tier: Standard Microsoft
Create new endpoint: ☑ Yes
CDN endpoint name: webapp-cdn-001
Origin type: Storage static website
Origin hostname: stlabdata001.z13.web.core.windows.net
```

### Step 2: Create CDN Profile (CLI)

```bash
# Create resource group
az group create \
  --name rg-cdn-lab-001 \
  --location eastus

# Create CDN profile
az cdn profile create \
  --resource-group rg-cdn-lab-001 \
  --name cdn-profile-webapp \
  --sku Standard_Microsoft \
  --location global

# Create CDN endpoint
az cdn endpoint create \
  --resource-group rg-cdn-lab-001 \
  --profile-name cdn-profile-webapp \
  --name webapp-cdn-001 \
  --origin stlabdata001.z13.web.core.windows.net \
  --origin-host-header stlabdata001.z13.web.core.windows.net \
  --enable-compression true \
  --content-types-to-compress \
    "text/plain" \
    "text/html" \
    "text/css" \
    "application/javascript" \
    "application/json"
```

### Step 3: Configure Custom Domain

```bash
# Add custom domain
az cdn custom-domain create \
  --resource-group rg-cdn-lab-001 \
  --profile-name cdn-profile-webapp \
  --endpoint-name webapp-cdn-001 \
  --name webapp-custom \
  --hostname www.yourdomain.com

# Enable HTTPS
az cdn custom-domain enable-https \
  --resource-group rg-cdn-lab-001 \
  --profile-name cdn-profile-webapp \
  --endpoint-name webapp-cdn-001 \
  --name webapp-custom
```

### Step 4: Configure Caching Rules

```bash
# Create caching rule
az cdn endpoint rule add \
  --resource-group rg-cdn-lab-001 \
  --profile-name cdn-profile-webapp \
  --endpoint-name webapp-cdn-001 \
  --order 1 \
  --rule-name CacheImages \
  --match-variable UrlFileExtension \
  --operator Equal \
  --match-values jpg png gif \
  --action-name CacheExpiration \
  --cache-behavior Override \
  --cache-duration 7.00:00:00
```

### Step 5: Purge CDN Cache

```bash
# Purge all content
az cdn endpoint purge \
  --resource-group rg-cdn-lab-001 \
  --profile-name cdn-profile-webapp \
  --name webapp-cdn-001 \
  --content-paths '/*'

# Purge specific paths
az cdn endpoint purge \
  --resource-group rg-cdn-lab-001 \
  --profile-name cdn-profile-webapp \
  --name webapp-cdn-001 \
  --content-paths '/images/*' '/css/style.css'
```

---

## Lab 8: Azure Database for MySQL

### Step 1: Create MySQL Flexible Server (Portal)

1. Go to Azure Portal
2. Click **"Create a resource"**
3. Search **"Azure Database for MySQL"**
4. Select **"Flexible Server"**
5. Click **"Create"**

#### Basics
```
Subscription: Your subscription
Resource group: Create new → "rg-mysql-lab-001"
Server name: mysql-server-webapp-001
Region: East US
MySQL version: 8.0
Workload type: Development
Compute + storage: Burstable, B1ms (1 vCore, 2 GiB RAM)
Storage: 20 GiB
Backup retention: 7 days
Admin username: mysqladmin
Password: <strong-password>
```

### Step 2: Create MySQL Server (CLI)

```bash
# Create resource group
az group create \
  --name rg-mysql-lab-001 \
  --location eastus

# Create MySQL Flexible Server
az mysql flexible-server create \
  --resource-group rg-mysql-lab-001 \
  --name mysql-server-webapp-001 \
  --location eastus \
  --admin-user mysqladmin \
  --admin-password 'YourStrongPassword123!' \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 8.0 \
  --storage-size 20 \
  --backup-retention 7 \
  --high-availability Disabled \
  --public-access 0.0.0.0-255.255.255.255

# Get connection string
az mysql flexible-server show-connection-string \
  --server-name mysql-server-webapp-001 \
  --database-name mydb \
  --admin-user mysqladmin \
  --admin-password 'YourStrongPassword123!'
```

### Step 3: Configure Firewall Rules

```bash
# Add firewall rule for your IP
az mysql flexible-server firewall-rule create \
  --resource-group rg-mysql-lab-001 \
  --name mysql-server-webapp-001 \
  --rule-name AllowMyIP \
  --start-ip-address <YOUR_IP> \
  --end-ip-address <YOUR_IP>

# Allow Azure services
az mysql flexible-server firewall-rule create \
  --resource-group rg-mysql-lab-001 \
  --name mysql-server-webapp-001 \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Step 4: Create Database and Tables

```bash
# Connect to MySQL
mysql -h mysql-server-webapp-001.mysql.database.azure.com \
  -u mysqladmin \
  -p

# Create database
CREATE DATABASE webapp_db;
USE webapp_db;

# Create users table
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

# Create products table
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  stock INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# Insert sample data
INSERT INTO users (username, email) VALUES
  ('john_doe', 'john@example.com'),
  ('jane_smith', 'jane@example.com');

INSERT INTO products (name, description, price, stock) VALUES
  ('Product 1', 'Description 1', 29.99, 100),
  ('Product 2', 'Description 2', 49.99, 50);

# Verify
SELECT * FROM users;
SELECT * FROM products;
```

### Step 5: Connect from Application

```javascript
// app-with-mysql.js
const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
app.use(express.json());

// MySQL connection pool
const pool = mysql.createPool({
  host: 'mysql-server-webapp-001.mysql.database.azure.com',
  user: 'mysqladmin',
  password: 'YourStrongPassword123!',
  database: 'webapp_db',
  ssl: {
    rejectUnauthorized: true
  },
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Get all users
app.get('/api/users', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM users');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all products
app.get('/api/products', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM products');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create user
app.post('/api/users', async (req, res) => {
  try {
    const { username, email } = req.body;
    const [result] = await pool.query(
      'INSERT INTO users (username, email) VALUES (?, ?)',
      [username, email]
    );
    res.status(201).json({ id: result.insertId, username, email });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

### Step 6: Configure High Availability

```bash
# Enable zone-redundant HA
az mysql flexible-server update \
  --resource-group rg-mysql-lab-001 \
  --name mysql-server-webapp-001 \
  --high-availability ZoneRedundant \
  --standby-zone 2
```

### Step 7: Configure Backup and Restore

```bash
# List backups
az mysql flexible-server backup list \
  --resource-group rg-mysql-lab-001 \
  --name mysql-server-webapp-001

# Restore to point in time
az mysql flexible-server restore \
  --resource-group rg-mysql-lab-001 \
  --name mysql-server-webapp-001-restored \
  --source-server mysql-server-webapp-001 \
  --restore-time "2026-03-25T08:00:00Z"
```

---

## Lab 9: Complete Web Application Deployment

### Architecture Overview
```
Internet → Azure Front Door → AKS (with Ingress) → Application Pods → MySQL Database
                           ↓
                      Azure CDN (Static Assets)
                           ↓
                      Blob Storage
```

### Step 1: Deploy Complete Application

```bash
# Create namespace
kubectl create namespace production

# Create secret for MySQL
kubectl create secret generic mysql-secret \
  --from-literal=host='mysql-server-webapp-001.mysql.database.azure.com' \
  --from-literal=user='mysqladmin' \
  --from-literal=password='YourStrongPassword123!' \
  --from-literal=database='webapp_db' \
  -n production
```

### Step 2: Deploy Application

```yaml
# complete-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: acrlabregistry001.azurecr.io/nodejs-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: host
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: user
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: database
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
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
  name: webapp-service
  namespace: production
spec:
  selector:
    app: webapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - webapp.yourdomain.com
    secretName: webapp-tls
  rules:
  - host: webapp.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Step 3: Apply Configuration

```bash
kubectl apply -f complete-deployment.yaml

# Verify deployment
kubectl get all -n production
kubectl get ingress -n production
```

### Verification and Testing

```bash
# Test application
curl https://webapp.yourdomain.com/api/users
curl https://webapp.yourdomain.com/api/products

# Load test
kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://webapp-service.production.svc.cluster.local; done"

# Monitor HPA
kubectl get hpa -n production --watch

# View logs
kubectl logs -f deployment/webapp -n production

# Check metrics
kubectl top pods -n production
kubectl top nodes
```

### Cleanup All Resources

```bash
# Delete AKS cluster
az aks delete --resource-group rg-aks-lab-001 --name aks-cluster-001 --yes --no-wait

# Delete MySQL server
az mysql flexible-server delete --resource-group rg-mysql-lab-001 --name mysql-server-webapp-001 --yes

# Delete resource groups
az group delete --name rg-aks-lab-001 --yes --no-wait
az group delete --name rg-mysql-lab-001 --yes --no-wait
az group delete --name rg-cdn-lab-001 --yes --no-wait
az group delete --name rg-storage-lab-001 --yes --no-wait
az group delete --name rg-vm-lab-001 --yes --no-wait
```

---

**© Copyright Sivakumar J**

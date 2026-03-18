# AKS Hands-On Labs & Practice Scenarios

## Lab 1: Deploy Multi-Tier Application on AKS

### Objective
Deploy a complete 3-tier application with frontend, API, and database on AKS with proper networking and security.

### Architecture
```
Internet → Azure LB → NGINX Ingress → Frontend (React)
                                    → API (Node.js)
                                    → Database (PostgreSQL StatefulSet)
```

### Step-by-Step Implementation

**1. Create AKS Cluster**
```bash
# Variables
RG="aks-lab-rg"
LOCATION="eastus"
CLUSTER_NAME="lab-aks-cluster"
ACR_NAME="labacr$RANDOM"

# Create resource group
az group create --name $RG --location $LOCATION

# Create ACR
az acr create --resource-group $RG --name $ACR_NAME --sku Standard

# Create AKS with ACR integration
az aks create \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --network-plugin azure \
  --enable-managed-identity \
  --attach-acr $ACR_NAME \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group $RG --name $CLUSTER_NAME
```

**2. Deploy PostgreSQL Database**
```yaml
# postgres-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  POSTGRES_USER: appuser
  POSTGRES_PASSWORD: SecureP@ssw0rd123
  POSTGRES_DB: appdb
---
# postgres-statefulset.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        envFrom:
        - secretRef:
            name: postgres-secret
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: managed-csi
      resources:
        requests:
          storage: 10Gi
```

**3. Deploy API Service**
```yaml
# api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        version: v1
    spec:
      containers:
      - name: api
        image: <your-acr>.azurecr.io/api:v1
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_HOST
          value: postgres
        - name: DATABASE_PORT
          value: "5432"
        - name: DATABASE_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_USER
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        - name: DATABASE_NAME
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_DB
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
```

**4. Deploy Frontend**
```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: <your-acr>.azurecr.io/frontend:v1
        ports:
        - containerPort: 80
        env:
        - name: API_URL
          value: http://api-service
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

**5. Configure Ingress**
```bash
# Install NGINX Ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

**6. Deploy Everything**
```bash
kubectl apply -f postgres-secret.yaml
kubectl apply -f postgres-statefulset.yaml
kubectl apply -f api-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml

# Wait for external IP
kubectl get svc -n ingress-nginx --watch
```

**7. Test Application**
```bash
EXTERNAL_IP=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP
curl http://$EXTERNAL_IP/api/health
```

---

## Lab 2: Implement Autoscaling (HPA + Cluster Autoscaler)

### Objective
Configure horizontal pod autoscaling and cluster autoscaling for dynamic workload management.

**1. Enable Metrics Server**
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**2. Deploy Sample Application**
```yaml
# php-apache.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  ports:
  - port: 80
  selector:
    app: php-apache
```

**3. Create HPA**
```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

**4. Enable Cluster Autoscaler**
```bash
az aks update \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10
```

**5. Generate Load**
```bash
kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

**6. Monitor Autoscaling**
```bash
# Watch HPA
kubectl get hpa php-apache-hpa --watch

# Watch pods
kubectl get pods -l app=php-apache --watch

# Watch nodes
kubectl get nodes --watch

# Check HPA details
kubectl describe hpa php-apache-hpa
```

---

## Lab 3: Secure AKS with Azure AD and Key Vault

### Objective
Implement Azure AD authentication and integrate Azure Key Vault for secrets management.

**1. Enable Azure AD Integration**
```bash
az aks update \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --enable-aad \
  --enable-azure-rbac
```

**2. Create Azure AD Group and Assign Role**
```bash
# Create AD group
AKS_ADMIN_GROUP=$(az ad group create --display-name AKSAdmins --mail-nickname AKSAdmins --query id -o tsv)

# Get AKS resource ID
AKS_ID=$(az aks show --resource-group $RG --name $CLUSTER_NAME --query id -o tsv)

# Assign role
az role assignment create \
  --assignee $AKS_ADMIN_GROUP \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope $AKS_ID
```

**3. Create Key Vault**
```bash
KV_NAME="aks-kv-$RANDOM"
az keyvault create \
  --name $KV_NAME \
  --resource-group $RG \
  --location $LOCATION

# Add secrets
az keyvault secret set --vault-name $KV_NAME --name DatabasePassword --value "SecureP@ssw0rd123"
az keyvault secret set --vault-name $KV_NAME --name ApiKey --value "api-key-12345"
```

**4. Enable Workload Identity**
```bash
az aks update \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --enable-oidc-issuer \
  --enable-workload-identity

# Get OIDC issuer URL
OIDC_ISSUER=$(az aks show -n $CLUSTER_NAME -g $RG --query "oidcIssuerProfile.issuerUrl" -o tsv)
```

**5. Create Managed Identity**
```bash
IDENTITY_NAME="aks-workload-identity"
az identity create --name $IDENTITY_NAME --resource-group $RG

# Get identity details
IDENTITY_CLIENT_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RG --query clientId -o tsv)
IDENTITY_PRINCIPAL_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RG --query principalId -o tsv)

# Grant Key Vault access
az keyvault set-policy \
  --name $KV_NAME \
  --object-id $IDENTITY_PRINCIPAL_ID \
  --secret-permissions get list
```

**6. Create Service Account and Federated Credential**
```bash
# Create namespace
kubectl create namespace secure-app

# Create service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-identity-sa
  namespace: secure-app
  annotations:
    azure.workload.identity/client-id: $IDENTITY_CLIENT_ID
EOF

# Create federated credential
az identity federated-credential create \
  --name aks-federated-credential \
  --identity-name $IDENTITY_NAME \
  --resource-group $RG \
  --issuer $OIDC_ISSUER \
  --subject system:serviceaccount:secure-app:workload-identity-sa
```

**7. Install CSI Secrets Driver**
```bash
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm install csi csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system
```

**8. Create SecretProviderClass**
```yaml
# secret-provider.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-sync
  namespace: secure-app
spec:
  provider: azure
  secretObjects:
  - secretName: app-secrets
    type: Opaque
    data:
    - objectName: DatabasePassword
      key: db-password
    - objectName: ApiKey
      key: api-key
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"
    clientID: "$IDENTITY_CLIENT_ID"
    keyvaultName: "$KV_NAME"
    cloudName: ""
    objects: |
      array:
        - |
          objectName: DatabasePassword
          objectType: secret
        - |
          objectName: ApiKey
          objectType: secret
    tenantId: "$(az account show --query tenantId -o tsv)"
```

**9. Deploy Application with Secrets**
```yaml
# secure-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: workload-identity-sa
      containers:
      - name: app
        image: nginx:alpine
        volumeMounts:
        - name: secrets-store
          mountPath: "/mnt/secrets"
          readOnly: true
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db-password
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api-key
      volumes:
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: azure-keyvault-sync
```

**10. Verify Secrets**
```bash
kubectl apply -f secret-provider.yaml
kubectl apply -f secure-app.yaml

# Check pod
kubectl get pods -n secure-app

# Verify secrets mounted
kubectl exec -it -n secure-app <pod-name> -- ls /mnt/secrets

# Check environment variables
kubectl exec -it -n secure-app <pod-name> -- env | grep -E 'DB_PASSWORD|API_KEY'
```

---

## Lab 4: Implement CI/CD Pipeline with GitHub Actions

### Objective
Create automated CI/CD pipeline to build, push, and deploy applications to AKS.

**1. GitHub Actions Workflow**
```yaml
# .github/workflows/deploy-to-aks.yml
name: Build and Deploy to AKS

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  AZURE_RESOURCE_GROUP: aks-lab-rg
  AKS_CLUSTER_NAME: lab-aks-cluster
  ACR_NAME: labacr12345
  IMAGE_NAME: myapp
  NAMESPACE: production

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Build and push image to ACR
      run: |
        az acr build \
          --registry ${{ env.ACR_NAME }} \
          --image ${{ env.IMAGE_NAME }}:${{ github.sha }} \
          --image ${{ env.IMAGE_NAME }}:latest \
          --file Dockerfile .
    
    - name: Get AKS credentials
      run: |
        az aks get-credentials \
          --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
          --name ${{ env.AKS_CLUSTER_NAME }} \
          --overwrite-existing
    
    - name: Deploy to AKS
      run: |
        kubectl set image deployment/myapp \
          myapp=${{ env.ACR_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${{ github.sha }} \
          -n ${{ env.NAMESPACE }}
        
        kubectl rollout status deployment/myapp -n ${{ env.NAMESPACE }}
    
    - name: Verify deployment
      run: |
        kubectl get pods -n ${{ env.NAMESPACE }}
        kubectl get svc -n ${{ env.NAMESPACE }}
```

**2. Create Azure Service Principal**
```bash
# Create service principal
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG \
  --sdk-auth)

echo $SP_OUTPUT
# Add this JSON to GitHub Secrets as AZURE_CREDENTIALS
```

**3. Kubernetes Manifests**
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: labacr12345.azurecr.io/myapp:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
  namespace: production
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

---

## Lab 5: Monitoring with Prometheus and Grafana

### Objective
Set up comprehensive monitoring stack with Prometheus and Grafana.

**1. Install Prometheus Stack**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.adminPassword=admin123
```

**2. Expose Grafana**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80
# Access: http://localhost:3000 (admin/admin123)
```

**3. Create Custom ServiceMonitor**
```yaml
# app-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-metrics
  namespace: monitoring
  labels:
    release: kube-prometheus
spec:
  selector:
    matchLabels:
      app: myapp
  namespaceSelector:
    matchNames:
    - production
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

**4. Sample Application with Metrics**
```javascript
// app.js (Node.js with Prometheus metrics)
const express = require('express');
const promClient = require('prom-client');

const app = express();
const register = new promClient.Registry();

// Default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.listen(8080, () => console.log('Server running on port 8080'));
```

**5. Create Grafana Dashboard**
```json
{
  "dashboard": {
    "title": "AKS Application Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_request_duration_seconds_count[5m])"
          }
        ]
      },
      {
        "title": "Pod CPU Usage",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"production\"}[5m])) by (pod)"
          }
        ]
      }
    ]
  }
}
```

---

## Practice Scenarios for AZ-305

### Scenario 1: High Availability E-Commerce Platform
**Requirements:**
- Multi-region deployment
- 99.99% uptime SLA
- Auto-scaling based on traffic
- Secure payment processing
- Real-time inventory updates

**Solution Design:**
- Azure Front Door for global load balancing
- AKS clusters in 2 regions (active-active)
- Azure Cosmos DB (multi-region writes)
- Azure Cache for Redis (geo-replication)
- Azure Service Bus for async processing
- Application Gateway with WAF
- Azure Key Vault for secrets
- Pod autoscaling (HPA) + Cluster autoscaling

### Scenario 2: Microservices Migration
**Requirements:**
- Migrate monolith to microservices
- Zero downtime migration
- Service-to-service authentication
- Distributed tracing
- Gradual rollout

**Solution Design:**
- Strangler pattern implementation
- Istio service mesh for mTLS
- Canary deployments with Flagger
- Jaeger for distributed tracing
- Azure API Management as gateway
- GitOps with Flux CD
- Blue-green deployment strategy

### Scenario 3: Batch Processing Platform
**Requirements:**
- Process millions of records daily
- Cost optimization
- Event-driven scaling
- Job scheduling
- Failure handling

**Solution Design:**
- KEDA for event-driven autoscaling
- Azure Service Bus queues
- Spot node pools for cost savings
- CronJobs for scheduled tasks
- Dead letter queues for failures
- Azure Monitor for job tracking
- Horizontal pod autoscaling

---

## Quick Reference Commands

```bash
# Cluster Management
az aks get-credentials -g $RG -n $CLUSTER
az aks scale -g $RG -n $CLUSTER --node-count 5
az aks upgrade -g $RG -n $CLUSTER --kubernetes-version 1.28.0

# Debugging
kubectl get events --sort-by='.lastTimestamp'
kubectl logs <pod> -f --previous
kubectl exec -it <pod> -- /bin/sh
kubectl describe pod <pod>
kubectl top nodes
kubectl top pods

# Networking
kubectl get svc,ep,ing
kubectl port-forward svc/<service> 8080:80
kubectl run tmp --rm -i --tty --image=nicolaka/netshoot

# Troubleshooting
kubectl get pods --field-selector=status.phase!=Running
kubectl get pods --all-namespaces | grep -v Running
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
```

---

**© Copyright Sivakumar J**

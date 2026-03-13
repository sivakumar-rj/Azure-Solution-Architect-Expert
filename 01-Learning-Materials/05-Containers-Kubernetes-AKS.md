# Containers, Docker, and Azure Kubernetes Service (AKS)

## Docker Fundamentals

### Docker Concepts
- **Image:** Read-only template with application and dependencies
- **Container:** Running instance of an image
- **Dockerfile:** Instructions to build an image
- **Registry:** Repository for storing images (Docker Hub, ACR)

### Sample Dockerfile
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

### Docker Commands
```bash
docker build -t myapp:v1 .
docker run -p 8080:3000 myapp:v1
docker push myregistry.azurecr.io/myapp:v1
docker ps
docker logs <container-id>
```

## Azure Container Registry (ACR)

### Features
- Private Docker registry
- Geo-replication
- Image scanning (security)
- Webhook integration
- Azure AD authentication

### SKUs
- **Basic:** Low volume, dev/test
- **Standard:** Production workloads
- **Premium:** Geo-replication, content trust, private link

### ACR Tasks
```bash
# Build image in Azure
az acr build --registry myacr --image myapp:v1 .

# Automated builds on git commit
az acr task create --registry myacr --name buildtask \
  --image myapp:{{.Run.ID}} \
  --context https://github.com/user/repo.git \
  --file Dockerfile --git-access-token <token>
```

## Kubernetes Fundamentals

### Core Concepts

**Pod:** Smallest deployable unit (one or more containers)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

**Deployment:** Manages replica sets and rolling updates
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: myacr.azurecr.io/webapp:v1
        ports:
        - containerPort: 80
```

**Service:** Network endpoint for pods
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
```

**ConfigMap:** Configuration data
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "mongodb://db:27017"
  log_level: "info"
```

**Secret:** Sensitive data (base64 encoded)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=
```

### Kubernetes Architecture

**Control Plane:**
- API Server
- etcd (key-value store)
- Scheduler
- Controller Manager

**Worker Nodes:**
- Kubelet (node agent)
- Container Runtime (Docker/containerd)
- Kube-proxy (networking)

## Azure Kubernetes Service (AKS)

### Key Features
- **Managed Control Plane:** Azure manages master nodes (free)
- **Automatic Upgrades:** Kubernetes version updates
- **Scaling:** Manual, horizontal pod autoscaler, cluster autoscaler
- **Azure Integration:** ACR, Azure AD, Azure Monitor, Key Vault
- **Networking:** kubenet, Azure CNI, Calico
- **Security:** Azure Policy, Pod Security, RBAC

### AKS Cluster Creation
```bash
# Create resource group
az group create --name myResourceGroup --location eastus

# Create AKS cluster
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 3 \
  --enable-managed-identity \
  --network-plugin azure \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster

# Verify connection
kubectl get nodes
```

### Node Pools

**System Node Pool:**
- Critical system pods
- Minimum 1 node
- Recommended: Standard_DS2_v2 or larger

**User Node Pool:**
- Application workloads
- Can scale to zero
- Different VM sizes per pool

```bash
# Add user node pool
az aks nodepool add \
  --resource-group myResourceGroup \
  --cluster-name myAKSCluster \
  --name userpool \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3
```

### AKS Networking

**kubenet (Basic):**
- Nodes get VNet IP
- Pods get IP from separate CIDR
- NAT for outbound traffic
- Lower IP consumption

**Azure CNI (Advanced):**
- Pods get VNet IP directly
- Direct connectivity to VNet resources
- Higher IP consumption
- Required for Windows nodes

**Network Policy:**
- Calico
- Azure Network Policy

### AKS Scaling

**Manual Scaling:**
```bash
kubectl scale deployment web-app --replicas=5
az aks scale --resource-group myRG --name myAKS --node-count 5
```

**Horizontal Pod Autoscaler (HPA):**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Cluster Autoscaler:**
```bash
az aks update \
  --resource-group myRG \
  --name myAKS \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 10
```

### AKS Security

**Azure AD Integration:**
```bash
az aks create \
  --resource-group myRG \
  --name myAKS \
  --enable-aad \
  --enable-azure-rbac
```

**Pod Identity:**
```bash
# Enable pod identity
az aks update \
  --resource-group myRG \
  --name myAKS \
  --enable-pod-identity

# Create identity
az identity create --resource-group myRG --name myPodIdentity

# Assign to pod
az aks pod-identity add \
  --resource-group myRG \
  --cluster-name myAKS \
  --namespace default \
  --name myPodIdentity \
  --identity-resource-id <identity-id>
```

**Azure Key Vault Integration:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: myapp:v1
    volumeMounts:
    - name: secrets
      mountPath: "/mnt/secrets"
      readOnly: true
  volumes:
  - name: secrets
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "azure-keyvault"
```

### AKS Monitoring

**Azure Monitor for Containers:**
- Container logs
- Performance metrics
- Live logs
- Recommended alerts

**Prometheus & Grafana:**
```bash
# Enable monitoring addon
az aks enable-addons \
  --resource-group myRG \
  --name myAKS \
  --addons monitoring
```

### AKS Best Practices

**Resource Management:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

**Health Checks:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Pod Disruption Budget:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web
```

## Container Services Comparison

| Service | Use Case | Management | Orchestration |
|---------|----------|------------|---------------|
| **AKS** | Microservices, complex apps | Medium | Kubernetes |
| **Container Instances** | Simple containers, batch jobs | Low | None |
| **App Service (Containers)** | Web apps, APIs | Very Low | Built-in |
| **Container Apps** | Microservices, event-driven | Low | KEDA |
| **Azure Red Hat OpenShift** | Enterprise Kubernetes | Low | OpenShift |

## Common kubectl Commands

```bash
# Get resources
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get nodes

# Describe resources
kubectl describe pod <pod-name>
kubectl describe node <node-name>

# Logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs
kubectl logs <pod-name> -c <container-name>  # Multi-container pod

# Execute commands
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec <pod-name> -- ls /app

# Apply configurations
kubectl apply -f deployment.yaml
kubectl apply -f https://example.com/config.yaml

# Delete resources
kubectl delete pod <pod-name>
kubectl delete deployment <deployment-name>
kubectl delete -f deployment.yaml

# Port forwarding
kubectl port-forward pod/<pod-name> 8080:80

# Scaling
kubectl scale deployment <name> --replicas=5

# Rolling updates
kubectl set image deployment/<name> container=image:v2
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>

# Context and config
kubectl config get-contexts
kubectl config use-context <context-name>
kubectl config set-context --current --namespace=<namespace>
```

## Helm Package Manager

### Helm Basics
```bash
# Add repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search charts
helm search repo nginx

# Install chart
helm install my-nginx bitnami/nginx

# List releases
helm list

# Upgrade release
helm upgrade my-nginx bitnami/nginx --set replicaCount=3

# Uninstall
helm uninstall my-nginx
```

### Custom Helm Chart Structure
```
mychart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
```

## AKS Architecture Patterns

### Microservices Pattern
```
Internet
    ↓
Azure Front Door / Application Gateway
    ↓
AKS Ingress Controller (NGINX/App Gateway Ingress)
    ↓
├─ Service A (Deployment + Service)
├─ Service B (Deployment + Service)
└─ Service C (Deployment + Service)
    ↓
Azure SQL / Cosmos DB / Storage
```

### CI/CD Pipeline
```
GitHub/Azure DevOps
    ↓
Build Docker Image
    ↓
Push to ACR
    ↓
Update Kubernetes Manifest
    ↓
Deploy to AKS (kubectl apply / Helm)
    ↓
Health Check & Monitoring
```

## Key Takeaways

✅ Use ACR for private container registry  
✅ Implement Azure CNI for production workloads  
✅ Enable cluster autoscaler for dynamic workloads  
✅ Use system and user node pools  
✅ Integrate with Azure AD for authentication  
✅ Store secrets in Azure Key Vault  
✅ Set resource requests and limits  
✅ Implement health checks (liveness/readiness)  
✅ Use Helm for package management  
✅ Enable Azure Monitor for observability  
✅ Implement pod disruption budgets for HA  
✅ Use namespaces for resource isolation

## Practice Scenarios

**Scenario 1:** Deploy a 3-tier application on AKS with Azure CNI  
**Scenario 2:** Implement CI/CD pipeline with ACR and AKS  
**Scenario 3:** Configure autoscaling (HPA + Cluster Autoscaler)  
**Scenario 4:** Secure AKS with Azure AD and Key Vault  
**Scenario 5:** Monitor AKS cluster with Azure Monitor and Prometheus

---

**© Copyright Sivakumar J - All Rights Reserved**

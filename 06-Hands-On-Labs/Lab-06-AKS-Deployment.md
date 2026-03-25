# Lab 06: AKS Deployment

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure CLI with kubectl
- Basic Docker knowledge
- Understanding of Kubernetes concepts

## Objective
Deploy and manage Azure Kubernetes Service (AKS) cluster.

---

## Method 1: Azure Portal

### Step 1: Create AKS Cluster
1. Navigate to Azure Portal
2. Search "Kubernetes services" → Click "Create"
3. **Basics tab:**
   - Resource group: Create new → `rg-aks-lab`
   - Cluster name: `aks-lab-cluster`
   - Region: `East US`
   - Kubernetes version: `1.28.x` (latest stable)
   - Node size: `Standard_B2s`
   - Scale method: `Manual`
   - Node count: `2`
4. **Node pools tab:**
   - Keep default settings
5. **Networking tab:**
   - Network configuration: `kubenet`
   - DNS name prefix: `aks-lab`
6. Click "Review + Create" → "Create" (takes 5-10 minutes)

### Step 2: Connect to Cluster
1. Go to AKS cluster → "Overview"
2. Click "Connect"
3. Run commands in Cloud Shell or local terminal

---

## Method 2: Azure CLI

```bash
# Create resource group
az group create --name rg-aks-lab-cli --location eastus

# Create AKS cluster
az aks create \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --generate-ssh-keys \
  --network-plugin kubenet \
  --kubernetes-version 1.28

# Get credentials
az aks get-credentials \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster

# Verify connection
kubectl get nodes
kubectl cluster-info
```

---

## Deploy Application to AKS

### Simple Nginx Deployment

**deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
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
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

**service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

### Deploy
```bash
# Apply deployment
kubectl apply -f deployment.yaml

# Apply service
kubectl apply -f service.yaml

# Check deployment
kubectl get deployments
kubectl get pods
kubectl get services

# Get external IP (wait for EXTERNAL-IP)
kubectl get service nginx-service --watch

# Test application
curl http://<EXTERNAL-IP>
```

---

## Scale Application

```bash
# Scale deployment
kubectl scale deployment nginx-deployment --replicas=5

# Verify
kubectl get pods

# Autoscale based on CPU
kubectl autoscale deployment nginx-deployment \
  --cpu-percent=50 \
  --min=3 \
  --max=10

# Check HPA
kubectl get hpa
```

---

## Update Application

```bash
# Update image
kubectl set image deployment/nginx-deployment nginx=nginx:1.25

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# View rollout history
kubectl rollout history deployment/nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# Rollback to specific revision
kubectl rollout undo deployment/nginx-deployment --to-revision=1
```

---

## Configure Ingress Controller

```bash
# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Verify installation
kubectl get pods -n ingress-nginx

# Get ingress controller IP
kubectl get service -n ingress-nginx
```

**ingress.yaml**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
```

```bash
# Apply ingress
kubectl apply -f ingress.yaml

# Check ingress
kubectl get ingress
```

---

## Configure Persistent Storage

**pvc.yaml**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-csi
  resources:
    requests:
      storage: 5Gi
```

**pod-with-pvc.yaml**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-disk
spec:
  containers:
  - name: nginx
    image: nginx:latest
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: azure-disk-pvc
```

```bash
# Apply PVC
kubectl apply -f pvc.yaml

# Check PVC
kubectl get pvc

# Apply pod
kubectl apply -f pod-with-pvc.yaml

# Verify
kubectl exec -it nginx-with-disk -- df -h
```

---

## Configure ConfigMap and Secrets

```bash
# Create ConfigMap
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info

# Create Secret
kubectl create secret generic app-secret \
  --from-literal=DB_PASSWORD=mysecretpassword

# View ConfigMap
kubectl get configmap app-config -o yaml

# View Secret
kubectl get secret app-secret -o yaml
```

**deployment-with-config.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: nginx:latest
        env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_ENV
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: DB_PASSWORD
```

---

## Monitor AKS Cluster

```bash
# Enable monitoring
az aks enable-addons \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --addons monitoring

# View cluster metrics
kubectl top nodes
kubectl top pods

# View logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs
kubectl logs <pod-name> --previous  # Previous container logs
```

---

## Upgrade AKS Cluster

```bash
# Check available versions
az aks get-upgrades \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --output table

# Upgrade cluster
az aks upgrade \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --kubernetes-version 1.29.0

# Check upgrade status
az aks show \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --query kubernetesVersion
```

---

## Verification Steps

```bash
# Check cluster health
kubectl get componentstatuses
kubectl get nodes
kubectl get pods --all-namespaces

# Test DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

---

## Troubleshooting

**Issue: Pods not starting**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events
```

**Issue: Service not accessible**
```bash
kubectl get endpoints
kubectl describe service <service-name>
```

**Issue: Node not ready**
```bash
kubectl describe node <node-name>
az aks show --resource-group <RG> --name <CLUSTER>
```

---

## Cleanup

```bash
# Delete deployments
kubectl delete deployment nginx-deployment
kubectl delete service nginx-service

# Delete cluster
az aks delete \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --yes --no-wait

# Delete resource group
az group delete --name rg-aks-lab-cli --yes --no-wait
```

---

## Key Takeaways
- AKS provides managed Kubernetes service
- Supports multiple node pools and scaling
- Integrated with Azure services (Monitor, ACR, Key Vault)
- Automatic upgrades and patching available
- Use kubectl for cluster management
- LoadBalancer service type creates Azure Load Balancer
- Persistent storage via Azure Disks and Files

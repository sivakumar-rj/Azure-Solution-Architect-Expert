# AKS Advanced Deep Dive - Production-Ready Kubernetes

## Advanced AKS Networking

### Network Topology Options

**Hub-Spoke with AKS**
```
Hub VNet (10.0.0.0/16)
├── Azure Firewall (10.0.1.0/24)
├── VPN Gateway (10.0.2.0/24)
└── Bastion (10.0.3.0/24)
    ↓ VNet Peering
Spoke VNet (10.1.0.0/16)
├── AKS System Pool (10.1.0.0/22)
├── AKS User Pool (10.1.4.0/22)
└── Private Endpoints (10.1.8.0/24)
```

### Private AKS Cluster
```bash
az aks create \
  --resource-group myRG \
  --name privateAKS \
  --enable-private-cluster \
  --private-dns-zone system \
  --network-plugin azure \
  --vnet-subnet-id /subscriptions/.../subnets/aks-subnet \
  --docker-bridge-address 172.17.0.1/16 \
  --service-cidr 10.2.0.0/16 \
  --dns-service-ip 10.2.0.10
```

### Ingress Controllers

**NGINX Ingress**
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

**Application Gateway Ingress Controller (AGIC)**
```bash
az aks enable-addons \
  --resource-group myRG \
  --name myAKS \
  --addons ingress-appgw \
  --appgw-name myAppGateway \
  --appgw-subnet-id /subscriptions/.../subnets/appgw-subnet
```

**Ingress Resource**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - app.example.com
    secretName: tls-secret
  rules:
  - host: app.example.com
    http:
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

### Network Policies

**Deny All Traffic**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Allow Specific Traffic**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

## Advanced Storage Solutions

### Storage Classes

**Azure Disk (Premium SSD)**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-premium-retain
provisioner: disk.csi.azure.com
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

**Azure Files (SMB)**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile-premium
provisioner: file.csi.azure.com
parameters:
  skuName: Premium_LRS
  protocol: smb
mountOptions:
  - dir_mode=0777
  - file_mode=0777
  - uid=0
  - gid=0
  - mfsymlinks
  - cache=strict
  - actimeo=30
```

### Persistent Volume Claims

**StatefulSet with Persistent Storage**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  serviceName: mongodb
  replicas: 3
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:6.0
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: data
          mountPath: /data/db
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: password
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: managed-premium-retain
      resources:
        requests:
          storage: 100Gi
```

### Azure Blob CSI Driver
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: blob-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: blob-storage
  csi:
    driver: blob.csi.azure.com
    volumeHandle: unique-volumeid
    volumeAttributes:
      containerName: mycontainer
      storageAccount: mystorageaccount
    nodeStageSecretRef:
      name: azure-storage-secret
      namespace: default
```

## Advanced Security & Identity

### Workload Identity (Recommended over Pod Identity)
```bash
# Enable workload identity
az aks update \
  --resource-group myRG \
  --name myAKS \
  --enable-oidc-issuer \
  --enable-workload-identity

# Create managed identity
az identity create \
  --resource-group myRG \
  --name myWorkloadIdentity

# Create service account
kubectl create serviceaccount workload-sa --namespace default

# Federate identity
az identity federated-credential create \
  --name myFederatedIdentity \
  --identity-name myWorkloadIdentity \
  --resource-group myRG \
  --issuer $(az aks show -n myAKS -g myRG --query "oidcIssuerProfile.issuerUrl" -o tsv) \
  --subject system:serviceaccount:default:workload-sa
```

**Pod with Workload Identity**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-identity
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-sa
  containers:
  - name: app
    image: myapp:v1
    env:
    - name: AZURE_CLIENT_ID
      value: "<managed-identity-client-id>"
```

### Azure Key Vault Secrets Provider

**Install CSI Driver**
```bash
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm install csi csi-secrets-store-provider-azure/csi-secrets-store-provider-azure
```

**SecretProviderClass**
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-sync
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
    clientID: "<workload-identity-client-id>"
    keyvaultName: mykeyvault
    cloudName: ""
    objects: |
      array:
        - |
          objectName: DatabasePassword
          objectType: secret
          objectVersion: ""
        - |
          objectName: ApiKey
          objectType: secret
          objectVersion: ""
    tenantId: "<tenant-id>"
```

### Pod Security Standards

**Restricted Policy**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

**Security Context**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: myapp:v1
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

### Azure Policy for AKS

**Built-in Policies**
- Enforce HTTPS ingress
- Require resource limits
- Block privileged containers
- Enforce image sources (ACR only)
- Require labels

```bash
# Assign policy
az policy assignment create \
  --name 'aks-policy' \
  --display-name 'AKS Security Policies' \
  --scope /subscriptions/<sub-id>/resourceGroups/myRG \
  --policy-set-definition '/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d'
```

## GitOps with Flux/ArgoCD

### Flux Installation
```bash
# Install Flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Bootstrap Flux
flux bootstrap github \
  --owner=myorg \
  --repository=fleet-infra \
  --branch=main \
  --path=clusters/production \
  --personal
```

**GitRepository Source**
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: app-repo
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/myorg/myapp
  ref:
    branch: main
```

**Kustomization**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: app-deployment
  namespace: flux-system
spec:
  interval: 5m
  path: ./deploy/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: app-repo
  healthChecks:
  - apiVersion: apps/v1
    kind: Deployment
    name: web-app
    namespace: production
```

## Advanced Monitoring & Observability

### Prometheus & Grafana Stack
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi
```

### ServiceMonitor for Custom Metrics
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: web-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Azure Monitor Integration
```bash
# Enable Container Insights
az aks enable-addons \
  --resource-group myRG \
  --name myAKS \
  --addons monitoring \
  --workspace-resource-id /subscriptions/.../workspaces/myWorkspace
```

**Custom Metrics**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: container-azm-ms-agentconfig
  namespace: kube-system
data:
  schema-version: v1
  config-version: ver1
  prometheus-data-collection-settings: |-
    [prometheus_data_collection_settings.cluster]
    interval = "1m"
    [prometheus_data_collection_settings.node]
    interval = "1m"
```

### Distributed Tracing with Jaeger
```bash
kubectl create namespace observability
kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/deploy/crds/jaegertracing.io_jaegers_crd.yaml
kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/deploy/service_account.yaml
kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/deploy/role.yaml
kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/deploy/role_binding.yaml
kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/deploy/operator.yaml
```

## Service Mesh with Istio/Linkerd

### Istio Installation
```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=production -y
kubectl label namespace default istio-injection=enabled
```

**Virtual Service**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: web-app-route
spec:
  hosts:
  - app.example.com
  gateways:
  - web-gateway
  http:
  - match:
    - uri:
        prefix: /api/v2
    route:
    - destination:
        host: api-service
        subset: v2
      weight: 90
    - destination:
        host: api-service
        subset: v1
      weight: 10
  - route:
    - destination:
        host: api-service
        subset: v1
```

**Destination Rule**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-service-dr
spec:
  host: api-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

## Multi-Cluster & Multi-Region

### Azure Arc-enabled Kubernetes
```bash
# Connect cluster to Azure Arc
az connectedk8s connect \
  --name myAKSCluster \
  --resource-group myRG

# Enable GitOps
az k8s-configuration flux create \
  --name cluster-config \
  --cluster-name myAKSCluster \
  --resource-group myRG \
  --cluster-type connectedClusters \
  --url https://github.com/myorg/fleet-infra \
  --branch main \
  --kustomization name=apps path=./apps prune=true
```

### Multi-Region Active-Active
```
Azure Traffic Manager / Front Door
    ↓
├── Region 1 (East US)
│   ├── AKS Cluster 1
│   ├── Cosmos DB (multi-region write)
│   └── Azure Cache for Redis (geo-replication)
│
└── Region 2 (West Europe)
    ├── AKS Cluster 2
    ├── Cosmos DB (multi-region write)
    └── Azure Cache for Redis (geo-replication)
```

## Cost Optimization

### Spot Node Pools
```bash
az aks nodepool add \
  --resource-group myRG \
  --cluster-name myAKS \
  --name spotnodepool \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 10 \
  --node-vm-size Standard_D4s_v3 \
  --node-taints kubernetes.azure.com/scalesetpriority=spot:NoSchedule
```

**Toleration for Spot Nodes**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-processor
spec:
  replicas: 5
  template:
    spec:
      tolerations:
      - key: kubernetes.azure.com/scalesetpriority
        operator: Equal
        value: spot
        effect: NoSchedule
      nodeSelector:
        kubernetes.azure.com/scalesetpriority: spot
      containers:
      - name: processor
        image: myapp:v1
```

### Vertical Pod Autoscaler (VPA)
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  updatePolicy:
    updateMode: Auto
  resourcePolicy:
    containerPolicies:
    - containerName: web
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2
        memory: 2Gi
```

### KEDA (Event-driven Autoscaling)
```bash
helm repo add kedacore https://kedacore.github.io/charts
helm install keda kedacore/keda --namespace keda --create-namespace
```

**ScaledObject for Azure Service Bus**
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: servicebus-scaler
spec:
  scaleTargetRef:
    name: message-processor
  minReplicaCount: 0
  maxReplicaCount: 30
  triggers:
  - type: azure-servicebus
    metadata:
      queueName: orders
      namespace: myservicebus
      messageCount: "5"
    authenticationRef:
      name: servicebus-auth
```

## Disaster Recovery & Backup

### Velero Backup
```bash
# Install Velero
velero install \
  --provider azure \
  --plugins velero/velero-plugin-for-microsoft-azure:v1.8.0 \
  --bucket velero-backups \
  --secret-file ./credentials-velero \
  --backup-location-config resourceGroup=myRG,storageAccount=velerobackups \
  --snapshot-location-config apiTimeout=5m,resourceGroup=myRG

# Create backup
velero backup create full-backup --include-namespaces production

# Schedule daily backups
velero schedule create daily-backup --schedule="0 2 * * *" --include-namespaces production

# Restore
velero restore create --from-backup full-backup
```

## Production Checklist

### Pre-Production
- [ ] Enable Azure CNI networking
- [ ] Configure private cluster
- [ ] Set up system and user node pools
- [ ] Enable cluster autoscaler
- [ ] Configure Azure AD integration
- [ ] Set up workload identity
- [ ] Integrate Azure Key Vault
- [ ] Enable Azure Policy
- [ ] Configure network policies
- [ ] Set up ingress controller with TLS
- [ ] Enable Azure Monitor for Containers
- [ ] Configure Prometheus/Grafana
- [ ] Set up GitOps (Flux/ArgoCD)
- [ ] Configure backup with Velero
- [ ] Implement pod security standards
- [ ] Set resource quotas per namespace
- [ ] Configure pod disruption budgets
- [ ] Enable diagnostic logs
- [ ] Set up alerts and dashboards
- [ ] Document runbooks

### Security Hardening
- [ ] Disable public API server access
- [ ] Enable authorized IP ranges
- [ ] Use private ACR with private endpoints
- [ ] Scan images for vulnerabilities
- [ ] Implement least privilege RBAC
- [ ] Enable audit logging
- [ ] Use read-only root filesystem
- [ ] Drop all capabilities
- [ ] Run as non-root user
- [ ] Enable seccomp profiles
- [ ] Implement network policies
- [ ] Use secrets encryption at rest
- [ ] Enable Azure Defender for Kubernetes

### Performance Optimization
- [ ] Set appropriate resource requests/limits
- [ ] Configure HPA for applications
- [ ] Enable VPA for right-sizing
- [ ] Use node affinity/anti-affinity
- [ ] Implement pod topology spread
- [ ] Configure connection pooling
- [ ] Enable HTTP/2 and gRPC
- [ ] Use CDN for static assets
- [ ] Implement caching strategies
- [ ] Optimize container images
- [ ] Use multi-stage Docker builds
- [ ] Enable compression

## Real-World Architecture Example

### E-Commerce Platform on AKS
```
Azure Front Door (Global Load Balancing)
    ↓
Application Gateway (WAF + SSL Termination)
    ↓
AKS Cluster (Azure CNI + Private)
├── Ingress: NGINX Ingress Controller
├── Frontend: React SPA (3 replicas, HPA)
├── API Gateway: Kong/Ambassador (2 replicas)
├── Microservices:
│   ├── Product Service (StatefulSet, 3 replicas)
│   ├── Order Service (Deployment, HPA 2-10)
│   ├── Payment Service (Deployment, 3 replicas)
│   ├── Inventory Service (Deployment, HPA 2-8)
│   └── Notification Service (KEDA, 0-20 replicas)
├── Message Queue: Azure Service Bus
├── Cache: Azure Cache for Redis (Premium)
├── Database: Azure SQL (Business Critical)
├── Storage: Azure Blob Storage (Hot tier)
├── Search: Azure Cognitive Search
├── Monitoring: Azure Monitor + Prometheus + Grafana
├── Logging: Azure Log Analytics + Fluentd
├── Tracing: Jaeger
└── Service Mesh: Istio (mTLS, traffic management)

External Services:
├── Azure Key Vault (secrets)
├── Azure AD (authentication)
├── Azure CDN (static assets)
├── Azure Cosmos DB (product catalog)
└── Azure Event Grid (event-driven workflows)
```

## Troubleshooting Guide

### Common Issues

**Pods in Pending State**
```bash
kubectl describe pod <pod-name>
# Check: Insufficient resources, node selector mismatch, PVC binding issues
```

**ImagePullBackOff**
```bash
kubectl describe pod <pod-name>
# Check: ACR authentication, image name/tag, network connectivity
```

**CrashLoopBackOff**
```bash
kubectl logs <pod-name> --previous
# Check: Application errors, missing dependencies, health check failures
```

**Node NotReady**
```bash
kubectl describe node <node-name>
az aks show -g myRG -n myAKS --query agentPoolProfiles
# Check: VM issues, network problems, kubelet errors
```

**DNS Resolution Issues**
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
# Check: CoreDNS pods, network policies, DNS configuration
```

## Key Exam Topics

✅ AKS networking models (kubenet vs Azure CNI)  
✅ Node pool types and scaling strategies  
✅ Ingress controllers and load balancing  
✅ Storage options (Azure Disk, Files, Blob)  
✅ Identity and access management (Azure AD, Workload Identity)  
✅ Security (Network Policies, Pod Security, Azure Policy)  
✅ Monitoring and logging (Azure Monitor, Prometheus)  
✅ GitOps and CI/CD integration  
✅ Multi-cluster management with Azure Arc  
✅ Cost optimization (Spot nodes, autoscaling, KEDA)  
✅ Disaster recovery and backup strategies  
✅ Service mesh concepts (Istio/Linkerd)

---

**© Copyright Sivakumar J**

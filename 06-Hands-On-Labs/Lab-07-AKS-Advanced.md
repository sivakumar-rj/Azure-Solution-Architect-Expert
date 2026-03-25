# Lab 07: AKS Advanced

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Completed Lab 06 (AKS Deployment)
- Azure Container Registry (ACR)
- Understanding of Kubernetes advanced concepts

## Objective
Implement advanced AKS features: ACR integration, RBAC, network policies, and service mesh.

---

## Azure Container Registry Integration

### Create ACR
```bash
# Create ACR
az acr create \
  --resource-group rg-aks-lab-cli \
  --name acrlabunique123 \
  --sku Basic

# Attach ACR to AKS
az aks update \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --attach-acr acrlabunique123

# Login to ACR
az acr login --name acrlabunique123

# Build and push image
docker build -t acrlabunique123.azurecr.io/myapp:v1 .
docker push acrlabunique123.azurecr.io/myapp:v1

# Or build directly in ACR
az acr build \
  --registry acrlabunique123 \
  --image myapp:v1 \
  --file Dockerfile .
```

### Deploy from ACR
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
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
        image: acrlabunique123.azurecr.io/myapp:v1
        ports:
        - containerPort: 3000
```

---

## Configure RBAC

### Create Service Account
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: default
```

### Create Role and RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Azure AD Integration
```bash
# Enable Azure AD integration
az aks update \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --enable-aad \
  --aad-admin-group-object-ids <GROUP_ID>

# Get credentials with Azure AD
az aks get-credentials \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --overwrite-existing

# Test access
kubectl get nodes
```

---

## Network Policies

### Enable Network Policy
```bash
# Create AKS with Azure Network Policy
az aks create \
  --resource-group rg-aks-lab-cli \
  --name aks-network-policy \
  --network-plugin azure \
  --network-policy azure \
  --node-count 2
```

### Deny All Traffic
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Allow Specific Traffic
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

---

## Implement Namespaces and Resource Quotas

### Create Namespace
```bash
kubectl create namespace dev
kubectl create namespace prod
```

### Resource Quota
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "10"
```

### Limit Range
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-limits
  namespace: dev
spec:
  limits:
  - max:
      cpu: "2"
      memory: 2Gi
    min:
      cpu: "100m"
      memory: 128Mi
    default:
      cpu: "500m"
      memory: 512Mi
    defaultRequest:
      cpu: "250m"
      memory: 256Mi
    type: Container
```

---

## Configure Pod Identity

```bash
# Enable pod identity
az aks update \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --enable-pod-identity \
  --enable-pod-identity-with-kubenet

# Create managed identity
az identity create \
  --resource-group rg-aks-lab-cli \
  --name pod-identity-example

# Get identity details
IDENTITY_CLIENT_ID=$(az identity show \
  --resource-group rg-aks-lab-cli \
  --name pod-identity-example \
  --query clientId -o tsv)

IDENTITY_RESOURCE_ID=$(az identity show \
  --resource-group rg-aks-lab-cli \
  --name pod-identity-example \
  --query id -o tsv)

# Create pod identity
az aks pod-identity add \
  --resource-group rg-aks-lab-cli \
  --cluster-name aks-lab-cluster \
  --namespace default \
  --name pod-identity-example \
  --identity-resource-id $IDENTITY_RESOURCE_ID
```

---

## Implement Azure Key Vault Integration

```bash
# Enable Key Vault provider
az aks enable-addons \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --addons azure-keyvault-secrets-provider

# Create Key Vault
az keyvault create \
  --resource-group rg-aks-lab-cli \
  --name kv-aks-lab-unique \
  --location eastus

# Add secret
az keyvault secret set \
  --vault-name kv-aks-lab-unique \
  --name db-password \
  --value "MySecretPassword123"

# Grant AKS access
az keyvault set-policy \
  --name kv-aks-lab-unique \
  --object-id <AKS_IDENTITY_OBJECT_ID> \
  --secret-permissions get
```

**SecretProviderClass**
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: <IDENTITY_CLIENT_ID>
    keyvaultName: kv-aks-lab-unique
    objects: |
      array:
        - |
          objectName: db-password
          objectType: secret
          objectVersion: ""
    tenantId: <TENANT_ID>
```

**Pod using Key Vault**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-keyvault
spec:
  containers:
  - name: app
    image: nginx:latest
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
        secretProviderClass: azure-keyvault
```

---

## Configure Cluster Autoscaler

```bash
# Enable cluster autoscaler
az aks update \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Update autoscaler settings
az aks update \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --update-cluster-autoscaler \
  --min-count 2 \
  --max-count 10

# Disable autoscaler
az aks update \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --disable-cluster-autoscaler
```

---

## Implement StatefulSets

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
  - port: 3306
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
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

---

## Configure DaemonSets

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:latest
        ports:
        - containerPort: 9100
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
```

---

## Implement Jobs and CronJobs

**Job**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  template:
    spec:
      containers:
      - name: migration
        image: busybox
        command: ["sh", "-c", "echo Migration complete && sleep 30"]
      restartPolicy: Never
  backoffLimit: 4
```

**CronJob**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox
            command: ["sh", "-c", "echo Backup complete"]
          restartPolicy: OnFailure
```

---

## Verification Steps

```bash
# Check network policies
kubectl get networkpolicies

# Check resource quotas
kubectl describe quota -n dev

# Check pod identity
kubectl get azureidentity
kubectl get azureidentitybinding

# Check autoscaler
kubectl get nodes
kubectl describe configmap cluster-autoscaler-status -n kube-system
```

---

## Troubleshooting

**Issue: ACR pull fails**
```bash
az aks check-acr \
  --resource-group rg-aks-lab-cli \
  --name aks-lab-cluster \
  --acr acrlabunique123.azurecr.io
```

**Issue: Network policy blocking traffic**
```bash
kubectl describe networkpolicy <policy-name>
kubectl logs <pod-name>
```

**Issue: Pod identity not working**
```bash
kubectl describe azureidentity
kubectl logs -n kube-system -l component=mic
```

---

## Cleanup

```bash
kubectl delete all --all -n default
az group delete --name rg-aks-lab-cli --yes --no-wait
```

---

## Key Takeaways
- ACR integration simplifies image management
- RBAC provides fine-grained access control
- Network policies secure pod communication
- Pod identity enables Azure service access
- Key Vault integration secures secrets
- Cluster autoscaler optimizes resource usage
- StatefulSets manage stateful applications
- DaemonSets run on every node

# Real-World Use Cases and Scenarios

## Use Case 1: E-Commerce Platform (Multi-Tier Architecture)

### Business Requirements
- Global customer base (US, Europe, Asia)
- 10 million users, peak 50K concurrent
- 99.99% availability required
- Sub-second response time
- PCI DSS compliance for payments
- Black Friday traffic spikes (10x normal)

### Architecture Solution

```
                    Azure Front Door (Global Load Balancer)
                              ↓
        ┌─────────────────────┼─────────────────────┐
        ↓                     ↓                     ↓
    Region 1 (US)        Region 2 (EU)        Region 3 (Asia)
        
Web Tier:
    App Service Premium (Auto-scale 3-20 instances)
    - React/Angular frontend
    - CDN for static assets
        ↓
Application Tier:
    AKS Cluster (3 node pools)
    ├─ Product Service (5-50 pods)
    ├─ Cart Service (3-30 pods)
    ├─ Order Service (5-40 pods)
    ├─ Payment Service (3-20 pods)
    └─ Inventory Service (3-20 pods)
        ↓
API Gateway:
    Azure API Management (Premium tier)
    - Rate limiting
    - OAuth 2.0
    - Request/response caching
        ↓
Data Tier:
    ├─ Azure SQL Database (Business Critical, geo-replicated)
    │  - Orders, Users, Transactions
    ├─ Cosmos DB (Multi-region writes)
    │  - Product catalog, Shopping carts
    ├─ Azure Cache for Redis (Premium)
    │  - Session state, Product cache
    └─ Blob Storage (RA-GZRS)
       - Product images, Documents
        ↓
Integration:
    ├─ Service Bus Premium (Queues/Topics)
    │  - Order processing, Email notifications
    ├─ Event Grid
    │  - Inventory updates, Price changes
    └─ Azure Functions (Premium)
       - Image processing, Report generation
```

### Implementation Details

**Web Tier Configuration:**
```bash
# App Service with auto-scale
az appservice plan create \
  --name ecommerce-plan \
  --resource-group ecommerce-rg \
  --sku P2V3 \
  --is-linux

az webapp create \
  --name ecommerce-web \
  --plan ecommerce-plan \
  --resource-group ecommerce-rg

# Auto-scale rule
az monitor autoscale create \
  --resource-group ecommerce-rg \
  --resource ecommerce-plan \
  --min-count 3 \
  --max-count 20 \
  --count 5

az monitor autoscale rule create \
  --resource-group ecommerce-rg \
  --autoscale-name ecommerce-autoscale \
  --condition "Percentage CPU > 75 avg 5m" \
  --scale out 3
```

**AKS Microservices Deployment:**
```yaml
# Product Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
spec:
  replicas: 5
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      containers:
      - name: product-api
        image: ecommerceacr.azurecr.io/product-service:v2.1
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        env:
        - name: COSMOS_DB_ENDPOINT
          valueFrom:
            secretKeyRef:
              name: cosmos-secret
              key: endpoint
        - name: REDIS_HOST
          value: "ecommerce-redis.redis.cache.windows.net"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
---
# HPA for Product Service
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: product-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-service
  minReplicas: 5
  maxReplicas: 50
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
```

**Database Configuration:**
```sql
-- Azure SQL Database (Business Critical)
-- Auto-failover group for DR
CREATE DATABASE EcommerceDB
  (EDITION = 'BusinessCritical',
   SERVICE_OBJECTIVE = 'BC_Gen5_8',
   MAXSIZE = 500GB);

-- Enable geo-replication
-- Primary: East US
-- Secondary: West Europe, Southeast Asia
```

### Cost Estimate (Monthly)
- App Service Premium: $300 x 3 regions = $900
- AKS (15 nodes avg): $1,500 x 3 = $4,500
- Azure SQL Business Critical: $3,000 x 3 = $9,000
- Cosmos DB (100K RU/s): $6,000
- Redis Premium: $1,200
- Front Door: $500
- API Management Premium: $3,000
- Storage & Bandwidth: $2,000
**Total: ~$27,000/month**

---

## Use Case 2: Healthcare SaaS Platform (Compliance & Security)

### Business Requirements
- HIPAA compliance mandatory
- Multi-tenant architecture
- 500 healthcare organizations
- PHI (Protected Health Information) storage
- Audit logging for all data access
- 99.95% availability SLA
- Data residency requirements

### Architecture Solution

```
Internet
    ↓
Azure Front Door + WAF (OWASP rules)
    ↓
Application Gateway (WAF enabled)
    ↓
AKS Private Cluster (Private endpoint)
├─ Tenant Isolation (Namespace per tenant)
├─ Patient Portal Service
├─ Provider Portal Service
├─ Appointment Service
├─ Medical Records Service
└─ Billing Service
    ↓
Private Endpoints
    ↓
├─ Azure SQL Managed Instance (VNet integrated)
│  - Encrypted at rest (TDE)
│  - Always Encrypted for PHI columns
│  - Auditing enabled
├─ Blob Storage (Private endpoint)
│  - Medical images, Documents
│  - Immutable storage for compliance
└─ Key Vault (Private endpoint)
   - Encryption keys, Certificates, Secrets
    ↓
Monitoring & Compliance:
├─ Azure Monitor + Log Analytics
├─ Azure Sentinel (SIEM)
├─ Azure Policy (HIPAA compliance)
└─ Microsoft Defender for Cloud
```

### Security Implementation

**Network Security:**
```bash
# Create private AKS cluster
az aks create \
  --resource-group healthcare-rg \
  --name healthcare-aks \
  --enable-private-cluster \
  --network-plugin azure \
  --vnet-subnet-id /subscriptions/.../subnets/aks-subnet \
  --enable-managed-identity \
  --enable-azure-rbac \
  --enable-aad

# NSG rules (deny all inbound by default)
az network nsg rule create \
  --resource-group healthcare-rg \
  --nsg-name healthcare-nsg \
  --name DenyAllInbound \
  --priority 4096 \
  --direction Inbound \
  --access Deny
```

**Data Encryption:**
```sql
-- Always Encrypted for PHI data
CREATE COLUMN MASTER KEY CMK_Auto1
WITH (
  KEY_STORE_PROVIDER_NAME = 'AZURE_KEY_VAULT',
  KEY_PATH = 'https://healthcare-kv.vault.azure.net/keys/CMK/...'
);

CREATE COLUMN ENCRYPTION KEY CEK_Auto1
WITH VALUES (
  COLUMN_MASTER_KEY = CMK_Auto1,
  ALGORITHM = 'RSA_OAEP'
);

-- Encrypt sensitive columns
ALTER TABLE Patients
ALTER COLUMN SSN ADD ENCRYPTED WITH (
  COLUMN_ENCRYPTION_KEY = CEK_Auto1,
  ENCRYPTION_TYPE = Deterministic,
  ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'
);
```

**Audit Logging:**
```yaml
# Kubernetes audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
- level: Metadata
  resources:
  - group: ""
    resources: ["pods", "services"]
```

---

## Use Case 3: Financial Services - Disaster Recovery

### Business Requirements
- Banking application
- Zero data loss (RPO = 0)
- 5-minute recovery time (RTO = 5 min)
- Active-Active across regions
- Real-time transaction processing
- Regulatory compliance (SOC 2, PCI DSS)

### DR Architecture

```
Primary Region (East US)              Secondary Region (West US)
        ↓                                      ↓
Traffic Manager (Priority routing)
        ↓                                      ↓
    Active                                  Active
        ↓                                      ↓
AKS Cluster (10 nodes)                AKS Cluster (10 nodes)
├─ Transaction Service                ├─ Transaction Service
├─ Account Service                    ├─ Account Service
└─ Auth Service                       └─ Auth Service
        ↓                                      ↓
SQL MI Auto-Failover Group ←──────────────────┘
(Synchronous replication)
        ↓
Cosmos DB (Multi-region writes)
├─ Strong consistency
└─ Automatic failover
        ↓
Event Hubs (Geo-DR enabled)
└─ Transaction logs, Audit trails
```

### DR Implementation

**SQL Managed Instance Failover Group:**
```bash
# Create failover group
az sql instance-failover-group create \
  --name banking-fog \
  --resource-group banking-rg \
  --location eastus \
  --partner-resource-group banking-rg \
  --partner-location westus \
  --source-mi banking-mi-east \
  --partner-mi banking-mi-west \
  --failover-policy Automatic \
  --grace-period 1
```

**Cosmos DB Multi-Region:**
```bash
# Create Cosmos DB with multi-region writes
az cosmosdb create \
  --name banking-cosmos \
  --resource-group banking-rg \
  --locations regionName=eastus failoverPriority=0 isZoneRedundant=true \
  --locations regionName=westus failoverPriority=1 isZoneRedundant=true \
  --enable-multiple-write-locations \
  --default-consistency-level Strong
```

**AKS Deployment with Region Awareness:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: transaction-service
spec:
  replicas: 10
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - transaction-service
            topologyKey: topology.kubernetes.io/zone
      containers:
      - name: transaction-api
        image: bankingacr.azurecr.io/transaction:v3.2
        env:
        - name: SQL_CONNECTION_STRING
          value: "Server=tcp:banking-fog.database.windows.net,1433;..."
        - name: COSMOS_ENDPOINT
          value: "https://banking-cosmos.documents.azure.com:443/"
        - name: REGION
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['topology.kubernetes.io/region']
```

**DR Testing Script:**
```bash
#!/bin/bash
# DR Failover Test

echo "Starting DR failover test..."

# 1. Trigger SQL failover
az sql instance-failover-group set-primary \
  --name banking-fog \
  --resource-group banking-rg \
  --location westus

# 2. Update Traffic Manager priority
az network traffic-manager endpoint update \
  --name westus-endpoint \
  --profile-name banking-tm \
  --resource-group banking-rg \
  --type azureEndpoints \
  --priority 1

# 3. Verify application health
kubectl get pods -n banking
curl https://banking-api.com/health

# 4. Monitor failover time
echo "Failover completed at: $(date)"
```

### DR Metrics
- **RPO Achieved:** 0 seconds (synchronous replication)
- **RTO Achieved:** 3 minutes (automated failover)
- **Data Loss:** None
- **Downtime:** < 5 minutes

---

## Use Case 4: IoT Platform - Real-Time Analytics

### Business Requirements
- 100,000 IoT devices
- 1 million events/second
- Real-time dashboards
- Predictive maintenance
- Historical data analysis
- 7-year data retention

### Architecture Solution

```
IoT Devices (100K)
    ↓
IoT Hub (S3 tier)
├─ Device-to-cloud messages
├─ Device twins
└─ Direct methods
    ↓
    ├──→ Stream Analytics ──→ Power BI (Real-time dashboard)
    ├──→ Event Hubs ──→ Azure Functions ──→ Cosmos DB (Hot data)
    └──→ Data Lake Gen2 (Cold storage)
              ↓
        Azure Synapse Analytics
        ├─ Dedicated SQL Pool (Data warehouse)
        ├─ Spark Pool (ML training)
        └─ Serverless SQL (Ad-hoc queries)
              ↓
        Azure Machine Learning
        └─ Predictive maintenance models
              ↓
        AKS (Inference API)
        └─ Real-time predictions
```

### Implementation

**IoT Hub Configuration:**
```bash
# Create IoT Hub
az iot hub create \
  --name manufacturing-iot \
  --resource-group iot-rg \
  --sku S3 \
  --partition-count 32

# Create device identity
az iot hub device-identity create \
  --hub-name manufacturing-iot \
  --device-id sensor-001
```

**Stream Analytics Query:**
```sql
-- Real-time anomaly detection
SELECT
    DeviceId,
    AVG(Temperature) AS AvgTemp,
    MAX(Temperature) AS MaxTemp,
    System.Timestamp AS WindowEnd
INTO
    [PowerBIOutput]
FROM
    [IoTHubInput]
TIMESTAMP BY EventTime
GROUP BY
    DeviceId,
    TumblingWindow(minute, 5)
HAVING
    AVG(Temperature) > 80 OR MAX(Temperature) > 100

-- Archive to Data Lake
SELECT
    *
INTO
    [DataLakeOutput]
FROM
    [IoTHubInput]
```

**Data Lake Storage Lifecycle:**
```json
{
  "rules": [
    {
      "name": "MoveToArchive",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["iot-data/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 365
            }
          }
        }
      }
    }
  ]
}
```

**ML Model Deployment on AKS:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-inference
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: inference-api
        image: mlacr.azurecr.io/predictive-maintenance:v1.5
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
            nvidia.com/gpu: "1"
          limits:
            memory: "4Gi"
            cpu: "2000m"
            nvidia.com/gpu: "1"
        env:
        - name: MODEL_PATH
          value: "/models/maintenance-model.pkl"
        volumeMounts:
        - name: model-storage
          mountPath: /models
      volumes:
      - name: model-storage
        persistentVolumeClaim:
          claimName: model-pvc
```

---

## Use Case 5: Media Streaming Platform

### Business Requirements
- 5 million concurrent viewers
- 4K video streaming
- Global CDN
- Live streaming + VOD
- DRM protection
- 99.9% availability

### Architecture Solution

```
Content Upload
    ↓
Blob Storage (Hot tier)
    ↓
Azure Media Services
├─ Encoding (multiple bitrates)
├─ Packaging (HLS, DASH)
├─ DRM (PlayReady, Widevine)
└─ Streaming endpoints
    ↓
Azure CDN (Premium Verizon)
├─ Edge caching
├─ Geo-filtering
└─ Token authentication
    ↓
Users (Web, Mobile, Smart TV)

Backend:
App Service (Premium)
├─ User management
├─ Content catalog
└─ Recommendations
    ↓
Cosmos DB (Multi-region)
├─ User profiles
├─ Watch history
└─ Recommendations
    ↓
Azure Cognitive Services
└─ Video indexer, Content moderation
```

### Cost Optimization
- Use Azure CDN for 95% cache hit ratio
- Implement tiered storage (Hot → Cool → Archive)
- Use reserved instances for predictable workloads
- Auto-scale based on viewer count

---

## Key Takeaways

✅ **Multi-tier architecture** separates concerns and enables independent scaling  
✅ **DR strategy** must align with RTO/RPO requirements  
✅ **Security** should be implemented at every layer (defense in depth)  
✅ **Compliance** requirements drive architecture decisions  
✅ **Cost optimization** through right-sizing and auto-scaling  
✅ **Monitoring** is critical for production systems  
✅ **Automation** reduces human error and recovery time  
✅ **Testing** DR procedures regularly ensures they work when needed

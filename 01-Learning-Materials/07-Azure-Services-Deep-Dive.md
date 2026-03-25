# Azure Services Deep Dive - Comprehensive Guide

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Table of Contents

1. [Compute Services](#compute-services)
2. [Storage Services](#storage-services)
3. [Database Services](#database-services)
4. [Networking Services](#networking-services)
5. [Container Services](#container-services)
6. [Integration Services](#integration-services)
7. [Analytics Services](#analytics-services)
8. [AI & Machine Learning](#ai-machine-learning)
9. [IoT Services](#iot-services)
10. [Security Services](#security-services)
11. [Monitoring & Management](#monitoring-management)
12. [DevOps Services](#devops-services)

---

## Compute Services

### Azure Functions - Deep Dive

**Consumption Plan (Serverless):**
- **Pricing:**
  - $0.20 per million executions
  - $0.000016 per GB-second
  - First 1 million executions free
  - First 400,000 GB-seconds free
- **Limits:**
  - Timeout: 5 minutes (default), 10 minutes (max)
  - Memory: 1.5 GB max
  - Concurrent executions: 200 (default), can increase
  - Scale: Automatic, scales to zero
- **Features:**
  - Auto-scale based on demand
  - No pre-warmed instances
  - Cold start: 1-3 seconds
  - No VNet integration
- **Use Cases:**
  - Sporadic workloads
  - Event-driven processing
  - Webhooks
  - Scheduled tasks
  - Cost-sensitive applications
- **Example Cost:**
  - 5 million executions/month
  - 200ms execution time
  - 512 MB memory
  - Cost: ~$20/month

**Premium Plan (Elastic Premium):**
- **Tiers:**
  - EP1: 1 vCPU, 3.5 GB RAM, $168/month
  - EP2: 2 vCPU, 7 GB RAM, $336/month
  - EP3: 4 vCPU, 14 GB RAM, $672/month
- **Limits:**
  - Timeout: Unlimited
  - Memory: Up to 14 GB
  - Pre-warmed instances: 1-20
  - Max instances: 100
- **Features:**
  - No cold start (pre-warmed)
  - VNet integration
  - Private site access
  - Unlimited execution duration
  - Premium hardware
  - Faster scaling
- **Use Cases:**
  - Predictable workloads
  - Long-running functions
  - VNet connectivity required
  - High-performance needs
  - Enterprise applications
- **Example Cost:**
  - 3 EP1 instances always on
  - Cost: $504/month base

**Dedicated (App Service) Plan:**
- Uses existing App Service plan
- Same pricing as App Service
- **Features:**
  - Predictable billing
  - Run alongside web apps
  - Use reserved instances
  - Full control over scaling
- **Use Cases:**
  - Existing App Service infrastructure
  - Underutilized App Service plans
  - Need for dedicated resources

**Triggers and Bindings:**

**HTTP Trigger:**
```csharp
[FunctionName("HttpExample")]
public static async Task<IActionResult> Run(
    [HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
{
    // Function code
}
```
- Authorization levels: Anonymous, Function, Admin
- Methods: GET, POST, PUT, DELETE, etc.
- Route templates supported
- CORS configuration

**Timer Trigger:**
```csharp
[FunctionName("TimerExample")]
public static void Run([TimerTrigger("0 */5 * * * *")] TimerInfo myTimer)
{
    // Runs every 5 minutes
}
```
- CRON expressions
- Schedule: Second Minute Hour Day Month DayOfWeek
- Timezone support
- Missed execution handling

**Queue Trigger (Storage Queue):**
```csharp
[FunctionName("QueueExample")]
public static void Run(
    [QueueTrigger("myqueue")] string myQueueItem,
    [Queue("outputqueue")] out string outputQueueItem)
{
    outputQueueItem = myQueueItem;
}
```
- Automatic polling
- Poison message handling
- Batch processing support
- Visibility timeout

**Blob Trigger:**
```csharp
[FunctionName("BlobExample")]
public static void Run(
    [BlobTrigger("container/{name}")] Stream myBlob,
    string name,
    [Blob("output/{name}")] out string outputBlob)
{
    // Process blob
}
```
- Path patterns
- Blob metadata access
- Large blob support
- Polling interval

**Event Hub Trigger:**
```csharp
[FunctionName("EventHubExample")]
public static void Run(
    [EventHubTrigger("eventhub", Connection = "EventHubConnection")] 
    EventData[] events)
{
    foreach (var evt in events)
    {
        // Process event
    }
}
```
- Batch processing
- Checkpoint management
- Partition key support
- Consumer group configuration

**Cosmos DB Trigger:**
```csharp
[FunctionName("CosmosDBExample")]
public static void Run(
    [CosmosDBTrigger(
        databaseName: "mydb",
        collectionName: "mycoll",
        ConnectionStringSetting = "CosmosDBConnection",
        LeaseCollectionName = "leases",
        CreateLeaseCollectionIfNotExists = true)]
    IReadOnlyList<Document> documents)
{
    // Process changed documents
}
```
- Change feed based
- Lease collection required
- Automatic checkpointing
- Partition support

**Service Bus Trigger:**
```csharp
[FunctionName("ServiceBusExample")]
public static void Run(
    [ServiceBusTrigger("myqueue", Connection = "ServiceBusConnection")] 
    string myQueueItem,
    Int32 deliveryCount,
    DateTime enqueuedTimeUtc,
    string messageId)
{
    // Process message
}
```
- Queue and Topic support
- Dead-letter queue handling
- Session support
- Message properties access

**Event Grid Trigger:**
```csharp
[FunctionName("EventGridExample")]
public static void Run(
    [EventGridTrigger] EventGridEvent eventGridEvent)
{
    // Process event
}
```
- Schema validation
- Event filtering
- Retry policies
- Dead-letter support

**Durable Functions:**

**Orchestrator Function:**
```csharp
[FunctionName("OrchestratorExample")]
public static async Task<List<string>> RunOrchestrator(
    [OrchestrationTrigger] IDurableOrchestrationContext context)
{
    var outputs = new List<string>();
    
    outputs.Add(await context.CallActivityAsync<string>("Activity1", "input1"));
    outputs.Add(await context.CallActivityAsync<string>("Activity2", "input2"));
    outputs.Add(await context.CallActivityAsync<string>("Activity3", "input3"));
    
    return outputs;
}
```

**Patterns:**
- Function chaining
- Fan-out/fan-in
- Async HTTP APIs
- Monitoring
- Human interaction
- Aggregator (stateful entities)
- Eternal orchestrations

**Features:**
- Automatic checkpointing
- Replay-based execution
- Reliable execution
- Long-running workflows
- Sub-orchestrations
- Timers and delays

**Best Practices:**
✅ Use appropriate hosting plan based on workload
✅ Implement idempotent functions
✅ Use managed identities for authentication
✅ Enable Application Insights
✅ Set appropriate timeout values
✅ Use async/await properly
✅ Implement proper error handling
✅ Use bindings instead of SDKs when possible
✅ Monitor cold start times
✅ Optimize function size and dependencies

---

### Azure Kubernetes Service (AKS) - Deep Dive

**Overview:**
Managed Kubernetes service that simplifies deploying, managing, and scaling containerized applications.

**Control Plane:**
- **Cost:** Free (Microsoft-managed)
- **Features:**
  - API server
  - etcd (state store)
  - Scheduler
  - Controller manager
  - Cloud controller manager
- **SLA:** 99.95% (Standard), 99.99% (with Availability Zones)
- **Uptime SLA:** $73/month per cluster (optional, 99.95% financially backed)

**Node Pools:**

**System Node Pool:**
- Required for cluster operation
- Runs system pods (CoreDNS, metrics-server, etc.)
- Minimum: 1 node
- Recommended: 3 nodes for production
- Taints: CriticalAddonsOnly
- **Typical Configuration:**
  - Standard_D2s_v3: 2 vCPU, 8 GB RAM, $96/month per node
  - 3 nodes = $288/month

**User Node Pools:**
- Run application workloads
- Multiple pools supported
- Different VM sizes per pool
- Spot node pools available
- Auto-scaling support
- **Typical Configuration:**
  - Standard_D4s_v3: 4 vCPU, 16 GB RAM, $192/month per node
  - 5 nodes = $960/month

**Node Pool Types:**

**Linux Node Pools:**
- Ubuntu 18.04/20.04
- Azure Linux (CBL-Mariner)
- Lower cost than Windows
- Most common workloads

**Windows Node Pools:**
- Windows Server 2019/2022
- .NET Framework applications
- Higher cost (Windows licensing)
- Requires Linux system pool

**Spot Node Pools:**
- Up to 90% discount
- Can be evicted
- Best for:
  - Batch processing
  - Dev/test
  - Stateless apps
  - Fault-tolerant workloads

**VM Sizes for AKS:**

**Development/Test:**
- Standard_B2s: 2 vCPU, 4 GB RAM, $30/month
- Standard_B4ms: 4 vCPU, 16 GB RAM, $120/month

**General Purpose:**
- Standard_D2s_v3: 2 vCPU, 8 GB RAM, $96/month
- Standard_D4s_v3: 4 vCPU, 16 GB RAM, $192/month
- Standard_D8s_v3: 8 vCPU, 32 GB RAM, $384/month
- Standard_D16s_v3: 16 vCPU, 64 GB RAM, $768/month

**Memory Optimized:**
- Standard_E2s_v3: 2 vCPU, 16 GB RAM, $122/month
- Standard_E4s_v3: 4 vCPU, 32 GB RAM, $244/month
- Standard_E8s_v3: 8 vCPU, 64 GB RAM, $488/month

**Compute Optimized:**
- Standard_F4s_v2: 4 vCPU, 8 GB RAM, $152/month
- Standard_F8s_v2: 8 vCPU, 16 GB RAM, $304/month

**GPU:**
- Standard_NC6s_v3: 6 vCPU, 112 GB RAM, 1x V100, $3,060/month
- Standard_NC4as_T4_v3: 4 vCPU, 28 GB RAM, 1x T4, $526/month

**Networking:**

**Network Plugins:**

**kubenet (Basic):**
- Default option
- Nodes get IP from VNet subnet
- Pods get IP from separate address space
- NAT for pod-to-internet
- User-defined routes (UDR) required
- Limitations:
  - No Windows node pools
  - No Azure Network Policies
  - No VNet peering for pods
- Use: Simple scenarios, IP conservation

**Azure CNI (Advanced):**
- Pods get IP from VNet subnet
- Direct VNet connectivity
- No NAT required
- Supports:
  - Windows node pools
  - Azure Network Policies
  - Calico Network Policies
  - Virtual nodes
- IP planning required
- Formula: (Max pods per node × Max nodes) + Max nodes
- Use: Enterprise scenarios, VNet integration

**Azure CNI Overlay:**
- Pods get IP from overlay network
- Nodes get IP from VNet
- Better IP utilization
- Up to 250 pods per node
- Use: IP address conservation with CNI features

**Network Policies:**
- Azure Network Policy
- Calico Network Policy
- Control pod-to-pod traffic
- Namespace isolation
- Ingress/egress rules

**Load Balancing:**

**LoadBalancer Service:**
- Azure Load Balancer (Layer 4)
- Public or internal
- Static IP support
- Cost: $18/month + $0.005/GB

**Ingress Controller:**
- Application Gateway Ingress Controller (AGIC)
- NGINX Ingress Controller
- Traefik
- Layer 7 load balancing
- SSL termination
- Path-based routing
- Host-based routing

**Storage:**

**Storage Classes:**

**Azure Disk:**
- Standard HDD: Low cost, low performance
- Standard SSD: Balanced
- Premium SSD: High performance
- Ultra Disk: Highest performance
- Access modes: ReadWriteOnce
- Use: Databases, stateful apps

**Azure Files:**
- Standard: SMB 3.0
- Premium: Low latency
- Access modes: ReadWriteMany
- Use: Shared storage, legacy apps

**Azure Blob (via CSI):**
- Blob Fuse
- NFS 3.0
- Access modes: ReadWriteMany
- Use: Big data, ML datasets

**Persistent Volume Claims:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-premium
  resources:
    requests:
      storage: 100Gi
```

**Scaling:**

**Cluster Autoscaler:**
- Automatically adds/removes nodes
- Based on pending pods
- Respects node pool min/max
- Scale-down delay: 10 minutes
- Configuration:
```yaml
--scale-down-delay-after-add=10m
--scale-down-unneeded-time=10m
--scale-down-utilization-threshold=0.5
```

**Horizontal Pod Autoscaler (HPA):**
- Scales pods based on metrics
- CPU, memory, custom metrics
- Min/max replicas
- Example:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
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

**Vertical Pod Autoscaler (VPA):**
- Adjusts CPU/memory requests
- Requires pod restart
- Recommendation mode available

**Security:**

**Azure AD Integration:**
- Kubernetes RBAC with Azure AD
- Cluster admin access
- Namespace-level access
- Group-based access

**Azure RBAC for Kubernetes:**
- Manage permissions via Azure
- No kubeconfig needed
- Integrated with Azure AD

**Pod Identity:**
- Managed identities for pods
- Access Azure resources
- No credentials in code
- AAD Pod Identity (legacy)
- Workload Identity (new)

**Azure Policy for AKS:**
- Enforce cluster configurations
- Built-in policies
- Custom policies
- Audit and deny modes

**Secrets Management:**
- Azure Key Vault integration
- CSI driver
- Secrets Store CSI Driver
- Automatic rotation

**Network Security:**
- Network policies
- Private cluster
- API server authorized IP ranges
- Azure Firewall integration

**Monitoring:**

**Azure Monitor for Containers:**
- Container logs
- Performance metrics
- Live logs
- Cluster health
- Prometheus metrics
- Cost: $2.30/GB ingested

**Metrics:**
- Node CPU/memory
- Pod CPU/memory
- Container restarts
- Network traffic
- Disk usage

**Logs:**
- Container stdout/stderr
- Kubernetes events
- Audit logs
- Diagnostic settings

**Add-ons and Extensions:**

**Built-in Add-ons:**
- Azure Monitor
- Azure Policy
- HTTP Application Routing (deprecated)
- Virtual Nodes (ACI integration)
- Open Service Mesh
- Azure Key Vault Secrets Provider

**Cluster Extensions:**
- Dapr
- GitOps (Flux)
- Azure Machine Learning
- Azure App Configuration

**Upgrade and Maintenance:**

**Kubernetes Version:**
- Support: N and N-2 versions
- Upgrade: Control plane first, then nodes
- Auto-upgrade channels:
  - None: Manual
  - Patch: Auto patch updates
  - Stable: N-1 minor version
  - Rapid: Latest version
- Maintenance windows
- Node surge upgrade

**Node Image Upgrade:**
- Security patches
- OS updates
- Weekly releases
- Auto-upgrade available

**Cost Optimization:**

**Strategies:**
✅ Use Spot node pools for fault-tolerant workloads
✅ Enable cluster autoscaler
✅ Right-size node pools
✅ Use reserved instances for predictable workloads
✅ Implement pod resource requests/limits
✅ Use Horizontal Pod Autoscaler
✅ Schedule non-critical workloads during off-hours
✅ Use Azure Hybrid Benefit for Windows nodes
✅ Monitor and optimize resource utilization
✅ Use smaller node sizes with more nodes

**Example Cluster Cost:**
```
System Node Pool:
- 3x Standard_D2s_v3 = $288/month

User Node Pool:
- 5x Standard_D4s_v3 = $960/month

Load Balancer: $20/month
Public IP: $4/month
Uptime SLA: $73/month
Storage (1 TB Premium SSD): $135/month
Monitoring (100 GB/month): $230/month

Total: ~$1,710/month
```

**Best Practices:**
✅ Use multiple node pools for different workload types
✅ Enable cluster autoscaler
✅ Implement resource requests and limits
✅ Use pod disruption budgets
✅ Enable Azure Monitor for containers
✅ Use managed identities
✅ Implement network policies
✅ Use private clusters for production
✅ Enable Azure Policy
✅ Regular cluster upgrades
✅ Use GitOps for deployments
✅ Implement proper RBAC
✅ Use Azure Key Vault for secrets
✅ Enable diagnostic logs
✅ Plan IP addressing carefully with Azure CNI

---

## Storage Services

### Azure Blob Storage - Deep Dive

**Overview:**
Massively scalable object storage for unstructured data. Optimized for storing massive amounts of text or binary data.

**Storage Account Types:**

**Standard (General Purpose v2):**
- Blob, File, Queue, Table support
- Hot, Cool, Archive tiers
- LRS, ZRS, GRS, RA-GRS, GZRS, RA-GZRS
- Best for: Most scenarios

**Premium Block Blob:**
- Block blobs only
- Low latency (< 10ms)
- High transaction rates
- LRS, ZRS only
- Best for: High IOPS, low latency

**Premium Page Blob:**
- Page blobs only (VHD files)
- LRS, ZRS only
- Best for: VM disks

**Premium File Shares:**
- Azure Files only
- LRS, ZRS only
- Best for: High-performance file shares

**Access Tiers - Detailed:**

**Hot Tier:**
- **Storage:** $0.0184/GB/month
- **Write:** $0.05 per 10,000 operations
- **Read:** $0.004 per 10,000 operations
- **Data retrieval:** Free
- **Early deletion:** None
- **Minimum storage:** None
- **Latency:** Milliseconds
- **Use Cases:**
  - Active data
  - Frequently accessed files
  - Staging data for processing
  - Web content
  - Mobile app data
- **Example:** 1 TB, 1M reads, 100K writes = $18.40 + $0.40 + $0.50 = $19.30/month

**Cool Tier:**
- **Storage:** $0.01/GB/month
- **Write:** $0.10 per 10,000 operations
- **Read:** $0.01 per 10,000 operations
- **Data retrieval:** $0.01/GB
- **Early deletion:** < 30 days (prorated)
- **Minimum storage:** 30 days
- **Latency:** Milliseconds
- **Use Cases:**
  - Short-term backup
  - Disaster recovery
  - Older media content
  - Compliance data
  - Data accessed < once per month
- **Example:** 1 TB, 100K reads, 10K writes = $10 + $1 + $1 + $10 = $22/month

**Archive Tier:**
- **Storage:** $0.00099/GB/month
- **Write:** $0.11 per 10,000 operations
- **Read:** $5.50 per 10,000 operations
- **Data retrieval:** $0.02/GB (high priority), $0.01/GB (standard)
- **Early deletion:** < 180 days (prorated)
- **Minimum storage:** 180 days
- **Latency:** Hours (rehydration required)
- **Rehydration time:** 
  - Standard: < 15 hours
  - High priority: < 1 hour
- **Use Cases:**
  - Long-term backup
  - Compliance archives
  - Historical data
  - Rarely accessed data
- **Example:** 10 TB stored = $10.10/month (storage only)

**Blob Types:**

**Block Blobs:**
- Max size: 190.7 TB
- Max block size: 4,000 MiB
- Max blocks: 50,000
- Optimized for: Upload and streaming
- Use: Documents, media files, logs
- Features:
  - Parallel uploads
  - Append operations
  - Versioning
  - Snapshots

**Append Blobs:**
- Max size: 195 GB
- Optimized for: Append operations
- Use: Logging, audit trails
- Features:
  - Append-only
  - No random writes
  - Efficient for sequential writes

**Page Blobs:**
- Max size: 8 TB
- 512-byte pages
- Optimized for: Random read/write
- Use: VHD files, databases
- Features:
  - Random access
  - Sparse files
  - Incremental snapshots

**Redundancy Options:**

**Locally Redundant Storage (LRS):**
- 3 copies in single datacenter
- 11 nines durability
- Lowest cost
- No protection against datacenter failure
- Use: Non-critical data, can be recreated

**Zone-Redundant Storage (ZRS):**
- 3 copies across 3 availability zones
- 12 nines durability
- Protection against datacenter failure
- Available in select regions
- Use: High availability requirements

**Geo-Redundant Storage (GRS):**
- 6 copies (3 local + 3 in paired region)
- 16 nines durability
- Async replication (RPO: minutes)
- Read access to secondary: No (unless RA-GRS)
- Use: Disaster recovery

**Read-Access Geo-Redundant Storage (RA-GRS):**
- Same as GRS + read access to secondary
- Read-only endpoint in secondary region
- Use: Read availability during regional outage

**Geo-Zone-Redundant Storage (GZRS):**
- ZRS in primary + LRS in secondary
- 16 nines durability
- Best of both worlds
- Use: Maximum durability and availability

**Read-Access Geo-Zone-Redundant Storage (RA-GZRS):**
- Same as GZRS + read access to secondary
- Highest availability
- Use: Mission-critical applications

**Lifecycle Management:**

**Policy Rules:**
```json
{
  "rules": [
    {
      "name": "moveToArchive",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["logs/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 90
            },
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          },
          "snapshot": {
            "delete": {
              "daysAfterCreationGreaterThan": 90
            }
          }
        }
      }
    }
  ]
}
```

**Actions:**
- Tier to cool
- Tier to archive
- Delete blob
- Delete snapshot
- Delete version

**Filters:**
- Blob type
- Prefix match
- Blob index tags

**Security:**

**Authentication:**
- Shared Key (storage account key)
- Shared Access Signature (SAS)
- Azure AD (recommended)
- Anonymous public access

**Authorization:**
- RBAC roles:
  - Storage Blob Data Owner
  - Storage Blob Data Contributor
  - Storage Blob Data Reader
- ACLs (for Data Lake Gen2)

**Encryption:**
- At rest: Always encrypted (AES-256)
- Customer-managed keys (CMK)
- Infrastructure encryption (double encryption)
- In transit: HTTPS enforced

**Network Security:**
- Firewall rules
- Virtual network service endpoints
- Private endpoints
- Require secure transfer

**Advanced Features:**

**Blob Versioning:**
- Automatic version creation
- Restore previous versions
- Immutable versions
- Cost: Storage for all versions

**Blob Snapshots:**
- Point-in-time read-only copy
- Incremental (only changed blocks)
- Manual creation
- Cost: Storage for changed blocks

**Soft Delete:**
- Retention: 1-365 days
- Recover deleted blobs
- Recover deleted containers
- Recover overwritten blobs
- Cost: Storage during retention

**Point-in-Time Restore:**
- Restore to any point in time
- Retention: 1-365 days
- Block blobs only
- Requires versioning and change feed

**Change Feed:**
- Ordered log of changes
- Transactional consistency
- Retention: Configurable
- Use: Event-driven processing

**Blob Index Tags:**
- Key-value metadata
- Queryable
- Up to 10 tags per blob
- Use: Data management, search

**Static Website Hosting:**
- Host static content
- Custom domain support
- HTTPS via Azure CDN
- Index and error documents
- Cost: Storage + bandwidth

**Performance:**

**Scalability Targets:**
- Max request rate: 20,000 requests/second
- Max bandwidth: 60 Gbps (egress), 120 Gbps (ingress)
- Max capacity: 5 PB per account
- Max blob size: 190.7 TB

**Optimization:**
- Use block blobs for large files
- Parallel uploads (multiple blocks)
- Use appropriate block size
- Enable CDN for frequently accessed content
- Use premium storage for low latency
- Implement retry logic
- Use appropriate access tier

**Monitoring:**
- Storage Analytics logs
- Metrics (capacity, transactions, availability)
- Azure Monitor integration
- Alerts on metrics
- Diagnostic settings

**Best Practices:**
✅ Use Azure AD authentication
✅ Enable soft delete
✅ Implement lifecycle management
✅ Use appropriate access tier
✅ Enable versioning for critical data
✅ Use private endpoints for security
✅ Implement proper RBAC
✅ Enable diagnostic logging
✅ Use CDN for static content
✅ Monitor costs and optimize
✅ Use SAS tokens with minimal permissions
✅ Enable encryption with customer-managed keys for compliance
✅ Implement proper backup strategy
✅ Use blob index tags for management
✅ Enable change feed for auditing

---

*This is Part 1 of the Deep Dive guide. The document continues with detailed coverage of all other Azure services...*

**© Copyright Sivakumar J**

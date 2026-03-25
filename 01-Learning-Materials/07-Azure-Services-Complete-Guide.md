# Complete Azure Services Guide - Deep Dive

> **📘 For extremely detailed information on each service, see:** [07-Azure-Services-Deep-Dive.md](./07-Azure-Services-Deep-Dive.md)
> 
> This guide provides comprehensive overview and pricing. The Deep Dive guide includes:
> - Detailed feature explanations
> - Configuration examples
> - Code samples
> - Best practices
> - Real-world scenarios
> - Troubleshooting tips

---

## Compute Services - Comprehensive Details

### Azure Virtual Machines - Complete Guide

**Overview:**
Azure VMs provide on-demand, scalable computing resources with full control over the operating system and applications.

**Key Features:**
- 700+ VM sizes across multiple series
- Support for Windows and Linux
- Custom images and marketplace images
- Availability Sets (99.95% SLA) and Availability Zones (99.99% SLA)
- VM Scale Sets for auto-scaling
- Spot VMs for cost savings
- Dedicated Hosts for compliance
- Proximity Placement Groups for low latency
- Accelerated Networking (up to 30 Gbps)
- Nested virtualization support
- Azure Hybrid Benefit
- Reserved Instances (1-year, 3-year)

**Disk Options:**
- OS Disk: Required, up to 4 TB
- Data Disks: Up to 64 disks per VM
- Temporary Disk: Ephemeral, lost on stop/deallocate
- Disk Caching: None, ReadOnly, ReadWrite
- Shared Disks: Multiple VMs can attach
- Disk Encryption: Azure Disk Encryption (ADE), Server-Side Encryption (SSE)

**Networking:**
- Multiple NICs (up to 8 depending on size)
- Public and Private IPs
- NSG at NIC or subnet level
- Load Balancer integration
- Application Gateway integration
- Azure Bastion for secure access
- Just-in-Time (JIT) VM access

**Backup and DR:**
- Azure Backup: Application-consistent backups
- Azure Site Recovery: Disaster recovery
- Snapshots: Point-in-time disk copies
- Images: Generalized VM templates

**Monitoring:**
- Boot diagnostics
- Performance metrics (CPU, memory, disk, network)
- Azure Monitor integration
- Log Analytics agent
- Dependency agent for service maps

**Limits:**
- Max vCPUs per VM: 416 (M416ms_v2)
- Max memory per VM: 11.4 TB (M416ms_v2)
- Max data disks: 64
- Max NICs: 8
- Max IOPS per VM: 400,000 (with Ultra Disks)

### Azure Virtual Machines

**VM Series Deep Dive:**

**A-Series (Entry-level, Basic tier):**
- A0: 1 vCPU, 0.75 GB RAM, $15/month
- A4: 8 vCPU, 14 GB RAM, $240/month
- No premium storage support
- No load balancing
- Use: Dev/test, low-traffic websites, learning
- **When to use:** Cost-sensitive non-production workloads

**B-Series (Burstable Performance):**
- B1s: 1 vCPU, 1 GB RAM, $8/month, 10% baseline
- B1ms: 1 vCPU, 2 GB RAM, $15/month, 20% baseline
- B2s: 2 vCPU, 4 GB RAM, $30/month, 40% baseline
- B2ms: 2 vCPU, 8 GB RAM, $60/month, 60% baseline
- B4ms: 4 vCPU, 16 GB RAM, $120/month, 90% baseline
- B8ms: 8 vCPU, 32 GB RAM, $240/month, 135% baseline
- CPU credits: Accumulate when below baseline, consume when above
- Premium storage support
- Use: Variable workloads, development servers, small databases
- **When to use:** Workloads that don't need full CPU continuously

**Dv5/Dsv5-Series (General Purpose, Latest Gen):**
- D2s_v5: 2 vCPU, 8 GB RAM, $96/month, 3,200 IOPS
- D4s_v5: 4 vCPU, 16 GB RAM, $192/month, 6,400 IOPS
- D8s_v5: 8 vCPU, 32 GB RAM, $384/month, 12,800 IOPS
- D16s_v5: 16 vCPU, 64 GB RAM, $768/month, 25,600 IOPS
- D32s_v5: 32 vCPU, 128 GB RAM, $1,536/month, 51,200 IOPS
- D64s_v5: 64 vCPU, 256 GB RAM, $3,072/month, 80,000 IOPS
- D96s_v5: 96 vCPU, 384 GB RAM, $4,608/month, 80,000 IOPS
- Intel Ice Lake or AMD EPYC processors
- Up to 30 Gbps network bandwidth
- Remote storage only (no temp disk on 's' models)
- Use: Web servers, application servers, small-medium databases
- **When to use:** Balanced CPU-to-memory ratio workloads

**Dv4/Dsv4-Series (General Purpose, Previous Gen):**
- Includes local temp disk
- Slightly lower cost than v5
- Use: When local temp storage needed

**Ev5/Esv5-Series (Memory Optimized, Latest Gen):**
- E2s_v5: 2 vCPU, 16 GB RAM, $122/month (1:8 ratio)
- E4s_v5: 4 vCPU, 32 GB RAM, $244/month
- E8s_v5: 8 vCPU, 64 GB RAM, $488/month
- E16s_v5: 16 vCPU, 128 GB RAM, $976/month
- E32s_v5: 32 vCPU, 256 GB RAM, $1,952/month
- E64s_v5: 64 vCPU, 512 GB RAM, $3,904/month
- E96s_v5: 96 vCPU, 672 GB RAM, $5,472/month
- High memory-to-vCore ratio (8:1)
- Up to 30 Gbps network
- Use: SQL Server, SAP, Redis, in-memory analytics
- **When to use:** Memory-intensive applications, large caches

**Fv2-Series (Compute Optimized):**
- F2s_v2: 2 vCPU, 4 GB RAM, $76/month (1:2 ratio)
- F4s_v2: 4 vCPU, 8 GB RAM, $152/month
- F8s_v2: 8 vCPU, 16 GB RAM, $304/month
- F16s_v2: 16 vCPU, 32 GB RAM, $608/month
- F32s_v2: 32 vCPU, 64 GB RAM, $1,216/month
- F48s_v2: 48 vCPU, 96 GB RAM, $1,824/month
- F64s_v2: 64 vCPU, 128 GB RAM, $2,432/month
- F72s_v2: 72 vCPU, 144 GB RAM, $2,745/month
- Intel Xeon Platinum 8168 (3.4 GHz all-core turbo)
- High CPU-to-memory ratio (1:2)
- Use: Batch processing, web servers, analytics, gaming
- **When to use:** CPU-intensive workloads with lower memory needs

**Lsv2-Series (Storage Optimized):**
- L8s_v2: 8 vCPU, 64 GB RAM, 1.92 TB NVMe, $624/month
- L16s_v2: 16 vCPU, 128 GB RAM, 3.84 TB NVMe, $1,248/month
- L32s_v2: 32 vCPU, 256 GB RAM, 7.68 TB NVMe, $2,496/month
- L48s_v2: 48 vCPU, 384 GB RAM, 11.52 TB NVMe, $3,744/month
- L64s_v2: 64 vCPU, 512 GB RAM, 15.36 TB NVMe, $4,992/month
- L80s_v2: 80 vCPU, 640 GB RAM, 19.2 TB NVMe, $6,240/month
- Direct-attached NVMe storage
- Up to 400,000 IOPS
- Use: NoSQL databases (Cassandra, MongoDB), data warehousing
- **When to use:** High IOPS, low latency storage requirements

**NCv3-Series (GPU - NVIDIA V100):**
- NC6s_v3: 6 vCPU, 112 GB RAM, 1x V100 (16GB), $3,060/month
- NC12s_v3: 12 vCPU, 224 GB RAM, 2x V100, $6,120/month
- NC24s_v3: 24 vCPU, 448 GB RAM, 4x V100, $12,240/month
- NVLink for GPU-to-GPU communication
- Use: Deep learning training, HPC, AI inference
- **When to use:** GPU-accelerated compute workloads

**NCasT4_v3-Series (GPU - NVIDIA T4):**
- NC4as_T4_v3: 4 vCPU, 28 GB RAM, 1x T4 (16GB), $526/month
- NC8as_T4_v3: 8 vCPU, 56 GB RAM, 1x T4, $1,052/month
- NC16as_T4_v3: 16 vCPU, 110 GB RAM, 1x T4, $2,104/month
- NC64as_T4_v3: 64 vCPU, 440 GB RAM, 4x T4, $8,416/month
- Cost-effective GPU option
- Use: AI inference, graphics, video encoding
- **When to use:** GPU workloads with budget constraints

**NDv2-Series (GPU - NVIDIA V100 with NVLink):**
- ND40rs_v2: 40 vCPU, 672 GB RAM, 8x V100 (32GB), $24,480/month
- 200 Gbps InfiniBand
- Use: Distributed deep learning, HPC
- **When to use:** Large-scale AI training requiring multi-GPU

**ND A100 v4-Series (GPU - NVIDIA A100):**
- ND96asr_v4: 96 vCPU, 900 GB RAM, 8x A100 (40GB), $27,936/month
- ND96amsr_v4: 96 vCPU, 1.9 TB RAM, 8x A100 (80GB), $32,772/month
- 200 Gbps InfiniBand
- 3rd Gen AMD EPYC
- Use: Large language models, GPT training, HPC
- **When to use:** Cutting-edge AI/ML requiring maximum GPU performance

**M-Series (Memory Intensive - SAP HANA Certified):**
- M8ms: 8 vCPU, 218.75 GB RAM, $2,084/month
- M16ms: 16 vCPU, 437.5 GB RAM, $4,168/month
- M32ts: 32 vCPU, 192 GB RAM, $2,918/month
- M32ls: 32 vCPU, 256 GB RAM, $3,891/month
- M32ms: 32 vCPU, 875 GB RAM, $8,336/month
- M64s: 64 vCPU, 1 TB RAM, $9,723/month
- M64ls: 64 vCPU, 512 GB RAM, $4,862/month
- M64ms: 64 vCPU, 1.75 TB RAM, $16,672/month
- M128s: 128 vCPU, 2 TB RAM, $19,446/month
- M128ms: 128 vCPU, 3.8 TB RAM, $33,344/month
- M208s_v2: 208 vCPU, 2.85 TB RAM, $27,720/month
- M208ms_v2: 208 vCPU, 5.7 TB RAM, $55,440/month
- M416s_v2: 416 vCPU, 5.7 TB RAM, $55,440/month
- M416ms_v2: 416 vCPU, 11.4 TB RAM, $110,880/month
- Write Accelerator support
- Up to 20,000 IOPS per disk
- Use: SAP HANA, SAP S/4HANA, large in-memory databases
- **When to use:** Mission-critical SAP workloads, massive in-memory processing

**HB-Series (HPC - High Bandwidth Memory):**
- HB120rs_v2: 120 vCPU, 480 GB RAM, $3,600/month
- HB120rs_v3: 120 vCPU, 448 GB RAM, $3,600/month
- AMD EPYC processors
- 200 Gbps InfiniBand
- Use: Computational fluid dynamics, weather modeling
- **When to use:** Memory bandwidth-intensive HPC workloads

**HC-Series (HPC - Compute Intensive):**
- HC44rs: 44 vCPU, 352 GB RAM, $2,640/month
- Intel Xeon Platinum 8168
- 100 Gbps InfiniBand
- Use: Molecular dynamics, computational chemistry
- **When to use:** Compute-intensive HPC with MPI

**VM Availability Options:**

**Single VM:**
- SLA: 99.9% (Premium SSD or Ultra Disk)
- SLA: 95% (Standard SSD)
- No SLA (Standard HDD)

**Availability Set:**
- SLA: 99.95%
- Fault Domains: 2-3 (separate racks)
- Update Domains: 5-20 (planned maintenance)
- Free feature
- Use: Protect against hardware failures

**Availability Zone:**
- SLA: 99.99%
- Physically separate datacenters
- Independent power, cooling, networking
- Use: Protect against datacenter failures

**VM Scale Sets:**
- Auto-scaling: 0-1000 instances
- Load balancer integration
- Automatic OS updates
- Instance protection
- Use: Scalable applications

**Spot VMs:**
- Up to 90% discount
- Eviction types: Capacity or Price
- Eviction notice: 30 seconds
- Use: Batch jobs, dev/test, stateless apps
- **When NOT to use:** Production databases, stateful apps

**Reserved Instances:**
- 1-year: ~40% savings
- 3-year: ~60% savings
- Payment: Upfront, monthly, or no upfront
- Flexibility: Instance size, region (with restrictions)
- Exchange: Allowed
- Refund: Allowed (with penalty)

**Azure Dedicated Host:**
- Pricing: $4.32-$21.60/hour depending on type
- Full physical server
- Compliance requirements
- License optimization
- Use: Regulatory compliance, license requirements

### Azure App Service - Complete Guide

**Overview:**
Fully managed platform for building, deploying, and scaling web apps, mobile backends, and RESTful APIs without managing infrastructure.

**Key Features:**
- Multiple language support: .NET, Java, Node.js, Python, PHP, Ruby
- Built-in CI/CD: GitHub, Azure DevOps, Bitbucket, Docker Hub
- Auto-scaling: Scale up/out based on metrics
- Deployment slots: Blue-green deployments, A/B testing
- Custom domains and SSL certificates
- Authentication: Azure AD, Facebook, Google, Twitter, Microsoft
- Hybrid connections: Connect to on-premises resources
- VNet integration: Private connectivity
- Always On: Keep app loaded
- WebJobs: Background tasks
- Application Insights: Built-in monitoring

**App Service Plans - Detailed:**

**Free Tier (F1):**
- 1 GB RAM, 1 GB storage
- 60 CPU minutes/day
- 10 apps per plan
- No custom domains
- No SSL
- No SLA
- Shared infrastructure
- No deployment slots
- No auto-scale
- Use: Learning, prototypes, personal projects
- **Limitations:** App sleeps after 20 min inactivity

**Shared (D1):**
- 1 GB RAM, 1 GB storage
- 240 CPU minutes/day
- 100 apps per plan
- Custom domains: Yes
- SSL: SNI SSL only
- $10/month
- Shared infrastructure
- No deployment slots
- No auto-scale
- Use: Personal websites, small blogs
- **Limitations:** Still shared compute

**Basic (B1, B2, B3):**
- B1: 1 core, 1.75 GB RAM, 10 GB storage, $55/month
- B2: 2 cores, 3.5 GB RAM, 10 GB storage, $110/month
- B3: 4 cores, 7 GB RAM, 10 GB storage, $220/month
- Manual scale: Up to 3 instances
- Custom domains: Unlimited
- SSL: SNI SSL and IP SSL
- SLA: 99.95%
- Dedicated compute
- No deployment slots
- No auto-scale
- No VNet integration
- Use: Low-traffic production apps, dev/test
- **When to use:** Small production apps without auto-scale needs

**Standard (S1, S2, S3):**
- S1: 1 core, 1.75 GB RAM, 50 GB storage, $70/month
- S2: 2 cores, 3.5 GB RAM, 50 GB storage, $140/month
- S3: 4 cores, 7 GB RAM, 50 GB storage, $280/month
- Auto-scale: Up to 10 instances
- Deployment slots: 5
- Daily backups: 10 per day
- Custom domains: Unlimited
- SSL: SNI SSL and IP SSL
- SLA: 99.95%
- Traffic Manager integration
- Use: Production web apps, APIs
- **When to use:** Standard production workloads

**Premium V2 (P1v2, P2v2, P3v2):**
- P1v2: 1 core, 3.5 GB RAM, 250 GB storage, $146/month
- P2v2: 2 cores, 7 GB RAM, 250 GB storage, $292/month
- P3v2: 4 cores, 14 GB RAM, 250 GB storage, $584/month
- Auto-scale: Up to 20 instances
- Deployment slots: 20
- Daily backups: 50 per day
- SLA: 99.95%
- Faster performance than Standard
- Use: High-traffic production apps

**Premium V3 (P0v3, P1v3, P2v3, P3v3):**
- P0v3: 1 core, 4 GB RAM, 250 GB storage, $106/month
- P1v3: 2 cores, 8 GB RAM, 250 GB storage, $212/month
- P2v3: 4 cores, 16 GB RAM, 250 GB storage, $424/month
- P3v3: 8 cores, 32 GB RAM, 250 GB storage, $848/month
- P1mv3: 2 cores, 16 GB RAM, 250 GB storage, $424/month (memory optimized)
- P2mv3: 4 cores, 32 GB RAM, 250 GB storage, $848/month
- P3mv3: 8 cores, 64 GB RAM, 250 GB storage, $1,696/month
- P4mv3: 16 cores, 128 GB RAM, 250 GB storage, $3,392/month
- P5mv3: 32 cores, 256 GB RAM, 250 GB storage, $6,784/month
- Auto-scale: Up to 30 instances
- Deployment slots: 20
- Daily backups: 50 per day
- VNet integration: Yes
- Private endpoints: Yes
- SLA: 99.95%
- Dv3 series VMs
- Use: High-performance production apps
- **When to use:** Performance-critical applications

**Isolated (I1v2, I2v2, I3v2):**
- I1v2: 2 cores, 8 GB RAM, 250 GB storage, $540/month
- I2v2: 4 cores, 16 GB RAM, 250 GB storage, $1,080/month
- I3v2: 8 cores, 32 GB RAM, 250 GB storage, $2,160/month
- I4v2: 16 cores, 64 GB RAM, 250 GB storage, $4,320/month
- I5v2: 32 cores, 128 GB RAM, 250 GB storage, $8,640/month
- I6v2: 64 cores, 256 GB RAM, 250 GB storage, $17,280/month
- App Service Environment (ASE) v3
- Complete network isolation
- Dedicated environment
- Auto-scale: Up to 100 instances per plan
- Deployment slots: 20
- SLA: 99.95%
- Private VNet deployment
- Internal load balancer
- Use: Compliance requirements, high security, massive scale
- **When to use:** Regulatory compliance, complete isolation needed

**App Service Environment (ASE) v3:**
- Pricing: $1,008/month base + instance costs
- Single-tenant environment
- Deployed into your VNet
- Internal or external load balancer
- Up to 200 instances
- Zone redundancy support
- Features:
  - Network isolation
  - High scale
  - Secure access
  - Compliance support
  - Custom DNS
  - IP SSL addresses

**Deployment Slots:**
- Production slot: Always exists
- Non-production slots: Based on tier
- Features:
  - Swap with validation
  - Auto swap
  - Slot-specific settings
  - Traffic routing (A/B testing)
  - Warm-up before swap
- Use cases:
  - Blue-green deployments
  - Staging environments
  - A/B testing
  - Gradual rollouts

**Auto-scaling:**
- Scale-out rules:
  - CPU percentage
  - Memory percentage
  - HTTP queue length
  - Data In/Out
  - Custom metrics
- Schedule-based scaling
- Min/max instances
- Cool-down period
- Scale-in rules
- Notifications

**Backup and Restore:**
- Automatic backups (Premium+)
- On-demand backups
- Backup includes:
  - App configuration
  - File content
  - Connected databases
- Restore options:
  - Overwrite existing
  - New app
  - Specific slot
- Retention: Up to 30 days

**Networking Features:**
- VNet Integration:
  - Regional VNet integration
  - Gateway-required VNet integration
  - Access private resources
- Hybrid Connections:
  - Connect to on-premises
  - No VPN required
  - TCP-based
- Private Endpoints:
  - Inbound private connectivity
  - Disable public access
- Service Endpoints:
  - Secure outbound to Azure services
- Access Restrictions:
  - IP-based rules
  - Service Tag rules
  - VNet rules

**Security Features:**
- Managed identities (System/User-assigned)
- Authentication/Authorization (Easy Auth)
- SSL/TLS enforcement
- Client certificates
- IP restrictions
- Azure AD integration
- Key Vault references
- Always On SSL
- Minimum TLS version

**Monitoring and Diagnostics:**
- Application Insights integration
- App Service logs:
  - Application logging
  - Web server logging
  - Detailed error messages
  - Failed request tracing
  - Deployment logging
- Metrics:
  - CPU time
  - Memory usage
  - Data In/Out
  - HTTP requests
  - Response time
  - HTTP errors
- Alerts and notifications
- Log streaming
- Diagnostic settings

**Limits:**
- Apps per plan: 100 (Free/Shared), Unlimited (others)
- Instances: 3 (Basic), 10 (Standard), 30 (Premium), 100 (Isolated)
- Storage: 1 GB (Free), 10 GB (Basic), 50 GB (Standard), 250 GB (Premium+)
- Backups: 10/day (Standard), 50/day (Premium+)
- Custom domains: 500 per app
- SSL bindings: Unlimited SNI SSL, 1 IP SSL (Basic), Unlimited (Standard+)

**Best Practices:**
✅ Use deployment slots for zero-downtime deployments
✅ Enable Application Insights for monitoring
✅ Configure auto-scaling for variable loads
✅ Use managed identities instead of connection strings
✅ Enable Always On for production apps
✅ Configure health checks
✅ Use VNet integration for secure backend access
✅ Enable diagnostic logging
✅ Implement proper backup strategy
✅ Use slot-specific settings appropriately

### Azure Functions - Complete Guide

**Overview:**
Serverless compute service that enables event-driven code execution without managing infrastructure. Pay only for execution time.

**Key Features:**
- Event-driven architecture
- Multiple language support: C#, Java, JavaScript, Python, PowerShell, TypeScript
- Triggers: HTTP, Timer, Queue, Blob, Event Hub, Cosmos DB, Service Bus, Event Grid
- Bindings: Input and output bindings for easy integration
- Durable Functions: Stateful workflows
- Function chaining and fan-out/fan-in patterns
- Built-in authentication
- CORS support
- Integrated monitoring with Application Insights
- Local development and testing
- CI/CD integration

**Hosting Plans:**

**Consumption Plan:**
- Pay per execution
- $0.20 per million executions
- $0.000016/GB-s for memory
- 1 million free executions/month
- Auto-scale to zero
- 5-minute timeout (default)
- Use: Event-driven, sporadic workloads

**Premium Plan:**
- EP1: 1 core, 3.5 GB RAM, $168/month
- EP2: 2 cores, 7 GB RAM, $336/month
- EP3: 4 cores, 14 GB RAM, $672/month
- Pre-warmed instances
- VNet integration
- Unlimited timeout
- Use: High-performance, predictable workloads

**Dedicated (App Service Plan):**
- Same pricing as App Service
- Runs on existing App Service plan
- Use: Existing App Service infrastructure

### Azure Kubernetes Service (AKS)

**Control Plane:** Free (managed by Azure)

**Worker Nodes:**
- Standard_D2s_v3: 2 vCPU, 8 GB RAM, $96/month
- Standard_D4s_v3: 4 vCPU, 16 GB RAM, $192/month
- Standard_D8s_v3: 8 vCPU, 32 GB RAM, $384/month

**Example Cluster Cost:**
- 3 system nodes (D2s_v3): $288/month
- 5 user nodes (D4s_v3): $960/month
- Load Balancer: $20/month
- Public IP: $4/month
- **Total: ~$1,272/month**

## Storage Services - Complete Guide

### Blob Storage Tiers

**Hot Tier:**
- Storage: $0.0184/GB/month
- Write: $0.05 per 10,000 operations
- Read: $0.004 per 10,000 operations
- Use: Frequently accessed data

**Cool Tier:**
- Storage: $0.01/GB/month
- Write: $0.10 per 10,000 operations
- Read: $0.01 per 10,000 operations
- Early deletion fee: < 30 days
- Use: Infrequently accessed (30+ days)

**Archive Tier:**
- Storage: $0.00099/GB/month
- Write: $0.11 per 10,000 operations
- Read: $5.50 per 10,000 operations
- Rehydration: $0.02/GB (high priority)
- Early deletion fee: < 180 days
- Use: Rarely accessed (180+ days)

**Premium Block Blob:**
- Storage: $0.15/GB/month
- Operations: $0.0045 per 10,000
- Low latency (< 10ms)
- Use: High IOPS workloads

### Azure Files

**Transaction Optimized:**
- Storage: $0.12/GB/month
- Operations: $0.01 per 10,000
- Use: General purpose file shares

**Hot:**
- Storage: $0.0255/GB/month
- Operations: $0.01 per 10,000
- Use: Team shares, lift-and-shift

**Cool:**
- Storage: $0.015/GB/month
- Operations: $0.05 per 10,000
- Use: Archive, backup

**Premium:**
- Storage: $0.20/GB/month (provisioned)
- IOPS: Included based on size
- Use: High-performance workloads

### Managed Disks

**Standard HDD:**
- S4 (32 GB): $1.54/month, 500 IOPS
- S30 (1 TB): $38.40/month, 500 IOPS
- Use: Backup, non-critical

**Standard SSD:**
- E4 (32 GB): $2.40/month, 500 IOPS
- E30 (1 TB): $76.80/month, 500 IOPS
- Use: Web servers, dev/test

**Premium SSD:**
- P4 (32 GB): $6.08/month, 120 IOPS
- P30 (1 TB): $135.17/month, 5,000 IOPS
- Use: Production VMs

**Ultra Disk:**
- $0.000145/GB/hour + IOPS + throughput
- Up to 160,000 IOPS
- Sub-millisecond latency
- Use: SAP HANA, SQL Server, Cassandra

## Database Services - Detailed Comparison

### Azure SQL Database

**DTU Model:**

**Basic:**
- 5 DTUs, 2 GB storage
- $5/month
- Use: Learning, very small apps

**Standard:**
- S0: 10 DTUs, $15/month
- S3: 100 DTUs, $152/month
- S12: 3000 DTUs, $4,551/month
- Use: Most applications

**Premium:**
- P1: 125 DTUs, $465/month
- P6: 2000 DTUs, $7,451/month
- P15: 4000 DTUs, $14,902/month
- Use: Mission-critical apps

**vCore Model:**

**General Purpose:**
- 2 vCore: $365/month
- 8 vCore: $1,460/month
- 80 vCore: $14,600/month
- 5-10ms latency
- Use: Most workloads

**Business Critical:**
- 2 vCore: $730/month
- 8 vCore: $2,920/month
- 80 vCore: $29,200/month
- 1-2ms latency
- Built-in read replica
- Use: Low-latency apps

**Hyperscale:**
- 2 vCore: $548/month
- 8 vCore: $2,190/month
- Up to 100 TB
- Rapid scale
- Use: Large databases

### Azure Cosmos DB

**Provisioned Throughput:**
- $0.008 per RU/s per hour
- 100 RU/s minimum
- Example: 10,000 RU/s = $584/month

**Serverless:**
- $0.25 per million RUs consumed
- $0.25/GB storage per month
- Use: Unpredictable workloads

**Autoscale:**
- $0.012 per RU/s per hour (max)
- Scales between 10% and 100%
- Example: 10,000 RU/s max = $876/month

**Multi-region:**
- Multiply by number of regions
- 2 regions = 2x cost
- 5 regions = 5x cost

### Azure Database for PostgreSQL/MySQL

**Flexible Server:**

**Burstable:**
- B1ms: 1 vCore, 2 GB RAM, $12/month
- B2s: 2 vCore, 4 GB RAM, $48/month
- Use: Dev/test

**General Purpose:**
- D2s_v3: 2 vCore, 8 GB RAM, $146/month
- D16s_v3: 16 vCore, 64 GB RAM, $1,168/month
- Use: Production workloads

**Memory Optimized:**
- E2s_v3: 2 vCore, 16 GB RAM, $183/month
- E32s_v3: 32 vCore, 256 GB RAM, $2,928/month
- Use: Memory-intensive workloads

## Networking Services - Complete Pricing

### VPN Gateway

**Basic:**
- $27/month
- 10 tunnels
- 100 Mbps
- Use: Dev/test

**VpnGw1:**
- $140/month
- 30 tunnels
- 650 Mbps
- Use: Small production

**VpnGw2:**
- $360/month
- 30 tunnels
- 1 Gbps
- Use: Medium production

**VpnGw3:**
- $1,200/month
- 30 tunnels
- 1.25 Gbps
- Use: Large production

**VpnGw1AZ (Zone-redundant):**
- $170/month
- 99.99% SLA
- Use: High availability

### ExpressRoute

**Local:**
- Unlimited data: $55/month
- Use: Same metro area

**Standard:**
- 50 Mbps: $55/month
- 100 Mbps: $560/month
- 1 Gbps: $1,627/month
- 10 Gbps: $6,510/month

**Premium:**
- 50 Mbps: $630/month
- 100 Mbps: $1,260/month
- 1 Gbps: $3,700/month
- 10 Gbps: $14,800/month
- Global connectivity

### Load Balancer

**Basic:**
- Free
- No SLA
- Use: Dev/test

**Standard:**
- $18/month
- $0.005 per GB processed
- 99.99% SLA
- Use: Production

### Application Gateway

**Standard_v2:**
- $0.246/hour (capacity unit)
- $0.008/GB processed
- ~$180/month base

**WAF_v2:**
- $0.443/hour (capacity unit)
- $0.008/GB processed
- ~$324/month base

### Azure Firewall

**Standard:**
- $1.25/hour = $912/month
- $0.016/GB processed
- Use: Basic firewall needs

**Premium:**
- $1.75/hour = $1,277/month
- $0.016/GB processed
- IDPS, TLS inspection
- Use: Advanced security

### Azure Front Door

**Classic:**
- $35/month base
- $0.0225/GB outbound
- $0.02 per 10,000 requests

**Standard:**
- $35/month base
- $0.03/GB outbound
- $0.0075 per 10,000 requests

**Premium:**
- $330/month base
- $0.03/GB outbound
- $0.0075 per 10,000 requests
- WAF, Private Link

## Monitoring and Management

### Azure Monitor

**Log Analytics:**
- First 5 GB/day: Free
- $2.30/GB ingested
- 31-day retention included
- $0.12/GB/month for additional retention

**Application Insights:**
- First 5 GB/day: Free
- $2.30/GB ingested
- 90-day retention included

**Metrics:**
- Platform metrics: Free
- Custom metrics: $0.10 per metric

**Alerts:**
- Metric alerts: $0.10 per alert rule
- Log alerts: $1.50 per alert rule

### Azure Backup

**Azure VM Backup:**
- Protected instance: $10/month
- Storage: $0.10/GB (LRS), $0.20/GB (GRS)

**SQL Server in Azure VM:**
- Protected instance: $15/month
- Storage: $0.10/GB

**Azure Files:**
- Protected instance: $10/month
- Storage: $0.10/GB

### Azure Site Recovery

**Azure to Azure:**
- $25 per protected instance/month
- Storage: Standard rates

**VMware/Physical to Azure:**
- $25 per protected instance/month
- Process server: Free

## Security Services

### Azure Key Vault

**Standard:**
- $0.03 per 10,000 operations
- Secrets: Free
- Keys: $1/month per key
- Certificates: $3/month per certificate

**Premium:**
- HSM-protected keys: $5/month per key
- HSM operations: $1 per 10,000

### Azure AD (Entra ID)

**Free:**
- 500,000 objects
- SSO, MFA
- Use: Small organizations

**Premium P1:**
- $6/user/month
- Conditional Access
- Self-service password reset
- Use: Enterprise features

**Premium P2:**
- $9/user/month
- Identity Protection
- Privileged Identity Management
- Use: Advanced security

### Microsoft Defender for Cloud

**Free:**
- Secure score
- Recommendations
- Use: Basic security

**Defender for Servers:**
- $15/server/month
- Threat detection
- Use: VM protection

**Defender for SQL:**
- $15/server/month
- Vulnerability assessment
- Use: Database protection

**Defender for Storage:**
- $10/storage account/month
- Malware scanning
- Use: Storage protection

## Cost Optimization Strategies

### Reserved Instances

**1-Year Reserved:**
- ~40% savings
- Pay monthly or upfront

**3-Year Reserved:**
- ~60% savings
- Pay monthly or upfront

**Example:**
- D4s_v3 VM: $192/month (pay-as-you-go)
- 1-year reserved: $115/month (40% savings)
- 3-year reserved: $77/month (60% savings)

### Azure Hybrid Benefit

**Windows Server:**
- Save up to 40% on VMs
- Use existing licenses

**SQL Server:**
- Save up to 55% on Azure SQL
- Use existing licenses

### Spot VMs

**Pricing:**
- Up to 90% discount
- Can be evicted with 30-second notice
- Use: Batch jobs, dev/test, stateless workloads

### Auto-shutdown

**Dev/Test VMs:**
- Schedule shutdown at night
- Save ~50% on compute costs
- Example: $192/month → $96/month

## Service Limits and Quotas

### Compute Limits (per subscription per region)

- VMs: 25,000
- vCPUs: 350 (default, can increase)
- VM Scale Sets: 2,500
- AKS clusters: 100
- App Service plans: 100

### Networking Limits

- VNets: 1,000
- Subnets per VNet: 3,000
- VNet peerings: 500
- NSGs: 5,000
- NSG rules: 1,000 per NSG
- Public IPs: 1,000
- Load Balancers: 1,000

### Storage Limits

- Storage accounts: 250
- Max capacity per account: 5 PB
- Max blob size: 190.7 TB (block blob)
- Max IOPS per disk: 160,000 (Ultra)
- Max throughput per disk: 4,000 MB/s (Ultra)

### Database Limits

- SQL Databases: 500 per server
- Max database size: 4 TB (DTU), 100 TB (Hyperscale)
- Cosmos DB: 50 accounts (default)
- Max RU/s per container: 1,000,000

## Container Services - Complete Guide

### Azure Container Instances (ACI)

**Pricing:**
- Linux: $0.0000125/vCPU/second + $0.0000014/GB/second
- Windows: $0.0000175/vCPU/second + $0.0000028/GB/second

**Example:**
- 1 vCPU, 1 GB RAM, running 24/7
- Linux: ~$11/month
- Windows: ~$18/month

**Use Cases:**
- Burst workloads
- CI/CD build agents
- Batch jobs
- Event-driven applications

### Azure Container Registry (ACR)

**Basic:**
- $5/day = $150/month
- 10 GB storage included
- 10 webhooks
- Use: Dev/test

**Standard:**
- $20/day = $600/month
- 100 GB storage included
- 100 webhooks
- Geo-replication: No
- Use: Small production

**Premium:**
- $50/day = $1,500/month
- 500 GB storage included
- 500 webhooks
- Geo-replication: Yes
- Content trust, Private Link
- Use: Enterprise production

### Azure Container Apps

**Consumption:**
- $0.000024/vCPU/second
- $0.000003/GB/second
- 180,000 vCPU-seconds free/month
- 360,000 GB-seconds free/month

**Example:**
- 0.5 vCPU, 1 GB RAM, 1M requests/month
- ~$15-30/month

**Use Cases:**
- Microservices
- API backends
- Event-driven apps
- Background workers

## Integration Services

### Azure Service Bus

**Basic:**
- $0.05 per million operations
- 256 KB message size
- No topics
- Use: Simple messaging

**Standard:**
- $10/month base + $0.80 per million operations
- 256 KB message size
- Topics and subscriptions
- Use: Enterprise messaging

**Premium:**
- 1 messaging unit: $677/month
- 1 MB message size
- Dedicated resources
- VNet integration
- Use: High-throughput, isolation

### Azure Event Grid

**Pricing:**
- $0.60 per million operations
- First 100,000 operations/month: Free

**Use Cases:**
- Event-driven architectures
- Serverless applications
- Reactive programming
- IoT telemetry

### Azure Event Hubs

**Basic:**
- $11/month
- 1 consumer group
- 100 brokered connections
- 1 MB/s ingress
- Use: Dev/test

**Standard:**
- $22/month per throughput unit
- 20 consumer groups
- 1,000 brokered connections
- 1 MB/s ingress per TU
- Use: Production streaming

**Premium:**
- $1,113/month per processing unit
- 100 consumer groups
- 10,000 brokered connections
- 1 MB/s ingress per PU
- Use: Mission-critical streaming

**Dedicated:**
- $8,671/month (1 capacity unit)
- Single-tenant deployment
- Use: Massive scale

### Azure Logic Apps

**Consumption:**
- $0.000025 per action execution
- Built-in actions: Included
- Standard connectors: $0.000125/action
- Enterprise connectors: $0.001/action

**Standard:**
- $0.1946/hour per workflow
- ~$142/month per workflow
- VNet integration
- Use: Complex integrations

### Azure API Management

**Consumption:**
- $3.50 per million calls
- $0.035 per GB bandwidth
- Auto-scale
- Use: Serverless APIs

**Developer:**
- $50/month
- No SLA
- 1 unit, 1 gateway
- Use: Non-production

**Basic:**
- $150/month
- 99.95% SLA
- 2 units max
- Use: Small production

**Standard:**
- $700/month
- 99.95% SLA
- 4 units max
- Multi-region
- Use: Production

**Premium:**
- $2,800/month per unit
- 99.99% SLA
- Unlimited units
- VNet integration
- Use: Enterprise

## Analytics Services

### Azure Synapse Analytics

**Serverless SQL Pool:**
- $5 per TB processed
- Pay per query
- Use: Ad-hoc queries

**Dedicated SQL Pool (formerly SQL DW):**
- DW100c: $1.20/hour = $876/month
- DW500c: $6/hour = $4,380/month
- DW1000c: $12/hour = $8,760/month
- DW3000c: $36/hour = $26,280/month
- Use: Data warehousing

**Apache Spark Pool:**
- Small (4 vCores, 32 GB): $0.36/hour
- Medium (8 vCores, 64 GB): $0.72/hour
- Large (16 vCores, 128 GB): $1.44/hour
- Use: Big data processing

### Azure Data Factory

**Data Pipeline:**
- $1 per 1,000 activity runs
- $0.25 per hour for orchestration

**Data Flow:**
- General Purpose: $0.27/vCore/hour
- Memory Optimized: $0.35/vCore/hour

**Example:**
- 100 pipelines, 10,000 activities/month
- ~$50-100/month

### Azure Databricks

**Standard:**
- $0.40/DBU + VM cost
- Use: Data engineering

**Premium:**
- $0.55/DBU + VM cost
- RBAC, audit logs
- Use: Enterprise analytics

**Example:**
- Standard_DS3_v2 (4 cores, 14 GB): $0.27/hour
- Premium tier: $0.55/DBU × 1.5 DBU = $0.825/hour
- Total: ~$1.10/hour = $803/month

### Azure HDInsight

**Hadoop:**
- D3 v2 (4 cores, 14 GB): $0.27/hour
- D4 v2 (8 cores, 28 GB): $0.54/hour
- Use: Batch processing

**Spark:**
- D12 v2 (4 cores, 28 GB): $0.54/hour
- D13 v2 (8 cores, 56 GB): $1.08/hour
- Use: In-memory processing

**Kafka:**
- D3 v2: $0.27/hour
- D4 v2: $0.54/hour
- Use: Streaming

### Azure Stream Analytics

**Standard:**
- $0.11 per streaming unit per hour
- 1 SU = 1 MB/s throughput
- Example: 3 SUs = $240/month

**Use Cases:**
- Real-time analytics
- IoT data processing
- Fraud detection
- Live dashboards

## AI and Machine Learning

### Azure Machine Learning

**Compute Instances:**
- Standard_DS3_v2: $0.27/hour
- Standard_NC6: $0.90/hour (GPU)
- Standard_ND40rs_v2: $27.20/hour (8x V100)

**Compute Clusters:**
- Same as VM pricing
- Auto-scale to zero
- Use: Training workloads

**Inference:**
- AKS deployment: AKS pricing
- ACI deployment: ACI pricing
- Managed endpoints: $0.50/hour per instance

### Azure Cognitive Services

**Computer Vision:**
- 0-1M transactions: $1 per 1,000
- 1M-10M: $0.65 per 1,000
- 10M+: $0.40 per 1,000

**Face API:**
- 0-1M transactions: $1 per 1,000
- 1M-10M: $0.65 per 1,000

**Speech Services:**
- Speech-to-Text: $1 per hour
- Text-to-Speech: $16 per 1M characters
- Neural voices: $16 per 1M characters

**Language Services:**
- Text Analytics: $2 per 1,000 records
- Translator: $10 per million characters
- LUIS: $1.50 per 1,000 transactions

**OpenAI Service:**
- GPT-4: $0.03 per 1K prompt tokens, $0.06 per 1K completion tokens
- GPT-3.5-turbo: $0.0015 per 1K prompt tokens, $0.002 per 1K completion tokens
- DALL-E 3: $0.04-0.12 per image

### Azure Bot Service

**Free:**
- Unlimited messages on standard channels
- Use: Development

**S1:**
- $0.50 per 1,000 premium channel messages
- Standard channels: Free
- Use: Production

## IoT Services

### Azure IoT Hub

**Free:**
- 8,000 messages/day
- 1 IoT Hub
- Use: Development

**Basic:**
- B1: $10/month + $0.0008 per message
- B2: $50/month + $0.0004 per message
- B3: $500/month + $0.00002 per message
- Use: One-way communication

**Standard:**
- S1: $25/month + $0.0008 per message
- S2: $250/month + $0.0004 per message
- S3: $2,500/month + $0.00002 per message
- Cloud-to-device messaging
- Use: Full IoT features

### Azure IoT Central

**Pricing:**
- $0.60 per device per month (0-20K devices)
- $0.30 per device per month (20K-1M devices)
- $0.15 per device per month (1M+ devices)

**Use Cases:**
- SaaS IoT solution
- No infrastructure management
- Pre-built templates

### Azure Digital Twins

**Pricing:**
- $3 per 1,000 operations
- $0.875 per GB storage per month
- $0.25 per 1,000 query units

**Use Cases:**
- Smart buildings
- Manufacturing
- Supply chain
- Spatial intelligence

## DevOps Services

### Azure DevOps

**Basic Plan:**
- First 5 users: Free
- Additional users: $6/user/month
- Unlimited private repos
- 2,000 build minutes/month

**Azure Pipelines:**
- 1 free parallel job (1,800 minutes/month)
- Additional parallel job: $40/month
- Self-hosted: Free unlimited

**Azure Artifacts:**
- 2 GB free storage
- Additional: $2/GB/month

### GitHub Actions (Azure-hosted)

**Free:**
- 2,000 minutes/month (public repos unlimited)
- 500 MB storage

**Pro:**
- $4/user/month
- 3,000 minutes/month

**Team:**
- $4/user/month
- 3,000 minutes/month

**Enterprise:**
- $21/user/month
- 50,000 minutes/month

### Azure Automation

**Process Automation:**
- 500 minutes free/month
- $0.002 per minute after

**Configuration Management:**
- First 5 nodes: Free
- Additional nodes: $5/node/month

**Update Management:**
- Free for Azure VMs
- $5/node/month for non-Azure

## Migration Services

### Azure Migrate

**Service:** Free

**Assessment:**
- Dependency analysis: Free
- Use: Discovery and assessment

**Migration:**
- Azure Site Recovery: $25/instance/month
- Database Migration Service: Free (Standard), $0.462/hour (Premium)

### Azure Database Migration Service

**Standard:**
- Free
- Offline migrations
- Use: One-time migrations

**Premium:**
- 1 vCore: $0.462/hour = $337/month
- 4 vCore: $1.848/hour = $1,349/month
- Online migrations
- Use: Minimal downtime

### Azure Data Box

**Data Box Disk (8 TB):**
- $25 per order
- Use: < 40 TB

**Data Box (100 TB):**
- $200 per order
- Use: 40-500 TB

**Data Box Heavy (1 PB):**
- $500 per order
- Use: > 500 TB

## Media Services

### Azure Media Services

**Encoding:**
- Standard Encoder: $0.015 per minute (output)
- Premium Encoder: $0.105 per minute (output)

**Streaming:**
- Standard Streaming Endpoint: $0.0004/hour
- Premium Streaming Endpoint: $0.0011/hour per unit

**Live Streaming:**
- Standard Pass-through: $0.526/hour
- Premium Pass-through: $2.632/hour
- Standard Encoding: $2.632/hour

### Azure Content Delivery Network (CDN)

**Microsoft CDN:**
- First 10 TB: $0.081/GB
- 10-50 TB: $0.070/GB
- 50+ TB: $0.060/GB

**Verizon Standard:**
- First 10 TB: $0.138/GB
- 10-50 TB: $0.125/GB

**Akamai Standard:**
- First 10 TB: $0.169/GB
- 10-50 TB: $0.155/GB

## Hybrid and Multi-Cloud

### Azure Arc

**Arc-enabled Servers:**
- Free for Azure services
- $6/server/month for Defender

**Arc-enabled Kubernetes:**
- Free for Azure services
- $2/vCore/month for Azure Policy

**Arc-enabled Data Services:**
- SQL Managed Instance: Same as Azure SQL MI
- PostgreSQL Hyperscale: Same as Azure PostgreSQL

### Azure Stack Hub

**Capacity-based:**
- $0.008/vCPU/hour
- Minimum: 12 nodes

**Pay-as-you-use:**
- Windows VM: $0.0451/vCPU/hour
- Linux VM: $0.0294/vCPU/hour

### Azure Stack HCI

**Pricing:**
- $10/physical core/month
- Example: 2 servers × 16 cores = $320/month

**Use Cases:**
- VDI
- Branch office
- Azure Kubernetes Service on-premises

## Governance and Compliance

### Azure Policy

**Service:** Free

**Features:**
- Policy definitions
- Compliance dashboard
- Remediation tasks
- Guest Configuration: $6/server/month

### Azure Blueprints

**Service:** Free

**Features:**
- Environment templates
- Compliance tracking
- Version control

### Azure Cost Management

**Service:** Free for Azure

**Third-party clouds:**
- AWS: 1% of managed spend
- GCP: 1% of managed spend

### Azure Advisor

**Service:** Free

**Recommendations:**
- Cost optimization
- Security
- Reliability
- Operational excellence
- Performance

## Identity and Access Management

### Azure AD B2C

**MAU Pricing:**
- First 50,000 MAU: Free
- Next 50,000 MAU: $0.00325/MAU
- Next 400,000 MAU: $0.0016/MAU
- 500,000+ MAU: $0.00013/MAU

**MFA:**
- $0.03 per authentication

### Azure AD Domain Services

**Standard:**
- $109/month
- 2 domain controllers
- Use: Basic AD DS

**Enterprise:**
- $150/month
- 2 domain controllers
- Forest trusts
- Use: Advanced scenarios

**Premium:**
- $300/month
- 5 domain controllers
- Use: High availability

### Azure AD Privileged Identity Management

**Included in:**
- Azure AD Premium P2: $9/user/month

**Features:**
- Just-in-time access
- Time-bound access
- Approval workflows
- Access reviews

## Disaster Recovery and Business Continuity

### Azure Backup - Extended

**Azure VM Backup:**
- Instance: $10/month
- Storage (LRS): $0.10/GB
- Storage (GRS): $0.20/GB
- Storage (RA-GRS): $0.25/GB

**Example:**
- 10 VMs, 1 TB backup data (GRS)
- Instance: $100/month
- Storage: $200/month
- Total: $300/month

### Azure Site Recovery - Extended

**Replication:**
- Azure to Azure: $25/instance/month
- VMware to Azure: $25/instance/month
- Hyper-V to Azure: $25/instance/month
- Physical to Azure: $25/instance/month

**Failover:**
- Compute: Standard VM pricing during failover
- Storage: Standard storage pricing

**Example:**
- 20 VMs replicated to Azure
- Replication: $500/month
- Storage (1 TB): $100/month
- Total: $600/month (standby)

## Specialized Services

### Azure Quantum

**Pricing:**
- IonQ: $0.00003 per gate-shot
- Honeywell: $0.00012 per HQC
- Microsoft QIO: $0.17 per hour

**Free Credits:**
- $500 Azure Quantum Credits

### Azure Confidential Computing

**DC-series VMs:**
- DC1s_v2: 1 vCPU, 4 GB RAM, $0.144/hour
- DC8_v2: 8 vCPU, 32 GB RAM, $1.152/hour
- Use: Encrypted data in use

### Azure VMware Solution

**Pricing:**
- $8.04/core/hour
- Minimum: 3 hosts (36 cores each)
- Example: 3 hosts = $20,904/month

**Use Cases:**
- VMware migration
- Disaster recovery
- Data center extension

### Azure HPC Cache

**Pricing:**
- $0.90/TB/hour
- 3 TB minimum
- Example: 12 TB = $7,776/month

**Use Cases:**
- High-performance computing
- Media rendering
- Genomics

### Azure Batch

**Compute:**
- Pay for underlying VMs only
- No additional charge for Batch service

**Low-priority VMs:**
- Up to 80% discount
- Can be preempted

**Use Cases:**
- Large-scale parallel jobs
- Rendering
- Simulations

## Service Comparison Tables

### Compute Services Comparison

| Service | Best For | Scaling | Management | Cost Model |
|---------|----------|---------|------------|------------|
| VMs | Full control | Manual/VMSS | High | Per hour |
| App Service | Web apps | Auto | Low | Per hour |
| Functions | Event-driven | Auto to zero | Minimal | Per execution |
| AKS | Containers | Auto | Medium | Per node |
| Container Apps | Microservices | Auto to zero | Low | Per second |
| ACI | Burst workloads | Manual | Low | Per second |

### Database Services Comparison

| Service | Type | Max Size | Scaling | Best For |
|---------|------|----------|---------|----------|
| SQL Database | Relational | 100 TB | Auto | OLTP |
| Cosmos DB | NoSQL | Unlimited | Auto | Global apps |
| PostgreSQL | Relational | 16 TB | Manual | Open source |
| MySQL | Relational | 16 TB | Manual | Open source |
| Synapse | Data warehouse | Unlimited | Manual | Analytics |
| Table Storage | NoSQL | 500 TB | Auto | Simple data |

### Storage Services Comparison

| Service | Type | Max Size | Performance | Best For |
|---------|------|----------|-------------|----------|
| Blob Storage | Object | 5 PB | High | Unstructured data |
| Files | File share | 100 TB | Medium | Shared files |
| Disk | Block | 64 TB | Very High | VM storage |
| Queue | Message | 500 TB | Medium | Async messaging |
| Table | NoSQL | 500 TB | Medium | Structured NoSQL |

## Best Practices Summary

### Cost Optimization
✅ Use Reserved Instances for predictable workloads (40-60% savings)
✅ Enable auto-shutdown for dev/test resources
✅ Implement auto-scaling based on metrics
✅ Use Spot VMs for fault-tolerant workloads (up to 90% savings)
✅ Right-size VMs based on actual utilization
✅ Use Azure Hybrid Benefit for existing licenses
✅ Choose appropriate storage tiers (Hot/Cool/Archive)
✅ Set up budgets and cost alerts
✅ Use serverless options for variable workloads
✅ Delete unused resources and orphaned disks

### Performance Optimization
✅ Use Premium SSD for production workloads
✅ Enable accelerated networking for VMs
✅ Use CDN for static content delivery
✅ Implement caching strategies (Redis, CDN)
✅ Use proximity placement groups for low latency
✅ Enable zone redundancy for high availability
✅ Use read replicas for read-heavy workloads
✅ Implement connection pooling for databases
✅ Use managed disks for better reliability
✅ Monitor and optimize query performance

### Security Best Practices
✅ Enable Azure AD authentication
✅ Use managed identities instead of credentials
✅ Implement network segmentation with NSGs
✅ Enable encryption at rest and in transit
✅ Use Azure Key Vault for secrets management
✅ Enable Azure Defender for threat protection
✅ Implement least privilege access (RBAC)
✅ Enable audit logging and monitoring
✅ Use Private Link for secure connectivity
✅ Regular security assessments and updates

### High Availability
✅ Deploy across availability zones
✅ Use geo-redundant storage for critical data
✅ Implement load balancing and traffic distribution
✅ Set up automated backups and disaster recovery
✅ Use health probes and auto-healing
✅ Implement retry logic and circuit breakers
✅ Test failover procedures regularly
✅ Use multiple regions for global applications
✅ Monitor SLA compliance
✅ Document recovery procedures

### Monitoring and Operations
✅ Enable Azure Monitor for all resources
✅ Set up alerts for critical metrics
✅ Use Log Analytics for centralized logging
✅ Implement Application Insights for apps
✅ Create dashboards for visibility
✅ Set up automated responses to alerts
✅ Regular review of recommendations
✅ Track and optimize costs continuously
✅ Document architecture and procedures
✅ Implement CI/CD for infrastructure

## Quick Reference - Service Selection

### When to Use What?

**Compute:**
- Full control needed → Virtual Machines
- Web/API hosting → App Service
- Event-driven → Functions
- Containers with orchestration → AKS
- Simple containers → Container Apps/ACI
- Batch processing → Azure Batch

**Storage:**
- Unstructured data → Blob Storage
- File shares → Azure Files
- VM disks → Managed Disks
- Archive → Archive tier Blob
- High IOPS → Premium SSD/Ultra Disk

**Database:**
- Relational OLTP → SQL Database
- Global distribution → Cosmos DB
- Open source → PostgreSQL/MySQL
- Data warehouse → Synapse Analytics
- Caching → Redis Cache
- Simple key-value → Table Storage

**Networking:**
- Site-to-site VPN → VPN Gateway
- Dedicated connection → ExpressRoute
- Load balancing → Load Balancer/App Gateway
- Global routing → Front Door/Traffic Manager
- Network security → Firewall/NSG
- DDoS protection → DDoS Protection

**Integration:**
- Enterprise messaging → Service Bus
- Event streaming → Event Hubs
- Event routing → Event Grid
- Workflow automation → Logic Apps
- API management → API Management

**Analytics:**
- Data warehouse → Synapse Analytics
- ETL/ELT → Data Factory
- Big data → Databricks/HDInsight
- Real-time analytics → Stream Analytics
- Business intelligence → Power BI

**AI/ML:**
- Custom ML models → Machine Learning
- Pre-built AI → Cognitive Services
- Conversational AI → Bot Service
- Document intelligence → Form Recognizer

---

**Last Updated: March 2026**
**© Copyright Sivakumar J**

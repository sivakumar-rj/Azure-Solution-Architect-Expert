# Complete Azure Services Guide

## Compute Services - Detailed Comparison

### Azure Virtual Machines

**VM Series Deep Dive:**

**A-Series (Entry-level):**
- A0: 1 vCPU, 0.75 GB RAM, $15/month
- A4: 8 vCPU, 14 GB RAM, $240/month
- Use: Dev/test, low-traffic websites

**B-Series (Burstable):**
- B1s: 1 vCPU, 1 GB RAM, $8/month
- B2ms: 2 vCPU, 8 GB RAM, $60/month
- Use: Variable workloads, accumulate CPU credits

**D-Series (General Purpose):**
- D2s_v5: 2 vCPU, 8 GB RAM, $96/month
- D16s_v5: 16 vCPU, 64 GB RAM, $768/month
- Use: Enterprise applications, web servers

**E-Series (Memory Optimized):**
- E2s_v5: 2 vCPU, 16 GB RAM, $122/month
- E64s_v5: 64 vCPU, 512 GB RAM, $3,942/month
- Use: SAP HANA, SQL Server, in-memory databases

**F-Series (Compute Optimized):**
- F2s_v2: 2 vCPU, 4 GB RAM, $76/month
- F72s_v2: 72 vCPU, 144 GB RAM, $2,745/month
- Use: Batch processing, gaming servers, analytics

**N-Series (GPU):**
- NC6s_v3: 6 vCPU, 112 GB RAM, 1x V100 GPU, $3,060/month
- ND96asr_v4: 96 vCPU, 900 GB RAM, 8x A100 GPU, $27,936/month
- Use: AI/ML training, rendering, simulation

**M-Series (Memory Intensive):**
- M128s: 128 vCPU, 2 TB RAM, $13,338/month
- M208ms_v2: 208 vCPU, 5.7 TB RAM, $37,440/month
- Use: SAP HANA, large in-memory databases

### Azure App Service Plans

**Free Tier:**
- 1 GB RAM, 1 GB storage
- 60 CPU minutes/day
- No custom domains
- No SLA
- Use: Learning, prototypes

**Shared (D1):**
- 1 GB RAM, 1 GB storage
- 240 CPU minutes/day
- Custom domains
- $10/month
- Use: Personal websites

**Basic (B1, B2, B3):**
- B1: 1 core, 1.75 GB RAM, $55/month
- B2: 2 cores, 3.5 GB RAM, $110/month
- B3: 4 cores, 7 GB RAM, $220/month
- Manual scale up to 3 instances
- Custom domains, SSL
- Use: Low-traffic production apps

**Standard (S1, S2, S3):**
- S1: 1 core, 1.75 GB RAM, $70/month
- S2: 2 cores, 3.5 GB RAM, $140/month
- S3: 4 cores, 7 GB RAM, $280/month
- Auto-scale up to 10 instances
- 5 deployment slots
- Daily backups
- Use: Production web apps

**Premium V3 (P1v3, P2v3, P3v3):**
- P1v3: 2 cores, 8 GB RAM, $212/month
- P2v3: 4 cores, 16 GB RAM, $424/month
- P3v3: 8 cores, 32 GB RAM, $848/month
- Auto-scale up to 30 instances
- 20 deployment slots
- VNet integration
- Use: High-performance apps

**Isolated (I1v2, I2v2, I3v2):**
- I1v2: 2 cores, 8 GB RAM, $540/month
- I2v2: 4 cores, 16 GB RAM, $1,080/month
- I3v2: 8 cores, 32 GB RAM, $2,160/month
- App Service Environment (ASE)
- Complete network isolation
- Use: Compliance, high security

### Azure Functions Pricing

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

## Key Takeaways

✅ Choose right VM size based on workload (CPU vs memory vs GPU)
✅ Use reserved instances for predictable workloads (40-60% savings)
✅ Implement auto-scaling to optimize costs
✅ Use appropriate storage tier based on access patterns
✅ Consider serverless options for variable workloads
✅ Enable Azure Hybrid Benefit for existing licenses
✅ Use Spot VMs for fault-tolerant workloads
✅ Monitor costs with budgets and alerts
✅ Right-size resources based on actual usage
✅ Use managed services to reduce operational overhead

# Advanced Practice Scenarios for AZ-305

## Scenario 1: Global E-Commerce Platform Migration

### Background
Contoso Retail is migrating their on-premises e-commerce platform to Azure. They have:
- 500 physical servers across 3 datacenters
- 50 TB SQL Server database
- 200 TB file storage
- 10 million customers globally
- Peak traffic: 100K concurrent users
- Compliance: PCI DSS, GDPR

### Requirements
1. 99.99% availability SLA
2. Sub-second response time globally
3. Zero data loss (RPO = 0)
4. Maximum 5-minute downtime (RTO = 5 min)
5. Cost optimization
6. Phased migration approach

### Questions

**Q1:** Which Azure regions should you deploy to for optimal global performance?
A) East US, West Europe, Southeast Asia
B) All available regions
C) East US only with Azure Front Door
D) East US and West US only

**Answer:** A
**Explanation:** Deploy to 3 strategic regions covering Americas, Europe, and Asia-Pacific for optimal latency. Azure Front Door provides global load balancing.

**Q2:** What database solution provides zero data loss with automatic failover?
A) Azure SQL Database with active geo-replication
B) SQL Managed Instance with auto-failover groups
C) SQL Server on VMs with Always On
D) Cosmos DB with strong consistency

**Answer:** B
**Explanation:** SQL MI auto-failover groups provide synchronous replication (RPO=0) with automatic failover capability.

**Q3:** How should you handle the 200 TB file storage migration?
A) Azure Files Premium
B) Blob Storage with lifecycle management
C) Data Lake Storage Gen2
D) Azure NetApp Files

**Answer:** B
**Explanation:** Blob Storage with Hot/Cool/Archive tiers provides cost-effective storage with lifecycle policies for aging data.

**Q4:** What's the best approach for phased migration?
A) Migrate all at once during maintenance window
B) Use Azure Migrate for assessment, then migrate in waves
C) Rebuild everything from scratch in Azure
D) Keep on-premises and use Azure as DR only

**Answer:** B
**Explanation:** Azure Migrate provides assessment tools. Migrate non-critical workloads first, then critical systems in phases.

**Q5:** How do you achieve PCI DSS compliance?
A) Use Azure Policy for compliance
B) Enable Microsoft Defender for Cloud
C) Implement network segmentation, encryption, and audit logging
D) All of the above

**Answer:** D
**Explanation:** PCI DSS requires multiple controls: governance (Policy), security monitoring (Defender), and technical controls (segmentation, encryption).

---

## Scenario 2: Healthcare SaaS Platform

### Background
MediCare Solutions is building a multi-tenant healthcare SaaS platform:
- 500 healthcare organizations (tenants)
- PHI (Protected Health Information) storage
- HIPAA compliance required
- 50K concurrent users
- Real-time patient monitoring
- Mobile app integration

### Requirements
1. Complete tenant isolation
2. Data residency (US only)
3. Audit all data access
4. 99.95% availability
5. Disaster recovery in different region
6. End-to-end encryption

### Questions

**Q6:** How should you implement tenant isolation?
A) Separate subscription per tenant
B) Separate resource group per tenant
C) Separate database per tenant with row-level security
D) Single database with tenant ID column

**Answer:** C
**Explanation:** Separate databases provide strong isolation. Row-level security adds additional protection within database.

**Q7:** What networking architecture ensures HIPAA compliance?
A) Public endpoints with firewall rules
B) Private endpoints with VNet integration
C) Service endpoints only
D) No networking restrictions needed

**Answer:** B
**Explanation:** HIPAA requires private connectivity. Private endpoints keep traffic on Microsoft backbone, never traversing internet.

**Q8:** How do you audit all PHI access?
A) Azure Monitor logs only
B) SQL Database auditing only
C) Azure Sentinel with custom analytics rules
D) All of the above with long-term retention

**Answer:** D
**Explanation:** HIPAA requires comprehensive auditing. Combine Azure Monitor, SQL auditing, and Sentinel for complete visibility with 7-year retention.

**Q9:** What encryption strategy meets HIPAA requirements?
A) Encryption at rest only
B) Encryption in transit only
C) Both at rest and in transit with customer-managed keys
D) No encryption needed if using private endpoints

**Answer:** C
**Explanation:** HIPAA requires encryption at rest and in transit. Customer-managed keys provide additional control and compliance evidence.

**Q10:** How do you implement disaster recovery?
A) Azure Site Recovery to secondary region
B) Geo-redundant storage only
C) SQL MI auto-failover groups + ASR for VMs + GRS storage
D) Manual failover procedures

**Answer:** C
**Explanation:** Comprehensive DR requires multiple services: SQL MI failover groups for databases, ASR for VMs, GRS for storage.

---

## Scenario 3: Financial Services - Real-Time Trading Platform

### Background
TradeFast Inc. operates a high-frequency trading platform:
- 1 million transactions per second
- Sub-millisecond latency required
- 24/7 operation
- Zero downtime tolerance
- Real-time risk analytics
- Regulatory compliance (SOC 2, ISO 27001)

### Requirements
1. Ultra-low latency
2. Active-Active across regions
3. Real-time data replication
4. Immutable audit logs
5. Automated failover
6. Cost: Not a primary concern

### Questions

**Q11:** What compute solution provides sub-millisecond latency?
A) App Service Premium
B) AKS with Standard VMs
C) VMs with Ultra Disk and Accelerated Networking
D) Azure Functions Premium

**Answer:** C
**Explanation:** Ultra Disks provide sub-millisecond latency. Accelerated Networking bypasses host virtualization for lowest network latency.

**Q12:** What database solution supports 1M transactions/second?
A) Azure SQL Database Hyperscale
B) Cosmos DB with provisioned throughput
C) Azure Cache for Redis Enterprise
D) SQL Server on M-series VMs with In-Memory OLTP

**Answer:** D
**Explanation:** M-series VMs with massive memory + In-Memory OLTP provide highest transaction throughput for relational data.

**Q13:** How do you implement Active-Active across regions?
A) Traffic Manager with priority routing
B) Azure Front Door with equal weight distribution
C) Cosmos DB multi-region writes + Traffic Manager
D) Manual DNS failover

**Answer:** C
**Explanation:** Cosmos DB multi-region writes allow simultaneous writes to multiple regions. Traffic Manager distributes load.

**Q14:** What ensures immutable audit logs for compliance?
A) Log Analytics with retention
B) Storage Account with immutable blob storage (WORM)
C) Azure Sentinel only
D) SQL Database audit logs

**Answer:** B
**Explanation:** Immutable blob storage (Write Once, Read Many) prevents deletion or modification, meeting regulatory requirements.

**Q15:** How do you achieve zero downtime deployments?
A) Blue-green deployment with Traffic Manager
B) Rolling updates in AKS
C) Deployment slots in App Service
D) All of the above depending on service

**Answer:** D
**Explanation:** Different services use different strategies. AKS uses rolling updates, App Service uses slots, VMs use blue-green with Traffic Manager.

---

## Scenario 4: IoT Manufacturing Platform

### Background
SmartFactory Inc. operates IoT-enabled manufacturing:
- 100,000 IoT devices
- 10 million events per second
- Real-time anomaly detection
- Predictive maintenance
- 7-year data retention
- Edge computing requirements

### Requirements
1. Ingest 10M events/second
2. Real-time analytics (< 1 second)
3. Machine learning inference at edge
4. Historical data analysis
5. Cost-effective long-term storage
6. Global deployment

### Questions

**Q16:** What service ingests 10M events/second?
A) Event Hubs Standard
B) Event Hubs Premium with 40 throughput units
C) Event Hubs Dedicated
D) IoT Hub Standard

**Answer:** C
**Explanation:** Event Hubs Dedicated provides highest throughput (multiple GB/s) for extreme ingestion rates.

**Q17:** How do you implement real-time anomaly detection?
A) Azure Stream Analytics with ML models
B) Azure Functions processing events
C) Databricks Structured Streaming
D) Azure Synapse Spark

**Answer:** A
**Explanation:** Stream Analytics provides sub-second latency with built-in ML model integration for real-time anomaly detection.

**Q18:** What's the cost-effective storage strategy for 7 years?
A) Hot tier for all data
B) Hot (30 days) → Cool (1 year) → Archive (6 years)
C) Premium tier for performance
D) Data Lake Gen2 Hot tier only

**Answer:** B
**Explanation:** Lifecycle management automatically tiers data: Hot for recent, Cool for occasional access, Archive for compliance retention.

**Q19:** How do you deploy ML models to edge devices?
A) Azure IoT Edge with custom modules
B) Azure Machine Learning edge deployment
C) Container instances on edge
D) Both A and B

**Answer:** D
**Explanation:** IoT Edge runs containers on edge devices. Azure ML can package models as IoT Edge modules for deployment.

**Q20:** What architecture supports historical data analysis?
A) Event Hubs → Stream Analytics → Data Lake → Synapse Analytics
B) IoT Hub → Cosmos DB → Power BI
C) Event Hubs → SQL Database → SSRS
D) IoT Hub → Blob Storage → Excel

**Answer:** A
**Explanation:** Data Lake stores raw data cost-effectively. Synapse Analytics provides powerful querying and ML capabilities for historical analysis.

---

## Scenario 5: Media Streaming Platform

### Background
StreamNow operates a global video streaming service:
- 5 million concurrent viewers
- 4K/8K video streaming
- Live events + VOD
- 100 PB content library
- DRM protection
- Global CDN

### Requirements
1. Sub-100ms latency globally
2. Adaptive bitrate streaming
3. Content protection (DRM)
4. Cost optimization for storage
5. Live streaming capability
6. 99.9% availability

### Questions

**Q21:** What service provides global video delivery?
A) Azure CDN Premium Verizon
B) Azure Front Door
C) Azure Media Services + CDN
D) Blob Storage with CDN

**Answer:** C
**Explanation:** Media Services handles encoding, packaging, and DRM. CDN provides global edge caching for low latency delivery.

**Q22:** How do you implement adaptive bitrate streaming?
A) Single bitrate encoding
B) Multiple bitrate encoding with HLS/DASH
C) Client-side transcoding
D) Manual bitrate selection

**Answer:** B
**Explanation:** Media Services encodes multiple bitrates. HLS/DASH protocols automatically adapt based on network conditions.

**Q23:** What DRM solution protects premium content?
A) Azure Media Services with PlayReady + Widevine + FairPlay
B) Custom encryption only
C) No DRM needed
D) Storage account encryption

**Answer:** A
**Explanation:** Media Services supports all major DRM systems: PlayReady (Windows), Widevine (Android), FairPlay (iOS).

**Q24:** How do you optimize storage costs for 100 PB?
A) Premium storage for all content
B) Hot tier for popular content, Archive for old content
C) Standard HDD for everything
D) Delete old content

**Answer:** B
**Explanation:** Use Hot tier for frequently accessed content, automatically move aging content to Archive tier (99% cost reduction).

**Q25:** What architecture supports live streaming?
A) Media Services Live Events → Streaming Endpoints → CDN
B) Blob Storage → CDN
C) App Service → CDN
D) Azure Functions → CDN

**Answer:** A
**Explanation:** Media Services Live Events ingest live streams, encode in real-time, and deliver through Streaming Endpoints to CDN.

---

## Complex Multi-Service Scenarios

### Scenario 6: Hybrid Cloud Architecture

**Q26:** Company has on-premises datacenter and wants hybrid cloud. What connectivity provides 10 Gbps with 99.95% SLA?
A) Site-to-Site VPN
B) ExpressRoute Standard
C) ExpressRoute Premium
D) Multiple VPN tunnels

**Answer:** C
**Explanation:** ExpressRoute Premium provides up to 10 Gbps with 99.95% SLA and global connectivity.

**Q27:** How do you extend on-premises AD to Azure?
A) Azure AD Connect with password hash sync
B) Azure AD Connect with pass-through authentication
C) Azure AD Connect with federation (ADFS)
D) All are valid options depending on requirements

**Answer:** D
**Explanation:** All three methods work. Choose based on requirements: PHS (simplest), PTA (no password in cloud), Federation (most control).

**Q28:** What enables seamless failover between on-premises and Azure?
A) Azure Site Recovery with recovery plans
B) Manual VM migration
C) Backup and restore
D) Azure Migrate

**Answer:** A
**Explanation:** ASR provides automated failover with recovery plans that orchestrate multi-tier application failover.

---

## Key Takeaways from Scenarios

✅ **Always consider:** Availability, Performance, Security, Cost, Compliance  
✅ **Multi-region:** Use for global applications and DR  
✅ **Right-size:** Choose appropriate service tiers  
✅ **Defense in depth:** Multiple security layers  
✅ **Automation:** Reduce human error and recovery time  
✅ **Monitoring:** Implement comprehensive observability  
✅ **Cost optimization:** Use reserved instances, lifecycle policies  
✅ **Compliance:** Understand regulatory requirements upfront

---

**© Copyright Sivakumar J - All Rights Reserved**
